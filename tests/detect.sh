#!/usr/bin/env bash
# Hardware detection against seven made-up computers (docs/hardware.md lists them). Each one is a small fake
# /sys and /proc tree in a throwaway folder, so this runs anywhere and changes nothing.
#   tests/detect.sh            run every profile
#   tests/detect.sh make DIR   only build the fake trees in DIR (other tests reuse them)
set -euo pipefail
cd "$(dirname "$0")/.."

put() { # put ROOT PATH VALUE: one fake sysfs file
    mkdir -p "$1$(dirname "$2")"
    printf '%s\n' "$3" >"$1$2"
}
dmi() { # dmi ROOT VENDOR PRODUCT CHASSIS
    put "$1" /sys/class/dmi/id/sys_vendor "$2"
    put "$1" /sys/class/dmi/id/product_name "$3"
    put "$1" /sys/class/dmi/id/chassis_type "$4"
}
cpu() { put "$1" /proc/cpuinfo "vendor_id	: $2"; }
card() { # card ROOT N VENDOR_ID PCI BOOT_VGA [CONNECTOR=status...]; BOOT_VGA - = no file (a "3D controller")
    local root=$1 n=$2 c
    put "$root" "/sys/class/drm/card$n/device/vendor" "$3"
    put "$root" "/sys/class/drm/card$n/device/uevent" "PCI_SLOT_NAME=$4"
    [[ $5 == - ]] || put "$root" "/sys/class/drm/card$n/device/boot_vga" "$5"
    shift 5
    for c in "$@"; do put "$root" "/sys/class/drm/card$n-${c%=*}/status" "${c#*=}"; done
}
battery() {
    put "$1" /sys/class/power_supply/BAT1/type Battery
    put "$1" /sys/class/power_supply/BAT1/charge_control_end_threshold 80
    put "$1" /sys/class/backlight/intel_backlight/brightness 100
}
input() { # input ROOT NAME PROP [SW]
    mkdir -p "$1/proc/bus/input"
    printf 'N: Name="%s"\nB: PROP=%s\nB: ABS=260800000000003\n%s\n' "$2" "$3" "${4:+B: SW=$4}" >>"$1/proc/bus/input/devices"
}

make_profiles() {
    local r
    r=$1/desktop-amd
    dmi "$r" "Gigabyte Technology Co., Ltd." "B650 AORUS" 3
    cpu "$r" AuthenticAMD
    card "$r" 0 0x1002 0000:03:00.0 1 DP-1=connected HDMI-A-1=disconnected

    r=$1/desktop-nvidia
    dmi "$r" "Micro-Star International" "MS-7D25" 3
    cpu "$r" GenuineIntel
    card "$r" 0 0x10de 0000:01:00.0 1 DP-1=connected DP-2=connected

    r=$1/laptop-intel
    dmi "$r" "LENOVO" "20XW ThinkPad X1" 10
    cpu "$r" GenuineIntel
    card "$r" 1 0x8086 0000:00:02.0 1 eDP-1=connected DP-1=disconnected
    battery "$r"
    input "$r" "SynPS/2 Synaptics TouchPad" 5
    put "$r" /sys/class/net/wlan0/wireless/x ""
    put "$r" /sys/class/bluetooth/hci0/x ""

    r=$1/laptop-hybrid-nvidia
    dmi "$r" "ASUSTeK COMPUTER INC." "ROG Flow X13" 31
    cpu "$r" AuthenticAMD
    # the NVIDIA card of a hybrid laptop is a "3D controller": no boot_vga, and it may come after the iGPU
    card "$r" 0 0x1002 0000:08:00.0 1 eDP-1=connected HDMI-A-1=connected
    card "$r" 1 0x10de 0000:01:00.0 -
    battery "$r"
    input "$r" "ASUE Touchpad" 5
    input "$r" "ELAN Touchscreen" 2
    input "$r" "Tablet Mode Switch" 0 2
    put "$r" "/sys/bus/iio/devices/iio:device0/in_accel_x_raw" 0
    put "$r" /sys/class/leds/asus::kbd_backlight/brightness 1
    put "$r" /sys/firmware/acpi/platform_profile balanced
    put "$r" "/sys/bus/hid/devices/0003:046D:C548.0005/x" ""

    r=$1/hidpi-single
    dmi "$r" "Framework" "Laptop 13" 10
    cpu "$r" AuthenticAMD
    card "$r" 1 0x1002 0000:c1:00.0 1 eDP-1=connected
    battery "$r"
    input "$r" "PIXA Touchpad" 5

    r=$1/multi-monitor
    dmi "$r" "ASRock" "X570" 3
    cpu "$r" AuthenticAMD
    card "$r" 0 0x1002 0000:0b:00.0 1 DP-1=connected DP-2=connected HDMI-A-1=connected

    r=$1/vm
    dmi "$r" "QEMU" "Standard PC (Q35 + ICH9, 2009)" 1
    cpu "$r" GenuineIntel
    card "$r" 0 0x1af4 "" "" Virtual-1=connected
}

if [[ ${1:-} == make ]]; then
    make_profiles "${2:?make needs a folder}"
    exit 0
