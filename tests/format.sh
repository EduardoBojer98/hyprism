#!/usr/bin/env bash
# Shell formatting and lint for every shell file, with the tools from Docker when they aren't installed.
#   tests/format.sh          check (what CI runs): shfmt -d and shellcheck at style level
#   tests/format.sh fix      rewrite the files with shfmt
set -euo pipefail
cd "$(dirname "$0")/.."
mapfile -t files < <(tests/shell-files.sh)

tool() { # tool NAME IMAGE ARGS...: the installed one, else the Docker image
    local name=$1 image=$2
    shift 2
    if command -v "$name" >/dev/null; then
        "$name" "$@"
    else
        docker run --rm -u "$(id -u):$(id -g)" -v "$PWD":/mnt -w /mnt "$image" "$@"
    fi
}

if [[ ${1:-} == fix ]]; then
    tool shfmt mvdan/shfmt:v3 -w -i 4 -ci "${files[@]}"
    exit 0
fi
fail=0
tool shfmt mvdan/shfmt:v3 -d -i 4 -ci "${files[@]}" || fail=1
tool shellcheck koalaman/shellcheck:stable -x -S style "${files[@]}" || fail=1
((fail == 0)) && echo "ok: ${#files[@]} shell files formatted and lint-clean"
exit "$fail"
