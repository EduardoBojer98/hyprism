# v2 roadmap: one desktop, one design system, one settings source

Status of the "complete and polish" brief (2026-10-30). Each phase lands as its own tested commit.
Tick boxes only for things verified on the machine; untested items say so.

## Audit findings (Phase 1)

- **Visual direction**: the brief pins dark Liquid Glass + Catppuccin Macchiato, with
  `UI-examples/` (Tahoe Spotlight: search pill + round mode buttons; Applications grid with
  category chips) as the reference. This replaces the "Exat 51" pick from the 2026-10-30 decision
  page.
- **Theme**: `Theme.qml` holds colours, but most components hard-code font sizes, spacing, radii
  and durations. Hyprland borders/rounding, hyprlock and Ghostty don't take colours from it.
- **Settings**: three stores: `quickshell/settings.json` (weather), Lua tables under
  `hypr/settings/` (displays, input), and `hypr/hypridle.conf`. There's no shared schema, no
  defaults/reset, and no validation.
- **Popups**: Launcher (full-screen overlay), Control Center (PopupWindow anchored to the bar),
  power menu and calendar each place themselves. Nothing follows the cursor or the active monitor.
- **Launcher**: fixed tabs (Apps / Files / Clipboard), substring scoring, no ranking across kinds,
  no usage memory. Opens on Super+Space, not on Super.
- **Clipboard**: `cliphist` keeps text and images, but not timestamps, pins, expiry or files as
  `text/uri-list`. There's no auto-paste, and `wtype` isn't installed.
- **Icons**: Papirus is set in gsettings and Quickshell, but `papirus-icon-theme` **isn't
  installed**, so icons fall back to hicolor/Breeze.
- **ASUS** (GV301QC, asusctl):
  - Quiet / Balanced / Performance profiles, set automatically by power source (AC → Performance,
    battery → Quiet).
  - Custom 8-point fan curves for the CPU and GPU fans (`asus_custom_fan_curve`).
  - PPT PL1 is 45 W (range 15–45) and PL2 is 80 W (65–80), both at their maximum.
  - CPU driver: amd-pstate-epp, boost on.
  - Package power can be read from `amdgpu` `power1_input` (PPT). RAPL `energy_uj` is root-only.
  - Only the Balanced CPU curve is custom (enabled); every other profile/fan runs the firmware
    curve. That Balanced curve jumps from 46 % to 70 % between 68 and 70 °C, the likely cause of
    the loud fans in Chrome.
  - Originals backed up 2026-10-30 in `~/.local/state/asus-backup/<time>/` (all three profiles'
    curves, asusd configs, PPT values, EPP). `asusfan restore` puts the oldest backup back.
  - The NVIDIA GPU was awake because the Whatsie Flatpak opened `/dev/nvidia*`. A per-app
    `flatpak override --user` now points it at the Mesa EGL/Vulkan drivers (takes effect on its
    next start; undo with `flatpak override --user --reset com.ktechpit.whatsie`).
- **JuhRadial MX**: the daemon is a user service (default.target) that started before Hyprland,
  so it had no `HYPRLAND_INSTANCE_SIGNATURE` or `DISPLAY` and couldn't find the cursor or the
  focused app. The overlay also had no window rule. Fixed in autostart.lua and rules.lua.
- **Missing tools**: wtype (auto-paste), hyprsunset (night light), papirus-icon-theme.
  Present: tesseract + eng data (OCR), qalc, fd, playerctl, grim/slurp/satty.

## Architecture (Phase 2)

