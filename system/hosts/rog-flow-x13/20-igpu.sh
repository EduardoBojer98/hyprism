#!/usr/bin/env bash
# ROG Flow X13: Hyprland renders on the AMD iGPU only (modules/env.lua uses the link if it exists),
# so the NVIDIA dGPU can sleep. The PCI address is this laptop's.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
step() { printf '\n==> %s\n' "$*"; }

step "Stable /dev/dri/amd-igpu link, so Hyprland renders on the AMD iGPU only"
cat > /etc/udev/rules.d/90-amd-igpu.rules <<'EOF'
# /dev/dri/amd-igpu -> AMD iGPU card node (PCI 0000:08:00.0). Used by AQ_DRM_DEVICES in Hyprland.
KERNEL=="card*", SUBSYSTEM=="drm", KERNELS=="0000:08:00.0", SYMLINK+="dri/amd-igpu"
EOF
udevadm control --reload
udevadm trigger --subsystem-match=drm --action=add
udevadm settle
ls -l /dev/dri/amd-igpu
