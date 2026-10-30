# Changelog

## v1.1 (unreleased)

- macOS Tahoe look: thin see-through menu bar (desktops, app name; weather, date and time in the
  centre; tray, temperatures, status, notifications bell, utility menu on the right), neutral
  smoked glass with a white rim, 8-14 px corners
- Spotlight: centred, apps grid before you type, results ranked by group (order and groups set in
  Settings), clipboard history inside it
- Notification centre (bell, Super+N) with history, grouping and Do Not Disturb (Super+Shift+N);
  calendar popup under the clock
- Mission Control (Super+W, three fingers up): live window previews, desktop strip, drag a window
  onto a desktop to move it
- Control Center in the Tahoe layout; utility menu with tools and power; Night Light, Caffeine,
  copy text from screen (OCR), emoji picker
- Settings app (Super+I): every page above plus Keyboard Shortcuts (record and change any bind)
  and ASUS Hardware (live readings, fan-curve editor)
- For any user: Settings choices stay local (gitignored) with defaults in code; hardware features
  detect themselves; per-computer Hyprland and system steps live under `hosts/<hostname>`;
  monswitch reads `~/.config/monswitch.conf`; docs/USER-GUIDE.md
- XWayland apps sharp on scaled screens (zero scaling)

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
