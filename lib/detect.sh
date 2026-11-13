# shellcheck shell=bash
# Hardware detection: looks at this computer once and writes what it found to hardware.toml.
# Everything optional (modules, bar items, key binds, doctor checks) reads that file instead of guessing.
# Sourced, not run. Reads only /sys and /proc, so tests can point HYPRISM_ROOT at a fake tree.
#
#   detect_hardware          print the TOML
#   detect_write             write ~/.config/hyprism/hardware.toml (keeps your [override] section)
#   hw_get SECTION.KEY       one value from the file, your override first; lists come space-separated
#   hw_has SECTION.KEY       true when the value is "true" or a non-empty string
#   hw_override KEY VALUE    record your own choice under [override]
#
# To correct a wrong guess, add to the end of hardware.toml (detect never touches this part):
#   [override]
#   display.internal = "eDP-2"

HW_ROOT=${HYPRISM_ROOT:-}
HW_FILE=${HYPRISM_HARDWARE:-${XDG_CONFIG_HOME:-$HOME/.config}/hyprism/hardware.toml}

_hw_read() { [[ -r $HW_ROOT$1 ]] && head -n1 "$HW_ROOT$1" 2>/dev/null || true; } # a missing sysfs file just means "not there"
_hw_bool() { if "$@"; then echo true; else echo false; fi; }
_hw_list() { # words -> ["a", "b"]
    local out="" w
    for w in "$@"; do out+="${out:+, }\"$w\""; done
    echo "[$out]"
}
_hw_any() { compgen -G "$HW_ROOT$1" >/dev/null; }

# laptop | desktop | vm, from the DMI chassis type (and a battery, for boards that report it wrong)
_hw_form() {
    local dmi
    dmi="$(_hw_read /sys/class/dmi/id/sys_vendor) $(_hw_read /sys/class/dmi/id/product_name)"
    if [[ $dmi =~ QEMU|KVM|VirtualBox|VMware|Virtual\ Machine|Xen|Bochs|Parallels ]] || [[ -e $HW_ROOT/sys/hypervisor/type ]]; then
        echo vm
        return
    fi
    case $(_hw_read /sys/class/dmi/id/chassis_type) in
        8 | 9 | 10 | 11 | 12 | 14 | 30 | 31 | 32) echo laptop ;;
        *) if [[ -n $(_hw_battery) ]]; then echo laptop; else echo desktop; fi ;;
    esac
}

_hw_cpu() {
    case $(grep -m1 '^vendor_id' "$HW_ROOT/proc/cpuinfo" 2>/dev/null) in # no cpuinfo (odd container) = other
        *AuthenticAMD*) echo amd ;;
        *GenuineIntel*) echo intel ;;
        *) echo other ;;
    esac
}

_hw_vendor_tools() {
    case $(_hw_read /sys/class/dmi/id/sys_vendor) in
        ASUS*) echo asus ;;
        LENOVO*) echo lenovo ;;
        Dell*) echo dell ;;
        Framework*) echo framework ;;
        HP* | Hewlett*) echo hp ;;
        *) echo "" ;;
    esac
}

# the first real battery (not a mouse or a UPS reporting itself as one)
_hw_battery() {
    local d
    for d in "$HW_ROOT"/sys/class/power_supply/*; do
        [[ $(_hw_read "${d#"$HW_ROOT"}/type") == Battery && $(_hw_read "${d#"$HW_ROOT"}/scope") != Device ]] || continue
        basename "$d"
        return
    done
}

_hw_first() { # the name of the first entry matching a glob, or nothing
    local d
    for d in "$HW_ROOT"$1; do [[ -e $d ]] && basename "$d" && return; done
    return 0
}

# One line per graphics card: "vendor pci boot_vga internal_panel connected_outputs..."
_hw_cards() {
    local card dev vendor pci conn name internal outs
    for card in "$HW_ROOT"/sys/class/drm/card[0-9]*; do
        [[ $card =~ /card[0-9]+$ ]] || continue
        dev=${card#"$HW_ROOT"}/device
        case $(_hw_read "$dev/vendor") in
            0x1002) vendor=amd ;;
            0x8086) vendor=intel ;;
            0x10de) vendor=nvidia ;;
            *) vendor=virtual ;;
        esac
        pci=$(sed -n 's/^PCI_SLOT_NAME=//p' "$HW_ROOT$dev/uevent" 2>/dev/null) # virtual cards have no PCI slot
        internal="-" outs=()
        for conn in "$card"-*; do
            [[ $(_hw_read "${conn#"$HW_ROOT"}/status") == connected ]] || continue
            name=${conn##*/}
            name=${name#card*-}
            outs+=("$name")
            [[ $name =~ ^(eDP|LVDS|DSI) ]] && internal=$name
        done
        echo "$vendor ${pci:--} $(_hw_read "$dev/boot_vga") $internal ${outs[*]}"
    done
}

# Input devices from /proc/bus/input/devices: PROP bit 0 = pointer (touchpad), bit 1 = direct (touchscreen),
# SW bit 1 = tablet-mode switch
_hw_input() {
    awk -v want="$1" '
        function low(hex) { return index("0123456789abcdef", tolower(substr(hex, length(hex)))) - 1 } # last hex digit
        function flush() {
            if (abs && prop % 2 == 1) pad = "true"
            if (abs && int(prop / 2) % 2 == 1) screen = "true"
            if (int(sw / 2) % 2 == 1) tablet = name
            abs = 0; prop = 0; sw = 0; name = ""
        }
        /^$/ { flush() }
        /^N: Name=/ { name = $0; sub(/^N: Name="/, "", name); sub(/"$/, "", name) }
        /^B: PROP=/ { prop = low($2) }
        /^B: ABS=/ { abs = 1 }
        /^B: SW=/ { sw = low($2) }
        END {
            flush()
            if (want == "tablet") print tablet
            else print ((want == "touchpad" ? pad : screen) == "true" ? "true" : "false")
        }
    ' "$HW_ROOT/proc/bus/input/devices" 2>/dev/null || { [[ $1 == tablet ]] || echo false; } # no input list = nothing to offer
}

