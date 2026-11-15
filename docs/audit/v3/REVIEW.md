# Independent review of PLAN.md (2026-11-15)

**Verdict: the direction is right but the plan is not ready to run.** 9 must-fix items: two would break the owner's
live desktop at merge, one keeps the dGPU awake, three are parallel-edit conflicts or hidden coupling, and three are
parts of the brief the plan leaves out (Dock redesign, multi-monitor, theme personality beyond colour).
Checked in code and on this machine. `Q/` = `config/quickshell/.config/quickshell/`.

## Must-fix

1. **[must-fix] Merging to main breaks the live shell before `install.sh update` runs.** `~/.config/quickshell` is
   linked one file at a time (checked), and Quickshell reloads when a file changes. New files (`PanelScroll`,
   `MenuList`, `Overlay`, `SettingsPageCapture`) have no link until stow runs again, so the reloaded shell refers to
   types it can't find. Removed themes leave broken links in `~/.local/share/hyprism/themes/<id>/`.
   *Change P6:* stop `qs` → merge → `./install.sh update` (links + migrations) → start `qs`. Add a migration that
   removes broken links and empty theme folders. Run the final nested test from a fresh stow, not the worktree.
2. **[must-fix] Theme renames already chain to themes that are being removed.** `Config.qml` `renamedThemes` maps
   `workstation/canvas/zen → glass`, `noir → console`, `mist → atlas`. `checkTheme()` applies the map once, so a
   saved `mist` would become `atlas`, which will no longer exist.
   *Change P0:* map every old id straight to its final theme. Put the theme-cut migration in `Config.repair()`
   (QML, runs on reload), not in `migrations/*.sh`; it also fixes `userThemes[].base`. Merge `appearance.custom` key
   by key (the target's keys win) instead of "move or drop". Drop orphans: the live file has `custom.mist`.
3. **[must-fix] The new flyouts never reach the owner's bar.** The live Monolith bar uses `status`
   (`custom.monolith.barItems.end`), and `BarStatus.qml:17` opens the whole Control Center. P2a covers only the
   separate volume/network/bluetooth/battery items. *Change P2a:* each icon in `status` opens its own flyout (a click
   target per icon). Check acceptance with the owner's layout.
4. **[must-fix] Control Center modules can't be reused as they stand.** They read the `ControlCenter` singleton
   directly: `ControlCenterSliders` 37 times (`.sink` ×14, `.expanded`, `.shownSections`), `Connections` 35 times
   (`.adapter` ×18, `.shownTiles`), and `ControlCenterPower` calls `ControlCenter.hide`. Inside a flyout, a section
   hidden in Control Center settings would also vanish, expanding Wi-Fi would expand it in Control Center too, and
   "close" would close the wrong panel. *Change P2a:* first move that state (sink/source/streams, adapter/wifi,
   player, expanded) into services or properties. Each module gets a `host` property (the panel it sits in). Add P1b
   as a dependency of P2a, because the power flyout shows battery watts.
5. **[must-fix] `nvidia-smi` polling keeps the dGPU awake once it has woken.** "Never woken by polling" holds while
   it is suspended. But `metrics:109` calls `nvidia-smi` every tick whenever `runtime_status` is `active`, so any
   brief wake (a browser probing Vulkan, `nv`) followed by a 2 s poll keeps resetting the idle timer
   (`autosuspend_delay_ms` gives an I/O error, so the driver controls it). The owner's bar shows `sysinfo` all the
   time. *Change P1b:* bar items read `runtime_status` only. Call `nvidia-smi` only while the System panel is open,
   at most every 10 s. *Acceptance:* with the gpu/sysinfo item shown, run `nv glxgears` for 5 s, close it, and check
   the dGPU is `suspended` again within 30 s.
6. **[must-fix] Two agents edit the same files.** `DockMenu` is in both P1a (agent A) and P2c (agent C). P1a says
   "every panel body uses `PanelScroll`" while B and C rewrite `Sensors.qml` and `Weather.qml` at the same time, and
   `NotificationCenter.qml` has no owner. `ThemeSync.qml` is in P2b, but P3 needs it too (the Ghostty font rule
   hardcodes Martian Mono, which leaves with Console). `Theme.qml`/`Themes.qml` are in P2c, but P3 needs tokens there
   (item 9). New pages need registering in `SettingsApp.qml`, which belongs to P4.
   *Change:* build the scroll body into `CursorPopup`, so no panel file needs editing; B and C delete their own
   clipping code. `DockMenu` goes to C only. `ThemeSync`, `Theme.qml` and `Themes.qml` go to the lead (P3); P2b sends
   its rainbow changes as a patch. P0 registers every new Settings page (as a stub) in `SettingsApp.qml`.
7. **[must-fix] The Dock redesign is missing.** The brief asks for it; the plan only gives the Dock menu keyboard
   support. Now: the Dock is pointer-only (`DockApp.qml` has no tab focus); its menu closes only on a 1.5 s leave
   timer; previews work on hover only; its widgets repeat bar items; the `apps` bar item and the Dock are two
   implementations of the same list. *Change:* add a Dock phase (agent C after P2c): keyboard access; the menu on
   `MenuList` inside `CursorPopup` (Esc and outside click for free); a shape and hover per theme; a setting to show
   only this screen's windows on each screen; one shared model for the `apps` item and the Dock. Acceptance: the
   same checks as for panels.
8. **[must-fix] Multi-monitor is in the brief but never tested.** The audit says "not checked live: multi-monitor";
   `tests/nested.sh` makes one headless output at scale 1. Toasts and the OSD show only on the focused screen. The
   laptop runs at 1.2 next to a monitor at 1.0. *Change:* `nested.sh` gets a second output
   (`HYPRISM_TEST_SCREENS=2`, scales 1.2 and 1.0). Acceptance on each screen: panels open on the screen that
   triggered them and stay inside its edges at its scale; the launcher opens at the pointer on the second screen;
   bar layouts per screen and the Dock per screen work; you choose where toasts appear (focused screen or primary).
9. **[must-fix] The three themes can't differ beyond colour with this engine.** Spacing is fixed in the engine
   (`Theme.qml:93-98`: `spaceXs…spaceXl` and `rowHeight: 34` are constants). The screenshots show the same launcher
   content and layout in all seven themes. P3 is listed as "data", so density, row shape and selection shape can't
   change. *Change:* split P3. **P3a** (lead, right after P0, before any visual work in P1/P2) adds engine tokens:
   `density` (compact/regular/roomy, scales space* and rowHeight), `row` (pill/plate/line), `tile`
   (round/square/none), and the display face for numbers. **P3b** fills in the data. The plan gets a table for the
   three themes: density, material, depth, motion curve, launcher style, row shape, bar voice, dock shape,
   wallpaper, lock. Every column must differ between themes.

## Should

10. **[should] The branch is broken right now (HEAD `12ac53f`).** `Weather.qml:14-16,162,199` reads
    `c.city/latitude/longitude/showHourly/showDetails`, which were removed; `SettingsPageWeather.qml:37` calls
    `Config.set("weather","latitude")`; `SettingsPageDisplays.qml:383` shows `Config.weather.city`. Rule: every phase
    commit leaves the shell working (A and B will run nested tests before P1c lands).
11. **[should] Battery time-left: the plan and the audit disagree on the cause.** PLAN F7 says "when not
    discharging"; the audit says "discharging, power_now 15000". `m_battery` already estimates only while
    `Charging`/`Discharging`, and right now the battery reads `Not charging` with `power_now=0`. Root cause before
    the fix: sample `power_now` for 2 min after unplugging. Then: no estimate below 1 W, average over about 30 s.
12. **[should] Don't show the iGPU's shared memory (GTT) as "VRAM + GTT".** GTT is system RAM the RAM figure already
    counts, and its 8 GB limit is an allowance, not a capacity. Show "graphics memory used (shared)" with no
    percentage and no warning. Keep warnings for the dGPU's real VRAM only.
13. **[should] The performance check misses the owner's case.** `tests/performance.sh` has `MAX_WATCH=0` because the
    default bar starts no `metrics watch`; the owner's bar always runs one (`sysinfo`, `status`). Add a run with
    Monolith and the owner's layout, and one with the rainbow border on. Fork less: `df` every 30 s, not every tick.
14. **[should] Rainbow border.** `animations.lua:58` turns every animation off when motion is `off`, which also stops
    the loop, and the plan doesn't say what `reduced` does. Animate only when motion is Full and the power mode isn't
    Silent; otherwise show a still rainbow. The loop makes Hyprland draw a frame on every refresh, which stops the
    panel's self-refresh: measure the cost on AC too and put it in the setting's hint. State what the accent
    override does when the style is rainbow.
15. **[should] `capture.audio: "both"` can't work as is.** wf-recorder takes one audio device. Drop "both", or mix
    the two through a PipeWire null sink with `pactl` (no new package). Decide in the plan.
16. **[should] Screenshots: agree with Satty, but the plan doesn't reach "better than Flameshot" yet.** Freeze the
    screen while selecting (`hyprpicker -r -z`, already installed) so menus and tooltips stay. One selection mode:
    drag an area or click a window (slurp gets window boxes from `hyprctl clients`). A small capture bar in a
    `CursorPopup`: area/window/screen, delay, record, audio. That is the part Flameshot users miss.
17. **[should] Weather: drop `weather.current`.** It is an index (reordering or removing a place moves it) and view
    state saved in settings; Night Light already uses the first place. Rule: the first place is the default for the
    bar and Night Light; the panel's place chips only change the panel and aren't saved. Cache the last result in
    `~/.cache` so a restart or being offline shows stale data, marked. Fetch all places in one request (Open-Meteo
    accepts lists of coordinates).
18. **[should] "Launcher at the pointer" does nothing on the owner's desktop.** Monolith's launcher is a strip
    (`placement: "strip"`), and strips ignore the anchor. Decide per style which placements honour "pointer", and
    say so in Settings.
19. **[should] The bar model is half global.** Items become global, but edge, size, floating and the Dock's place
    stay per theme in `appearance.custom`. Switching from a theme with `apps` in the bar to one with a bottom Dock
    shows the app list twice. And `bar.monitors` points to presets by name while presets stop being live.
    *Change:* after the first edit, the whole geometry (items, edge, size, floating, Dock place) is global; the theme
    gallery offers "Use this theme's starting layout"; per-screen layouts store their own `{start,center,end}`.
20. **[should] Notifications are left out.** Cards can't be reached by keyboard. History is lost on every shell
    reload, the merge included (`Notifications.qml:12`): keep it in `~/.local/state`. Toasts show only on the
    focused screen.
21. **[should] P4 (Settings) is the core of the brief but gets one vague line, last, from a lead who also does P3, P5
    and P6.** Write the target navigation as a list in the plan (34 pages in 13 groups now; merge Window
    Behaviour + Look; move the OSD out of Notifications; caffeine on Power). Add a static test to `tests/lint.sh`:
    every `ConfigData` key has a control and a consumer, or is listed as state. Add a nested run that opens every
    page and checks there are no QML warnings. The audit's control map came from grep, not from clicking.
22. **[should] Pebble as the "elegant" theme is a new theme under an old id.** Its identity is playful (coral and
    mint, spring overshoot, pills, Outfit). As the default on laptops it would use glass blur everywhere, and in
    `pebble-dark.webp` the launcher overlaps the Dock. Spec: neutral warm greys, one muted accent and no accent2,
    ease-out with no overshoot, hairline rims, roomy density, a bundled OFL serif display face, blur on popups only
    and none on battery. Fix the overlap with the Dock.
23. **[should] Monolith as "experimental/immersive" is today's theme, polished.** It takes nothing from Console or
    Reactor, so the third personality is under-designed. Keep the owner's identity and add opt-in parts: Console's
    HUD brackets as decor, an edge-to-edge launcher, an accent that follows the wallpaper, the rainbow border on AC
    by default.
24. **[should] Agent A carries the critical path:** P1a (about 16 files, 4 overlays, 5 menus), then P2a, while B and C
    finish early. Move launcher pointer placement and the Clipboard height to agent C. Leave `MissionControl`
    (433 lines, drag/snap) off the shared `Overlay`: give it only the same Esc and outside-click behaviour.

## Consider

25. **[consider]** Cut the Theme Builder, `userThemes` and "Save as a theme". The live `userThemes` is `[]`, and they
    are a profile-like system that works against "at most three themes". Keep only Adjust.
26. **[consider]** Cut what multiplies the test matrix: launcher styles from 6 to 3 (one per theme); the Control
    Center `borderless` style (the dead ternary in `ControlCenterTile.qml:9`); user-saved bar presets (the four
    built-in starting layouts are enough).
27. **[consider]** Move state out of `settings.json` into `~/.local/state/hyprism/`: `caffeine.*`,
    `launcher.usage/recent`, `system.welcomed`, `controlCenter.slidersOpen`. Hand edits stop fighting the shell's
    writes.
28. **[consider]** P3 "restyles … lock" leaves out the login screen: the new greetd module isn't themed (THEMES.md
    "Still to do"). Add it or record that it is left out.
29. **[consider]** Agree that `TrayMenu`/`Dropdown` stay `PopupWindow`s: the Settings window is a normal app window, so
    its menus can't use a full-screen layer. Spell out that they share one look-and-motion frame and `MenuList` with
    `CursorPopup`: two transports, one design.

**Agree (no change):** Satty over Flameshot (cross-monitor overlay, fractional scale); `CursorPopup` as the one placement path, with Escape
fixed at the window root; settings migrations in `Config.repair()`; no new packages; Silent/Balanced/Performance on
asusctl; caffeine through `systemd-inhibit`.
