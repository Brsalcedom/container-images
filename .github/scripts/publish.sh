#!/usr/bin/env bash
# Publishes to Docker Hub the image already built and scanned in the local registry,
# without rebuilding it: the same multi-arch index (same digest) that passed the gate
# is copied.
#
# Usage:
#   publish.sh exists <repo> <version>          exit 0 if <repo>:<version> already exists
#   publish.sh push <source> <repo> <version>   publishes X.Y.Z and moves X.Y, X and latest
#                                               only if <version> is the highest in its line
# Requires skopeo (preinstalled on ubuntu-latest) and a prior `docker login` (skopeo
# reads ~/.docker/config.json).
set -euo pipefail

semver_re='^[0-9]+\.[0-9]+\.[0-9]+$'

exists() { # <ref>
  local out
  if out=$(skopeo inspect --raw "docker://$1" 2>&1 >/dev/null); then
    return 0
  fi
  # Docker Hub answers "denied"/"unauthorized" for repositories that do not exist yet
  if grep -qiE 'manifest unknown|not found|denied|unauthorized' <<<"$out"; then
    return 1
  fi
  echo "::error::Could not query $1: $out" >&2
  exit 2
}

# Is $version the highest among the published semver tags starting with $prefix?
is_highest() { # <prefix> <version> <tags>
  local prefix=$1 version=$2 tags=$3 max
  max=$({ grep -F "$prefix" <<<"$tags" | grep -E "^${prefix//./\\.}" || true; echo "$version"; } | sort -V | tail -n1)
  [[ $max == "$version" ]]
}

case ${1:-} in
  exists)
    exists "$2:$3"
    ;;
  push)
    src=$2 repo=$3 version=$4
    [[ $version =~ $semver_re ]] || { echo "::error::Invalid version: $version" >&2; exit 1; }
    if exists "$repo:$version"; then
      echo "::error::$repo:$version already exists: published versions are never overwritten" >&2
      exit 1
    fi

    published=$(skopeo list-tags "docker://$repo" 2>/dev/null | jq -r '.Tags[]' | grep -E "$semver_re" || true)
    major=${version%%.*}
    minor=${version%.*}
    tags=("$version")
    is_highest "$minor." "$version" "$published" && tags+=("$minor")
    is_highest "$major." "$version" "$published" && tags+=("$major")
    is_highest "" "$version" "$published" && tags+=(latest)

    for tag in "${tags[@]}"; do
      echo "Publishing $repo:$tag"
      skopeo copy --all --preserve-digests --retry-times 3 --src-tls-verify=false \
        "docker://$src" "docker://$repo:$tag"
    done

    digest=$(skopeo inspect --raw "docker://$repo:$version" | sha256sum | cut -d' ' -f1)
    if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
      {
        echo "### Published \`$repo:$version\`"
        echo "Digest: \`sha256:$digest\`"
        echo
        echo "Tags: $(printf '`%s` ' "${tags[@]}")"
      } >> "$GITHUB_STEP_SUMMARY"
    fi
    ;;
  *)
    echo "Usage: $0 exists <repo> <version> | push <source> <repo> <version>" >&2
    exit 1
    ;;
esac
