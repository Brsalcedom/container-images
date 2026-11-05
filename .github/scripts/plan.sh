#!/usr/bin/env bash
# Decide qué imágenes hay que procesar y las emite como matrix de GitHub Actions.
#
# Fuentes:
#   images.yml                     configuración de build de cada imagen
#   .release-please-manifest.json  versión de cada imagen (la mantiene release-please)
#
# Entradas (variables de entorno):
#   EVENT        github.event_name
#   BASE_SHA     commit contra el que comparar (base del PR o `before` del push)
#   INPUT_IMAGE  workflow_dispatch: imagen puntual (vacío = todas)
#   ALL          "true" para procesar siempre todas (p.ej. escaneo programado)
# Salidas ($GITHUB_OUTPUT):
#   images  JSON con [{name, version, platforms, test, free-disk-space, cache}]
#   any     "true" si hay al menos una imagen
set -euo pipefail

CONFIG=images.yml
VERSIONS=.release-please-manifest.json
DEFAULT_PLATFORMS="linux/amd64,linux/arm64"

# Nota: no usar `// true` para booleanos; `//` trata `false` como ausente.
all=$(yq -o=json -I=0 '
  .images | to_entries | map({
    "name": .key,
    "platforms": (.value.platforms // "'"$DEFAULT_PLATFORMS"'"),
    "test": (.value.test // ""),
    "free-disk-space": (.value."free-disk-space" == true),
    "cache": (.value.cache != false)
  })' "$CONFIG" \
  | jq -c --slurpfile v "$VERSIONS" 'map(. + {version: ($v[0]["images/\(.name)"] // "")})')

# Toda imagen debe tener versión semver X.Y.Z: de ahí salen los tags X.Y.Z, X.Y, X y latest
invalid=$(jq -r 'map(select(.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$") | not))
                 | map("\(.name)=\(.version | if . == "" then "<sin versión>" else . end)")
                 | join(", ")' <<<"$all")
if [[ -n $invalid ]]; then
  echo "::error file=$VERSIONS::Imágenes sin versión semver X.Y.Z en $VERSIONS (y en release-please-config.json): $invalid"
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
    echo "::error::La imagen '$INPUT_IMAGE' no existe en $CONFIG"
    exit 1
  fi
elif [[ $EVENT == workflow_dispatch || -z ${BASE_SHA:-} || $BASE_SHA =~ ^0+$ ]] \
  || ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
  selected=$all
else
  changed=$(git diff --name-only "$BASE_SHA" HEAD)
  echo "Archivos modificados:"; sed 's/^/  /' <<<"$changed"

  # Cambios en el pipeline, en scripts compartidos o en la política de escaneo
  # afectan a todas las imágenes
  if grep -qE '^(\.github/workflows/images\.yml|\.github/scripts/|scripts/|\.trivyignore\.yaml|\.hadolint\.yaml)' <<<"$changed"; then
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
        echo "::notice::'$name' cambió pero su versión sigue en $new_version: se construye y escanea, pero se publica recién cuando se haga merge del PR de release."
      fi
    done
    selected=$(select_names "${names[@]}")
  fi
fi

echo "Imágenes seleccionadas: $(jq -r 'map("\(.name)@\(.version)") | join(", ")' <<<"$selected")"
{
  echo "images=$selected"
  echo "any=$(jq 'length > 0' <<<"$selected")"
} >> "${GITHUB_OUTPUT:-/dev/stdout}"
