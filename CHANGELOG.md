# Changelog

## v1.1 (unreleased)

- Top bar redesigned as floating glass complications: workspaces, focused app, weather (Open-Meteo),
  clock, CPU/GPU temperature rings, tray, status, power; colour only for active or out-of-range states
- Settings app (Super+I) with native pages for displays, sound, network, Bluetooth, power, keyboard and
  touchpad, wallpaper, lock and sleep, default apps, weather and system info
- Display and input settings moved to hypr/settings/*.lua so the Settings app can write them
- Workspaces numbered from 1, laptop starts on 1 and the Acer on 2
- DESIGN.md and PRODUCT.md describe the shell's design system and purpose

## v1.0 (2026-10-30)

First complete setup on the ROG Flow X13 (GV301QC).

- Hardware: asusctl + ROG Control Center, 80 % charge limit, hibernation (20 GB swapfile on `@swap`),
  NVIDIA kept off the Hyprland session's EGL path; dGPU on/off through ROG Control Center
- Hyprland 0.56 with a modular Lua config, alongside KDE Plasma
- monswitch: Acer XZ322QU S input switching over DDC/CI with workspace save/restore and a watcher
- Quickshell shell: bar with tray and status pill, macOS-style Control Center (Wi-Fi, Bluetooth, audio
  devices, brightness, power mode), auto-hiding dock, tabbed launcher (apps / files / clipboard), OSD,
  notifications, power menu
- Dark liquid-glass look (Glass component + Hyprland blur) with Catppuccin Macchiato accents
- Tablet mode (auto-rotation, on-screen keyboard button) and lid handling
- Apps: Ghostty, Starship, zoxide, fzf, uv, PHP/Composer, Okular, OnlyOffice, Bitwarden
- install.sh with backups, dry run and undo; gitleaks pre-commit hook
