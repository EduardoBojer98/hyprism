# shellcheck shell=bash
# Computers are no longer picked by hostname (hosts/<name>): the hardware is detected and modules switch on
# by themselves. The old per-host records are dropped, so each module's steps are offered once.
run rm -f "$STATE"/steps/flow-x13-* "$STATE"/steps/default-* "$STATE/last-backup"
# host.lua was a link into hosts/; the modules' own files replace it
if [[ -L $HOME/.config/hypr/host.lua ]]; then run rm "$HOME/.config/hypr/host.lua"; fi
