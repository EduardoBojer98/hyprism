#!/usr/bin/env bash
# Phase 1 hardware setup for the ROG Flow X13 (GV301QC) on CachyOS + Limine.
# Safe to re-run: every step checks before it changes anything.
# Run: sudo bash system/01-hardware.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }

ROOT_UUID=b4605ab1-d8eb-4b3f-a682-4e2e191d1db9
SWAP_SIZE=20g   # >= RAM (16 GB) so a full hibernation image always fits

step() { printf '\n==> %s\n' "$*"; }

step "asusctl (charge limit, power profiles, keyboard LEDs)"
pacman -S --needed --noconfirm asusctl
systemctl enable --now asusd 2>/dev/null || systemctl start asusd

step "NVIDIA suspend/hibernate helpers (save GPU memory across sleep)"
systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service

step "Subvolume @swap at top level, so snapshots never include the swapfile"
mkdir -p /swap
if ! grep -q 'subvol=/@swap' /etc/fstab; then
  mnt=$(mktemp -d)
  mount -o subvolid=5 "/dev/disk/by-uuid/$ROOT_UUID" "$mnt"
  [[ -d $mnt/@swap ]] || btrfs subvolume create "$mnt/@swap"
  umount "$mnt"; rmdir "$mnt"
  echo "UUID=$ROOT_UUID /swap btrfs subvol=/@swap,noatime 0 0" >> /etc/fstab
  systemctl daemon-reload
fi
mountpoint -q /swap || mount /swap

step "Swapfile for hibernation (pri=0, so zram at 100 is still used first)"
[[ -f /swap/swapfile ]] || btrfs filesystem mkswapfile --size "$SWAP_SIZE" /swap/swapfile
grep -q '^/swap/swapfile' /etc/fstab || echo "/swap/swapfile none swap defaults,pri=0 0 0" >> /etc/fstab
swapon --show=NAME --noheadings | grep -q '^/swap/swapfile$' || swapon -p 0 /swap/swapfile

step "Kernel resume parameters, applied to every Limine kernel entry"
offset=$(btrfs inspect-internal map-swapfile -r /swap/swapfile)
mkdir -p /etc/limine-entry-tool.d
# Spaces on both ends: += concatenates with the cmdline from /etc/default/limine.
echo "KERNEL_CMDLINE[default]+=\" resume=UUID=$ROOT_UUID resume_offset=$offset \"" \
  > /etc/limine-entry-tool.d/50-hibernate.conf
limine-update

step "Suspend-then-hibernate waits 60 min before hibernating"
mkdir -p /etc/systemd/sleep.conf.d
printf '[Sleep]\nHibernateDelaySec=60min\n' > /etc/systemd/sleep.conf.d/50-hibernate.conf

step "Result"
swapon --show
grep -m2 -o 'resume=[^ ]* resume_offset=[0-9]*' /boot/limine.conf || echo "WARNING: resume params not found in /boot/limine.conf"
systemctl is-enabled nvidia-suspend nvidia-hibernate nvidia-resume asusd
