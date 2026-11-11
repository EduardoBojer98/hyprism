#!/usr/bin/env bash
# ROG Flow X13: power modes from the 2026-10-31 audit (docs/thermal-audit.md). Safe to re-run.
#
# One owner per setting: asusd switches the mode (plug in -> Balanced, battery -> Quiet) and applies
# each mode's fan curves, power limits and CPU energy preference (EPP). power-profiles-daemon stays
# as the switch KDE and `powerprofilesctl` talk to, but no longer writes EPP itself (it fought asusd).
# Switch modes with `powermode`, Super+F5 (Hyprland) or the Control Center.
#
# Runs as you (asusctl talks to asusd over D-Bus); asks for sudo once for the systemd drop-in.
# Power limits apply on AC; on battery the firmware hides them and uses its own (about 12 W in Quiet).
set -euo pipefail
[[ $EUID -ne 0 ]] || {
    echo "Run as your normal user"
    exit 1
}
step() { printf '\n==> %s\n' "$*"; }
a() { asusctl "$@" 2>/dev/null >/dev/null; } # asusctl warns "Multiple asusd interfaces" on stderr; harmless

# asusctl switches the active mode too when setting the AC/battery one; put it back at the end
was=$(asusctl profile get 2>/dev/null | awk '/Active profile/{print tolower($3)}')

step "Plugging in -> Balanced (was Performance, which runs at 95 C under load), battery -> Quiet"
a profile set -a balanced
a profile set -b quiet

step "Per mode: both fan curves (asusd only allows power limits with custom curves on) + power limits"
# PL1 = sustained W, PL2 = short-term W (65 is this firmware's minimum). The GPU fan follows the
# dGPU temperature, so while the dGPU is off it holds its first point.
# Undo one mode: asusctl profile set MODE; asusctl profile tuning false;
#                asusctl fan-curve --mod-profile MODE --enable-fan-curves false
mode() { # mode PROFILE PL1 PL2 CPU_CURVE GPU_CURVE
    a profile set "$1"
    a fan-curve --mod-profile "$1" --fan cpu --data "$4"
    a fan-curve --mod-profile "$1" --fan gpu --data "$5"
    a fan-curve --mod-profile "$1" --enable-fan-curves true
    a profile tuning true
    a armoury set ppt_pl1_spl "$2"
    a armoury set ppt_pl2_sppt "$3"
    echo "$1: PL1 $2 W / PL2 $3 W, curves on"
}
mode quiet 15 65 "50c:10%,60c:20%,66c:30%,72c:40%,77c:52%,82c:66%,87c:82%,92c:100%" \
    "50c:25%,60c:28%,66c:32%,72c:40%,77c:50%,82c:65%,87c:80%,92c:100%"
mode balanced 25 65 "45c:15%,55c:25%,62c:35%,67c:48%,72c:62%,77c:76%,82c:90%,87c:100%" \
    "45c:30%,55c:32%,62c:38%,67c:48%,72c:60%,77c:72%,82c:88%,87c:100%"
mode performance 45 80 "48c:32%,56c:34%,60c:46%,63c:52%,67c:67%,72c:94%,77c:96%,82c:100%" \
    "48c:55%,56c:56%,60c:58%,63c:62%,67c:68%,72c:88%,77c:94%,82c:100%"

step "CPU energy preference (EPP) per mode, set by asusd"
# asusd values: 1 performance, 2 balance_performance, 3 balance_power, 4 power
p=xyz.ljones.Platform
busctl --system set-property xyz.ljones.Asusd /xyz/ljones $p PlatformProfileLinkedEpp b true
busctl --system set-property xyz.ljones.Asusd /xyz/ljones $p ProfileQuietEpp u 4
busctl --system set-property xyz.ljones.Asusd /xyz/ljones $p ProfileBalancedEpp u 3
busctl --system set-property xyz.ljones.Asusd /xyz/ljones $p ProfilePerformanceEpp u 1
# asusd applies an EPP to the CPU as soon as it is set, whatever the mode; re-enter the mode you were in
a profile set "${was/lowpower/quiet}"

step "power-profiles-daemon: stop it writing EPP (asusd does), keep the profile switch"
# Undo: sudo rm -r /etc/systemd/system/power-profiles-daemon.service.d; sudo systemctl daemon-reload;
#       sudo systemctl restart power-profiles-daemon
dropin=/etc/systemd/system/power-profiles-daemon.service.d/50-asusd-owns-epp.conf
want=$'# asusd sets EPP per mode (hosts/flow-x13/steps/50-power.user.sh)\n[Service]\nExecStart=\nExecStart=/usr/lib/power-profiles-daemon --block-driver=amd_pstate'
if [[ "$(cat "$dropin" 2>/dev/null)" != "$want" ]]; then
    sudo mkdir -p "${dropin%/*}"
    printf '%s\n' "$want" | sudo tee "$dropin" >/dev/null
    sudo systemctl daemon-reload
    sudo systemctl restart power-profiles-daemon
fi

step "Result"
asusctl profile get 2>/dev/null
powerprofilesctl | grep -E 'CpuDriver|PlatformDriver|^\*' | sort -u
on_ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1)
[[ $on_ac == 1 ]] || echo "On battery: the firmware sets its own power limits here; the AC ones apply when plugged in."
