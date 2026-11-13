# shellcheck shell=bash
# Flow X13 power modes: plugging in -> Balanced, battery -> Quiet; per mode both fan curves, power limits
# and the CPU energy preference. Values measured on this model. Needs asusd (the asus module).
command -v asusctl >/dev/null || {
    warn "asusctl isn't installed yet; run ./install.sh again after the asus module."
    exit 1
}
a() { if $DRY; then echo "   would run: asusctl $*"; else asusctl "$@" >/dev/null 2>&1; fi; } # asusctl warns about "Multiple asusd interfaces"; harmless

# asusctl switches the active mode too when setting the AC/battery one; put it back at the end
was=$(asusctl profile get 2>/dev/null | awk '/Active profile/{print tolower($3)}')

a profile set -a balanced
a profile set -b quiet

# PL1 = sustained W, PL2 = short-term W (65 is this firmware's minimum). asusd only allows power limits
# with custom curves on, and a curve on only one fan left the other at 0 RPM, so both are set.
mode() { # mode PROFILE PL1 PL2 CPU_CURVE GPU_CURVE
    a profile set "$1"
    a fan-curve --mod-profile "$1" --fan cpu --data "$4"
    a fan-curve --mod-profile "$1" --fan gpu --data "$5"
    a fan-curve --mod-profile "$1" --enable-fan-curves true
    a profile tuning true
    a armoury set ppt_pl1_spl "$2"
    a armoury set ppt_pl2_sppt "$3"
    echo "   $1: PL1 $2 W / PL2 $3 W, curves on"
}
mode quiet 15 65 "50c:10%,60c:20%,66c:30%,72c:40%,77c:52%,82c:66%,87c:82%,92c:100%" \
    "50c:25%,60c:28%,66c:32%,72c:40%,77c:50%,82c:65%,87c:80%,92c:100%"
mode balanced 25 65 "45c:15%,55c:25%,62c:35%,67c:48%,72c:62%,77c:76%,82c:90%,87c:100%" \
    "45c:30%,55c:32%,62c:38%,67c:48%,72c:60%,77c:72%,82c:88%,87c:100%"
mode performance 45 80 "48c:32%,56c:34%,60c:46%,63c:52%,67c:67%,72c:94%,77c:96%,82c:100%" \
    "48c:55%,56c:56%,60c:58%,63c:62%,67c:68%,72c:88%,77c:94%,82c:100%"

# CPU energy preference per mode, set by asusd (1 performance, 2 balance_performance, 3 balance_power, 4 power)
p=xyz.ljones.Platform
run busctl --system set-property xyz.ljones.Asusd /xyz/ljones $p PlatformProfileLinkedEpp b true
run busctl --system set-property xyz.ljones.Asusd /xyz/ljones $p ProfileQuietEpp u 4
run busctl --system set-property xyz.ljones.Asusd /xyz/ljones $p ProfileBalancedEpp u 3
run busctl --system set-property xyz.ljones.Asusd /xyz/ljones $p ProfilePerformanceEpp u 1
a profile set "${was/lowpower/quiet}"

# power-profiles-daemon stays as the switch, but must not write the energy preference too (it fought asusd)
exe=$(systemctl cat power-profiles-daemon 2>/dev/null | sed -n 's/^ExecStart=\([^ ]*\).*/\1/p' | head -1)
if [[ -n $exe ]]; then
    sys_write /etc/systemd/system/power-profiles-daemon.service.d/50-asusd-owns-epp.conf "# asusd sets the energy preference per mode (Hyprism, modules/quirk-flow-x13)
[Service]
ExecStart=
ExecStart=$exe --block-driver=amd_pstate"
    run sudo systemctl daemon-reload
    run sudo systemctl restart power-profiles-daemon
fi
