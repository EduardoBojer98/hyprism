# Desktop v3 plan (2026-11-15)

Branch `desktop-v3`, worktree `.claude/worktrees/v3`. Evidence: [ui-surfaces.md](ui-surfaces.md),
[settings-and-services.md](settings-and-services.md), [research.md](research.md). The earlier overhaul
([../FINAL_REPORT.md](../FINAL_REPORT.md)) is merged: installer, modules, item folders, Metrics service, theme
folders, contrast tests and CI all exist. This round builds on them; it is not a rewrite.

## 1. Findings that drive the plan

| # | Finding | Evidence |
|---|---|---|
| F1 | Escape does not close 7+ panels; popup focus is only set for Launcher and Clipboard | `CursorPopup.qml` `Keys.onEscapePressed` on an item that never gets focus |
| F2 | Calendar, Weather, Control Center, Launcher home clip content; no scroll, no cue | screenshots `audit-shots/01-*` |
| F3 | Five private menu-row copies, four copies of the full-screen overlay, two segmented controls, CC sliders apart from `Slider.qml`, `TrayMenu`/`Dropdown` skip the theme's depth and decor | ui-surfaces "Duplicates" |
| F4 | Menus, Dock menu, CC rows, notification cards are pointer-only; Dock menu has no Esc or outside click | ui-surfaces |
| F5 | Volume, network, Bluetooth, brightness and status items have no flyout of their own (all open Control Center); battery opens Settings; power-profile cycles blind; media has no popover | ui-surfaces |
| F6 | Weather: one location, failures swallowed (`Weather.qml:95`), "Loading…" forever, fixed 15 min / 12 h | settings-and-services §2 |
| F7 | Metrics: time-left shows 32248 min when not discharging; iGPU memory compared with the 512 MB carve-out (GTT is 8 GB) gives a false warning; poll interval never rises again; no per-core, frequency, load, swap, disk I/O in the panel | §3, measured |
| F8 | Bar layout is decided by four layers (theme, per-theme custom, presets, per-monitor); the editor edits a preset or the theme without saying which | §8 |
| F9 | Seven themes, several near-duplicates: Pebble≈Glass (soft glass), Atlas≈Poster (red brutalist), Console≈Monolith≈Reactor (mono, one hot accent on black). Layouts differ little between them | screenshots `docs/screenshots/themes` |
| F10 | Window border: no gradient/rainbow control; `animations.lua:62` forces `borderangle` off | §6 |
| F11 | Screenshots/recording have no Settings page; folders hardcoded; record binds never pass audio; `Print` and `Alt+Shift+S` duplicate | §7 |
| F12 | Launcher never opens at the pointer (no "pointer" placement); Clipboard stays 540 px tall when empty | ui-surfaces |
| F13 | Dead or controlless keys: `startup.apps` (legacy), `apps.terminal`, `launcher.columns`; `StatusGlyph.qml` unused; personal defaults ship to everyone (Belgrade, RS, Chrome/VS Code pins) | §1 |
| F14 | Wording leaks internals ("CPU temperature in Power mode"), page names differ from groups (Screens/Displays) | §1b |

Not problems (keep): token discipline is good (7 stray hex values), the app stack is complete (Nautilus,
File Roller, Loupe, Papers, hyprpolkitagent, both portals, udiskie, gvfs, Satty, wtype), clipboard already stores
images and pastes into the active app, the dGPU is never woken by polling, power modes already drive asusctl +
PL1/PL2 + fan curves on this laptop, caffeine already uses `systemd-inhibit --what=idle`.

## 2. Decisions

- **Screenshots: keep grim + slurp + Satty; do not install Flameshot.** Flameshot 15 still captures through one
  overlay window sized across all monitors; its docs assume equal resolutions and list fractional scaling as a
  known fault. This laptop runs 1.2 next to a 1.0 monitor. Satty already covers Flameshot's editor (arrows, shapes,
  text, highlight, blur, pixelate, undo/redo, copy, save) and selecting with slurp first has no overlay problem.
  Add a Screenshots page and fix the audio of recordings (wf-recorder stays; it is installed and works on AMD).
