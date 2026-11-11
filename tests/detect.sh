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
card() { # card ROOT N VENDOR_ID PCI BOOT_VGA [CONNECTOR=status...]
    local root=$1 n=$2 c
    put "$root" "/sys/class/drm/card$n/device/vendor" "$3"
    put "$root" "/sys/class/drm/card$n/device/uevent" "PCI_SLOT_NAME=$4"
    put "$root" "/sys/class/drm/card$n/device/boot_vga" "$5"
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
    card "$r" 0 0x10de 0000:01:00.0 0
    card "$r" 1 0x1002 0000:08:00.0 1 eDP-1=connected HDMI-A-1=connected
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
expect laptop-hybrid-nvidia input.tablet_switch true
expect laptop-hybrid-nvidia input.rotation_sensor true
expect laptop-hybrid-nvidia power.kbd_backlight asus::kbd_backlight
expect laptop-hybrid-nvidia machine.tools asus
expect laptop-hybrid-nvidia peripherals.logitech true

expect hidpi-single machine.tools framework
expect hidpi-single gpu.hybrid false
expect hidpi-single input.tablet_switch false

expect multi-monitor display.external DP-1 DP-2 HDMI-A-1
expect multi-monitor machine.form desktop

expect vm machine.form vm
expect vm gpu.primary virtual
expect vm gpu.hybrid false
expect vm power.battery ""

# your [override] wins and survives a re-detect
printf 'display.internal = "eDP-2"\n' >>"$t/laptop-intel.toml"
expect laptop-intel display.internal eDP-2

exit "$fail"
