# UI surfaces audit (branch desktop-v3)

Facts only. Static read of `config/quickshell/.config/quickshell/` (194 QML files) plus a live run in the nested
desktop (`HYPRISM_TEST_NAME=audit`, Reactor theme, 1 screen, no real windows). Screenshots:
`/tmp/claude-1000/-home-eduardo--claude-spares-spare-MPHxNc/00c27bad-52c7-456d-a0ce-d1c5d1b2bf21/scratchpad/audit-shots/`.
All paths below are relative to `config/quickshell/.config/quickshell/` unless they start with `config/` or `docs/`.
Not checked live: click-outside, multi-monitor, light themes, a vertical bar, real notifications, real windows
(Mission Control / Window menu / Dock menu were empty).

## How panels open (the framework)

- `CursorPopup.qml` (250 lines) is the one popup framework: full-screen transparent overlay `PanelWindow`
  (`WlrLayer.Overlay`, `keyboardFocus: Exclusive` while open), a click catcher, a `HyprlandFocusGrab` for other
  monitors, and a `box` that animates with Theme motion. 11 users: Clipboard, Calendar, Keyboard, ControlCenter,
  Launcher, NotificationCenter, Sensors, UtilityMenu, Weather, WindowMenu (+ itself).
- Position: `Anchor.qml` records the clicked bar/dock item (valid 500 ms); `place()` puts the box beside it, clamped to the
  screen minus bar/dock reserves (`Theme.reserve*`). From a shortcut: `hyprctl cursorpos/monitors` picks the monitor
  under the pointer, then the panel's own bar item there (`Anchor.find`), else a `placement` (center, top, strip,
  island, cursor...). A fullscreen/strip/half/column placement ignores the anchor.
- Own `PanelWindow`, not CursorPopup: PowerMenu, Cheatsheet, Welcome, MissionControl, Osd, Notifications (toasts),
  HotCorners, Pins, Bar, Dock. `PopupWindow`: Dropdown, TrayMenu, ToolTipText.
- Shortcuts (`config/hypr/.config/hypr/modules/binds.lua:37-110`): tap Super or Super+Space = `launcher toggle`;
  Super+V = `clipboard toggle`; Super+C control center; Super+N notifications; Super+W overview; Super+/ cheatsheet;
  Super+Z window menu; Super+I settings; F6 focus bar. IPC targets: clipboard, launcher, controlcenter, calendar,
  weather, system, notifications, overview, power, cheatsheet, utilitymenu, keyboard, windowmenu, osd, welcome,
  settings, bar, caffeine, nightlight, pins, tablet, recorder, config, themes, wallpapers.
- Launcher: `Launcher.qml:141` toggle/apps/files/search/mode. Opens on the monitor under the pointer. Place comes from
  the style or theme (`Launcher.qml:20-47`): spotlight/terminal = centred (top at max(reserve, 20% of height)),
  command = top strip, launchpad = fullscreen, drawer = above the bottom, sidebar = left column. Not at the pointer
  unless the theme/style says `placement: "cursor"` (none of the 6 styles does). From a bar click it opens beside the item
  (except strip/half/column/fullscreen). Clipboard: `Clipboard.qml:66-71`, 400x540 (capped by `maxHeight`), default
  placement `"cursor"` = centred horizontally on the pointer, 28 px above it, clamped; from the bar it sits beside the item.

## Surface table

Legend: Esc = Escape closes; Out = click outside closes; Kbd = keyboard navigation inside; Tok = theme tokens.
"CP" = CursorPopup. All surfaces use Theme tokens for colours, fonts and radii except where "hard" is listed.

