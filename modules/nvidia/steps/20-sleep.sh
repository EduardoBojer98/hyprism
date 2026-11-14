# shellcheck shell=bash
# NVIDIA and sleep. Drivers with kernel suspend notifiers (NVreg_UseKernelSuspendNotifiers) save video memory
# themselves. NVIDIA's sleep services are then not needed, and they hurt: nvidia-sleep.sh switches to text
# console 63 before every sleep, the console moves the screens to other CRTCs, and the compositor's restore
# on wake can fail for good (a black screen until reboot; seen on a Flow X13, 2026-11-14). Older drivers
# still need the services, with the option that keeps video memory across sleep.
# Applies from the next boot.
if modinfo -p nvidia 2>/dev/null | grep -q '^NVreg_UseKernelSuspendNotifiers'; then
    for u in nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service nvidia-suspend-then-hibernate.service; do
        sys_disable "$u"
    done
    opt="# save video memory across sleep from the kernel itself, without a console switch
options nvidia NVreg_UseKernelSuspendNotifiers=1"
else
    sys_enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
    opt="# keep video memory across sleep; the nvidia-suspend/resume services do nothing without it
options nvidia NVreg_PreserveVideoMemoryAllocations=1"
fi
sys_write /etc/modprobe.d/hyprism-nvidia-sleep.conf "# Written by Hyprism (modules/nvidia)
$opt"
