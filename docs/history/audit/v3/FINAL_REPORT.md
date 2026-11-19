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
- **Control Center (redesigned after the first merge):**
  - Header with time, battery, and Settings / Lock / Power reachable by Tab.
  - Connection tiles: an icon well that toggles, a chevron that opens the list.
  - Quick toggles in equal rows of 3 or 4; the last row shares the full width.
  - Sliders with a handle, a mute well and a device chevron.
  - A full-width power-mode control.
  - Spacing comes from density tokens (`Theme.qml`, "Control Center tokens").
  - Clicking the bar's quick-settings cluster opens the whole Control Center, not one flyout per icon.
- **Bar editor:** chips with names; zones sized by item count.
- **Dock:** reachable from the keyboard with Shift+F6.
- **Settings:** new Screenshots page, border colour rows, "Open: at the pointer" row for the Launcher.
  "Screens" was renamed to "Displays".

## 6. Design system and themes

| Theme | Personality | Signature |
|---|---|---|
| **Pebble** (default) | elegant, calm | sage on charcoal, Archivo light, roomy, r14, soft motion, river-stone wallpaper |
| **Poster** | expressive, colourful | red/cobalt/yellow on paper, hard cobalt shadow, reverse-video segments |
| **Monolith** (redesigned) | experimental, crafted TUI | olive-tinted grey layers, JetBrains Mono UI + Martian Mono numbers, status line with dim labels (`bar.dimLabels`), inverse lime clock block, corner-bracket panels, rainbow frame on AC, 140/90 ms expo motion, monolith-at-dawn wallpaper; the light half keeps lime as reverse video |

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
  - The launcher opens in the middle of the screen in every style (the default, at the owner's request);
    "At the pointer" and "Style's place" stay as choices.
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
  - `tests/performance.sh`, final `main` vs the release before (5b11a1a): idle CPU 0.27 % vs 0.23 %, memory 415 MB vs
    413 MB (budgets 2 % / 450 MB). PLAN's 299 MB target predates this machine's numbers: 5b11a1a itself uses 413 MB.
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
- **Bug found in the re-check:** `shape.density` and `hypr.frame` never took effect in any theme. Themes are
  merged over the built-in safe theme, which lacked both keys. Fixed, and `tests/themes.py` now fails on any theme
  key the safe theme lacks.
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
- **Not checked by click:** the bar's quick-settings cluster opening the Control Center (the test desktop cannot
  click); a brightness slider in the Control Center (the test desktop has no backlight); the Control Center's fit
  at scale 1.2 (estimated about 810 px of 1000).
- **Plan items changed on purpose:** Settings keeps 13 sidebar groups rather than the PLAN's Look / System / Apps /
  Tools headings (every page is reachable and searchable); tile state text stays short ("MKhome 5G", "On"), as
  "On · MKhome 5G" did not fit 60 px.
- **Open:** Monolith app icons stay in colour; the calendar's "today" marker is round in every theme.
- **Wallpaper art:** Poster's paper square under the bar is part of the wallpaper; change `themes/poster/wallpaper.sh` if it should go.
- **Owner's checklist:**
  - Log out and in once.
  - Press Print and take an area shot.
  - Try Rainbow in Settings > Windows.
  - Add a second weather place.
  - Open the System panel while on battery.

## 11. Follow-up requests (2026-11-15, after the first live merge)

