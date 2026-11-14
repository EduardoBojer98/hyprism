# shellcheck shell=bash
# Leftovers from two sleep workarounds of 2026-11-14 (no automatic hibernation, then pm_async = 0). Both
# chased a black screen on wake whose real cause was NVIDIA's console switch (the nvidia module now turns it
# off), so this model needs neither.
sys_remove /etc/tmpfiles.d/60-hyprism-flow-x13-pm-async.conf
sys_remove /etc/systemd/sleep.conf.d/60-hyprism-flow-x13.conf
sys_remove /etc/systemd/logind.conf.d/60-hyprism-flow-x13.conf
