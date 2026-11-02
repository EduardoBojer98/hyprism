#!/usr/bin/env bash
# ROG Flow X13: run monswitch sync after resume so Hyprland reflects the actual monitor input.
# Safe to re-run. Runs as your normal user.
# Run: bash hosts/flow-x13/steps/60-monswitch-resume.user.sh
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo "Run as your normal user"; exit 1; }

UNIT_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user
mkdir -p "$UNIT_DIR"

cat > "$UNIT_DIR/monswitch-resume.service" <<'EOF'
[Unit]
Description=Sync monswitch state after resume
After=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

[Service]
Type=oneshot
# Wait for Hyprland's socket to be ready before poking it.
ExecStartPre=/bin/sleep 2
ExecStart=/bin/bash -c '[ -f %h/.config/monswitch.conf ] && monswitch sync'
Environment=XDG_RUNTIME_DIR=/run/user/%U

[Install]
WantedBy=suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
EOF

systemctl --user daemon-reload
systemctl --user enable monswitch-resume.service
echo "monswitch-resume.service installed and enabled."
systemctl --user status monswitch-resume.service --no-pager || true