- **Three themes, three audiences** (F9). Keep one engine; cut data, not features.
  1. **Pebble: refined and calm** (absorbs Glass). Warm frosted surfaces, soft depth, generous spacing, a serif
     display face for the clock and big numbers, one quiet accent. Light and dark. New default for new installs.
  2. **Poster: expressive and colourful** (absorbs Atlas). Neo-brutalist paper and ink, three primaries used as
     state colours, heavy type, hard offset shadows, slam motion.
  3. **Monolith: immersive terminal** (absorbs Console and Reactor). tmux-style status line, mono type, an acid
     accent, frames instead of shadows, instant motion. The owner's current theme: unchanged identity, polished.
  Migration: `reactor`, `console` → `monolith`; `glass` → `pebble`; `atlas` → `poster`, applied to the active
  theme, user themes' `base`, and per-theme adjustments (moved when the target has none, else dropped).
- **Bar layout: one user layout** (F8). Theme gives the default items; once you edit, `bar.layout`
  ({start, center, end}) is yours and survives theme switches (the brief: layouts stay consistent across themes).
  Presets become buttons that copy a starting layout into `bar.layout`. Per-monitor layouts stay. Migration takes
  the active theme's `barItems` (or the selected preset) into `bar.layout`.
- **One popup framework** (F1–F5). `CursorPopup` stays the one positioning path (side of trigger, clamp to the
  screen, cap to the room between bar and dock, theme depth/decor/motion). Add: focus on open so Escape always
  closes; one `PanelScroll` (flickable + fade cue + scrollbar) every panel body uses; one `MenuList`/`MenuRow`
  with arrow-key navigation for the five menus; one `Overlay` for the four full-screen panels; `TrayMenu` and
  `Dropdown` take the theme's depth. Each panel keeps its own layout; only the frame and behaviour are shared.
- **Small flyouts reuse Control Center modules** (F5): volume, network, Bluetooth, brightness, battery/power and
  media items open a `CursorPopup` showing that one CC module, so there is one implementation per topic.
- **Power flyout**: battery, charge state, draw (W), time left only when discharging, Silent/Balanced/Performance
  (labels; asusctl keeps its `quiet` id), CPU temperature, fan RPM where hwmon has it, caffeine toggle.
- **Weather**: `weather.locations` (list of {name, lat, lon, country}), `weather.current` (index); Settings to
  search, add, rename, reorder, remove, set default; panel switches location with chips; fields, hours, days,
  refresh are settings; loading / stale / offline / no-location states. Open-Meteo (no key, attribution line).
- **System monitor**: one `metrics` script, one `Metrics.qml`; add per-core %, frequency, load averages, swap,
  disk read/write, iGPU memory as VRAM + GTT, dGPU state (sleeping is shown as such, never woken), interval that
  follows the fastest live reader up and down. Panel: CPU, memory, GPU(s), storage, network, top processes.
- **Rainbow border**: `windows.border` style `accent | gradient | rainbow`, rainbow speed, "animate on battery"
  (default off: a static rainbow on battery, because the `loop` style redraws every frame).
- **Launcher at the pointer**: Settings → Launcher position: At the pointer (default) / Theme's place. Clipboard
  height follows its content.
- **No new dependencies.** Nothing to install for this round.

## 3. Phases and order

