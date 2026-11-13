# shellcheck shell=bash
# NVIDIA driver: installs it if no NVIDIA driver is loaded. Changes kernel modules; reboot afterwards.
if [[ -e /proc/driver/nvidia ]]; then
    say "The NVIDIA driver is already loaded."
else
    distro_nvidia
fi