| Surface | Files | Open / position | Esc / Out / Kbd | Tokens vs hardcoded | States | Problems |
|---|---|---|---|---|---|---|
| Menu bar | `Bar.qml` (196), `BarWidget.qml`, `BarItem.qml`, `BarItems.qml`, `BarActions.qml`, `BarFocus.qml`, `BarEditor.qml` | Own PanelWindow per screen, any edge, 3 sections | F6 focus mode: arrows/Tab, Enter, Esc (`BarItem.qml:42-52`) / n/a / yes | Tok. Hard: font sizes `bar/items/launcher/Item.qml`, `controls/Item.qml` pixelSize 18; `BarBell.qml:13,20`; `BarKeyboard.qml:31`; `BarBattery.qml:44,47` | items hide via `shown` | Item opens panel via `Anchor.take` before `pressed`; `hiddenOn`, per-monitor presets supported |
| Item launcher | `bar/items/launcher` | Toggle Launcher | as Launcher | Tok | - | - |
| Item controls | `bar/items/controls`, `UtilityMenu.qml` | CP `topLeft`, 236 wide | Esc NO (see Problem 1) / Out yes / Kbd none | Tok; `UtilityMenu.qml:~100` icon px 14 hard | no empty/err | Row_ is a private copy (`UtilityMenu.qml:88`); rows are MouseArea only, no `activeFocusOnTab` |
| Item workspaces | `bar/items/workspaces`, `BarWs.qml` | in bar | via bar focus | Tok | - | - |
| Item window | `bar/items/window`, `BarApp.qml` | in bar | - | Tok | - | no click panel |
| Item clock / date | `bar/items/clock`, `date` | opens `calendar` | as Calendar | Tok | - | - |
| Item weather | `bar/items/weather` | opens `weather` | as Weather | Tok | - | - |
| Item cpu/memory/gpu/sysinfo | `bar/items/{cpu,memory,gpu,sysinfo}`, `BarMetric.qml`, `Metrics.qml` | open `system` (Sensors) | as Sensors | Tok | metrics runs only while an item shows | - |
| Item volume | `bar/items/volume` | click -> `ControlCenter.showSection("out")`; middle = mute; scroll = volume | as CC | Tok | muted state | no volume popover of its own; goes to CC |
| Item network / bluetooth | `bar/items/network`, `bluetooth` | click -> CC expanded section wifi / bt | as CC | Tok | offline / wifi off / wired words | no own flyout |
| Item brightness | `bar/items/brightness` | click -> `ControlCenter.toggle()` (not a section); scroll | as CC | Tok | hidden when `Sys.brightness < 0` | - |
| Item battery | `bar/items/battery`, `BarBattery.qml` | click -> `SettingsApp.show("power")` | - | Tok; `BarBattery.qml:44,47` hard px | hidden w/o battery; low = error tint | no popup (no %, time, profile): jumps to Settings |
| Item power-profile | `bar/items/power-profile`, `PowerMode.qml` | click cycles quiet/balanced/perf | - | Tok | - | blind cycle, no menu or confirmation of current mode beyond glyph |
| Item media | `bar/items/media` | click = play/pause, scroll = prev/next | - | Tok | hidden w/o player | no media popover; the full player is only inside CC (`ControlCenterMedia.qml`) |
| Item keyboard | `bar/items/keyboard`, `BarKeyboard.qml`, `Keyboard.qml` | CP menu 236 wide | Esc NO / Out yes / Kbd none | Hard: `Keyboard.qml:110` radius 4, `:117` px 9, `:131` px 14 | - | - |
| Item notifications | `bar/items/notifications`, `BarBell.qml` | opens notification centre | as NC | Hard `BarBell.qml:13,20` px 16/9 | badge, DND glyph | - |
| Item status | `bar/items/status`, `BarStatus.qml` | opens CC (wifi/bt/vol/battery cluster) | as CC | Hard `BarStatus.qml:33` 10px radius 5 | - | duplicates volume/network/bt items |
| Item tray | `bar/items/tray`, `BarTray.qml`, `TrayMenu.qml` | left = activate, right = TrayMenu (PopupWindow `anchor.item`, opens away from bar edge) | Esc via `grabFocus` / Out via grab / Kbd none | Tok; hard px 12/13, 236 w, 560 max h (`TrayMenu.qml`) | submenu "Back" stack; disabled 40% | No theme depth/decor (no shadow/topline/brackets) unlike CursorPopup; own motion copy; `Theme.menu` surface not `Glass` |
| Item apps | `bar/items/apps` | running apps in bar | - | Tok | - | overlaps Dock features (`Config.dock.*` read by a bar item) |
| Item recording | `bar/items/recording` | click stops recording | - | Hard `recording/Item.qml:14` 10px radius 5 | hidden unless `Sys.recording` | - |
| Dock | `Dock.qml` (270), `DockApp.qml`, `DockWidget.qml` (505), `DockLauncher.qml`, `DockMark.qml`, `DockSeparator.qml`, `DockTip.qml`, `DropSpot.qml` | Own PanelWindow per screen, 340 px deep, input `mask` limited to island/menu/preview (`Dock.qml:143`); any edge; auto-hide edge strip | n/a | Tok; hard radius `DockWidget.qml:341`, `DropSpot.qml:33`, `DockMenu.qml:73` | running dots, drag/drop | Hover-driven; tab focus 0 in `DockApp.qml` (no keyboard access) |
| Dock menu | `DockMenu.qml` (96) | `Glass` inside the Dock window, beside icon (`dock.beside`) | Esc no / Out no (closes 1.5 s after pointer leaves, `:25`) / Kbd none | Tok; hard `:73` | windows list + actions | pointer-only; no Esc |
| Dock preview | `DockPreview.qml` | `Glass` in Dock window, hover | hover only | Tok; hard px `:73` | up to 8 tiles | pointer-only |
| Launcher | `Launcher.qml` (215), `LauncherHeader/Panel/Results/Home/HomeRow/HomeLabel/Apps/Mark/StylePreview.qml`, `Search.qml` (361) | CP, see "How panels open" | Esc yes (focusItem field) / Out yes / Kbd: type, up/down, Tab mode, Enter | Tok; `LauncherPanel.qml:31` `Qt.rgba(Theme.warning...)` | home, apps grid, results, "Nothing matches" (`LauncherResults.qml:31`), confirm-first actions | At rest the home view clips the "Quick actions" row behind the footer hint (`01-launcher.png`); 6 styles x themes = large matrix |
| Clipboard | `Clipboard.qml`, `ClipboardView.qml`, `clipstore` script | CP (400x540), also embedded in Launcher (`clipboardInside`) | Esc yes / Out yes / Kbd: type, up/down, Enter, Space, Ctrl+P, Del (`Clipboard.qml:130`) | Tok | empty ("Copy something...", "History is paused", "Nothing matches") | Always 540 tall even when empty (`01-clipboard.png`) |
| Emoji | `config/scripts/.local/bin/emojipick`, UtilityMenu row | external script (`UtilityMenu.qml:~32`) | external | n/a | n/a | Not a shell surface; no theme |
| Control Center | `ControlCenter.qml` (305), `ControlCenter{Bar,Connections,ConnTile,DeviceRow,Drop,Empty,IconButton,Media,Module,Power,QuickToggle,Reveal,SectionLabel,Segmented,SettingsLink,Shortcuts,SliderHead,Sliders,Tile,Toggles,WifiRow}.qml` | CP; `expand(name)` IPC; width `cc.customWidth` | Esc NO / Out yes / Kbd: only tiles/toggles with `activeFocusOnTab` (QuickToggle, ConnTile); rows (`DeviceRow`, `WifiRow`) none | Tok; hard px `ControlCenter.qml` x2, `DeviceRow.qml:35,76`, `Media.qml:43`, etc. | wifi failed ("Couldn't connect"), switch off, empty list (`ControlCenterEmpty`) | Content clipped to Flickable height with thin scrollbar (`01-controlcenter.png`: "Screen · Sound" cut); `ControlCenterTile.qml:9` `width: ... ? 0 : 0` dead ternary |
| Volume / mic / brightness | in `ControlCenterSliders.qml` | inside CC ("Screen · Sound" tile) | as CC | Tok | device lists | no standalone volume popup; OSD separate |
| Network (wifi) | `ControlCenterConnections.qml`, `ControlCenterWifiRow.qml` | CC section | as CC | Tok | known/other lists, password field, failed | `TextInput` (not shared `TextField`) at `ControlCenterWifiRow.qml:51` |
| Bluetooth | `ControlCenterDeviceRow.qml`, `ControlCenterDrop.qml` | CC section | as CC | Tok; hard px 14 | switch | - |
| Battery / power profile | `ControlCenterPower.qml`, `PowerMode.qml`, `SettingsPagePower.qml` | CC section; bar item goes to Settings | as CC | Tok | - | battery info reachable only via CC or Settings |
| Media | `ControlCenterMedia.qml` | inside CC | as CC | Hard px 20 `:43` | no-player hides | - |
| Notification centre | `NotificationCenter.qml` (144), `NotificationCard.qml` | CP 380 wide; bell item / Super+N | Esc NO / Out yes / Kbd none | Tok; `NotificationCard.qml:134,137` hard radius/px | empty ("You're all caught up"), grouped/unfolded | cards not focusable (0 `activeFocusOnTab`); history in memory only (`Notifications.qml:12`) |
| Notification toasts | `Notifications.qml` (188), `NotificationCard.qml` | Own PanelWindow on focused screen, corner from `Theme.current.notify.corner`, max 5, 344 wide | none (click = card actions; timer dismiss; hover pauses) | Tok | hidden while CC / NC open; DND; sharing mode | no mask set; toasts not keyboard-reachable; only the focused monitor |
| Calendar | `Calendar.qml` (397) | CP 340 wide, `placement: "top"`, wheel = month | Esc NO / Out yes / Kbd none | Tok; hard `Calendar.qml:267,288,377` | no events, upcoming | OVERFLOW: no Flickable/clip, content spills below the box and under the dock (`Calendar.qml:159-163`; `01-calendar.png`) |
| Weather | `Weather.qml` (336) | CP 340 wide | Esc NO / Out yes / Kbd none | Tok; hard `:148,188,221,270` px, `:292,298` radius | "Loading..." / "-" | No error state: a failed fetch stays "Loading..." (`:326`); scrolls via Flickable with no visible scrollbar/`MoreBelow`, forecast list cut mid-row (`01-weather.png`) |
| System (sysinfo) | `Sensors.qml` (336), `Metrics.qml` | CP 330 wide, from cpu/mem/gpu/sysinfo items | Esc NO / Out yes / Kbd none | Tok; hard `Sensors.qml:260-316` radii, `:210,332` px | threshold tones | `Tile_`, `Chip_` private copies (`:226,232`) of Glass/Chip; "Open btop++" button not `PillButton` |
| Keyboard layout | `Keyboard.qml` (154) | CP 236 wide | Esc NO / Out yes / Kbd none | see item | - | - |
| Window menu | `WindowMenu.qml` (268), plugin title-bar button | CP at pointer; Super+Z; `windowmenu open` | Esc NO / Out yes / Kbd none | Tok; hard `:148` radius 3 | no focused window -> empty (nothing opened in nested, `03-windowmenu.png`) | `Pill_`, `Label_` private copies (`:242,248`); raw `Slider` for opacity (`:227`) |
| Power menu | `PowerMenu.qml` (227) | Own PanelWindow (fullscreen scrim), focused screen; bar item and CC | Esc yes / Out yes / Kbd: arrows/Tab/Enter/Space (`:75-86`) | Tok; hard `:134` 28px circle, `:136` px 14; `:163` `Qt.rgba(tone...)` | confirm step ("confirming") | own scrim/Esc/click-outside copy; no `HyprlandFocusGrab` |
| Cheatsheet | `Cheatsheet.qml` (203) | Own PanelWindow, covers whole screen incl. bar | Esc yes / Out yes / Kbd: type to filter (`:Keys.onPressed`) | Tok | filter | Scrollbar overlaps right-hand key caps ("Super + W|", `01-cheatsheet.png`); "Type to filter..." header text runs under scrollbar |
| Welcome | `Welcome.qml` (230) | Own PanelWindow, first run (`system.welcomed`), `welcome open` | Esc yes / Out yes / Kbd Tab+Enter | Tok | - | Covers the whole desktop at start; own scrim copy |
| Mission Control | `MissionControl.qml` (433) | Own PanelWindow on the monitor with focus (`root.mon`), `overview toggle`, Super+W | Esc yes (`:136`) / Out yes (`:167`) / Kbd digits 1-9 | Tok; hard px `:255,295`; | "No windows on this desktop" | window drag/snap; `activeFocusOnTab` 0 |
| OSD | `Osd.qml` (157) | Own PanelWindow 260x48, focused screen, bottom or top (`Config.osd`), input mask empty | n/a (never takes input) | Tok | volume, mute, brightness, mic | `osd test` shows a keyboard icon for "volume" (test glyph hardcoded) |
| Battery warning | `BatteryWarning.qml` (32) | notification-style | - | Tok | low only | - |
| Hot corners | `HotCorners.qml` (39), `HotCornerActions.qml` | 2x2 px overlay windows per enabled corner, 150 ms dwell | n/a | Tok | - | one PanelWindow per enabled corner per screen |
| Lock screen | `LockScreen.qml` (140), `LockPreview.qml`, `ThemeSync.qml`, `config/hypr/.config/hypr/hyprlock.conf` | Real lock is hyprlock; QML only builds its layout (`LockScreen.qml:1-9`) | n/a | Tok; `Theme.onImage` fixed light ink | clock/date/password/widgets | not testable in nested (hyprlock is shimmed) |
| Settings app | `SettingsApp.qml` (393), `SettingsPage*.qml` (29), `Settings*.qml` | Normal toplevel window (Hyprland tiles it) | Esc?/Out n/a/ Kbd Tab | Tok; hard `SettingsApp.qml:295,377` etc. | per page | In the nested desktop it renders edge to edge under the bar (`04-settings.png`); out of scope for popups |
| Dropdown (select) | `Dropdown.qml` | `PopupWindow` below the field, `grabFocus` | Esc via grab / Out via grab / Kbd: Up/Down picks, Space/Enter opens (no arrow nav inside list) | Tok | `(custom)` | - |

