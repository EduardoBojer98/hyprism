#!/usr/bin/env bash
# Phase 2: Hyprland next to KDE. Safe to re-run; changes nothing KDE depends on.
# Run: sudo bash system/02-desktop.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

step "Packages from packages/desktop.txt"
grep -vE '^\s*(#|$)' packages/desktop.txt | pacman -S --needed --noconfirm -

step "Stable /dev/dri/amd-igpu link, so Hyprland renders on the AMD iGPU only"
cat > /etc/udev/rules.d/90-amd-igpu.rules <<'EOF'
# /dev/dri/amd-igpu -> AMD iGPU card node (PCI 0000:08:00.0). Used by AQ_DRM_DEVICES in Hyprland.
KERNEL=="card*", SUBSYSTEM=="drm", KERNELS=="0000:08:00.0", SYMLINK+="dri/amd-igpu"
EOF
udevadm control --reload
udevadm trigger --subsystem-match=drm --action=add
udevadm settle
ls -l /dev/dri/amd-igpu

step "Lid: suspend-then-hibernate on battery; ignored while the Acer is plugged in"
# KDE's power settings take over the lid while Plasma runs, so this only affects Hyprland.
mkdir -p /etc/systemd/logind.conf.d
printf '[Login]\nHandleLidSwitch=suspend-then-hibernate\nHandleLidSwitchExternalPower=suspend\nHandleLidSwitchDocked=ignore\n' \
  > /etc/systemd/logind.conf.d/50-lid.conf

# NVIDIA EGL hiding for the Hyprland session lives in home/fish/.config/fish/conf.d/hyprland-igpu.fish
rm -f /usr/share/wayland-sessions/hyprland-igpu.desktop  # older approach, replaced by the fish snippet

step "Hyprland as the default session (KDE Plasma stays selectable at the login screen)"
sed -i 's/^Session=plasma$/Session=hyprland/' /etc/plasmalogin.conf

step "Done. The lid setting applies after the next reboot."
