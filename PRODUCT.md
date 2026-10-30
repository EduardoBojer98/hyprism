# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

<!-- Not a website: a Wayland desktop shell written in QML (Quickshell) for Hyprland. "web" is the
closest schema value; there is no iOS/Android design language involved. -->

## Users

One person: Eduardo, a full-stack web developer (WordPress, Shopify, React/TS, Node, PHP, Docker/Lando)
on an ASUS ROG Flow X13 (13.4" 1920x1200 @120 Hz, touch + stylus, 360° hinge) usually docked to a 32"
Acer (2560x1440 @144 Hz) that is shared with a work PC. Daily work: browser-heavy research and site
testing, VS Code, terminals, Claude Code; sometimes tablet/tent mode. New to daily Linux and Hyprland.

## Product Purpose

The desktop shell of his own Hyprland setup: the top bar, dock, Spotlight-style launcher, Control
Center, notifications, OSD and (next) a Settings app. It should make everyday system state visible and
every common setting reachable without a terminal, while staying fast and battery-friendly.

## Positioning

A personal shell built for exactly this machine and workflow: one key hands the shared Acer monitor
to the work PC and back (DDC/CI), tablet rotation and lid handling are built in, and everything lives
in one reproducible repo (github.com/EduardoBojer98/linux-setup).

## Operating Context

- Laptop screen + big external monitor at the same time; the external one is sometimes taken by the
  work PC (workspaces then move to the laptop).
- Mouse/keyboard (Keychron, MX Master 4) most of the time, touch and stylus in tablet mode.
- Battery matters: the NVIDIA GPU is normally off; the shell must stay light.
- KDE Plasma stays installed as a fallback session and must never be modified.

## Capabilities and Constraints

- Built with Quickshell 0.3 (QML) on Hyprland 0.56 (Lua config). Free and open source only.
- Bar must keep: workspaces, clock + date, tray icons, a status area (Wi-Fi, Bluetooth, volume,
  battery) that opens the Control Center. New: weather for his location, CPU and GPU temperatures.
- Bar priority: rich but tidy — more live information visible at once, grouped cleanly.
- Settings: an own Settings app with native pages (Displays with drag-to-arrange writing the Hyprland
  config, Sound, Network, Bluetooth, Power & battery, Keyboard & touchpad, Appearance/wallpaper, Idle &
  lock, Default apps), deep-linking to ROG Control Center for fans and GPU.
- Accent and theme so far: dark "liquid glass" with Catppuccin Macchiato accents; Inter for UI,
  JetBrains Mono Nerd Font for icons. Treat as the incumbent look, not a binding commitment.

## Brand Commitments

None beyond the user's stated wish for a modern, macOS-inspired dark glass feel.

## Evidence on Hand

No external assets. Real data sources: Hyprland IPC, PipeWire, UPower, NetworkManager, BlueZ,
lm-sensors/hwmon temperatures, a weather service to be chosen (free, no account).

## Product Principles

1. Glanceable first: state is readable at a glance from across the desk.
2. One place per job: bar shows, Control Center adjusts quickly, Settings configures fully.
3. Native to this machine: dual screens, tablet mode and the shared monitor are first-class.
4. Light on battery: no polling-heavy widgets; nothing runs on the NVIDIA GPU.
5. Reproducible: every setting the shell writes ends up in the repo or a documented state file.
