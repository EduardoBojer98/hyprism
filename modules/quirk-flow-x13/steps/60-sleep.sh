# shellcheck shell=bash
# No automatic hibernation on this model: the RTC alarm never wakes it from sleep (s2idle), so systemd's
# "hibernate after an hour" fires only when you open the lid, and the laptop hibernates instead of waking
# (2026-11-14 after 9.5 h, 2026-11-17 after 11 h; the second resume also crashed Hyprland 0.57.2 in
# aquamarine's recheckOutputs). The lid and the idle timer sleep instead; Hibernate stays in the power menu.
# AllowSuspendThenHibernate=no also makes idle-sleep and the panel fall back to plain suspend.
sys_write /etc/systemd/sleep.conf.d/60-hyprism-flow-x13.conf "[Sleep]
AllowSuspendThenHibernate=no"
# sorts after the laptop module's 50-hyprism-lid.conf and wins over its HandleLidSwitch
sys_write /etc/systemd/logind.conf.d/60-hyprism-flow-x13.conf "[Login]
HandleLidSwitch=suspend"
# leftover of the pm_async = 0 workaround of 2026-11-14
sys_remove /etc/tmpfiles.d/60-hyprism-flow-x13-pm-async.conf
