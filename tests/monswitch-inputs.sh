#!/usr/bin/env bash
# monswitch inputs against a fake ddcutil that replays tests/fixtures-ddc/ and fails loudly on any write.
# Run by tests/lint.sh or by hand: tests/monswitch-inputs.sh
# shellcheck disable=SC2016  # check takes its condition as a single-quoted string on purpose (eval runs it later)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
bin=$PWD/config/scripts/.local/bin
export HYPRISM_LIB=$PWD/config/scripts/.local/lib/hyprism
fx=$PWD/tests/fixtures-ddc
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
fail=0
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

mkdir -p "$t/fake" "$t/empty"
cat >"$t/fake/ddcutil" <<EOF
#!/usr/bin/env bash
case "\$1 \$2" in
    "detect --brief") cat "$fx/detect.txt" ;;
    "capabilities --bus") cat "$fx/capabilities.txt" ;;
    "getvcp 60") cat "$fx/getvcp60.txt" ;;
    *) touch "$t/WROTE"; echo "fake ddcutil: unexpected call \$*" >&2; exit 99 ;;
esac
EOF
chmod +x "$t/fake/ddcutil"
# a PATH with the tools monswitch needs but no ddcutil
for c in bash env jq awk sed cat timeout; do ln -s "$(command -v "$c")" "$t/empty/$c"; done

run() { PATH="$t/fake:$PATH" bash "$bin/monswitch" "$@" 2>/dev/null; }
json=$(run inputs)
check "inputs prints valid JSON" 'jq -e . <<<"$json" >/dev/null'
check "inputs names the output" '[[ $(jq -r ".[0].output" <<<"$json") == HDMI-A-1 ]]'
check "inputs reads the current input" '[[ $(jq -r ".[0].current" <<<"$json") == 0x11 ]]'
check "inputs lists named inputs" '(($(jq ".[0].inputs | length" <<<"$json") >= 2)) && [[ $(jq -r ".[0].inputs[] | select(.code == \"0x11\") | .name" <<<"$json") == HDMI-1 ]]'
check "inputs skips the screen that has no DDC" '[[ $(jq length <<<"$json") == 1 ]]'
check "inputs with the right output name works" '[[ $(run inputs HDMI-A-1 | jq length) == 1 ]]'
check "inputs for an unknown output is []" '[[ $(run inputs NOSUCH) == "[]" ]]'
check "inputs without ddcutil is []" '[[ $(PATH="$t/empty" bash "$bin/monswitch" inputs 2>/dev/null) == "[]" ]]'
check "inputs never wrote to the monitor" '[[ ! -e $t/WROTE ]]'

# toggle: decided by Hyprland's side (own screen -> hand over, mirroring -> take back), never stuck on a mirror.
# Fakes: hyprctl reports $t/sw/monitors.json and logs eval/dispatch; ddcutil logs setvcp (fails when $t/sw/refuse exists).
sw=$t/sw
mkdir -p "$sw/fake" "$sw/cfg/hypr/settings" "$sw/state"
printf 'OUT=HDMI-A-1\nLAPTOP=0x11\nPC=0x12\nMIRROR=eDP-1\n' >"$sw/cfg/monswitch.conf"
cat >"$sw/fake/hyprctl" <<FAKE
#!/usr/bin/env bash
case "\$*" in
    "-j monitors") cat "$sw/monitors.json" ;;
    "-j workspaces") echo '[{"id":3,"monitor":"HDMI-A-1"}]' ;;
    *) echo "\$*" >>"$sw/hypr.log" ;;
esac
FAKE
cat >"$sw/fake/ddcutil" <<FAKE
#!/usr/bin/env bash
[[ "\$*" == *setvcp* ]] || exit 0
[[ -e "$sw/refuse" ]] && exit 1
echo "\$*" >>"$sw/ddc.log"
FAKE
printf '#!/bin/sh\n' >"$sw/fake/notify-send"
printf '#!/bin/sh\nexit 0\n' >"$sw/fake/sleep"
printf '#!/bin/sh\necho /sys/devices/i2c-7\n' >"$sw/fake/readlink" # the monitor's i2c bus
chmod +x "$sw/fake"/*
own='[{"name":"eDP-1","mirrorOf":"none","activeWorkspace":{"id":1}},{"name":"HDMI-A-1","mirrorOf":"none","activeWorkspace":{"id":3}}]'
mirrored='[{"name":"eDP-1","mirrorOf":"none","activeWorkspace":{"id":1}},{"name":"HDMI-A-1","mirrorOf":"eDP-1","activeWorkspace":{"id":1}}]'
toggle() {
    : >"$sw/hypr.log"
    : >"$sw/ddc.log"
    PATH="$sw/fake:$PATH" XDG_CONFIG_HOME="$sw/cfg" XDG_STATE_HOME="$sw/state" bash "$bin/monswitch" "${1:-toggle}" 2>/dev/null
}
echo "$own" >"$sw/monitors.json"
toggle
check "toggle on its own screen hands it over (PC input, then mirror)" 'grep -q "setvcp 60 0x12" "$sw/ddc.log" && grep -q "SHARED = { output = \"HDMI-A-1\", mirror = \"eDP-1\"" "$sw/hypr.log"'
echo "$mirrored" >"$sw/monitors.json"
toggle
check "toggle while mirroring takes it back (mirror off, then laptop input)" 'grep -q "SHARED = nil" "$sw/hypr.log" && grep -q "setvcp 60 0x11" "$sw/ddc.log" && [[ ! -e $sw/cfg/hypr/settings/shared.lua ]]'
toggle pc
check "pc while already handed over leaves Hyprland alone" '! grep -q "SHARED =" "$sw/hypr.log"'
echo "$own" >"$sw/monitors.json"
touch "$sw/refuse"
toggle
check "a monitor that refuses the switch is not mirrored" '! grep -q "SHARED =" "$sw/hypr.log"'
exit $fail
