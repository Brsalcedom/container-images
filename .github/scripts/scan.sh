#!/usr/bin/env bash
# Security gate: scans an image with Trivy on every platform and fails if it finds
# HIGH or CRITICAL vulnerabilities with a fix available (except those in
# .trivyignore.yaml).
#
# Usage: scan.sh <image> <comma-separated platforms>
# Inputs (environment variables):
#   TRIVY_IMAGE      Trivy image to use (version pinned in the workflow)
#   TRIVY_CACHE_DIR  Trivy database directory (default ~/.cache/trivy)
#   SARIF_DIR        if set (path relative to the current directory), also writes the
#                    full report for the first platform to $SARIF_DIR/results.sarif
set -euo pipefail

image=$1
IFS=, read -ra platforms <<<"$2"
: "${TRIVY_IMAGE:?TRIVY_IMAGE is not set}"
cache=${TRIVY_CACHE_DIR:-$HOME/.cache/trivy}
mkdir -p "$cache"
[[ -n ${SARIF_DIR:-} ]] && mkdir -p "$SARIF_DIR"

trivy() {
  # --network host: to read images from the local registry (localhost:5000).
  # --user: keep the cache and reports owned by the runner user (actions/cache).
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
        echo "✅ No fixable HIGH/CRITICAL vulnerabilities."
      else
        echo '<details open><summary>❌ Vulnerabilities found</summary>'
        echo; echo '```'; cat "$report"; echo '```'; echo '</details>'
      fi
      echo
    } >> "$GITHUB_STEP_SUMMARY"
  fi

  if [[ $rc -ne 0 ]]; then
    echo "::error::$image ($platform) has fixable HIGH/CRITICAL vulnerabilities (exit $rc)"
    status=1
  fi
done

if [[ -n ${SARIF_DIR:-} ]]; then
  # Full report (all severities) for the GitHub Security tab
  trivy "${common[@]}" --platform "${platforms[0]}" --format sarif \
    --output "$SARIF_DIR/results.sarif" "$image" \
    || echo "::warning::Could not generate the SARIF report for $image"
fi

exit $status
