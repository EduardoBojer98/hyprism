#!/usr/bin/env bash
# Phase 5: shell tools, runtimes and everyday apps. Safe to re-run.
# Run: sudo bash system/03-apps.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
cd "$(dirname "$0")/.."

# Package lists allow "# comments", also at the end of a line
sed 's/#.*//' packages/dev.txt packages/apps.txt | xargs pacman -S --needed --noconfirm
