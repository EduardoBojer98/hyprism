# shellcheck shell=bash
# DDC/CI talks to the monitor over I2C: load that kernel module now and at every boot.
sys_write /etc/modules-load.d/hyprism-i2c.conf "i2c-dev"
run sudo modprobe i2c-dev || warn "Could not load i2c-dev now; it loads at the next boot."