| Phase | Work | Files (owner) | Depends on |
|---|---|---|---|
| P0 | Config keys + validation + migrations for everything below | `ConfigData.qml`, `Config.qml`, `migrations/` (lead) | – |
| P1a | Popup framework: focus/Escape, `PanelScroll`, `MenuList`, `Overlay`, TrayMenu/Dropdown depth, Calendar overflow, Clipboard height, launcher pointer placement | `CursorPopup`, `Dropdown`, `TrayMenu`, `UtilityMenu`, `WindowMenu`, `DockMenu`, `Keyboard`, `PowerMenu`, `Cheatsheet`, `Welcome`, `MissionControl`, `Calendar`, `Clipboard*`, `Launcher*` (agent A) | P0 |
| P1b | Metrics service + system panel | `metrics`, `Metrics.qml`, `Sensors.qml`, `bar/items/{cpu,gpu,memory,sysinfo}`, `tests/metrics.sh` (agent B) | P0 |
| P1c | Weather service, panel, Settings page | `Weather.qml`, `SettingsPageWeather.qml`, `bar/items/weather`, `NightLight.qml` coords (agent C) | P0 |
| P2a | Flyouts from CC modules + power flyout | `bar/items/{volume,network,bluetooth,brightness,battery,power-profile,media}`, `ControlCenter*` (agent A after P1a) | P1a |
| P2b | Rainbow border, Screenshots page, record audio, bind dedupe | `ThemeSync.qml`, `look.lua`, `animations.lua`, `binds.lua`, `screenshot`, `record`, new `SettingsPageCapture.qml` (agent B after P1b) | P0 |
| P2c | Bar layout model + editor target clarity, Dock menu keyboard | `Themes.qml` (layout part), `Theme.qml`, `BarEditor.qml`, `SettingsPageBar.qml`, `SettingsBarLayout.qml`, `DockMenu.qml` (agent C after P1c) | P0 |
| P3 | Three themes: data, fonts, wallpapers, previews, docs, migration | `themes/`, `config/fonts`, `ThemePreview.qml`, `docs/DESIGN.md`, `docs/THEMES.md` (lead) | P1a |
| P4 | Settings app: navigation, grouping, wording, missing rows, dead keys | `SettingsApp.qml`, `SettingsPage*.qml` not owned above (lead) | P2 |
| P5 | Visual QA all three themes × light/dark, every panel; independent visual review; fixes | lead + reviewer | P3, P4 |
| P6 | Tests (`tests/all.sh`), docs, merge to main (= live desktop), live check | lead | P5 |

Simplification targets: delete `StatusGlyph.qml`, four theme folders, `bar.preset` live link, the five menu-row
copies, the four overlay copies, `Choice`/`ControlCenterSegmented` duplicate, legacy `startup.apps`.

## 4. Risks

- Merging to `main` changes the owner's running desktop at once (stow). Everything is proven in `tests/nested.sh`
  first; migrations run on `./install.sh update`, and `rollback` exists.
- Theme cut removes looks someone may use (owner: Monolith, kept). Migration maps every old id.
- Bar layout change could lose a custom layout: the migration copies, never drops; covered by a round-trip test.
- Rainbow loop costs battery: off on battery by default, static gradient instead.
- asusd vs power-profiles-daemon fight: the current code already uses asusctl first; unchanged.
- Agents editing shared files: P0 lands all config keys first so agents never touch `ConfigData.qml`/`Config.qml`.

## 5. Acceptance (each checked in the test desktop, then on the live desktop after merge)

- Every panel closes on Escape and outside click, opens on its trigger's monitor, never past a screen edge,
  scrolls with a visible cue when content is taller than the room. Menus work with arrow keys + Enter.
- Weather: add 3 locations, rename, reorder, remove, set default, switch in the panel; restart keeps them;
  offline shows "Couldn't update · last at HH:mm".
- Metrics: values match `/proc/stat`, `free`, `df`, `/proc/net/dev` within one interval; no time-left on AC; no
  false GPU-memory warning; NVIDIA stays `suspended` while idle.
- Bar: add/remove/reorder/move between sections, preset as start point, reset; survives restart and theme switch.
- Themes: three, each light and dark, pass `tests/contrast`; switching restyles shell, borders, GTK, Ghostty, lock.
- Border: accent / gradient / rainbow apply live; rainbow stops looping on battery when set so.
- Screenshots: region, window, screen, annotate, copy, save to the chosen folder; recording with chosen audio.
- `tests/all.sh` green; `tests/performance.sh` idle CPU and memory not worse than 0.37 % / 299 MB.
