#!/usr/bin/env bash
# Logitech MX Master 4: buttons, gestures and haptics with JuhRadial MX (GPL-3.0, github.com/JuhLabs/juhradial-mx).
# Its installer adds the daemon (/usr/local/bin), the user service, udev rules, uinput and the
# input group. It runs as your user and asks for sudo itself, so install.sh runs it without sudo.
# Skipped when already installed; to update, run the curl line below by hand.
set -euo pipefail
[[ $EUID -ne 0 ]] || { echo "Run as your normal user"; exit 1; }

if command -v juhradiald >/dev/null; then
    echo "JuhRadial MX already installed ($(juhradiald --version))"
    exit 0
fi
curl -fsSL https://raw.githubusercontent.com/JuhLabs/juhradial-mx/master/install.sh | bash -s -- --yes
echo "Log out and back in once so the input group applies."
