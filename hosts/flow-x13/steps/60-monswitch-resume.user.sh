#!/usr/bin/env bash
# ROG Flow X13: removes the old monswitch-resume user unit. It was meant to run `monswitch sync` after
# resume, but a user service manager has no suspend.target, so it never ran. `monswitch watch` (started
# by Hyprland, modules/autostart.lua) survives a suspend and re-reads the monitor's input every 3 s,
# which covers resume. Safe to re-run. Runs as your normal user.
# Run: bash hosts/flow-x13/steps/60-monswitch-resume.user.sh
set -euo pipefail
[[ $EUID -ne 0 ]] || {
    echo "Run as your normal user"
    exit 1
}

unit=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/monswitch-resume.service
if [[ -f $unit ]]; then
    systemctl --user disable monswitch-resume.service 2>/dev/null || true
    rm -f "$unit"
    systemctl --user daemon-reload
    echo "Removed the old monswitch-resume.service (monswitch watch covers resume)."
else
    echo "Nothing to do: monswitch watch covers resume."
fi