| Request | Done | Checked |
|---|---|---|
| Quick settings icons open the whole Control Center | `BarStatus.qml` | QML loads; the click itself not scriptable |
| Redesign the quick settings panel | Control Center redesign; Screen and Sound in separate tiles (fold row and `controlCenter.slidersOpen` removed) | test desktop, 3 themes; live (built-in + XZ322QU brightness) |
| Launcher in the middle in every theme | `launcher.position: center` (default), set live | test desktop, 3 themes |
| Monolith redesign, cyberpunk terminal, new bar layout | neon terminal HUD: workspace tabs, split clock, slash rules, magenta brackets + glow, lime→magenta frame, scanline wallpaper; new theme options `ws: tabs`, `clock: split`, `bar.sepStyle`, `popup.decorColour` | test desktop dark + light; live bar |
| Better animations, different looks, examples in Settings | looks Theme's own / Smooth / Snappy / Springy / Minimal (`appearance.motionStyle`), preview cards in Settings > Appearance > Motion; overlay, OSD, weather skeleton, Hyprland close curve and Reduced fixed; shell layers skip Hyprland's fade | test desktop; idle CPU unchanged |
| Menu Bar visual editor, only the picked item's settings | bar preview + three equal columns + "Add to the bar"; keyboard moves; per-item panel | test desktop, 3 themes, keyboard only |
| Notification badge with no notifications | unread is counted from the history (`Notifications.qml`) | reproduced live, fixed live |
| Screenshot tool not working | `~/.local/bin` was not on Hyprland's PATH under greetd (also broke `hypr-plugins`, `hypr-crashlog` at login) | live: a keybind shot saves |

Also fixed on the way: `shape.density` and `hypr.frame` never applied (lint now guards theme keys); a start-up
TypeError in `shell.qml`; Wi-Fi row warnings; 24-hour time reachable from the Lock Screen page.

Not verified by a real pointer: dragging in the bar editor, the quick-settings click, Springy overshoot on real
panels (checked in the preview cards), an area selection with the mouse.

## 12. Second round of requests (2026-11-15 evening to 2026-11-16)

| Request | Done |
|---|---|
| Second colour choices; Monolith's second colour | a palette for the second colour (Settings > Appearance); Monolith's is electric blue `#4f8cff` |
| Monolith workspaces, Caffeine spacing, dividers, quick tools icon, default layout | reticle workspace marker; Caffeine cup spaced in the status cluster; quiet pips; widgets glyph; the owner's layout is Monolith's default (apps left, no active window) |
| System info item | CPU and GPU temperature by default; System panel leads with four vitals, graphics cards by real name (PCI ids, a sleeping card is never woken), labelled detail grid |
| Bar items many times, each independent | `id#n` copies with their own settings; each anchors its own panel |
| Clock customizer, floating-bar overflow | per-clock time, date parts, order, separator or an own Qt pattern, with preview; a block clock is now exactly the bar's height |
| Bar and dock size sliders | `PresetSlider.qml`: presets over a slider, a chip lights on an exact match |
| Dock: names instead of icon + title | `dock.nameOnly`, in the dock and the bar's dock |
| Control Center redesign | large / small tiles from one tile list, Screen and Sound cards, a live arrange editor; Screen, Sound and Power fold to one line; Dark mode, Microphone, Airplane, Clipboard, Text, Emoji buttons |
| Notifications page | test buttons, six styles with previews, position, per-urgency timeouts and sounds, max on screen, group by app, icons, a Do Not Disturb schedule |
| Icon and cursor theme per theme | `icons` / `cursor` in theme.json; Settings "Theme's own" by default |
| Monolith launcher, launcher options | centred terminal-HUD palette; the full-width style removed; suggestions before you type by default; every option checked |
| Menu Bar editor hover glitch, hide | a HoverHandler keeps the row hovered; an eye hides an item in place |
| Title bars fit the theme | colours, font and height from the theme, live; Size / Buttons side / Title alignment settings |
| Border on/off and more styles | neon, mono, sunset, ocean, custom; angle; "Turn the colours" switch |
| Shared monitor toggle with no picture on HDMI 2 | the hand-off is checked against the monitor's input; no mirror is left behind |

Bugs found on the way: the notification badge counted dismissed notifications; `~/.local/bin` was not on
Hyprland's PATH under greetd (screenshots, `hypr-plugins` and `hypr-crashlog` never ran: title-bar plugins were
not loaded until now); `shell.qml` wrote a read-only property at start.

Not verified with a real pointer or device: mouse drags in the editors, the Screen card's brightness on the
laptop (seen live only before the redesign), the monitor switch on the real monitor, title-bar buttons after a
fresh login, notification sounds.