## Problems found live (nested desktop)

1. Escape does not close 7 CursorPopup panels. Opened via IPC then Escape key (wtype): Sensors/system, Weather,
   Calendar, ControlCenter, NotificationCenter, UtilityMenu stayed mapped (`hyprctl layers` still lists `qs-<name>`);
   Clipboard closed (also Launcher, PowerMenu). Cause (static): `Keys.onEscapePressed` sits on `CursorPopup.qml`'s `box`
   Item, which needs active focus; only Launcher and Clipboard set `focusItem` (`Launcher.qml:190`, `Clipboard.qml:71`).
   Keyboard is also affected (no `focusItem`); WindowMenu likewise. Exclusive keyboard focus is taken but nothing handles keys.
2. Calendar overflows its box (`Calendar.qml:159` caps height, `:163` Column has no scroll/clip): "Coming up" rows
   draw over the dock.
3. Launcher home view cuts the "Quick actions" row behind the footer (`01-launcher.png`); Weather and Control Center
   cut a row at the bottom with no `MoreBelow` cue; Cheatsheet scrollbar covers key caps.
4. Welcome overlay covers the first screen on every fresh home; the cheatsheet/welcome overlays also cover the bar.

## Shared primitives (use counts = files that instantiate them, excluding the file itself)

| Primitive | File | Used in | Notes |
|---|---|---|---|
| Glass | `Glass.qml` | 23 | solid/glass surface; `strong`, `flat`; hard `Qt.rgba(1,1,1,...)` rim `Glass.qml:22,31` |
| PillButton | `PillButton.qml` | 36 | text button; focus ring, Space/Enter |
| Toggle / ConfigToggle | `Toggle.qml`, `ConfigToggle.qml` | 17 | keyboard: Space/Enter |
| Slider / ConfigSlider | `Slider.qml`, `ConfigSlider.qml` | 7 files, 23 call sites, nearly all Settings; CC sliders use their own `ControlCenterSliders.qml` + `ControlCenterSliderHead.qml` | thick "icon" variant vs thin plain variant in one file |
| Chip | `Chip.qml` | 10 | bar-style clickable (not the BarEditor `Chip`, `BarEditor.qml:176`) |
| Choice / ConfigChoice | `Choice.qml`, `ConfigChoice.qml` | 15 | segmented; Left/Right |
| TextField | `TextField.qml` | 17 | `TextInput` used raw in `Clipboard.qml:117`, `LauncherHeader.qml:30`, `ControlCenterWifiRow.qml:51`, `SettingsPageInstalled.qml:97`, `SettingsPageWeather.qml:56` |
| Dropdown | `Dropdown.qml` | 15 | select, not a menu |
| FocusRing | `FocusRing.qml` | 13 | |
| Chevron, MoreBelow, GlassScrollBar, ToolTipText, ArrowButton | | 6, 4, 5, 9, 1 | `MoreBelow` only in Cheatsheet and Launcher panel; `GlassScrollBar` only in Cheatsheet, ControlCenter, NotificationCenter |
| StatusGlyph | `StatusGlyph.qml` | 0 references | dead file |
| Theme tokens | `Theme.qml` | everywhere | only 4 hard hex colour literals outside Theme/Themes: `CursorPopup.qml:156` (`"black"` scrim), `Glass.qml:22,31`, `SettingsPageWallpaper.qml:150-151`, `SettingsPageAppearance.qml:24` (palette); 45 hard `pixelSize` and ~30 hard radii, mostly icon/dot sizes |

