# Settings reference

Every setting, with its type, default and meaning. This file is generated from `ConfigData.qml` by
`tests/settings-reference.py`; do not edit it by hand (`tests/lint.sh` fails when it is out of date).

- The settings live in `~/.config/quickshell/settings.json`, one object per section below.
- The Settings app writes the file. The shell reloads it when you edit it by hand, and a missing key takes the
  default shown here.
- From a terminal: `qs ipc call config set <section> <key> '<json>'`, for example
  `qs ipc call config set appearance motion '"reduced"'`. Read one back with `qs ipc call config get <section> <key>`.

## (top level)

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `version` | `int` | `3` | settings format; Config.repair() upgrades older files |

## appearance

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `theme` | `string` | `"reactor"` | the whole desktop design (Themes.qml): layout, type, shape, colour, motion |
| `userThemes` | `var` | `{}` | your own themes (Theme builder): { "custom-name": { name, base, ...parts } } |
| `mode` | `string` | `"theme"` | theme (each theme's own) \| light \| dark: every theme has both halves (Themes.qml alt) |
| `custom` | `var` | `{}` | your adjustments per theme: { pebble: { accent: "#ff9e7a", radius: 12, ... } } (Themes.adjustable) |
| `terminal` | `bool` | `true` | Ghostty follows the theme (ThemeSync writes ghostty/theme.conf) |
| `wallpaper` | `bool` | `true` | the theme's own wallpaper; off = keep yours (Settings > Wallpaper) |
| `wallpaperColours` | `bool` | `false` | the accents follow your own wallpaper (WallpaperColours.qml); off = the theme's own |
| `fontScale` | `real` | `1` |  |
| `motion` | `string` | `"full"` | full (the theme's own motion) \| reduced (short fades, nothing moves) \| off |
| `iconTheme` | `string` | `"Papirus-Dark"` |  |
| `monoTray` | `bool` | `true` | tray icons in the bar's ink (off: the apps' own colours) |
| `cursorTheme` | `string` | `"default"` | a folder in ~/.local/share/icons, ~/.icons or /usr/share/icons; "default" = the system's cursor |
| `cursorSize` | `int` | `24` |  |

## dock

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `enabled` | `bool` | `true` | every theme has a dock; off hides it everywhere |
| `size` | `string` | `"regular"` | compact \| regular \| roomy: the padding around the icons |
| `hiddenOn` | `list<string>` | `[]` | monitor names (e.g. "eDP-1") without a dock |
| `iconSize` | `int` | `44` |  |
| `autoHide` | `bool` | `false` | visible by default; true slides it away until the pointer reaches its edge |
| `showRunning` | `bool` | `true` |  |
| `barLabels` | `string` | `"icon"` | open windows in the dock inside the bar: icon \| name (app name) \| title (window title) |
| `combine` | `bool` | `false` | like Windows' "combine taskbar buttons": open apps share their icon |
| `previews` | `bool` | `true` | combined: hover an open app for a picture of each window |
| `thumbnails` | `bool` | `true` | off: open windows show only their app icon |
| `thumbRefresh` | `int` | `60` | s between still pictures (live only while hovered) |
| `pinned` | `list<string>` | `["firefox", "google-chrome", "com.microsoft.VSCode", "com...` |  |

## launcher

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `webSearch` | `string` | `"https://duckduckgo.com/?q=%s"` |  |
| `showFiles` | `bool` | `true` |  |
| `actions` | `list<var>` | `[]` |  |
| `usage` | `var` | `{}` | launch counts, for ranking |
| `columns` | `int` | `7` | apps per row in the apps grid |
| `startView` | `string` | `"theme"` | theme (the theme's own) \| home (suggestions until you type) \| apps (grid) \| search (empty pill) |
| `recent` | `list<string>` | `[]` | result keys, most recent first, for the home view |
| `order` | `list<string>` | `["apps", "files", "calc", "settings", "actions", "web"]` |  |
| `clipboardInside` | `bool` | `true` | Spotlight's clipboard button shows history in the panel |

## clipboard

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `maxItems` | `int` | `300` |  |
| `maxAgeDays` | `int` | `30` | 0 = keep forever (pins are always kept) |
| `images` | `bool` | `true` |  |
| `paused` | `bool` | `false` |  |
| `skipSensitive` | `bool` | `true` | skip copies password managers mark as secret |
| `autoPaste` | `bool` | `true` |  |

## notifications

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `dnd` | `bool` | `false` |  |
| `timeoutSec` | `int` | `6` |  |
| `historyMax` | `int` | `100` |  |
| `sound` | `string` | `"message-new-instant"` | a freedesktop sound name (Notifications.sounds), "" = none |
| `volume` | `int` | `60` | % |
| `mutedApps` | `list<string>` | `[]` | app names that only go to the notification centre |

## osd

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `timeoutMs` | `int` | `1400` |  |
| `volume` | `bool` | `true` |  |
| `brightness` | `bool` | `true` |  |
| `micMute` | `bool` | `true` |  |
| `layout` | `bool` | `true` |  |
| `capsLock` | `bool` | `true` | polls the keyboard's caps lock light every 500 ms while on (if it has one) |
| `position` | `string` | `"bottom"` | bottom \| top \| center |

## caffeine

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `defaultMinutes` | `int` | `0` | 0 = until turned off |
| `on` | `bool` | `false` |  |
| `minutes` | `int` | `0` | length of the current run, 0 = until turned off |
| `endsAt` | `real` | `0` | ms since epoch, 0 = until turned off |

## nightLight

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `mode` | `string` | `"off"` | off \| on \| sun \| schedule |
| `temperature` | `int` | `4000` |  |
| `from` | `string` | `"21:00"` |  |
| `to` | `string` | `"07:00"` |  |

## controlCenter

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `showHardware` | `bool` | `true` |  |
| `slidersOpen` | `bool` | `true` |  |
| `style` | `string` | `"panel"` | panel (current), compact (denser), borderless (flat tiles, no outlines) |
| `width` | `int` | `330` | panel width in px (280..460) |
| `sections` | `list<string>` | `[]` |  |
| `tiles` | `list<string>` | `[]` |  |
| `toggles` | `list<string>` | `[]` |  |
| `shortcuts` | `list<string>` | `[]` |  |
| `hidden` | `list<string>` | `["colorpicker", "mission"]` |  |

## lockscreen

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `clock` | `string` | `"theme"` | theme \| big \| stacked \| terminal \| readout \| small |
| `position` | `string` | `"theme"` | theme \| center \| top \| bottom \| left |
| `date` | `bool` | `true` |  |
| `greeting` | `bool` | `false` | "Welcome back, <name>" above the clock |
| `avatar` | `string` | `""` | a picture of you (path), "" = none |
| `widgets` | `list<string>` | `["battery", "layout"]` | battery, layout (in the password field), media |
| `wallpaper` | `string` | `""` | full path; empty = the desktop wallpaper |
| `blur` | `int` | `3` | blur passes, 0 = sharp |
| `brightness` | `real` | `0.72` |  |

## windows

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `layout` | `string` | `"dwindle"` | "dwindle" (split), "master" (main + stack) or "scrolling" |
| `newSplit` | `int` | `0` | dwindle: 0 where the mouse is, 1 left/top, 2 right/bottom |
| `smartSplit` | `bool` | `false` | dwindle: split by where in the window the mouse is |
| `masterNew` | `string` | `"slave"` | master: new windows join the stack ("slave") or become main |
| `masterSide` | `string` | `"left"` | master: where the main window sits |
| `columnWidth` | `real` | `0.5` | scrolling: share of the screen per column |
| `followMouse` | `bool` | `true` |  |
| `focusOnActivate` | `bool` | `false` | apps may bring themselves to the front |
| `warpCursor` | `bool` | `true` | pointer jumps to the window focused from the keyboard |
| `backAndForth` | `bool` | `false` | the current desktop's shortcut goes back to the last one |
| `inactiveOpacity` | `real` | `0.96` |  |
| `dimInactive` | `bool` | `false` |  |
| `dimStrength` | `real` | `0.2` |  |
| `resizeOnBorder` | `bool` | `true` |  |
| `snap` | `bool` | `false` | floating windows snap to edges and each other |
| `hideCursorTyping` | `bool` | `false` |  |
| `titleBars` | `bool` | `true` | hyprbars: title bar with buttons on apps that draw none |
| `apps` | `var` | `[]` | [{ id, name, class (regex), open: normal\|float\|pin\|maximize\|fullscreen, workspace: 0 = any }] |

## keybinds

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `overrides` | `var` | `{}` |  |

## weather

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `city` | `string` | `"Belgrade"` |  |
| `latitude` | `real` | `44.82` |  |
| `longitude` | `real` | `20.46` |  |
| `days` | `int` | `7` | forecast days in the weather dropdown |
| `showHourly` | `bool` | `true` | next 12 hours strip |
| `showDetails` | `bool` | `true` | feels like, humidity, wind, UV, sunrise/sunset |
| `units` | `string` | `"celsius"` | "celsius" (km/h) or "fahrenheit" (mph) |

## system

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `taskManager` | `string` | `"auto"` | desktop id, or "auto": first installed (Sensors.taskManagers) |
| `welcomed` | `bool` | `false` | the first-login hint has been shown (shell.qml) |

## calendar

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `holidays` | `bool` | `true` | public holidays (date.nager.at, cached per year) |
| `country` | `string` | `"RS"` | ISO country code for holidays |
| `localNames` | `bool` | `false` | holiday names in the country's language |
| `observances` | `bool` | `true` | worldwide days: New Year, Earth Day, … |
| `moon` | `bool` | `false` | new / full moon and quarters |
| `weekNumbers` | `bool` | `false` |  |
| `firstDay` | `string` | `"monday"` | monday \| sunday |

## language

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `languages` | `list<string>` | `["en_US"]` | glibc locale ids; the first is the apps' language, the rest fallbacks |
| `formats` | `string` | `""` | locale id for dates, numbers, units; "" = the first language |

## startup

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `apps` | `list<string>` | `[]` | desktop entry ids opened at login (startup-apps) |

## bar

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `margin` | `int` | `8` | gap around a floating bar, px |
| `hiddenOn` | `list<string>` | `[]` | monitor names (e.g. "eDP-1") without a bar |
| `clock24` | `bool` | `true` |  |
| `seconds` | `bool` | `false` |  |
| `date` | `string` | `"full"` | "full" (Fri 30 Oct), "short" (30 Oct) or "none" |
| `batteryPercent` | `string` | `"beside"` | the battery's percentage: inside (the icon) \| beside \| off |
| `windowTitle` | `bool` | `true` | the focused window's title after the app name |
| `items` | `var` | `{}` |  |
| `preset` | `string` | `"theme"` |  |
| `presets` | `var` | `{ minimal: { start: ["launcher", "workspaces"], center: [...` |  |
| `monitors` | `var` | `{}` | screen name (e.g. "eDP-1") -> preset name; unlisted or "" follows `preset` |

## battery

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `warn` | `bool` | `true` | a notification when the battery runs low |
| `warnAt` | `int` | `15` | % |
| `criticalAt` | `int` | `5` | %, a critical notification that stays |

## hotCorners

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `topLeft` | `string` | `""` |  |
| `topRight` | `string` | `""` |  |
| `bottomLeft` | `string` | `""` |  |
| `bottomRight` | `string` | `""` |  |

## wallpaper

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `folders` | `list<string>` | `["~/Pictures/Wallpapers"]` |  |
| `current` | `string` | `""` | full path; empty = whatever hypr/settings/wallpaper points at |
| `slideshow` | `bool` | `false` |  |
| `interval` | `int` | `30` | minutes between slideshow changes |
| `source` | `string` | `"all"` | "all": every image in the folders, "selected": only picked ones |
| `selected` | `list<string>` | `[]` | full paths for source "selected" |
| `order` | `string` | `"shuffle"` | "shuffle" or "name" |
| `blur` | `int` | `0` | desktop only (a blurred copy in ~/.cache); 0 = sharp |

## idle

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `lockMin` | `int` | `5` | minutes to lock; 0 = never |
| `sleepMin` | `int` | `20` | minutes to sleep; 0 = never |
| `imported` | `bool` | `false` |  |

## input

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `layouts` | `var` | `[{ code: "us", variant: "" }]` | xkb layouts, the first is the default (max 4) |
| `shortcut` | `int` | `3` | extra layout switch: 0 Alt+Shift, 1 Ctrl+Shift, 2 Caps Lock, 3 none (Super+Ctrl+Space always works) |
| `repeatRate` | `int` | `25` | keys per second while held |
| `repeatDelay` | `int` | `600` | ms before a held key repeats |
| `sensitivity` | `real` | `0` | pointer speed, -1..1 |
| `naturalScroll` | `bool` | `true` |  |
| `tapToClick` | `bool` | `true` |  |
| `disableWhileTyping` | `bool` | `true` | touchpad ignores the palm while typing |
| `clickMethod` | `string` | `"clickfinger"` | "clickfinger" (1, 2, 3 fingers = left, right, middle) or "buttonareas" (bottom corners) |
| `scrollFactor` | `real` | `1.0` | touchpad scroll speed, 0.2..3 |
| `middleEmulation` | `bool` | `false` | left + right together = middle click |
| `dragLock` | `bool` | `false` | lift the finger mid-drag without dropping the item |
| `imported` | `bool` | `false` |  |

## displays

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `layout` | `var` | `{}` | output -> { mode, position, scale, transform, vrr, bitdepth, mirror, disabled } |
| `autoHdr` | `bool` | `false` | switch a screen's colour space on fullscreen video (HDR screens) |
| `sendContentType` | `bool` | `false` | tell the screen what is playing (some screens blank briefly when it changes) |
| `xwaylandNativeScale` | `bool` | `true` | old X11 apps draw sharp but small, instead of stretched |
| `vrr` | `string` | `"off"` | adaptive sync: off \| on \| fullscreen |
| `preferHighRefresh` | `bool` | `true` | new screens start at their highest refresh rate |
| `imported` | `bool` | `false` |  |

## apps

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `terminal` | `string` | `"ghostty +new-window"` | command the terminal key runs (SettingsSync writes hypr/settings/apps.lua) |

## monitorShare

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `enabled` | `bool` | `false` |  |
| `output` | `string` | `""` | Hyprland output name, e.g. HDMI-A-1 |
| `thisInput` | `string` | `"0x11"` | DDC input (VCP 0x60) this computer is on |
| `otherInput` | `string` | `"0x12"` | the other computer's input |
| `mirror` | `string` | `""` | screen it mirrors while away (keeps a signal); empty = this computer's own screen, "none" = no mirror |
| `mirrorMode` | `string` | `""` | the mode for that mirror, e.g. 1920x1080@60; empty = the screen's own |
| `imported` | `bool` | `false` |  |