detect_hardware() {
    local form vendor pci boot internal outs
    local vendors=() all_outs=() primary="" primary_pci="" discrete="" discrete_pci="" panel="" first="" first_pci=""
    form=$(_hw_form)
    while read -r vendor pci boot internal outs; do
        [[ -n $vendor ]] || continue
        vendors+=("$vendor")
        # shellcheck disable=SC2206  # output names never hold spaces
        all_outs+=($outs)
        [[ -n $first ]] || { first=$vendor first_pci=$pci; }
        [[ $internal != - ]] && panel=$internal
        # the card that drives the screen: the one with the laptop panel, else the firmware's boot card
        if [[ $internal != - ]] || { [[ -z $primary && $boot == 1 ]]; }; then primary=$vendor primary_pci=$pci; fi
    done < <(_hw_cards)
    [[ -n $primary ]] || { primary=$first primary_pci=$first_pci; }
    # a second, different card is the discrete one (the one apps are sent to with `nv`)
    while read -r vendor pci _; do
        [[ -n $vendor && $pci != "$primary_pci" && $vendor != virtual ]] && discrete=$vendor discrete_pci=$pci
    done < <(_hw_cards)
    local external=() o
    for o in "${all_outs[@]}"; do [[ $o == "$panel" ]] || external+=("$o"); done

    local battery backlight kbd
    battery=$(_hw_battery)
    backlight=$(_hw_first "/sys/class/backlight/*")
    kbd=$(_hw_first "/sys/class/leds/*kbd_backlight*")

    cat <<EOF
# What Hyprism found on this computer. Written by: hyprism detect (./install.sh detect).
# Don't edit the values here: they are replaced on the next detect. Corrections go in [override] at the end.

[machine]
# laptop | desktop | vm
form = "$form"
vendor = "$(_hw_read /sys/class/dmi/id/sys_vendor)"
product = "$(_hw_read /sys/class/dmi/id/product_name)"
cpu = "$(_hw_cpu)"
# whose extra tools are worth offering: asus | lenovo | dell | framework | hp
tools = "$(_hw_vendor_tools)"

[gpu]
vendors = $(_hw_list "${vendors[@]}")
# primary draws the desktop; discrete is the second card, for games and AI ("" with one card)
primary = "$primary"
primary_pci = "${primary_pci#-}"
discrete = "$discrete"
discrete_pci = "${discrete_pci#-}"
hybrid = $(_hw_bool test -n "$discrete")

[display]
# internal is the laptop's own screen ("" on a desktop); external lists what was plugged in when detect ran
internal = "$panel"
external = $(_hw_list "${external[@]}")

[power]
battery = "$battery"
charge_limit = $(_hw_bool test -n "$battery" -a -e "$HW_ROOT/sys/class/power_supply/$battery/charge_control_end_threshold")
backlight = "$backlight"
kbd_backlight = "$kbd"
profiles = $(_hw_bool test -e "$HW_ROOT/sys/firmware/acpi/platform_profile")

[input]
touchpad = $(_hw_input touchpad)
touchscreen = $(_hw_input touchscreen)
# the name of the hinge switch on a 2-in-1 ("" when there is none)
tablet_switch = "$(_hw_input tablet)"
rotation_sensor = $(_hw_bool _hw_any "/sys/bus/iio/devices/iio:device*/in_accel_x_raw")

[radio]
bluetooth = $(_hw_bool _hw_any "/sys/class/bluetooth/hci*")
wifi = $(_hw_bool _hw_any "/sys/class/net/*/wireless")

[peripherals]
logitech = $(_hw_bool _hw_any "/sys/bus/hid/devices/*:046D:*")
EOF
}

# Writes the file only when something changed; your [override] section is carried over untouched.
detect_write() {
    local new old override=""
    [[ -f $HW_FILE ]] && override=$(sed -n '/^\[override\]/,$p' "$HW_FILE")
    new="$(detect_hardware)"$'\n\n'"${override:-[override]}"
    old=$(cat "$HW_FILE" 2>/dev/null || true) # first run: no file yet
    [[ $new == "$old" ]] && return 0
    mkdir -p "$(dirname "$HW_FILE")"
    printf '%s\n' "$new" >"$HW_FILE.tmp" && mv "$HW_FILE.tmp" "$HW_FILE"
}

hw_get() {
    awk -v want="$1" '
        function clean(v) { gsub(/^\[|\]$|"|,/, "", v); return v }
        /^\[/ { section = substr($0, 2, index($0, "]") - 2); next }
        /^[A-Za-z_.]+[ \t]*=/ {
            key = $1; val = $0; sub(/^[^=]*=[ \t]*/, "", val)
            if (section == "override" && key == want) { over = clean(val); found = 1 }
            else if (section "." key == want) base = clean(val)
        }
        END { print (found ? over : base) }
    ' "$HW_FILE" 2>/dev/null || true # no file yet = nothing detected
}

# hw_override KEY VALUE: record your own choice (e.g. module.gaming true); it survives every detect
hw_override() {
    [[ -f $HW_FILE ]] || detect_write
    sed -i "/^\\[override\\]/,\$ { /^${1//./\\.}[ \t]*=/d }" "$HW_FILE"
    printf '%s = %s\n' "$1" "$2" >>"$HW_FILE"
}

hw_has() {
    local v
    v=$(hw_get "$1")
    [[ -n $v && $v != false ]]
}