Panels that bypass primitives: Sensors (`Tile_`, `Chip_`, raw buttons), WindowMenu (`Pill_`, `Label_`, raw Slider),
UtilityMenu and TrayMenu (private `Row_`), PowerMenu/Cheatsheet/Welcome/MissionControl (own window + scrim + Esc),
ControlCenter (its own 20 building blocks), Dock menu/preview (Glass but own Esc-less behaviour).

## Duplicates

- Menu row: `UtilityMenu.qml:88 Row_`, `TrayMenu.qml:96 Row_`, `WindowMenu.qml:248 Pill_`, `DockMenu.qml` rows, `Keyboard.qml` rows: five hover-accent list rows.
- Segmented control: `Choice.qml` vs `ControlCenterSegmented.qml`.
- Toggle/switch: `Toggle.qml` vs `ControlCenterQuickToggle.qml` / `ControlCenterConnTile.qml` / `ControlCenterDrop.qml` (embeds Toggle).
- Icon button: `ArrowButton.qml`, `ControlCenterIconButton.qml`, close/dismiss circles in `PowerMenu.qml:134`, `NotificationCard.qml:134`.
- Fullscreen overlay scaffolding (PanelWindow + scrim + Esc + click-outside + key handler): PowerMenu, Cheatsheet, Welcome, MissionControl, versus CursorPopup's `dim`/`fullscreen`.
- Sliders: `Slider.qml` + `ConfigSlider.qml` + CC sliders + `SettingsPageAppearance.qml:189 AdjustSlider`, `SettingsPageBuilder.qml` `Num`.
- Text input: `TextField.qml` vs raw `TextInput` (5 places, above).
- Popup motion/depth: `CursorPopup.qml` and `TrayMenu.qml` / `Dropdown.qml` each carry their own enter/exit animation; only CursorPopup has depth (soft/glow/hard) and decor (topline/brackets).
- Bar status cluster: `status`, `volume`, `network`, `bluetooth`, `battery` items overlap (status = all of them).
- Scroll areas: 16 files use raw `Flickable`; 3 use `GlassScrollBar`; 2 use `MoreBelow`.

