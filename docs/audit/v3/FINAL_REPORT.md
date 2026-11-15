# Desktop v3: final report (2026-11-15)

Branch `desktop-v3`, merged into `main` (live) on 2026-11-15. Working notes: `ui-surfaces.md`,
`settings-and-services.md`, `research.md` (audits), `PLAN.md` (plan + revisions), `REVIEW.md` (independent review).

## 1. Initial audit

- **Panels:** Escape did not close 7 of the cursor panels: Sensors, Weather, Calendar, Control Center,
  Notification Center, Utility menu and Keyboard. The cause was that the key handler needed focus no one gave it.
- **Overflow:** Calendar and Launcher overflowed their boxes. Weather and Control Center cut their last row with
  no hint that more was below.
- **Duplicate code:** Four overlays and five menus each repeated their own positioning code.
- **Metrics:**
  - Battery watts and time left were wrong on this laptop: 0.0 W and 32248 min. The firmware reports 15 mW while
    the battery is "Not charging".
  - The VRAM check compared against the iGPU's 512 MB carve-out.
- **Weather:** one city only, errors swallowed silently, no offline state.
- **Bar layout:** four layers decided it (theme, preset, per-theme override, editor target).
- **Settings gaps:**
  - The border colour had no control; the rainbow loop was switched off in `animations.lua`.
  - Screenshots and recording had no Settings page.
  - Dead keys: `apps.terminal` and `launcher.columns`.
  - State was mixed into `settings.json`: caffeine, launcher usage, notification history.
- **Themes:** 10 themes, mostly recolours of one layout.

## 2. Independent review (`REVIEW.md`)

9 must-fix, 15 should, 5 consider. All 9 must-fix items were handled:

1. **Live merge order.** The merge to main followed the review's order, and update now restarts the shell
   correctly (section 9).
2. **Theme renames.** Every old theme id now maps to one of the three themes left.
3. **Flyouts on the live bar.** The flyouts were wired to the live bar's status items.
4. **Control Center modules.** They no longer read the singleton, so the flyouts can reuse them.
5. **Sleeping dGPU.** `nvidia-smi` is only asked while the card is already awake and the System panel is open.
6. **File ownership.** Each agent got its own files.
7. **Dock.** The Dock got keyboard support.
8. **Multi-monitor.** Tested on a second headless screen at scale 1.2 (`tests/nested.sh screens2`).
9. **Themes that differ beyond colour.** A density token was added, and the themes also differ in shape, motion
   and frame.

Consider items taken:

- The Theme Builder and "Save as a theme" were cut.
- State moved to `~/.local/state`.

## 3. Architecture

- **Settings is the single source.** `ConfigData.qml` holds the defaults. `Config.qml` holds the schema,
  `problem()` validation and `repair()` migrations. `tests/settings-coverage.py` (in lint) checks that all
  191 options have a control and a user; there are 0 gaps.
- **One popup system.** `CursorPopup` covers placement at the pointer or an anchor, screen edges, focus, Esc,
  outside click and a scrolling body. Menus are built from `MenuList`, `MenuRow` and `MenuDivider`. `Overlay`
  is used for centred cards, `PopupDepth` for the theme's shadow, and `PanelState` makes sure only one panel is
  open at a time. Flyouts reuse the Control Center modules.
- **One bar layout.** `bar.layout` holds edge, size, floating, the item lists and the Dock. Presets only copy
  items into it. Migration: a per-theme layout or a chosen preset becomes `bar.layout`.
- **Theme tokens.**
  - `shape.density`: compact 0.85, regular 1, roomy 1.2.
  - `hypr.frame`: accent, gradient or rainbow.
  - `panelWidth` 336 / `panelWide` 368.
  - `selectInverse`, for reverse-video segments.
- **Migration 0006.** Removes the dead links and cached wallpapers of the four retired themes.

## 4. Applications

No new dependencies. The apps already installed are enough:

- Files and archives: Nautilus, File Roller.
- Images and documents: Loupe, Papers, Satty.
- Authentication and portals: hyprpolkitagent, xdg-desktop-portal-hyprland and xdg-desktop-portal-gtk.
- Drives: udiskie, gvfs.
- Input and recording: wtype, wf-recorder.
- Settings tools: pavucontrol, nm-connection-editor.
- Disk usage: baobab.

Settings > Apps now has a Terminal row.

## 5. UI redesign

- **Panels:** Every panel closes on Esc. Tested in all three themes, 15 panels each.
- **Weather:** places, hourly strip, daily range bars.
- **System monitor:**
  - CPU, memory, swap.
  - A graphics grid with one row per GPU (Load, Temp, Power, Shared). The dGPU shows "Sleeping" when it is.
  - Disk temperature, network sparkline, battery, top processes.
