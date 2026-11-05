#!/usr/bin/env bash
# Behaviour checks for the scripts that hold logic, in throwaway folders (nothing on this computer changes).
# Run by tests/lint.sh (CI) or by hand: tests/scripts.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
bin=$PWD/config/scripts/.local/bin
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
fail=0
# check NAME CONDITION: the condition is evaluated here, so it may use the variables set above it
check() { if eval "$2"; then echo "ok: $1"; else echo "xx $1"; fail=1; fi; }

# monswitch reads its config as KEY=value lines, never as shell: a command in a value is not run
mkdir -p "$t/cfg"
printf 'OUT=HDMI-A-1\nLAPTOP=0x11\nPC=$(touch %s/pwned)\n' "$t" > "$t/cfg/monswitch.conf"
# shellcheck disable=SC2034  # read inside check's condition
out=$(env -u HYPRLAND_INSTANCE_SIGNATURE XDG_CONFIG_HOME="$t/cfg" XDG_STATE_HOME="$t/state" bash "$bin/monswitch" pc 2>&1)
check "monswitch runs nothing from its config" '[[ ! -e $t/pwned ]]'
check "monswitch refuses a config value that isn't plain" '[[ $out == *"set PC"* ]]'

# desktop-reset puts Settings files aside (nothing deleted) and seeds the defaults Hyprland needs
mkdir -p "$t/home/quickshell" "$t/home/hypr/settings" "$t/home/ghostty"
echo '{"x":1}' > "$t/home/quickshell/settings.json"; echo 'return {}' > "$t/home/hypr/settings/theme.lua"
env -u HYPRLAND_INSTANCE_SIGNATURE XDG_CONFIG_HOME="$t/home" XDG_STATE_HOME="$t/state" bash "$bin/desktop-reset" >/dev/null 2>&1
# shellcheck disable=SC2034  # read inside check's condition
kept=$(find "$t/state/linux-setup" -name settings.json 2>/dev/null | head -1)
check "desktop-reset keeps the old settings.json" '[[ -n $kept && $(cat "$kept") == "{\"x\":1}" ]]'
check "desktop-reset removes it from ~/.config" '[[ ! -e $t/home/quickshell/settings.json ]]'
check "desktop-reset seeds hypridle.conf" '[[ -f $t/home/hypr/settings/hypridle.conf ]]'

# the Hyprland Lua the installer seeds parses
luac=$(command -v luac || command -v luac5.4 || true)
[[ -n $luac ]] && for f in config/hypr/.config/hypr/defaults/*.lua; do [[ -f $f ]] && check "parses: $f" "\"$luac\" -p \"$f\""; done

exit "$fail"
