#!/usr/bin/env bash
# Logitech MX Master 4: buttons, gestures and haptics with JuhRadial MX (GPL-3.0, github.com/JuhLabs/juhradial-mx).
# Its installer adds the daemon (/usr/local/bin), the user service, udev rules, uinput and the
# input group. It runs as your user and asks for sudo itself, so install.sh runs it without sudo.
# Skipped when already installed. Pinned to a release you can read first (it runs sudo inside);
# to update, change VERSION and SHA256 after reading that release's install.sh.
set -euo pipefail
[[ $EUID -ne 0 ]] || {
    echo "Run as your normal user"
    exit 1
}

if command -v juhradiald >/dev/null; then
    echo "JuhRadial MX already installed ($(juhradiald --version))"
    exit 0
fi
VERSION=v0.4.5-beta.6 # installed on the X13 2026-10-31
# the installer as read for that release: a moved tag or a changed file is refused, not run
SHA256=f7500dfdd1c21eebe574ea7b5addd08d19807096e3eab2c4377bbeae702ad1e5
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsSL "https://raw.githubusercontent.com/JuhLabs/juhradial-mx/$VERSION/install.sh" -o "$tmp"
echo "$SHA256  $tmp" | sha256sum -c --quiet || {
    echo "JuhRadial MX installer changed since it was checked; read it, then update SHA256 here" >&2
    exit 1
}
bash "$tmp" --yes
echo "Log out and back in once so the input group applies."
