#!/usr/bin/env bash
# Behaviour checks for the scripts that hold logic, in throwaway folders (nothing on this computer changes).
# Run by tests/lint.sh (CI) or by hand: tests/scripts.sh
# shellcheck disable=SC2016  # check takes its condition as a single-quoted string on purpose (eval runs it later)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
bin=$PWD/config/scripts/.local/bin
export HYPRISM_LIB=$PWD/config/scripts/.local/lib/hyprism # the scripts load their library from here
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
fail=0
# check NAME CONDITION: the condition is evaluated here, so it may use the variables set above it
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

# monswitch reads its config as KEY=value lines, never as shell: a command in a value is not run
mkdir -p "$t/cfg"
printf 'OUT=HDMI-A-1\nLAPTOP=0x11\nPC=$(touch %s/pwned)\n' "$t" >"$t/cfg/monswitch.conf"
# shellcheck disable=SC2034  # read inside check's condition
out=$(env -u HYPRLAND_INSTANCE_SIGNATURE XDG_CONFIG_HOME="$t/cfg" XDG_STATE_HOME="$t/state" bash "$bin/monswitch" pc 2>&1)
check "monswitch runs nothing from its config" '[[ ! -e $t/pwned ]]'
check "monswitch refuses a config value that isn't plain" '[[ $out == *"set PC"* ]]'

# desktop-reset puts Settings files aside (nothing deleted) and seeds the defaults Hyprland needs
mkdir -p "$t/home/quickshell" "$t/home/hypr/settings" "$t/home/ghostty"
echo '{"x":1}' >"$t/home/quickshell/settings.json"
echo 'return {}' >"$t/home/hypr/settings/theme.lua"
env -u HYPRLAND_INSTANCE_SIGNATURE XDG_CONFIG_HOME="$t/home" XDG_STATE_HOME="$t/state" bash "$bin/desktop-reset" >/dev/null 2>&1
# shellcheck disable=SC2034  # read inside check's condition
kept=$(find "$t/state/hyprism" -name settings.json 2>/dev/null | head -1)
check "desktop-reset keeps the old settings.json" '[[ -n $kept && $(cat "$kept") == "{\"x\":1}" ]]'
check "desktop-reset removes it from ~/.config" '[[ ! -e $t/home/quickshell/settings.json ]]'
check "desktop-reset seeds hypridle.conf" '[[ -f $t/home/hypr/settings/hypridle.conf ]]'

# every script (nv is plain sh and has no help) answers --help: exit 0, at least 2 lines, no raw "#" comment marks
for f in "$bin"/*; do
    n=${f##*/}
    [[ $n == nv ]] && continue
    # shellcheck disable=SC2034  # read inside check's condition
    help=$(env -u HYPRLAND_INSTANCE_SIGNATURE XDG_CONFIG_HOME="$t/cfg" XDG_STATE_HOME="$t/state" bash "$f" --help 2>&1)
    # shellcheck disable=SC2034  # read inside check's condition
    rc=$?
    check "$n --help prints help and exits 0" '((rc == 0)) && [[ $(wc -l <<<"$help") -ge 2 ]] && ! grep -q "^#" <<<"$help"'
done

# usage prints the header comment: the same lines as the file, minus the leading "# "
# shellcheck disable=SC2034  # read inside check's condition
hdr=$(awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$bin/remind")
check "usage output equals the script's header block" '[[ $(bash "$bin/remind" --help) == "$hdr" ]]'

# log writes under XDG_STATE_HOME, and a name that doesn't exist never fails hwmon
lib=$PWD/config/scripts/.local/lib/hyprism/common.sh
XDG_STATE_HOME="$t/logstate" bash -c '. "$1"; log hello' logtest "$lib"
check "log writes a timestamped line to its own file" 'grep -qE "^[0-9-]+ [0-9:]+ hello$" "$t/logstate/hyprism/logs/logtest.log"'
# shellcheck disable=SC2034  # read inside check's condition
none=$(bash -c 'set -e; . "$1"; hwmon nosuchname; echo end' x "$lib")
check "hwmon of an unknown name prints nothing and succeeds under set -e" '[[ $none == end ]]'

# package-manager commands live in distros/ only
check "no package-manager command in scripts or module bin dirs" '! grep -nwE "pacman|paru|yay|dnf|rpm" "$bin"/* modules/*/home/.local/bin/* 2>/dev/null | grep -q .'

# hypr-plugins build refuses a Hyprland tag that has no pin, before it downloads anything (stand-in tools on PATH)
mkdir -p "$t/fake"
printf '#!/bin/sh\necho "{\\"tag\\":\\"v0.0.0-nopin\\"}"\n' >"$t/fake/hyprctl"
printf '#!/bin/sh\n' >"$t/fake/notify-send"
printf '#!/bin/sh\nwhile [ $# -gt 0 ]; do [ "$1" = -o ] && touch "$2"; shift; done\n' >"$t/fake/g++"
printf '#!/bin/sh\n' >"$t/fake/pkg-config"
chmod +x "$t"/fake/*
# shellcheck disable=SC2034  # read inside check's condition
out=$(PATH=$t/fake:$PATH XDG_DATA_HOME="$t/plug" bash "$bin/hypr-plugins" build 2>&1)
check "hypr-plugins build refuses a tag with no pin" '[[ $out == *"has no pin"* && ! -d $t/plug/hypr-plugins/src ]]'

# every distro backend defines the app-list functions
for b in distros/*.sh; do
    for fn in distro_pkg_owners distro_pkg_source distro_pkg_versions distro_pkg_info distro_pkg_url distro_pkg_remove_cmd; do
        # shellcheck disable=SC2016  # expanded by the inner bash
        check "$b defines $fn" 'bash -c "run(){ :; }; warn(){ :; }; say(){ :; }; . \"\$1\"; declare -F \"\$2\" >/dev/null" x "$b" "$fn"'
    done
done

# the clipboard history is private: folder 700, entries not readable by others
mkdir -p "$t/clip"
XDG_DATA_HOME="$t/clip" bash "$bin/clipstore" list >/dev/null 2>&1
check "clipstore keeps its folder private (700)" '[[ $(stat -c %a "$t/clip/clipboard") == 700 ]]'

# the Hyprland Lua the installer seeds parses
luac=$(command -v luac || command -v luac5.4 || true)
[[ -n $luac ]] && for f in config/hypr/.config/hypr/defaults/*.lua; do [[ -f $f ]] && check "parses: $f" "\"$luac\" -p \"$f\""; done

exit "$fail"
