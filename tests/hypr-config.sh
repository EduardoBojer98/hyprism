#!/usr/bin/env bash
# Hyprland's own check of the config (hyprland --verify-config), once per made-up computer from
# tests/detect.sh, each in a throwaway home folder with every module's Lua linked in. Starts nothing and
# touches nothing in your session. Skipped when Hyprland isn't installed.
#   tests/hypr-config.sh
set -euo pipefail
cd "$(dirname "$0")/.."
command -v hyprland >/dev/null || {
    echo "skipped: Hyprland isn't installed"
    exit 0
}
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
bash tests/detect.sh make "$t/fixtures"
fail=0
for profile in "$t"/fixtures/*/; do
    name=$(basename "$profile")
    home=$t/home-$name
    mkdir -p "$home/.config/hypr/hardware" "$home/.config/hyprism"
    ln -s "$PWD/config/hypr/.config/hypr/hyprland.lua" "$PWD/config/hypr/.config/hypr/modules" "$home/.config/hypr/"
    HYPRISM_ROOT=$profile HYPRISM_HARDWARE=$home/.config/hyprism/hardware.toml bash -c '. lib/detect.sh; detect_write'
    # every module's Lua at once: more than any real computer loads, so each file is checked on each profile
    for f in modules/*/home/.config/hypr/hardware/*.lua; do
        ln -s "$PWD/$f" "$home/.config/hypr/hardware/"
        basename "$f" .lua >>"$home/.config/hypr/hardware/index"
    done
    out=$(HOME=$home XDG_CONFIG_HOME=$home/.config hyprland --verify-config -c "$home/.config/hypr/hyprland.lua" 2>&1) || true # judged by its text below
    if grep -qi 'config ok\|no errors' <<<"$out"; then
        echo "ok: Hyprland accepts the config on $name"
    else
        echo "xx Hyprland rejects the config on $name:"
        cat <<<"$out"
        fail=1
    fi
done
exit "$fail"
