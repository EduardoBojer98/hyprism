# shellcheck shell=bash
# Battery charge limit: stop charging at 80% so the battery lasts longer (you can change the number later).
# Writes one small file, /etc/tmpfiles.d/hyprism-charge-limit.conf, that sets the limit at every boot.
if ! hw_has power.charge_limit; then
    say "This battery has no charge limit the kernel can set: nothing to do"
elif [[ $(hw_get machine.tools) == asus ]]; then
    say "ASUS laptops: asusctl sets the charge limit, nothing to do here"
elif ask "Stop charging at 80% to make the battery last longer (you can change the number later)?"; then
    sys_write /etc/tmpfiles.d/hyprism-charge-limit.conf "w /sys/class/power_supply/BAT*/charge_control_end_threshold - - - - 80"
    run sudo systemd-tmpfiles --create /etc/tmpfiles.d/hyprism-charge-limit.conf || warn "could not set the charge limit now; it applies at the next boot"
fi
