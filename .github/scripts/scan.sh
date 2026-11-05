#!/usr/bin/env bash
# Security gate: escanea una imagen con Trivy en cada plataforma y falla si encuentra
# vulnerabilidades HIGH o CRITICAL con fix disponible (salvo las de .trivyignore.yaml).
#
# Uso: scan.sh <imagen> <plataformas separadas por coma>
# Entradas (variables de entorno):
#   TRIVY_IMAGE      imagen de Trivy a usar (versión fijada en el workflow)
#   TRIVY_CACHE_DIR  directorio de la base de datos de Trivy (default ~/.cache/trivy)
#   SARIF_DIR        si se define (ruta relativa al directorio actual), deja además el
#                    reporte completo de la primera plataforma en $SARIF_DIR/results.sarif
set -euo pipefail

image=$1
IFS=, read -ra platforms <<<"$2"
: "${TRIVY_IMAGE:?TRIVY_IMAGE no definido}"
cache=${TRIVY_CACHE_DIR:-$HOME/.cache/trivy}
mkdir -p "$cache"
[[ -n ${SARIF_DIR:-} ]] && mkdir -p "$SARIF_DIR"

trivy() {
  # --network host: para leer imágenes del registry local (localhost:5000).
  # --user: que la caché y los reportes queden a nombre del runner (actions/cache).
  docker run --rm --network host \
    --user "$(id -u):$(id -g)" -e HOME=/tmp \
    -v "$cache:/cache" \
    -v "$PWD:/work" -w /work \
    "$TRIVY_IMAGE" "$@"
}

common=(
  image
  --cache-dir /cache
  --cache-backend memory
  --scanners vuln
  --ignorefile .trivyignore.yaml
  --timeout 30m
  --quiet
)

report=$(mktemp)
trap 'rm -f "$report"' EXIT

status=0
for platform in "${platforms[@]}"; do
  echo "::group::Trivy $image ($platform)"
  set +e
  trivy "${common[@]}" --platform "$platform" \
    --severity CRITICAL,HIGH --ignore-unfixed --exit-code 1 \
    --format table --table-mode detailed "$image" | tee "$report"
  rc=${PIPESTATUS[0]}
  set -e
  echo "::endgroup::"

  if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
    {
      echo "### Trivy: \`$image\` ($platform)"
      if [[ $rc -eq 0 ]]; then
        echo "✅ Sin vulnerabilidades HIGH/CRITICAL con fix disponible."
      else
        echo '<details open><summary>❌ Vulnerabilidades encontradas</summary>'
        echo; echo '```'; cat "$report"; echo '```'; echo '</details>'
      fi
      echo
    } >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ $rc -ne 0 ]]; then
    echo "::error::$image ($platform) tiene vulnerabilidades HIGH/CRITICAL con fix disponible (exit $rc)"
    status=1
  fi
done

if [[ -n ${SARIF_DIR:-} ]]; then
  # Reporte completo (todas las severidades) para la pestaña Security de GitHub
  trivy "${common[@]}" --platform "${platforms[0]}" --format sarif \
    --output "$SARIF_DIR/results.sarif" "$image" \
    || echo "::warning::No se pudo generar el reporte SARIF de $image"
fi

exit $status
