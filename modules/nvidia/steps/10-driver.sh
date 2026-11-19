# shellcheck shell=bash
# NVIDIA driver: installs it if no NVIDIA driver is loaded. Changes kernel modules; reboot afterwards.
if [[ -e ${HW_ROOT:-}/proc/driver/nvidia ]]; then # HW_ROOT: the made-up computers of tests/detect.sh
    say "The NVIDIA driver is already loaded."
else
    distro_nvidia
fi
