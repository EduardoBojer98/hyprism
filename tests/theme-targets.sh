#!/usr/bin/env bash
# The theme reaches every program it is pushed to: in a test desktop (session "c"), switch to three themes and
# check each generated file holds that theme's accent. Needs the test desktop, so tests/lint.sh does not run it.
# Run by hand: tests/theme-targets.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
export HYPRISM_TEST_NAME=c
fail=0
check() { if [[ $2 == ok ]]; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }
trap 'tests/nested.sh stop >/dev/null 2>&1' EXIT
tests/nested.sh start >/dev/null || exit 1
T=$(. "$XDG_RUNTIME_DIR/hyprism-nested-c/env" && echo "$T")
for id in reactor atlas glass; do
    tests/nested.sh ipc config set appearance theme "$id" >/dev/null
    sleep 2
    accent=$(jq -r .colour.accent "themes/$id/theme.json")
    bare=${accent#\#}
    for pair in ghostty/theme.conf:"$accent" qt6ct/colors/hyprism.conf:"#ff$bare" btop/themes/hyprism.theme:"$accent" \
        hyprism/starship.toml:"$accent" hypr/settings/theme.lua:"$bare" gtk-4.0/hyprism.css:"$accent"; do
        f=${pair%%:*} want=${pair#*:}
        r=no
        grep -qiF -- "$want" "$T/.config/$f" 2>/dev/null && r=ok
        check "$id: $f has $want" "$r"
    done
done
exit $fail