| Piece | File(s) | Contract |
|---|---|---|
| Settings source | `Config.qml` (singleton, `FileView` + `JsonAdapter` on `quickshell/settings.json`) | Every desktop option, with defaults in the adapter. Setters validate. `reset(section)`. Writes are atomic and the file is watched, so edits apply live. Hyprland-owned values (displays, input, idle) keep writing their Lua/conf files from the same pages. |
| Design tokens | `Theme.qml` | Derived from `Config.appearance`: palette, accent, glass alphas, stroke, radii (scaled), spacing, type scale, icon sizes, durations and easing. `ThemeSync.qml` pushes the same values to Hyprland (`hyprctl eval`), hyprlock and GTK/Qt settings. |
| Popups | `CursorPopup.qml` | Full-monitor transparent overlay layer on the monitor under the cursor (from `hyprctl cursorpos` + monitors). The content box opens at the cursor, clamped to that monitor, with exclusive keyboard focus. Click outside or Esc closes it. Shared open/close animation. |
| Search | `Search.qml` (singleton) + providers | Providers return `{title, subtitle, icon, kind, score, run()}`: apps (name, generic name, keywords, categories, frecency), settings pages, system actions, calculator (qalc), `>` commands, files (fd, async), custom actions/snippets, web fallback. Results are merged and ranked; the best one is preselected. |
| Clipboard | `clipstore` script + `Clipboard.qml` | `wl-paste --watch clipstore` saves each copy as a file with its MIME type and a timestamp under `~/.local/share/clipboard/`. Event-driven, no polling. Skips copies flagged as passwords. Dedupes, prunes by count/age, never prunes pins. Restore = `wl-copy --type <mime>`, then `wtype` Ctrl+V (Ctrl+Shift+V in terminals). |
| Hardware | `Sensors.qml` | One 2–3 s timer for temps; dashboard-only reads (fans, PPT, util, net) run only while the dashboard is visible. The NVIDIA GPU is never queried unless its runtime status is `active`. |
| Caffeine | `Caffeine.qml` | `systemd-inhibit --what=idle` held by a child process tied to Quickshell's PID, so it dies with qs. hypridle honours systemd idle inhibitors. |

## Thermal measurements (Phase 4)

Same load for every run: 4 busy threads (about 25-35 % CPU), 180 s, after 90 s settling, on AC
(`thermlog`; script in the session scratchpad). Averages:

| Run | CPU °C | Package W | Clock MHz | CPU fan rpm (avg / max) |
|---|---|---|---|---|
| Quiet, firmware curve | 84 | 28.8 | 2176 | 5958 / 7000 |
| Balanced, old custom curve | 90 | 32.0 | 2282 | 8864 / 9300 |
| Performance, firmware curve | 96 | 41.2 | 2674 | 9158 / 10400 |
| Balanced, new smooth curve | 90 | 29.7 | 2621 | 7695 / 8900 |

The CPU boosts until it reaches ~90-96 °C in every mode, so a fan curve mostly sets the noise,
not the temperature. The new Balanced CPU curve (50c:8 %, 60:18, 65:26, 70:34, 75:43, 80:52,
85:62, 92:80) has no 68-70 °C jump and is ~1200 rpm quieter on average at the same temperature.
Caveat: background load was higher during that run (idle 20 % vs 2 %), so treat it as indicative.
Quiet and Performance keep their firmware curves. Power limits (PPT) are unchanged: per-mode PPT
lives in root-owned `/etc/asusd/asusd.ron`.

## Phases

- [x] 1 Audit (this file)
- [x] 2 Architecture: Config + Theme tokens + ThemeSync + CursorPopup (accent/radius verified live in Hyprland, hyprlock file, GTK)
- [x] 3 Core: Spotlight on Super (search/apps/files/actions), clipboard on Super+V (auto-paste needs
      wtype), Settings on Config, dock on Config (size, auto-hide, pinned, right-click menu with
      minimise/restore/pin/quit, Super+H minimises), calendar under the clock. Moving the older
      components' hard-coded sizes onto tokens moves to Phase 6.
- [x] 4 Hardware: baseline measurements, Balanced fan curve, Caffeine, ASUS page with fan-curve editor
      (PPT per mode not changed: needs root)
- [ ] 5 Desktop: Control Center, notification centre + DND, MPRIS, night light, OCR, Mission
      Control, dock minimise, custom launcher actions
- [ ] 6 Polish and validation
- [ ] 7 Docs, packages, installer

## Needs the user

- `sudo pacman -S papirus-icon-theme wtype hyprsunset` (listed in `packages/desktop.txt`).
- Thermal benchmarks: about 10 of your usual Chrome tabs open while measurements run.
- Dock right-click menu and the clock calendar: open each once (checked by rendering, not by a real click).
- JuhRadial slices (in ~/.config/juhradial, not in this repo): Emoji = emojipick, Screenshot =
  grim+slurp+satty; de_defaults_applied=true stops its settings app overwriting them.
- JuhRadial: press the gesture button once in Hyprland to confirm the wheel opens at the cursor.
