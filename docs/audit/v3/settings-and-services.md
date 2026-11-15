# Audit v3: Settings app, config flow and backing services

Facts only. Branch `desktop-v3`. Paths relative to the worktree; `Q/` = `config/quickshell/.config/quickshell/`,
`H/` = `config/hypr/.config/hypr/`, `S/` = `config/scripts/.local/bin/`. Run on the real machine (ROG Flow X13 GV301QC).

## 0. Config flow in one view

- `Q/ConfigData.qml` (181 keys in 27 sections, defaults) -> `Q/Config.qml` (load/save `~/.config/quickshell/settings.json`,
  `schema` validation at `Config.qml:48-115`, `set()` at `:130`, IPC `qs ipc call config set|get|reset`, `repair()` on every load).
- Settings pages bind with `ConfigToggle/ConfigChoice/ConfigSlider` (`section`+`key`) or `Config.set(...)`. Edits apply live (bindings).
- Hyprland-side keys are written to files by two writers: `Q/SettingsSync.qml` (idle, input, displays, workspaces, apps, monitorShare)
  and `Q/ThemeSync.qml` (theme.lua, windows.lua, keybinds.lua, hyprlock, GTK, Qt, Ghostty, btop, starship, fuzzel).
- Script-side readers read settings.json directly with `jq`: `S/clipstore:20-60` (clipboard.*), `S/startup-apps`.
- The user's current settings.json has no unknown keys or sections (checked).

## 1. Settings pages and controls

34 pages in 13 groups (`Q/SettingsApp.qml:30-44`, pages `:49-88`). Search words per page in `allSections`. Every `Config` key has a
control except those marked "state". Every key has a consumer (checked by grep; generic readers noted). "Live" = binding or `hyprctl eval`;
"reload" = needs `hyprctl reload` (the app triggers it).

