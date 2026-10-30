#!/usr/bin/env bash
# Hyprland next to whatever desktop is already installed (KDE stays untouched). Safe to re-run; changes nothing KDE depends on.
# Run: sudo bash system/02-desktop.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

step "Packages from packages/desktop.txt"
grep -vE '^\s*(#|$)' packages/desktop.txt | pacman -S --needed --noconfirm -

step "Lid: suspend-then-hibernate on battery; ignored while an external screen is plugged in"
# KDE's power settings take over the lid while Plasma runs, so this only affects Hyprland.
mkdir -p /etc/systemd/logind.conf.d
printf '[Login]\nHandleLidSwitch=suspend-then-hibernate\nHandleLidSwitchExternalPower=suspend\nHandleLidSwitchDocked=ignore\n' \
  > /etc/systemd/logind.conf.d/50-lid.conf

# NVIDIA EGL hiding for the Hyprland session lives in home/fish/.config/fish/conf.d/hyprland-igpu.fish
rm -f /usr/share/wayland-sessions/hyprland-igpu.desktop  # older approach, replaced by the fish snippet

step "Hyprland as the default session (KDE Plasma stays selectable at the login screen)"
[[ -f /etc/plasmalogin.conf ]] && sed -i 's/^Session=plasma$/Session=hyprland/' /etc/plasmalogin.conf
# other login screens (SDDM, GDM, greetd) list Hyprland themselves; pick it there once

step "Done. The lid setting applies after the next reboot."