## Broken / half-done

- `CursorPopup.qml:152-157,239` Esc depends on `focusItem` (Problem 1); no `focusItem` in Sensors, Weather, Calendar, NotificationCenter, ControlCenter, UtilityMenu, Keyboard, WindowMenu.
- `Calendar.qml:159,163` no scroll/clip; overflows.
- `Weather.qml:27,140,326` no error/offline state, "Loading..." forever; no scroll cue.
- `ControlCenterTile.qml:8-9` `width: cond ? 0 : 0` (dead branch); `ControlCenter.style === "borderless"` is the only consumer.
- `Notifications.qml:12` history is memory only ("shortcut" comment).
- `Notifications.qml` `sharing` flag: restart during a share forgets it (comment at `:25-26`).
- `Osd.qml:100-101` `osd test` shows a fixed keyboard glyph.
- `ThemePreview.qml:33` loads `~/.cache/hyprism/wallpapers/<id>-v9.png` that do not exist on a fresh home (see Runtime errors); Settings thumbnails stay blank until `theme-wallpaper` runs.
- `StatusGlyph.qml`: not referenced anywhere (grep), dead file.
- No `TODO`/`FIXME` markers anywhere in the QML tree.
- Settings read but never applied: none found by an automated pass (every `ConfigData.qml` key is read by a panel, `SettingsSync.qml`, `clipstore`, or the Lua config).