| Page (group) | Controls -> key | Consumer | Applies | Notes |
|---|---|---|---|---|
| Themes (Appearance) `SettingsPageAppearance.qml` | mode, theme gallery, Adjust sliders (accent, accent2, radius, gapsIn, gapsOut, border, size, font, motion, shadow, blur), wallpaper, terminal, fontScale, motion | `Themes.qml` resolve, `Theme.qml`, `ThemeSync.qml` | live | Adjust writes `appearance.custom[theme]` (`Themes.qml:125-144`). Two "motion" controls (Adjust `motion` = Hyprland preset, `appearance.motion` = full/reduced/off). Two sizes: Adjust `size` px and `fontScale` %. |
| Theme Builder `...Builder.qml` | userThemes | `Themes.qml` | live | Third way to store theme changes (userThemes) besides custom and theme.json |
| Wallpaper | folders, selected, blur, slideshow, interval, source, order, `appearance.wallpaperColours` | `Wallpapers.qml`, `WallpaperColours.qml` | live | `wallpaper.*` is read from the Appearance section for one toggle. `wallpaperColours` rewrites `appearance.custom` accents (`THEMES.md`). |
| Icons | iconTheme, monoTray | `ThemeSync.qml` (gsettings), `BarTray.qml` | live | `Papirus-Dark` auto swapped to `Papirus-Light` in light mode (hardcoded, `ThemeSync.qml:24`) |
| Cursor | cursorTheme, cursorSize | `ThemeSync.qml` (`gsettings`, `hyprctl setcursor`, `theme.lua`) | live; env at next login | |
| Menu Bar | barEdge, barSize, barFloating (per theme via `ThemeChoice`), `bar.margin`, battery %, clock24, seconds, date, windowTitle, preset, Save layout, per-screen preset, item editor | `Theme.qml:104-135`, `Bar*.qml`, `Sys.qml`, `BarItems.qml` | live | See section 8. `bar.clock24` also drives `LockScreen.qml`. |
| Dock | enabled, position (`ThemeChoice dock`), size, per-screen on/off, barLabels, mark, markSide, iconSize, autoHide, combine, previews, showRunning, thumbnails, thumbRefresh, widgets, pinned | `Dock*.qml`, `Theme.qml:137-157`, `bar/items/apps/Item.qml` | live | All consumed. size/per-screen hidden when dock is in the bar. |
| Lock Screen | clock, position, date, greeting, avatar, widgets, wallpaper, blur, brightness | `LockScreen.qml:12`, `ThemeSync.qml:35` writes `hyprlock-theme.conf` | on next lock | Preview in `LockPreview.qml` |
| Control Center | style, width, showHardware, sections/tiles/toggles/shortcuts order, hidden | `ControlCenter*.qml` (generic `Config.controlCenter[group]`) | live | `slidersOpen`: state, no control (`ControlCenterSliders.qml`) |
| Notifications | dnd, timeoutSec, sound, volume, mutedApps, historyMax, **OSD**: volume, brightness, micMute, layout, capsLock, position, timeoutMs | `Notifications.qml`, `Osd.qml:20-101` | live | OSD settings live on the Notifications page. |
| Search & Launcher | style, startView, clipboardInside, order, webSearch, showFiles, actions, usage (Forget) | `Launcher.qml`, `Search.qml` | live | `columns`, `recent`: no control (columns has none; recent is state) |
| Clipboard | paused, maxItems, maxAgeDays, images, skipSensitive, autoPaste | `S/clipstore:34-60` (jq), `Clipboard.qml` | next copy | No QML consumer for maxItems/maxAgeDays/images/skipSensitive: only the script reads them. |
| Weather | city search, days, showHourly, showDetails, units | `Weather.qml` | live | Section 2 |
| Calendar | holidays, country, localNames, observances, moon, firstDay, weekNumbers | `Calendar.qml:15` | live | |
| Hot Corners | 4 corners | `HotCorners.qml:14-35` | live | |
| Window Behaviour | layout, newSplit, smartSplit, masterNew, masterSide, columnWidth, followMouse, focusOnActivate, warpCursor, backAndForth, resizeOnBorder, snap, hideCursorTyping | `ThemeSync.qml:231-241` -> `settings/windows.lua` -> `H/modules/windows.lua` | live (`apply_windows()`) | Defaults duplicated in `H/modules/windows.lua:7` |
| Window Look | titleBars, inactiveOpacity, dimInactive, dimStrength | same | live | Also "window frame" in Themes Adjust: border settings split over two pages. |
| App Rules | windows.apps | `ThemeSync.qml:234` | live | |
| Screens (Displays) | per-output layout, vrr, autoHdr, sendContentType, xwaylandNativeScale, preferHighRefresh, newScreen, **Night Light** (mode, temperature, from, to) | `SettingsSync.qml`, `NightLight.qml` | live | Night Light sits on Screens; its "sun" mode uses `weather.latitude/longitude`. |
| Workspaces | mode, count, screens | `SettingsSync.qml:100` | **reload** (`hyprctl reload`) | |
| Shared Monitor | monitorShare.* | `SettingsSync.qml:84` -> `monswitch.conf` | live | DDC/KVM; very niche; hidden jargon "VCP 0x60" in ConfigData |
| Keyboard & Touchpad | layouts, shortcut, repeatRate, repeatDelay, sensitivity, naturalScroll, tapToClick, disableWhileTyping, clickMethod, scrollFactor, middleEmulation, dragLock | `SettingsSync.qml:44-55` -> `input.lua` | live (`apply_input()`) | |
| Keyboard Shortcuts | keybinds.overrides | `ThemeSync.qml:196-212` -> `keybinds.lua` | **reload** | Base binds in `H/modules/binds.lua` |
| Sound / Wi-Fi / Bluetooth | no Config keys | PipeWire / NetworkManager / BlueZ | live | |
| Battery & Power | warn, warnAt, criticalAt, power mode, lid (read-only) | `BatteryWarning.qml:16`, `PowerMode.qml` | live | Section 4 |
| Lock & Sleep | idle.lockMin, sleepMin, sleepOnPowerMin, Lock now, **caffeine.defaultMinutes** | `SettingsSync.qml:35-45` -> `hypridle.conf` (hypridle restarted), `Caffeine.qml` | live | Caffeine default lives here; no mention on the Power page. |
| ASUS Hardware | fan curve editor, mode | `asusfan` + `asusctl` | live | Only with `Machine.asus`. 2 s sampler while visible (`SettingsPageAsus.qml:61`). |
| Installed Apps / Default Apps / Startup Apps | system.taskManager, startup (autostart folder) | `Sensors.qml`, `S/startup-apps` | live | `startup.apps` in settings.json is legacy: migrated into `~/.config/autostart` and cleared (`SettingsPageStartup.qml:46`, `S/startup-apps:12`). Dead key. |
| Language & Region | languages, formats | writes `hypr/settings/language.lua` (`SettingsPageLanguage.qml:49`) | next login | Needs `sudo locale-gen` for missing locales (page prints the command). |
| About | none | | | |

