#!/usr/bin/env bash
# Decides which images to process and emits them as a GitHub Actions matrix.
#
# Sources:
#   images.yml                     per-image build settings
#   .release-please-manifest.json  version of each image (maintained by release-please)
#
# Inputs (environment variables):
#   EVENT        github.event_name
#   BASE_SHA     commit to compare against (PR base or the push `before`)
#   INPUT_IMAGE  workflow_dispatch: a single image (empty = all)
#   ALL          "true" to always process every image (e.g. scheduled scan)
# Outputs ($GITHUB_OUTPUT):
#   images  JSON with [{name, version, repos, platforms, test, free-disk-space, cache, sbom}]
#           `repos` = every registry/namespace the image is published to + "/<name>"
#   any     "true" if there is at least one image
set -euo pipefail

CONFIG=images.yml
VERSIONS=.release-please-manifest.json
DEFAULT_PLATFORMS="linux/amd64,linux/arm64"
DEFAULT_REGISTRIES='["docker.io/brsalcedom"]'

registries_at() { # <ref|WORKTREE>: top-level `registries` list
  if [[ $1 == WORKTREE ]]; then
    yq -o=json -I=0 ".registries // $DEFAULT_REGISTRIES" "$CONFIG"
  else
    git show "$1:$CONFIG" 2>/dev/null | yq -o=json -I=0 ".registries // $DEFAULT_REGISTRIES" 2>/dev/null || echo null
  fi
}

# Note: do not use `// true` for booleans; `//` treats `false` as missing.
all=$(yq -o=json -I=0 '
  .images | to_entries | map({
    "name": .key,
    "registries": (.value.registries // null),
    "platforms": (.value.platforms // "'"$DEFAULT_PLATFORMS"'"),
    "test": (.value.test // ""),
    "free-disk-space": (.value."free-disk-space" == true),
    "cache": (.value.cache != false),
    "sbom": (.value.sbom != false)
  })' "$CONFIG" \
  | jq -c --slurpfile v "$VERSIONS" --argjson r "$(registries_at WORKTREE)" '
      map(. + {
        version: ($v[0]["images/\(.name)"] // ""),
        repos: ((.registries // $r) as $regs | .name as $n | $regs | map("\(.)/\($n)"))
      } | del(.registries))')

# Every image needs a strict X.Y.Z semver version: the X.Y.Z, X.Y, X and latest tags
# are derived from it
invalid=$(jq -r 'map(select(.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$") | not))
                 | map("\(.name)=\(.version | if . == "" then "<no version>" else . end)")
                 | join(", ")' <<<"$all")
if [[ -n $invalid ]]; then
  echo "::error file=$VERSIONS::Images without an X.Y.Z semver version in $VERSIONS (and release-please-config.json): $invalid"
  exit 1
fi

select_names() {
  jq -c 'map(select(.name as $n | $ARGS.positional | any(. == $n)))' --args "$@" <<<"$all"
}

config_entry() { # <ref> <name>
  git show "$1:$CONFIG" 2>/dev/null | yq -o=json -I=0 ".images.\"$2\"" 2>/dev/null || echo null
}

version_at() { # <ref> <name>
  git show "$1:$VERSIONS" 2>/dev/null | jq -r --arg k "images/$2" '.[$k] // empty' 2>/dev/null || true
}

if [[ ${ALL:-false} == true ]]; then
  selected=$all
elif [[ $EVENT == workflow_dispatch && -n ${INPUT_IMAGE:-} ]]; then
  selected=$(select_names "$INPUT_IMAGE")
  if [[ $(jq length <<<"$selected") -eq 0 ]]; then
    echo "::error::Image '$INPUT_IMAGE' does not exist in $CONFIG"
    exit 1
  fi
elif [[ $EVENT == workflow_dispatch || -z ${BASE_SHA:-} || $BASE_SHA =~ ^0+$ ]] \
  || ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  selected=$all
else
  changed=$(git diff --name-only "$BASE_SHA" HEAD)
  echo "Changed files:"; sed 's/^/  /' <<<"$changed"

  # Changes to the pipeline, shared scripts or the scan policy affect every image
  if grep -qE '^(\.github/workflows/images\.yml|\.github/scripts/|scripts/|\.trivyignore\.yaml|\.hadolint\.yaml)' <<<"$changed"; then
    selected=$all
  # A new registry has to be backfilled with the current version of every image
  elif [[ $(registries_at "$BASE_SHA") != "$(registries_at WORKTREE)" ]]; then
    echo "::notice::The registry list changed: processing every image to backfill the new registries."
    selected=$all
  else
    names=()
    for name in $(jq -r '.[].name' <<<"$all"); do
      new_version=$(jq -r --arg n "$name" '.[] | select(.name == $n) | .version' <<<"$all")
      old_version=$(version_at "$BASE_SHA" "$name")
      dir_changed=false
      grep -q "^images/$name/" <<<"$changed" && dir_changed=true

      if [[ $dir_changed == true || $old_version != "$new_version" ]] \
        || [[ $(config_entry "$BASE_SHA" "$name") != "$(config_entry HEAD "$name")" ]]; then
        names+=("$name")
      fi
      if [[ $dir_changed == true && $old_version == "$new_version" ]]; then
        echo "::notice::'$name' changed but its version is still $new_version: it is built and scanned, but only published once the release PR is merged."
      fi
    done
    selected=$(select_names "${names[@]}")
  fi
fi

echo "Selected images: $(jq -r 'map("\(.name)@\(.version)") | join(", ")' <<<"$selected")"
{
  echo "images=$selected"
  echo "any=$(jq 'length > 0' <<<"$selected")"
} >> "${GITHUB_OUTPUT:-/dev/stdout}"
