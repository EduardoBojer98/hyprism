# shellcheck shell=bash
# NVIDIA sleep and power: keeps video memory across sleep (without it the screen can come back black), and
# powers the card off whenever no app uses it. Applies from the next boot.
sys_enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
sys_write /etc/modprobe.d/hyprism-nvidia.conf "# Written by Hyprism (modules/nvidia-hybrid)
# keep video memory across sleep; the nvidia-suspend/resume services do nothing without it
options nvidia NVreg_PreserveVideoMemoryAllocations=1
# power the card off when idle (NVIDIA README, Dynamic Power Management)
options nvidia NVreg_DynamicPowerManagement=0x02"
for old in nvidia-sleep.conf nvidia-rtd3.conf nvidia-runtime-pm.conf; do sys_remove "/etc/modprobe.d/$old"; done # names before 2.0
# Dynamic Boost keeps the card awake, and firmware disables it on battery anyway
sys_mask nvidia-powerd.service
