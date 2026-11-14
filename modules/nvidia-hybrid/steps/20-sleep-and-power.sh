# shellcheck shell=bash
# NVIDIA power: powers the card off whenever no app uses it. Applies from the next boot. (Sleep: the nvidia
# module, steps/20-sleep.sh.)
sys_write /etc/modprobe.d/hyprism-nvidia.conf "# Written by Hyprism (modules/nvidia-hybrid)
# power the card off when idle (NVIDIA README, Dynamic Power Management)
options nvidia NVreg_DynamicPowerManagement=0x02"
for old in nvidia-sleep.conf nvidia-rtd3.conf nvidia-runtime-pm.conf; do sys_remove "/etc/modprobe.d/$old"; done # names before 2.0
# Dynamic Boost keeps the card awake, and firmware disables it on battery anyway
sys_mask nvidia-powerd.service
