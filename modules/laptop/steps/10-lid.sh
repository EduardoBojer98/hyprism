# shellcheck shell=bash
# Lid: closing it puts the laptop to sleep; with an external screen connected it keeps running.
# Hibernate after sleep is used only where this computer can already do it.
sleep=suspend
# logind does nothing at all for an action the machine can't do, so plain sleep is the safe default
if busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanSuspendThenHibernate 2>/dev/null | grep -q '"yes"'; then
    sleep=suspend-then-hibernate
fi
sys_write /etc/systemd/logind.conf.d/50-hyprism-lid.conf "[Login]
HandleLidSwitch=$sleep
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore"
sys_remove /etc/systemd/logind.conf.d/50-lid.conf # the name before 2.0
