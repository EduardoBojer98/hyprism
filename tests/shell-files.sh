#!/usr/bin/env bash
# Prints every shell file in the repo, one per line: the one list that shellcheck, shfmt and CI all use.
#   tests/shell-files.sh
set -euo pipefail
cd "$(dirname "$0")/.."
for f in install.sh lib/*.sh distros/*.sh migrations/*.sh modules/*/steps/*.sh modules/*/doctor modules/*/detect \
    modules/*/home/.local/bin/* config/themes/.local/share/hyprism/themes/*/wallpaper.sh tests/*.sh .githooks/pre-commit config/scripts/.local/bin/* config/scripts/.local/lib/hyprism/*.sh; do
    [[ -f $f ]] || continue
    head -1 "$f" | grep -qE '^#!.*(bash|sh)|shellcheck shell=bash' && echo "$f"
done