fi

t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
make_profiles "$t"
fail=0
# expect PROFILE KEY VALUE...: detect that fake computer, then compare one value
expect() {
    local profile=$1 key=$2 got
    shift 2
    got=$(HYPRISM_ROOT=$t/$profile HYPRISM_HARDWARE=$t/$profile.toml bash -c '. lib/detect.sh; detect_write; hw_get "$1"' _ "$key")
    if [[ $got == "$*" ]]; then echo "ok: $profile $key = $*"; else
        echo "xx $profile $key: expected '$*', got '$got'"
        fail=1
    fi
}

expect desktop-amd machine.form desktop
expect desktop-amd gpu.primary amd
expect desktop-amd gpu.hybrid false
expect desktop-amd display.internal ""
expect desktop-amd display.external DP-1
expect desktop-amd power.battery ""
expect desktop-amd input.touchpad false
expect desktop-amd radio.bluetooth false

expect desktop-nvidia gpu.primary nvidia
expect desktop-nvidia gpu.discrete ""
expect desktop-nvidia machine.cpu intel

expect laptop-intel machine.form laptop
expect laptop-intel machine.tools lenovo
expect laptop-intel gpu.primary intel
expect laptop-intel display.internal eDP-1
expect laptop-intel power.battery BAT1
expect laptop-intel power.charge_limit true
expect laptop-intel input.touchpad true
expect laptop-intel input.touchscreen false
expect laptop-intel radio.wifi true

expect laptop-hybrid-nvidia gpu.primary amd
expect laptop-hybrid-nvidia gpu.primary_pci 0000:08:00.0
expect laptop-hybrid-nvidia gpu.discrete nvidia
expect laptop-hybrid-nvidia gpu.hybrid true
expect laptop-hybrid-nvidia display.external HDMI-A-1
expect laptop-hybrid-nvidia input.touchscreen true
expect laptop-hybrid-nvidia input.tablet_switch Tablet Mode Switch
expect laptop-hybrid-nvidia input.rotation_sensor true
expect laptop-hybrid-nvidia power.kbd_backlight asus::kbd_backlight
expect laptop-hybrid-nvidia machine.tools asus
expect laptop-hybrid-nvidia peripherals.logitech true

expect hidpi-single machine.tools framework
expect hidpi-single gpu.hybrid false
expect hidpi-single input.tablet_switch ""

expect multi-monitor display.external DP-1 DP-2 HDMI-A-1
expect multi-monitor machine.form desktop

expect vm machine.form vm
expect vm gpu.primary virtual
expect vm gpu.hybrid false
expect vm power.battery ""

# your [override] wins and survives a re-detect
HYPRISM_HARDWARE=$t/laptop-intel.toml bash -c '. lib/detect.sh; hw_override display.internal "\"eDP-2\""; hw_override display.internal "\"eDP-3\""'
expect laptop-intel display.internal eDP-3
[[ $(grep -c '^display.internal' "$t/laptop-intel.toml") == 1 ]] || {
    echo "xx hw_override left a duplicate line"
    fail=1
}
# NVIDIA generation: Turing and newer run the open driver; an older card needs 580xx
gen() { HYPRISM_ROOT=$t/$1 bash -c '. lib/detect.sh; nvidia_open_supported && echo open || echo legacy'; }
put "$t/laptop-hybrid-nvidia" /sys/class/drm/card1/device/device 0x2520 # RTX 3060 mobile
put "$t/desktop-nvidia" /sys/class/drm/card0/device/device 0x1b80       # GTX 1080
check_gen() { if [[ $(gen "$1") == "$2" ]]; then echo "ok: $1 nvidia driver = $2"; else
    echo "xx $1 nvidia driver: expected $2, got $(gen "$1")"
    fail=1
fi; }
check_gen laptop-hybrid-nvidia open
check_gen desktop-nvidia legacy
check_gen desktop-amd open

# module names with a hyphen (--without nvidia-hybrid) are overrides too
HYPRISM_HARDWARE=$t/laptop-intel.toml bash -c '. lib/detect.sh; hw_override module.nvidia-hybrid false'
expect laptop-intel module.nvidia-hybrid false

# the login check (hardware-check): quiet while nothing changed, one notice for a change, not again for the same one
mkdir -p "$t/bin" && printf '#!/bin/sh\necho x >>"%s"\n' "$t/notified" >"$t/bin/notify-send" && chmod +x "$t/bin/notify-send"
check() { PATH=$t/bin:$PATH HYPRISM_ROOT=$t/$1 HYPRISM_HARDWARE=$t/hidpi-single.toml XDG_STATE_HOME=$t/state \
    config/scripts/.local/bin/hardware-check; }
check hidpi-single && check desktop-amd && check desktop-amd
if [[ $(wc -l <"$t/notified" 2>/dev/null) == 1 ]]; then echo "ok: hardware-check announces a change once"; else
    echo "xx hardware-check: expected 1 notice, got $(wc -l <"$t/notified" 2>/dev/null || echo 0)"
    fail=1
fi

exit "$fail"
