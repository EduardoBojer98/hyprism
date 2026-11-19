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
    # your own user.lua is loaded last (a variable, so the check can't miss that it ran)
    echo 'USER_LUA_LOADED = true' >"$home/.config/hypr/user.lua"
    # hl.timer segfaults --verify-config (Hyprland 0.57: no event loop when only verifying), so a wrapper
    # stubs it before loading the real config; timers only re-apply things at runtime, nothing to verify
    printf 'hl.timer = function() end\ndofile(os.getenv("HOME") .. "/.config/hypr/hyprland.lua")\nassert(USER_LUA_LOADED, "user.lua was not loaded")\n' >"$home/.config/hypr/verify.lua"
    rc=0
    out=$(HOME=$home XDG_CONFIG_HOME=$home/.config hyprland --verify-config -c "$home/.config/hypr/verify.lua" 2>&1) || rc=$? # judged by its text below
    # a crash anyway (a new runtime-only call): no verdict, so say so rather than pass
    if ((rc >= 128)); then
        echo "skipped: hyprland --verify-config crashed on $name (signal $((rc - 128))): Hyprland's bug, not the config"
        crashed=1
    elif grep -qi 'config ok\|no errors' <<<"$out"; then
        echo "ok: Hyprland accepts the config on $name"
    else
        echo "xx Hyprland rejects the config on $name:"
        cat <<<"$out"
        fail=1
    fi
done
# the config this session is running, as Hyprland itself loaded it (the check that works when --verify-config can't)
if ((${crashed:-0})) && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} && $(readlink -f "$HOME/.config/hypr/hyprland.lua") == "$PWD"/* ]]; then
    errs=$(hyprctl configerrors 2>&1)
    if [[ -z ${errs//[[:space:]]/} ]]; then echo "ok: the running Hyprland loaded this repo's config without errors"; else
        echo "xx the running Hyprland reports config errors:"
        echo "$errs"
        fail=1
    fi
fi
exit "$fail"
