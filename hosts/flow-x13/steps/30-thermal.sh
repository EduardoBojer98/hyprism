#!/usr/bin/env bash
# ROG Flow X13: the fixes for the 2026-10-31 overheating (idle Tctl 83 °C -> ~61 °C, measured).
# Two causes: the CPU fan sat at 0 RPM in Balanced, and the NVIDIA dGPU never powered off (~9 W).
# Safe to re-run. Runs after 10-hardware.sh (needs asusd).
# Run: sudo bash hosts/flow-x13/steps/30-thermal.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
step() { printf '\n==> %s\n' "$*"; }

# Fan curves and power limits moved to 50-power.user.sh (both curves on or both off: a curve on only
# the GPU fan left the CPU fan at 0 RPM).

step "NVIDIA: power the dGPU off (D3cold) whenever no app uses it"
# Fine-grained RTD3 (NVIDIA README, "Dynamic Power Management"). nvidia isn't in the initramfs on
# CachyOS (chwd drops the kms hook), so this applies at the next boot without a rebuild.
echo 'options nvidia NVreg_DynamicPowerManagement=0x02' > /etc/modprobe.d/nvidia-rtd3.conf

step "TEMPORARY: boot the LTS kernel by default"
# shortcut: RTD3 is broken on kernel 7.3 with driver 615 (CachyOS/linux-cachyos#1053,
# NVIDIA/open-gpu-kernel-modules#1489). Drop this step and restore BOOT_ORDER="*, *lts, ..." once a
# 7.3 boot shows `suspended` in /sys/bus/pci/devices/0000:01:00.0/power/runtime_status.
if ! command -v limine-update >/dev/null || ! pacman -Si linux-cachyos-lts >/dev/null 2>&1; then
    echo "Skipped: needs CachyOS (linux-cachyos-lts) and Limine."
else
pacman -S --needed --noconfirm linux-cachyos-lts linux-cachyos-lts-nvidia-open linux-cachyos-lts-headers
want='BOOT_ORDER="*lts, *, *fallback, Snapshots"'
if ! grep -qxF "$want" /etc/default/limine; then
    cp /etc/default/limine "/etc/default/limine.bak-$(date +%Y%m%d)"
    if grep -q '^BOOT_ORDER=' /etc/default/limine; then
        sed -i "s/^BOOT_ORDER=.*/$want/" /etc/default/limine
    else
        echo "$want" >> /etc/default/limine
    fi
    limine-update
fi
fi

step "Result (after the next reboot the dGPU should say 'suspended')"
asusctl fan-curve --get-enabled | head -3
grep BOOT_ORDER /etc/default/limine
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status 2>/dev/null || true