## Runtime errors (nested desktop, ~3 min of opening every panel)

`tests/nested.sh errors`, deduplicated:

- `WARN scene: QML QQuickImage at @ThemePreview.qml[33:9]: Cannot open: .../.cache/hyprism/wallpapers/{reactor,poster,pebble,monolith,glass,console}-v9.png` (2-3 each): theme preview images missing in a fresh home.
- `WARN scene: QML FileView at @Config.qml[149:5]: Read of .../.config/quickshell/settings.json failed: File does not exist.` (once, first run; written afterwards).
- `WARN quickshell.io.fileview: got operation finished from dropped operation` (once).
- `WARN qt.qpa.wayland.textinput: ... QWaylandTextInputv3::disableSurface/enableSurface ... focused` (about 35 lines): Qt text-input focus churn as exclusive-focus popups open and close; no QML source line.
- `WARN qt.qpa.services: Failed to register with host portal ... Connection already associated with an application ID` (once).
- Filtered by the script: `org.freedesktop.Notifications`, `StatusNotifierWatcher` (the test session's own D-Bus).
- No ERROR or CRITICAL lines. No binding-loop or type errors.

## One-line recommendations

- Give `CursorPopup` its own Escape (a `Shortcut`/`Keys` on the window's root, not on a focus-dependent child).
- Put one scrollable body (Flickable + `GlassScrollBar` + `MoreBelow`) inside `CursorPopup` so Calendar/Weather/CC cannot overflow.
- One shared `MenuRow`, `Segmented`, `SwitchTile` and `IconButton` replace the five-way duplicates.
- Move PowerMenu/Cheatsheet/Welcome onto CursorPopup `fullscreen` placement.
- Add an error state to Weather and keyboard rows (focusable) to menus (UtilityMenu, TrayMenu, DockMenu, WindowMenu).
