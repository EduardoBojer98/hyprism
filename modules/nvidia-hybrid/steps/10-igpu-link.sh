# shellcheck shell=bash
# A stable name, /dev/dri/igpu, for the built-in graphics card. Hyprland draws only on it, so the NVIDIA
# card can power off. (card0 / card1 swap between boots; the PCI address doesn't.)
pci=$(hw_get gpu.primary_pci)
[[ $pci =~ ^[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9a-f]$ ]] || {
    warn "No PCI address for the built-in card in hardware.toml; skipped."
    exit 0
}
sys_write /etc/udev/rules.d/90-hyprism-igpu.rules "# /dev/dri/igpu -> the built-in graphics card ($pci). Written by Hyprism (modules/nvidia-hybrid).
KERNEL==\"card*\", SUBSYSTEM==\"drm\", KERNELS==\"$pci\", SYMLINK+=\"dri/igpu\""
sys_remove /etc/udev/rules.d/90-amd-igpu.rules # the name before 2.0
run sudo udevadm control --reload
run sudo udevadm trigger --subsystem-match=drm --action=add
