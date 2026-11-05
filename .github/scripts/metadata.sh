#!/usr/bin/env bash
# Reads and validates the OCI metadata of an image from its Dockerfile labels, and
# emits it for the workflow: index annotations (GHCR reads them from the index of
# multi-arch images, not from the per-platform labels) and the Docker Hub short
# description.
#
# Usage: metadata.sh <image>
# Outputs ($GITHUB_OUTPUT): title, description, source, authors, licenses, created
set -euo pipefail

name=$1
dockerfile=images/$name/Dockerfile
required=(title description source authors licenses)
max_description=100 # Docker Hub short description limit

label() { # <key>: value of org.opencontainers.image.<key>="..." in the Dockerfile
  grep -oP "org\.opencontainers\.image\.$1=\"\K[^\"]*" "$dockerfile" | head -n1 || true
}

status=0
declare -A meta
for key in "${required[@]}"; do
  meta[$key]=$(label "$key")
  if [[ -z ${meta[$key]} ]]; then
    echo "::error file=$dockerfile::Missing LABEL org.opencontainers.image.$key"
    status=1
  fi
done
if (( ${#meta[description]} > max_description )); then
  echo "::error file=$dockerfile::org.opencontainers.image.description is ${#meta[description]} characters; Docker Hub allows $max_description"
  status=1
fi
(( status == 0 )) || exit 1

# Commit time instead of build time: stable for a given commit
meta[created]=$(TZ=UTC git log -1 --date='format-local:%Y-%m-%dT%H:%M:%SZ' --format=%cd HEAD)

{
  for key in "${required[@]}" created; do
    echo "$key=${meta[$key]}"
  done
} >> "${GITHUB_OUTPUT:-/dev/stdout}"
