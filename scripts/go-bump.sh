#!/bin/sh
# Raises Go dependencies of the current module to a minimum version, never downgrading.
# Used to patch CVEs in upstream tools whose latest release still ships a vulnerable
# dependency.
# Usage: go-bump.sh module@version [module@version ...]
set -eu

for spec in "$@"; do
    mod=${spec%@*}
    want=${spec#*@}
    have=$(go list -m -f '{{.Version}}' "$mod" 2>/dev/null || true)
    if [ -z "$have" ]; then
        echo "go-bump: $mod is not a dependency, skipping"
        continue
    fi
    if [ "$(printf '%s\n%s\n' "$have" "$want" | sort -V | tail -n1)" != "$have" ]; then
        echo "go-bump: $mod $have -> $want"
        go get "$mod@$want"
    else
        echo "go-bump: $mod already at $have (>= $want), skipping"
    fi
done

go mod tidy
