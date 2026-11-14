# shellcheck shell=bash
# Hibernation resume: devices wake one at a time (pm_async = 0). With the default parallel wake-up, resuming
# from hibernation left the internal screen black (Hyprland's restore of eDP-1 failed with EINVAL and never
# recovered; 2026-11-14). With it off, the same resume came back clean. Workaround from
# https://community.frame.work/t/hibernate-resume-failures-on-framework-13-amd-ryzen-ai-300-krackan-a-b-tested-workaround-pm-async-0/83040
sys_write /etc/tmpfiles.d/60-hyprism-flow-x13-pm-async.conf "w /sys/power/pm_async - - - - 0"
# the earlier fix turned automatic hibernation off; with pm_async = 0 it is back on
sys_remove /etc/systemd/sleep.conf.d/60-hyprism-flow-x13.conf
sys_remove /etc/systemd/logind.conf.d/60-hyprism-flow-x13.conf
