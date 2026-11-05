#!/usr/bin/env bash
# Publishes the image already built and scanned in the local registry to one or more
# registries, without rebuilding it: the same multi-arch index (same digest) that
# passed the gate is copied to every registry.
#
# Usage:
#   publish.sh exists <repo> <version>
#       exit 0 if <repo>:<version> already exists, 1 if it does not
#   publish.sh push <source> <version> <repo> [<repo>...]
#       publishes X.Y.Z to each repo and moves X.Y, X and latest only if <version> is
#       the highest in its line *in that repo*; never overwrites an existing X.Y.Z
#   publish.sh in-sync <version> <repo> [<repo>...]
#       fails if <version> is missing from any repo or the digests differ
#
# <repo> is a full reference without tag, e.g. docker.io/brsalcedom/kubetools or
# ghcr.io/brsalcedom/kubetools. Requires skopeo (preinstalled on ubuntu-latest) and a
# prior `docker login` to each registry (skopeo reads ~/.docker/config.json).
set -euo pipefail

semver_re='^[0-9]+\.[0-9]+\.[0-9]+$'

exists() { # <ref>
  local out
  if out=$(skopeo inspect --raw "docker://$1" 2>&1 >/dev/null); then
    return 0
  fi
  # Registries answer "denied"/"unauthorized" (Docker Hub) or "403 Forbidden" (GHCR)
  # for repositories that do not exist yet. A real permission problem still surfaces
  # as a failed push.
  if grep -qiE 'manifest unknown|not found|denied|unauthorized|forbidden' <<<"$out"; then
    return 1
  fi
  echo "::error::Could not query $1: $out" >&2
  exit 2
}

digest() { # <ref>: digest of the manifest (index) as stored in the registry
  echo "sha256:$(skopeo inspect --raw "docker://$1" | sha256sum | cut -d' ' -f1)"
}

# Is $version the highest among the published semver tags starting with $prefix?
is_highest() { # <prefix> <version> <tags>
  local prefix=$1 version=$2 tags=$3 max
  max=$({ grep -F "$prefix" <<<"$tags" | grep -E "^${prefix//./\\.}" || true; echo "$version"; } | sort -V | tail -n1)
  [[ $max == "$version" ]]
}

summary() {
  [[ -n ${GITHUB_STEP_SUMMARY:-} ]] && cat >> "$GITHUB_STEP_SUMMARY" || cat > /dev/null
}

push_one() { # <source> <version> <repo>
  local src=$1 version=$2 repo=$3 published major minor tag
  if exists "$repo:$version"; then
    echo "::error::$repo:$version already exists: published versions are never overwritten" >&2
    return 1
  fi

  published=$(skopeo list-tags "docker://$repo" 2>/dev/null | jq -r '.Tags[]' | grep -E "$semver_re" || true)
  major=${version%%.*}
  minor=${version%.*}
  local tags=("$version")
  is_highest "$minor." "$version" "$published" && tags+=("$minor")
  is_highest "$major." "$version" "$published" && tags+=("$major")
  is_highest "" "$version" "$published" && tags+=(latest)

  for tag in "${tags[@]}"; do
    echo "Publishing $repo:$tag"
    skopeo copy --all --preserve-digests --retry-times 3 --src-tls-verify=false \
      "docker://$src" "docker://$repo:$tag"
  done

  echo "| \`$repo\` | \`$(digest "$repo:$version")\` | $(printf '`%s` ' "${tags[@]}")|" | summary
}

case ${1:-} in
  exists)
    exists "$2:$3"
    ;;

  push)
    src=$2 version=$3
    shift 3
    [[ $version =~ $semver_re ]] || { echo "::error::Invalid version: $version" >&2; exit 1; }
    [[ $# -gt 0 ]] || { echo "::error::No target repositories" >&2; exit 1; }
    printf '### Published %s\n\n| Repository | Digest | Tags |\n|---|---|---|\n' "$version" | summary
    status=0
    for repo in "$@"; do
      push_one "$src" "$version" "$repo" || status=1
    done
    echo | summary
    exit $status
    ;;

  in-sync)
    version=$2
    shift 2
    status=0 first=""
    printf '### Registry sync: %s\n\n| Repository | Digest |\n|---|---|\n' "$version" | summary
    for repo in "$@"; do
      if ! exists "$repo:$version"; then
        echo "::error::$repo:$version is missing"
        echo "| \`$repo\` | ❌ missing |" | summary
        status=1
        continue
      fi
      d=$(digest "$repo:$version")
      echo "$repo:$version -> $d"
      if [[ -z $first ]]; then
        first=$d
      elif [[ $d != "$first" ]]; then
        echo "::error::$repo:$version has digest $d, expected $first"
        status=1
      fi
      echo "| \`$repo\` | \`$d\` |" | summary
    done
    echo | summary
    exit $status
    ;;

  *)
    echo "Usage: $0 exists <repo> <version> | push <source> <version> <repo>... | in-sync <version> <repo>..." >&2
    exit 1
    ;;
esac