- **Control Center:** a 12-column tile grid, so a short last row fills the width; one "on" style.
- **Bar editor:** chips with names; zones sized by item count.
- **Dock:** reachable from the keyboard with Shift+F6.
- **Settings:** new Screenshots page, border colour rows, "Open: at the pointer" row for the Launcher.
  "Screens" was renamed to "Displays".

## 6. Design system and themes

| Theme | Personality | Signature |
|---|---|---|
| **Pebble** (default) | elegant, calm | sage on charcoal, Archivo light, roomy, r14, soft motion, river-stone wallpaper |
| **Poster** | expressive, colourful | red/cobalt/yellow on paper, hard cobalt shadow, reverse-video segments |
| **Monolith** | experimental, terminal | mono, compact, accent on black, inverse selection |

All three have a light and a dark half. The old themes map to these:

- workstation, canvas, zen, halo, garden, glass → Pebble
- noir, console, reactor → Monolith
- mist, atlas → Poster

## 7. Features

- **Weather:**
  - Up to 20 places: search, add, rename, reorder, remove.
  - The first place is the default and Night Light uses it.
  - Switch places from the panel.
- **Metrics:**
  - Battery time left is hidden below 1 W and when the battery is neither charging nor discharging. It uses a
    30 s average.
  - The dGPU is never woken: it sleeps again in about 9 s.
- **Border:** Theme / Accent / Gradient / Rainbow. Rainbow turns only when:
  - motion is Full;
  - the power mode is not Silent;
  - the laptop is on AC, unless you allow it on battery.
- **Launcher and clipboard:**
  - The launcher opens at the pointer on Super.
  - The clipboard opens near the pointer.
- **Power:**
  - Power modes are named Silent / Balanced / Performance.
  - The Caffeine toggle uses `systemd-inhibit --what=idle`.

## 8. Screenshots

The stack is grim + slurp + Satty, plus `hyprpicker -r -z` to freeze the screen and wf-recorder to record. The
capture bar opens on Print. It offers area, window, screen, delay and record, with audio set to none, desktop or
mic. After a shot it can edit, copy or save, and the folders are settings.

Flameshot was not used. It draws one overlay window across all monitors, and that breaks when screens have
different scales: this desktop mixes 1.2 and 1.0.

## 9. Testing

- **Tests (pass):**
  - `tests/all.sh` passes: lint, install on Arch and Fedora, and the update test from the last release, which
    runs migration 0006.
  - `settings-coverage`: 191 options, 0 gaps.
  - `tests/performance.sh` with the laptop preset: 0.67 % CPU, 443 MB.
- **Test desktop QA:**
  - All panels, the battery flyout and the Settings pages (Appearance, Menu Bar) were checked in Pebble, Poster
    and Monolith.
  - An independent visual review gave the verdict "fix". Its items were then fixed by the lead and a polish
    agent.
- **Rainbow cost:** the loop costs about 8.9 % Hyprland CPU with software rendering in the test desktop; a still
  rainbow costs 0 %.
- **Live merge:**
  - Hyprland reports no config errors.
  - Monolith was kept; the bar layout migrated; Zrenjanin is the first place.
  - The retired themes are removed.
  - GTK is `adw-gtk3-dark` with prefer-dark.
  - The dGPU is `suspended`.
  - The bar is on both monitors.
  - The weather panel, Control Center and capture bar render.
- **Problem found in the live merge:** the shell reloaded by itself when the links changed. That left a second
  instance and a crash dialog, and `qs kill` stopped only one of them. The second instance was stopped by hand.
  `install.sh update` now stops every instance, up to 3.

## 10. Remaining work

- **Not done:** Login screen (greetd) theming.
- **Workaround:** The Quickshell IPC CLI mangles JSON arguments, so tests edit `settings.json` directly.
- **Not tested live:**
  - Per-screen bar editing, and drag and drop in the bar editor.
  - A real slurp selection, and recording.
- **Partly tested:** Panels on a second screen; checked on the headless screen only.
- **Not re-checked after the polish pass:**
  - The Poster cheatsheet against the bar clock.
  - The bar editor's final chip widths.
- **Open:** Monolith app icons stay in colour.
- **Wallpaper art:** Poster's paper square under the bar is part of the wallpaper; change `themes/poster/wallpaper.sh` if it should go.
- **Owner's checklist:**
  - Log out and in once.
  - Press Print and take an area shot.
  - Try Rainbow in Settings > Windows.
  - Add a second weather place.
  - Open the System panel while on battery.
