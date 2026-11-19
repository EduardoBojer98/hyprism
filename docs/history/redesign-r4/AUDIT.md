# Redesign round 4: audit

Taken 2026-11-19 on `develop` 61ef5d2. Paths are under `config/quickshell/.config/quickshell/` unless given in full.
How checked: code reading (two read-only audit agents + lead), a nested screenshot sweep (3 themes x light/dark x
desktop, Control Center, launcher, notifications, power, calendar, Settings pages), `nested.sh errors`,
`tests/performance.sh`, the lint suite.

## Inventory (short)

- 205 QML files; 40 Settings pages (`SettingsPage*.qml`); 244 settings, every one with a control and a user
  (`tests/settings-coverage.py`: 0 gaps).
- IPC targets: launcher, controlcenter, notifications, power, clipboard, calendar, weather, system, flyout,
  wallpaper, overview, welcome, cheatsheet, alttab, settings, config, osd, displays, dock, bar, focus, phone,
  capture, recorder, nightlight, caffeine, tablet, keyboard, quicklook, pins, themes, updates, actions …
- Always-on timers: Focus.qml:76 (20 s), NightLight.qml:69, Notifications.qml:230 (30 s), Updates.qml:63 (1 h)
  and :107 (6 h), Phone.qml:122 (10/60 s, only with a phone), Weather.qml:122 (only with a place),
  Dock.qml:133 (60 s thumbnails, only while the dock shows). Everything else runs only while its surface is open.
- Long-running processes: `metrics watch` (Metrics.qml:59, only when a bar item needs it), `powermode watch`
  (PowerMode.qml:21, ASUS only), hyprsunset (Night Light on), systemd-inhibit (Caffeine on).
- Settings pages load only while Settings is open (SettingsApp.qml:393); the bar and dock through LazyLoaders.

## Feature status

Checked in depth: Control Center (tiles, toggles, sliders, Wi-Fi/Bluetooth lists), bar menu, Caffeine, Night Light,
Do Not Disturb, Phone, Clipboard, Inputs, OSK, brightness, audio. Grep-level only: Dock, Mission Control, Alt-Tab,
Hot Corners, Quick Look, Cheatsheet, Display switcher, Power menu, OSD, Notification center, Welcome.

- Works (read back from the real source): volume/mic sliders and devices, brightness, keyboard light, Caffeine,
  DND, Night Light, dark mode, floating, clipboard pause, phone switches, mic mute, user actions' state.
- Visual-only: none found. Broken (missing function, script, IPC target or key): none found.
- One-way (fixed in e681bbc unless noted):
  - Inputs.qml:21,25 touchpad/touchscreen: local bool, a restarted shell could show "on" for a device left off.
  - Osk.qml:8 on-screen keyboard: flipped locally, never read back from squeekboard.
  - Bar.qml:34,36 bar menu checkmarks: only built-in states, user toggles always unchecked, and a snapshot.
  - ControlCenterSliders.qml:132 DDC brightness: optimistic, `--noverify`, no read-back. Kept (DDC reads take
    about a second; the slider only appears after a successful read, so the bus is known). Listed in the report.
- Unavailable not handled (fixed in e681bbc): Wi-Fi, Bluetooth, Airplane, Touchscreen, On-screen keyboard tiles
  were offered with no hardware/program behind them (BuiltinActions.qml:76-92).
- Low, open: ROG Control Center is in packages/fedora.txt only (BuiltinActions.qml:63, ASUS only); Phone
  "Send files" fails silently without zenity (Phone.qml:126, zenity is in the manifest).

## Critical bugs

- None that lose data or break a surface. The worst were the fake-state tiles above (S each, fixed).

## Important improvements

- Reduced motion: Launchpad's wave scaled from 0.6 with an OutBack overshoot under Reduced
  (LauncherApps.qml:137, LauncherPadCell.qml:22 gated on `Theme.enter > 0`). S, fixed.
- Teardown warnings: ControlCenterWifiRow.qml:13,18,40 and Sys.qml:76 assign undefined while a network object
  goes away (16 per sweep). Harmless, noisy. S, open.
- ThemePreview.qml:33 asks for theme wallpapers before they are drawn (warning, blank card until drawn). S, open.

## Visual

- Control Center small tiles shrank each label on its own (ControlCenterQuickToggle.qml:51): "Microphone" smaller
  than "Caffeine" in Pebble, three sizes in Monolith. S, fixed (one size per grid).
- Otherwise the sweep shows cohesive surfaces in all six theme halves; no clipped text, no unreadable contrast
  (`tests/accessibility.sh` and the theme contrast lint pass).

## Optional features

- None added this round: the brief's constraints (three themes, no builder, no profiles) and a full surface set
  leave polish, not features.

## Design-system gaps

- Theme id in tokens: Theme.qml:68-69 picked Monolith's segmented-control colour by id. Fixed: `popup.segments`.
- Literal motion: 50 `Easing.OutCubic`, 13 literal durations (pulses 520/700 ms, cursor 530 ms, wave 200/320 ms).
  Fixed: tokens `easing`, `pulse`, `blink`, `pop`, `popFade`, `stagger`.
- Literal sizes: 12 glyph sizes (11-34 px) across 23 files. Fixed: five glyph steps (`glyphXs`..`glyphL`,
  `iconLarge`) and `fontBadge`; three one-off giant glyphs are marked.
- Colours: hex only in theme data and tokens (lint check); 23 `Qt.rgba`/hex lines are all in Theme/Themes or
  marked `// palette`.
- `tests/no-hardcode.sh` now fails on literal durations, OutCubic and font sizes in the shell.
- States: hover/pressed/disabled come from `fill`, `fillHover`, `fillActive` and `pressScale` across the shared
  controls (Toggle, Slider, PillButton, MenuRow, SettingRow). Focus ring: `FocusRing.qml` on the shared controls.

## Motion

- Tokens: per-theme `motion` (enter/exit/curve/travel/scale/press) + `appearance.motionStyle` looks (Theme.qml
  `looks`) + `appearance.motion` Full/Reduced/Off; Hyprland preset follows (`hyprMotion`).
- Reduced: 90/60 ms fades, no travel, no scale; the wave now obeys it. Pulses stay (opacity only).
- Panels take input from the first frame (Panel/Overlay); nothing found that blocks input during motion.

## Performance

- `tests/performance.sh` (nested, idle, 30 s): default bar 0.03 % CPU, 178 MB; sysinfo bar 0.20 % CPU, 333 MB,
  one `metrics watch`. Budgets 2 % / 450 MB. Already event-driven where Quickshell allows (Pipewire, Networking,
  Bluetooth, UPower, Hyprland sockets).
- Images without `sourceSize`: QuickLookView.qml:166 pages (fixed), Pins.qml:75 (pinned screenshots are shown
  at their own size; kept).

## Multi-monitor, scaling, distros

- `nested.sh screens2` (1.2 second screen) was covered in round 3; panels are kept on their monitor
  (`Displays.popupScreen`). Real multi-monitor, NVIDIA and Fedora on metal need real hardware (see REPORT).
