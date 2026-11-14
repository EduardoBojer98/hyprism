# shellcheck shell=bash
# No automatic hibernation on this model: resuming from it left the internal screen black (Hyprland's restore
# of eDP-1 failed with EINVAL and never recovered; 2026-11-14), while plain sleep resumes fine. The lid and
# the idle timer sleep instead; Hibernate stays in the power menu for when you choose it.
# AllowSuspendThenHibernate=no also makes idle-sleep fall back to plain suspend.
sys_write /etc/systemd/sleep.conf.d/60-hyprism-flow-x13.conf "[Sleep]
AllowSuspendThenHibernate=no"
# sorts after the laptop module's 50-hyprism-lid.conf and wins over its HandleLidSwitch
sys_write /etc/systemd/logind.conf.d/60-hyprism-flow-x13.conf "[Login]
HandleLidSwitch=suspend"
