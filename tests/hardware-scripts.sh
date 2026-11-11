#!/usr/bin/env bash
# The desktop scripts ask hardware.toml instead of naming this owner's hardware, in throwaway folders.
# Run by tests/lint.sh (CI) or by hand: tests/hardware-scripts.sh
# shellcheck disable=SC2016  # check takes its condition as a single-quoted string on purpose (eval runs it later)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
bin=$PWD/config/scripts/.local/bin
export HYPRISM_LIB=$PWD/config/scripts/.local/lib/hyprism
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
fail=0
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

# hw reads a hardware.toml that detect wrote for a made-up laptop with an NVIDIA card
bash tests/detect.sh make "$t/fx" >/dev/null
export HYPRISM_HARDWARE=$t/hw.toml
HYPRISM_ROOT=$t/fx/laptop-hybrid-nvidia bash -c '. lib/detect.sh; detect_write' >/dev/null
# shellcheck source=config/scripts/.local/lib/hyprism/common.sh
. "$HYPRISM_LIB/common.sh"
check "hw reads the discrete card's vendor" '[[ $(hw gpu.discrete) == nvidia ]]'
check "hw reads the internal screen" '[[ -n $(hw display.internal) ]]'
check "hw reads the battery" '[[ -n $(hw power.battery) ]]'
printf '\n[override]\ndisplay.internal = "X-1"\n' >>"$HYPRISM_HARDWARE"
check "hw: [override] wins" '[[ $(hw display.internal) == X-1 ]]'
check "hw agrees with hw_get" '[[ $(hw gpu.vendors) == $(HYPRISM_ROOT= bash -c ". lib/detect.sh; hw_get gpu.vendors") ]]'

# a missing key or file prints nothing and never fails the caller
check "hw: unknown key prints nothing, exit 0" '[[ -z $(bash -c "set -e; . \"$HYPRISM_LIB/common.sh\"; hw nosuch.key; echo done" | tr -d "\n" | sed s/done//) ]]'
check "hw: missing file is fine under set -e" '[[ $(HYPRISM_HARDWARE=$t/none.toml bash -c "set -e; . \"$HYPRISM_LIB/common.sh\"; hw gpu.primary; echo done") == *done ]]'
check "gpu_render_node: no such card prints nothing" '[[ -z $(gpu_render_node 0000:ff:ff.9) ]]'

# no owner's hardware left in the scripts
files=(
    "$bin/record" "$bin/theme-wallpaper" "$bin/monswitch" "$bin/nv"
    modules/asus/home/.local/bin/asusfan modules/asus/home/.local/bin/thermlog
)
for v in renderD128 0000:01:00.0 0000:08:00.0 BAT0 Acer; do
    check "no $v in the scripts" '! grep -n -- "$v" "${files[@]}"'
done
check "monswitch names screens only in comments" '! grep -n "eDP-1\|HDMI-A-1" "$bin/monswitch" | grep -v "^[0-9]*:[[:space:]]*#"'

check "nvidia-hybrid.lua is valid Lua" 'luac -p modules/nvidia-hybrid/home/.config/hypr/hardware/nvidia-hybrid.lua'

exit "$fail"
