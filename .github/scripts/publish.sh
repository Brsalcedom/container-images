#!/usr/bin/env bash
# Publica en Docker Hub la imagen ya construida y escaneada en el registry local, sin
# reconstruirla: se copia el mismo índice multi-arch (mismo digest) que pasó el gate.
#
# Uso:
#   publish.sh exists <repo> <version>          exit 0 si <repo>:<version> ya existe
#   publish.sh push <origen> <repo> <version>   publica X.Y.Z y mueve X.Y, X y latest
#                                               solo si <version> es la más alta de su rama
# Requiere skopeo (preinstalado en ubuntu-latest) y `docker login` previo (skopeo usa
# ~/.docker/config.json).
set -euo pipefail

semver_re='^[0-9]+\.[0-9]+\.[0-9]+$'

exists() { # <ref>
  local out
  if out=$(skopeo inspect --raw "docker://$1" 2>&1 >/dev/null); then
    return 0
  fi
  # Docker Hub responde "denied"/"unauthorized" para repositorios que todavía no existen
  if grep -qiE 'manifest unknown|not found|denied|unauthorized' <<<"$out"; then
    return 1
  fi
  echo "::error::No se pudo consultar $1: $out" >&2
  exit 2
}

# ¿Es $version la más alta entre los tags semver publicados que empiezan con $prefix?
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
    [[ $version =~ $semver_re ]] || { echo "::error::Versión inválida: $version" >&2; exit 1; }
    if exists "$repo:$version"; then
      echo "::error::$repo:$version ya existe: las versiones publicadas no se sobrescriben" >&2
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
      echo "Publicando $repo:$tag"
      skopeo copy --all --preserve-digests --retry-times 3 --src-tls-verify=false \
        "docker://$src" "docker://$repo:$tag"
    done

    digest=$(skopeo inspect --raw "docker://$repo:$version" | sha256sum | cut -d' ' -f1)
    if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
      {
        echo "### Publicado \`$repo:$version\`"
        echo "Digest: \`sha256:$digest\`"
        echo
        echo "Tags: $(printf '`%s` ' "${tags[@]}")"
      } >> "$GITHUB_STEP_SUMMARY"
    fi
    ;;
  *)
    echo "Uso: $0 exists <repo> <version> | push <origen> <repo> <version>" >&2
    exit 1
    ;;
esac