Control mapping was done by grep and spot checks, not by clicking: a few more keys may lack a control.

State stored as settings (not preferences): `caffeine.on/minutes/endsAt`, `launcher.usage/recent`, `system.welcomed`,
`controlCenter.slidersOpen`, `idle|input|displays|monitorShare.imported` flags. These are written to the same file the user hand-edits.

### 1a. Duplicate or competing sources of truth

| Thing | Where it can be set | Winner / issue |
|---|---|---|
| Bar items | `theme.json bar.start/center/end`, `appearance.custom[theme].barItems`, `bar.presets`, `bar.preset`, `bar.monitors` | `Theme.qml:118-130`: a named preset (per screen, then global) wins; else theme + `barItems`. The editor writes to whichever is active (`BarEditor.qml:36-40`). Four layers. |
| Dock place | `theme.json dock.edge`, `custom.dock`, `dock.enabled`, `dock.hiddenOn` | `Theme.dockMode` (`Theme.qml:136`) |
| Window border colour | `theme.json hypr.active/inactive` (and `alt.hypr`), `custom.accent` (overwrites first border stop, `Themes.qml:205-210`), `wallpaperColours` (writes custom accent), `look.lua` defaults | No direct border-colour control; only via accent. |
| Gaps / border / rounding / shadow / blur | `theme.json hypr.*`, `custom.*`, `H/modules/look.lua:9` defaults, `look.lua` fixed blur params | look.lua comment says defaults are "Pebble's" (`look.lua:2`) but they are Reactor's. |
| Window behaviour defaults | `ConfigData.windows`, `H/modules/windows.lua:7` | Duplicated by design (comment in ConfigData). |
| Motion | `appearance.motion` (full/reduced/off), theme `motion` preset, Adjust `motion`, `hypr.motion` | `ThemeSync.qml:80` maps level to Hyprland preset. |
| Wallpaper | `appearance.wallpaper` (theme's own), `wallpaper.current`, `lockscreen.wallpaper`, `hypr/settings/wallpaper` | 3 places, 2 pages. |
| Terminal command | `apps.terminal` (no control on any page) vs `binds.lua` `terminal` var | `SettingsSync.writeApps`; key has no UI. |
| Screenshot/record/launcher binds | `binds.lua` + `keybinds.overrides` | Two bindings for the same action: `ALT+SHIFT+S` and `Print` both "Screenshot an area (editor)" (`binds.lua:83-84`). |
| Clock/weather | bar items vs dock widgets (`dock.widgets`) | Same data shown by two UIs, set on two pages. |
| Night Light location | `weather.latitude/longitude` | Not shown on the Night Light control; changing weather city changes sunset time. Appearance "Auto" mode referenced in `NightLight.qml:25` comment is not in `ConfigData.appearance.mode` (theme|light|dark). |
| Battery % | `bar.batteryPercent` and `battery.warn*` on different pages | |

"Profile"-like systems: power mode quiet/balanced/performance (`PowerMode.qml`), bar `presets` (name -> layout),
per-theme `appearance.custom`, `userThemes`. No general settings profile (no save/load/switch of whole settings sets).
`ResetGroup.qml` resets one section; `desktop-reset` script exists.

### 1b. Confusing wording / jargon (examples)

- Control Center: "CPU temperature in Power mode" for `showHardware` (`SettingsPageControlcenter.qml:162`).
- "Desktop shortcut goes back" (`windows.backAndForth`), "Let apps bring themselves forward", "Colours from the wallpaper".
- Page names differ from group names: group "Displays" / page "Screens"; group "Apps" id `applications`; "Search & Launcher" vs "Spotlight" in binds; "Window Behaviour" vs "Window Look"; Power group holds "Lock & Sleep".
- Menu Bar "Position/Size/Shape" are per theme ("Default" = theme) but "Gap" (`bar.margin`) is global.
- Dock "Spacing" (`size`) and "Icon size" are separate sliders.
- Power page hint "Plugging in picks Balanced, unplugging picks Quiet" is static text (true only after the quirk-flow-x13 step, `SettingsPagePower.qml:92`).
- Lid page says "Set when installing (./install.sh --only session changes it)": read-only info page with a terminal hint.

### 1c. Hardcoded values that could be settings

| Value | Place |
|---|---|
| Weather refresh 15 min; 12-hour strip (`forecast_hours=12`); popup width 340 | `Weather.qml:73,57`, `CursorPopup boxWidth` |
| Ghostty font: only "Martian Mono" else "JetBrainsMono Nerd Font"; `background-opacity` 0.86 for glass themes | `ThemeSync.qml:58-60` |
| GTK theme `adw-gtk3[-dark]`, fonts size 11 | `ThemeSync.qml:146-149` |
| Idle: 30 s dim before lock, 30 s lock to screens off, dim to 30% brightness | `SettingsSync.qml:21-28` |
| Metrics: sparkline 24 points, warn/critical per registry entry (item `warn`/`critical` can override), 5 s process list | `Metrics.qml:22`, `Sensors.qml:66` |
| OSD caps-lock poll 500 ms | `Osd.qml` / ConfigData comment |
| Screenshot dir `~/Pictures/Screenshots`, 5 s delay, recording dir/codec | `S/screenshot:22`, `S/record:13` |
| Personal defaults shipped to all: city Belgrade, country RS, dock pins (`google-chrome`, VS Code), wallpaper folder | `ConfigData.qml` |
| Blur size/passes/noise/vibrancy, `rounding_power 2.4` | `H/modules/look.lua:55-70` |
| Satty palette and tools | `config/satty/.config/satty/config.toml` (not Settings) |

## 2. Weather

| Aspect | Fact |
|---|---|
| Source | Open-Meteo forecast API, no key (`Weather.qml:53-62`), `curl -sf --max-time 10` |
| Location | One place: `weather.city/latitude/longitude`. Set on Weather page by typing a city and Enter; Open-Meteo geocoding (6 results, `SettingsPageWeather.qml:15`). No GPS/IP location, no multiple places. Default Belgrade. |
| Units | celsius (km/h) or fahrenheit (mph) via API params (`Weather.qml:60`). The bar shows `°` only. |
| Forecast | `weather.days` 3,5,7,10,14 in UI (schema 1-16); hourly strip fixed 12 h; details: feels like, humidity, wind, UV, sunrise/sunset |
| Refresh | every 15 min, on open if older than 10 min, 200 ms after location/days/units change (`:63-74,115`) |
| Errors | `catch (e) {}` (`:95`): a failed fetch keeps old data silently; footer still says "Updated HH:mm" of the last success. Empty state is "Loading…" forever if the first fetch fails. No offline/stale marker. Location search shows "Couldn't reach the weather service". |
| Dropdown | `CursorPopup` under the bar item (`click` = toggle): city, temp, condition, H/L; details grid; 12 h strip; per-day rows with min/max bar and rain % (>=20); footer "Updated ... Open-Meteo". Day names use `Qt.locale("en_GB")` (not the Language setting). |
| Bar item | `bar/items/weather` (`shown: Weather.ready`); also a dock widget `weather`. |

## 3. System metrics

Pipeline: `S/metrics watch NAMES SECS` (bash, one process) -> `Q/Metrics.qml` (singleton; `want/unwant` ref-counted; restarts
the process when the source list changes, `:37-45`) -> bar items (`BarMetric.qml:17`), dock widgets (`DockWidget.qml:367,381`),
`Sensors.qml` dropdown (`panelIds`, `Metrics.want(ids, 2)` at `Sensors.qml:28`). One shared service; nothing runs for a hidden bar.

| Metric | Source (read by kind, not device name) |
|---|---|
| cpu, cores | `/proc/stat` deltas |
| cpu_temp | hwmon named k10temp/coretemp/zenpower/cpu_thermal `temp1_input` |
| cpu_freq | mean of `scaling_cur_freq` |
| gpu (primary, amdgpu iGPU) | PCI sysfs: `gpu_busy_percent`, `mem_info_vram_*`, hwmon `temp1_input`, `power1_average` |
| dgpu (NVIDIA) | `power/runtime_status` always (does not wake). Only when `active` and vendor nvidia: `nvidia-smi --query-gpu` (`metrics:109`). Suspended: `{"state":"suspended"}` |
| ram, swap | `/proc/meminfo` |
| disk | `df -P` (a fork every tick), diskio `/proc/diskstats`, disk_temp nvme hwmon |
| net | `/proc/net/dev` (excludes lo, docker, veth, tun, wg...), iface from `/proc/net/route` |
| battery | `power_supply` capacity/status/power_now (or current x voltage), minutes from energy_now/power_now |
| fans | all `hwmon*/fan*_input` |
| profile | `/sys/firmware/acpi/platform_profile` |
| uptime, load | `/proc/uptime`, `/proc/loadavg` |

Polling: default 2 s; item `interval` setting (`cpu/gpu/sysinfo defaults.json`); `Metrics.interval` only ever decreases
(`Metrics.qml:31`, `Math.min`; `unwant` never raises it) until restart. Process list: `ps` every 5 s only while the dropdown is open.
No Settings page for metrics; per-item settings (reading picker, warn/critical) live in the Menu Bar item editor (`SettingsBarSysinfo.qml`).

Real output (`metrics once`, this machine, discharging 59 %):
`cpu 4 %, cpu_temp 68.5, cpu_freq 2325, gpu {pct 5, vram_used 467, vram_total 512, temp 58, watts 16}, dgpu {state: suspended},
ram 46 %, swap 2 %, disk [/ 22 %, /boot 8 %], diskio, disk_temp 42.8, net wlan0, battery {pct 59, state discharging, watts 0.0, minutes 32248},
fans [6600, 4000], profile balanced, uptime, load`.

Problems found:
- **Battery watts/minutes wrong.** `power_now` = 15000 (kernel unit is microwatts: reads as 0.015 W; the value looks like mW). `metrics` prints `watts 0.0` and
  `minutes 32248` (537 h). Real draw about 15 W, about 100 min left (energy_now 25.26 Wh). The `battery_power` and `battery_time` readings and the battery tooltip show these (`metrics:219-232`, `Metrics.qml` battery entries). Unit bug is inferred from the numbers, not confirmed with a meter.
- **Graphics memory reading misleading.** `vram_total` 512 MB is only the iGPU carve-out (467/512 = 91 %), over the 90 % `warn` level (`Metrics.qml` `gpu_vram`); GTT/shared memory is not counted.
- dGPU (RTX 3050) handling is safe for waking: runtime status read only; `nvidia-smi` only when already `active`. Risk (not tested): polling `nvidia-smi` every 2 s while active can reset the autosuspend idle timer.
- No missing fields on this machine apart from the above. `dgpu` shows only `state` while asleep (by design).
- No value is faked. Estimates: battery minutes (linear), nothing else. `profile` metric returns value 0 for thresholds (`Metrics.qml` registry).
- `metrics` is a bash loop forking `awk`, `df`, `head` per tick; fine at 2 s, heavier than a daemon.
- `Sensors.cpu/gpu` aliases exist for the Control Center; `Machine.qml:33` separately detects NVIDIA by PCI vendor.

## 4. Power

| Piece | Fact |
|---|---|
| Modes | quiet / balanced / performance (`PowerMode.qml:9`, `S/powermode:16`) |
| ASUS (asusctl present) | `asusctl profile set` (quiet = firmware "LowPower"); mode watched via `gdbus monitor` on `xyz.ljones.Asusd` (`powermode watch`) |
| Other machines | `powerprofilesctl` (power-saver mapped to quiet); modes limited to what ppd lists; UI `PowerProfiles` (UPower service) |
| What a mode controls on this machine | Installed by `modules/quirk-flow-x13/steps/50-power.sh`: per mode PL1/PL2 (quiet 15/65, balanced 25/65, performance 45/80 W), CPU and GPU fan curves (both fans), EPP (4/3/1) via asusd; AC -> balanced, battery -> quiet (`asusctl profile set -a/-b`). ppd kept but told not to write EPP (`--block-driver=amd_pstate`). |
| UI | Control Center power (`ControlCenterPower.qml`), bar item `power-profile`, Battery & Power page, ASUS page (curve editor, 2 s sampler) |
| Caffeine | `systemd-inhibit --what=idle ... tail --pid=$PPID` (`Caffeine.qml:63-70`): hypridle and logind honour it; dies with the shell. Timer + state in `caffeine.*`; restored on shell start. IPC `qs ipc call caffeine toggle|start N|stop|status`. Default length is chosen on Lock & Sleep, not Power. Blocks idle only (not lid, not manual sleep). |
| Battery | UPower for the Power page and bar (percentage, state, health, charge limit via asus); `battery.warn/warnAt/criticalAt` notifications in `BatteryWarning.qml` (choices 10-30 / 3-8 %) |
| Idle | `idle.lockMin`/`sleepMin`/`sleepOnPowerMin` -> hypridle listeners; `S/idle-sleep` picks battery or mains time; hibernate after 60 more minutes where set up |
| Lid | logind config, read-only in Settings |

## 5. Themes

Token flow: `themes/<id>/theme.json` (+ `~/.config/hyprism/themes/<id>`) -> `Themes.qml` (reads folders; `resolve(id, custom, mode)` at `:180`
merges `appearance.custom`, light/dark `alt`, wallpaper colours; `adjustable` list `:125`) -> `Theme.qml` (122 readonly tokens: colours, fonts,
radii, bar/dock geometry, motion level, `fontScale`) -> every component. `ThemeSync.qml` (debounced 300 ms, only after `Config.loaded && Themes.ready`)
pushes to: `settings/theme.lua` + `hyprctl eval apply_theme()` (gaps, border, rounding, shadow, blur, motion), `hyprlock-theme.conf`, gsettings
(color-scheme, adw-gtk3, accent-color by hue, icons, fonts, cursor), `gtk-3.0|4.0/hyprism.css` (imported into gtk.css), `ghostty/theme.conf`
(SIGUSR2 reload), `qt6ct/colors/hyprism.conf`, KDE colour scheme, `btop`, `starship`, `fuzzel`, theme wallpaper (`theme-wallpaper`, recipe `wallpaper.sh`).
Not themed: login screen (greetd/DM, `THEMES.md` "Still to do").

theme.json: 106 leaf keys per theme (Console 107). Top-level parts: name about order dark colour(13) alt font shape bar dock popup motion launcher notify hypr lock term wall.

| Theme | Character |
|---|---|
| Reactor (default) | Acid yellow on near-black, orange second colour, inverse clock, glow; Archivo; radius 10 solid; bar top floating |
| Glass | Liquid glass floating bar, blue-violet window glow; IBM Plex Sans; radius 16 glass |
| Pebble | Soft round floating pills, coral/mint, spring motion; Outfit; radius 18 glass |
| Atlas | Swiss grid, black top strip, red squares; light; Archivo; radius 0 |
| Console | Amber HUD, caps readout, corner brackets, phosphor glow; Martian Mono; radius 0 |
| Monolith | tmux-like status line, lime inverse clock, 1 px gaps; JetBrainsMono Nerd; radius 0 |
| Poster | Loud flat paper bar, hard offset shadows, slam motion; light; Archivo; radius 0 |

Notes:
- Hardcoded colours outside Theme/Themes: `Glass.qml` (2), `LauncherPanel.qml` (1), `PowerMenu.qml` (1), `SettingsPageAppearance.qml` (1), `SettingsPageWallpaper.qml` (2). Components otherwise use tokens.
- Theme preview UI: `ThemePreview.qml` (mini drawing of wallpaper, bar, window, dock per theme) used in the Themes gallery, Theme Builder and Welcome. No live full-desktop preview.
- `Theme.qml:8` comment mentions `.animations` (key is `motion`).
- `ThemeSync.qml:58` ignores a theme's own `font.mono` except Martian Mono; any other mono font in a user theme is dropped for Ghostty.
- `look.lua:55-70` keeps blur size/passes/vibrancy fixed in every theme; theme only toggles blur.
- Contrast tests: `tests/themes.py` (CI).

## 6. Window borders

- Source: `theme.json hypr.active` (list of 8-hex colours) + `hypr.inactive` (+ `alt.hypr` for the other half), `hypr.border` px, `hypr.rounding`.
- Path: `ThemeSync.qml:76` `hyprLua` -> `settings/theme.lua` and live `hyprctl eval "THEME = ...; apply_theme()"` -> `H/modules/look.lua:24-45`:
  `col.active_border = { colors = {rgba...}, angle = 45 }`, inactive a single colour. Any number of stops works (list is mapped, `look.lua:26`).
- Settings control: only Themes > Adjust: accent (replaces the first stop and keeps alpha, `Themes.qml:205`), accent2 (second stop, `:210`), "Window frame" width. No gradient/glow editor.
- Glow: not a Hyprland setting; `shadow` presets (`none/soft/paper/hard`, `look.lua:19-24`) and Hyprland `shadow` colour. Glow themes use the `soft` shadow plus gradient colours.
- **Animated gradient is feasible with the existing mechanism**: `H/modules/animations.lua:62` explicitly sets
  `hl.animation({ leaf = "borderangle", enabled = false, speed = 1, bezier = "linear" })` on every `apply_motion()`. Turning it on needs
  `enabled = true`, `style = "loop"`, a long `speed` and `linear` bezier there, and a multi-stop `THEME.active` list (already supported). It is currently
  unreachable from Settings and conflicts with `motion = off/reduced` (`animations.enabled = name ~= "off"`, `:58`). No new transport is required: add a `hypr.borderAnim`-style field to `hyprLua` and `look.lua`. Static angle is a hard 45.
- Cost not measured (Hyprland redraws borders each frame while the loop runs).

## 7. Screenshot, recording, clipboard, launcher

| Tool | Facts |
|---|---|
| `S/screenshot` (132 lines) | grim + slurp + Satty. Modes: area (default), screen, window, all, delay N, pin (floating always-on-top pin), `--copy` (no editor). Saves `~/Pictures/Screenshots/Screenshot_<date>.png` (XDG pictures dir), `wl-copy` PNG, notification with preview, click opens. Satty config: `config/satty/.config/satty/config.toml` (palette, corner roundness, Inter Bold; tools via letters). No Settings page. |
| `S/record` (94 lines) | wf-recorder, pid file in `$XDG_RUNTIME_DIR/record.pid`, modes screen/area/stop/status, `--audio` (default sink monitor) / `--mic` (exclusive, last wins), GPU encode if available, `~/Videos/Recordings/*.mp4`; tells the shell via `qs ipc call recorder recording` (bar red dot, `bar/items/recording`). The binds never pass `--audio`/`--mic`, so recordings are silent unless run by hand. No Settings page. |
| `S/screentext` | OCR of an area to clipboard |
| `S/clipstore` (160 lines) | `wl-paste --watch clipstore store` from `H/modules/autostart.lua:25`; entries are folders in `~/.local/share/clipboard` (mode 700); list/copy/paste/pin/delete/clear; limits from `Config.clipboard` via `jq`; skips password-manager copies; paste simulates Ctrl+V (Ctrl+Shift+V in terminals). UI: `Clipboard.qml`/`ClipboardView.qml`, also inside Spotlight (`launcher.clipboardInside`). |
| `S/emojipick` | fuzzel-based picker, themed by `fuzzel/theme.ini` |
| `hyprpicker -a` | colour picker |

Keybinds (`H/modules/binds.lua`; all editable in Settings > Keyboard Shortcuts except fixed ones):

| Action | Keys | Line |
|---|---|---|
| Spotlight | tap Super; Super+Space | 37-38 |
| Spotlight files / all apps | Super+Shift+Space / Super+A | 44-45 |
| Clipboard history | Super+V | 42 |
| Emoji | Super+. | 43 |
| Screenshot area (editor) | Alt+Shift+S **and** Print | 83-84 (duplicate) |
| Area copy only / screen / window / both screens / 5 s delay | Ctrl+Print / Shift+Print / Super+Print / Ctrl+Shift+Print / Alt+Print | 85-89 |
| Pin area | Super+Ctrl+S | 90 |
| OCR | Super+Shift+T | 92 |
| Record screen / area | Super+Alt+R / Super+Alt+Shift+R | 93-94 |
| Colour picker | Super+Shift+C | 95 |

Gaps: no screenshot-to-file-only without editor in the keybind set except `--copy`; no recording audio bind; no settings for save folder, format, delay, audio, or editor.

## 8. Menu bar and Dock

- Storage: theme default `theme.json bar` (edge, size, floating, fill, voice, start/center/end) -> overridden per theme by `appearance.custom[theme]`
  (`barEdge`, `barSize`, `barFloating`, `barItems`) -> or by a named preset in `bar.presets` selected by `bar.preset` and per screen by `bar.monitors`
  (`Theme.qml:118`, `barLayoutFor`). Global: `bar.margin`, `bar.hiddenOn`, clock/date/battery/title options, per-item `bar.items.<id>` over `bar/items/<id>/defaults.json`.
- Presets: 4 shipped in `ConfigData.bar.presets` (minimal, full, laptop, external); `repair()` restores missing ones; built-in "Reset", own ones "Delete" (`SettingsBarLayout.qml`). "Save current layout as..." stores the editor lists.
- Items: 25 folders in `bar/items/` (apps, battery, bluetooth, brightness, clock, controls, cpu, date, gpu, keyboard, launcher, media, memory, network, notifications, power, power-profile, recording, status, sysinfo, tray, volume, weather, window, workspaces).
- **Drag and drop exists**: `BarEditor.qml` uses `DragItem`/`DropSpot` (key `baritem`) between start/center/end zones and an unused-items tray, plus a hover x badge; click an item for its settings (`SettingsBarItem.qml`, sysinfo reading picker `SettingsBarSysinfo.qml`). "Apps" item = the dock inside the bar (`BarEditor.qml:56`). Dock pinned apps also drag to reorder (`SettingsPageDock.qml` DropSpot). Control Center tiles use the same mechanism.
- Edits go to the theme's `barItems` unless a preset is selected, in which case the preset is edited (`BarEditor.qml:36-40`, banner text at `:85`): an easy-to-miss mode switch.
- Dock settings, all consumed: enabled, position, size (spacing), iconSize, autoHide, showRunning, combine, previews, thumbnails, thumbRefresh, barLabels (only when in bar), widgets, pinned, per-screen `hiddenOn`, mark/markSide. Dock modes: bottom/left/right/top or "in the bar" (when the edge equals the bar's, `Theme.qml:136`).
- Not working / unclear: no setting found that is unconsumed. `dock.widgets` duplicates bar items (clock/date/weather/media). `dock.autoHide` sets `dockReserves` false (`Theme.qml:156`) so windows overlap.

## Priority findings

1. Battery watts and time-left in `metrics` are wrong on this machine (0.0 W, 32248 min).
2. `gpu_vram` compares against 512 MB carve-out: permanent "!" warning risk.
3. Weather: silent error swallow; one location only; fixed 12 h; no stale/offline state.
4. Four layers decide bar layout; the editor silently switches between theme and preset target.
5. Border colour has no direct control; rainbow loop is disabled in `animations.lua:62` and easy to enable.
6. Dead/legacy keys: `startup.apps`, `apps.terminal` (no UI), `launcher.columns` (no control), state mixed into settings.json (caffeine, usage, recent).
7. Duplicate/ conflicting items: `Print` and `Alt+Shift+S`; wallpaper in three places; Night Light sunrise tied to the Weather city; caffeine default on the Idle page.
8. Screenshot/record have no Settings; record binds have no audio option.
9. Hardcoded: Ghostty font logic, 30 s idle dim, weather refresh/hours, personal defaults (Belgrade, RS, Chrome/VS Code pins).
10. Metrics interval never rises after a fast reader leaves.
