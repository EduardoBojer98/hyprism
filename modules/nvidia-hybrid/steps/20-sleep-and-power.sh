# shellcheck shell=bash
# NVIDIA sleep and power: keeps video memory across sleep (without it the screen can come back black), and
# powers the card off whenever no app uses it. Applies from the next boot.
# Drivers with kernel suspend notifiers save video memory themselves. NVIDIA's sleep services are then not
# needed, and they hurt: nvidia-sleep.sh switches to text console 63 before every sleep, the console moves
# the screens to other CRTCs, and Hyprland's restore on wake can fail for good (black laptop screen after
# the external monitor dropped off while asleep; 2026-11-14). Older drivers still need the services.
if modinfo -p nvidia 2>/dev/null | grep -q '^NVreg_UseKernelSuspendNotifiers'; then
    for u in nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service; do sys_disable "$u"; done
    sleep_opt="# save video memory across sleep from the kernel itself, without a console switch
options nvidia NVreg_UseKernelSuspendNotifiers=1"
else
    sys_enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
    sleep_opt="# keep video memory across sleep; the nvidia-suspend/resume services do nothing without it
options nvidia NVreg_PreserveVideoMemoryAllocations=1"
fi
sys_write /etc/modprobe.d/hyprism-nvidia.conf "# Written by Hyprism (modules/nvidia-hybrid)
$sleep_opt
# power the card off when idle (NVIDIA README, Dynamic Power Management)
options nvidia NVreg_DynamicPowerManagement=0x02"
for old in nvidia-sleep.conf nvidia-rtd3.conf nvidia-runtime-pm.conf; do sys_remove "/etc/modprobe.d/$old"; done # names before 2.0
# Dynamic Boost keeps the card awake, and firmware disables it on battery anyway
sys_mask nvidia-powerd.service
