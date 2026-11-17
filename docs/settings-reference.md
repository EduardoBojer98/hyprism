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
| `version` | `int` | `7` | settings format; Config.repair() upgrades older files |

## appearance

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `theme` | `string` | `"pebble"` | the whole desktop design (Themes.qml): layout, type, shape, colour, motion |
| `mode` | `string` | `"theme"` | theme (each theme's own) \| light \| dark: every theme has both halves (Themes.qml alt) |
| `custom` | `var` | `{}` | your adjustments per theme: { pebble: { accent: "#ff9e7a", radius: 12, ... } } (Themes.adjustable) |
| `terminal` | `bool` | `true` | Ghostty follows the theme (ThemeSync writes ghostty/theme.conf) |
| `wallpaper` | `bool` | `true` | the theme's own wallpaper; off = keep yours (Settings > Wallpaper) |
| `wallpaperColours` | `bool` | `false` | the accents follow your own wallpaper (WallpaperColours.qml); off = the theme's own |
| `fontScale` | `real` | `1` |  |
| `motion` | `string` | `"full"` | full (the theme's own motion) \| reduced (short fades, nothing moves) \| off |
| `motionStyle` | `string` | `"theme"` | the motion look (Theme.qml looks): theme (its own) \| smooth \| snappy \| springy \| minimal |
| `iconTheme` | `string` | `"theme"` | theme (the theme's own) \| a folder in ~/.local/share/icons or /usr/share/icons |
| `monoTray` | `bool` | `true` | tray icons in the bar's ink (off: the apps' own colours) |
| `cursorTheme` | `string` | `"theme"` | theme (the theme's own) \| a folder in ~/.local/share/icons, ~/.icons or /usr/share/icons \| default (the system's) |
| `cursorSize` | `int` | `24` |  |

## dock

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `enabled` | `bool` | `true` | every theme has a dock; off hides it everywhere |
| `size` | `string` | `"regular"` | compact \| regular \| roomy: the padding around the icons |
| `hiddenOn` | `list<string>` | `[]` | monitor names (e.g. "eDP-1") without a dock |
| `iconSize` | `int` | `44` | the dock's size: Settings presets 36 / 44 / 52 / 60, or any size 24-72 on its slider |
| `autoHide` | `bool` | `false` | visible by default; true slides it away until the pointer reaches its edge |
| `showRunning` | `bool` | `true` |  |
| `barLabels` | `string` | `"icon"` | open windows in the dock inside the bar: icon \| name (app name) \| title (window title) |
| `nameOnly` | `bool` | `false` | open windows show just their app's name, no icon, picture or title (dock and bar) |
| `combine` | `bool` | `false` | like Windows' "combine taskbar buttons": open apps share their icon |
| `previews` | `bool` | `true` | combined: hover an open app for a picture of each window |
| `thumbnails` | `bool` | `true` | off: open windows show only their app icon |
| `thumbRefresh` | `int` | `60` | s between still pictures (live only while hovered) |
| `widgets` | `list<string>` | `[]` | small tiles after the open windows, in order: ids of Theme.dockWidgets (clock, date, weather, media, …) |
| `pinned` | `list<string>` | `["firefox", "google-chrome", "com.microsoft.VSCode", "com...` |  |

## launcher

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `webSearch` | `string` | `"https://duckduckgo.com/?q=%s"` |  |
| `showFiles` | `bool` | `true` |  |
| `usage` | `var` | `{}` | launch counts, for ranking |
| `style` | `string` | `"theme"` | theme (the theme's own) \| spotlight \| launchpad \| drawer \| sidebar \| terminal (Launcher.qml styles) |
| `columns` | `int` | `7` | apps per row in the apps grid (fewer when the panel is too narrow) |
| `startView` | `string` | `"home"` | home (suggestions until you type, every theme) \| apps (grid) \| search (empty field) \| theme (the style's own) |
| `recent` | `list<string>` | `[]` | result keys, most recent first, for the home view |
| `order` | `list<string>` | `["apps", "files", "calc", "settings", "actions", "web"]` |  |
| `clipboardInside` | `bool` | `true` | Spotlight's clipboard button shows history in the panel |
| `position` | `string` | `"center"` | center (middle of the screen) \| pointer (around the mouse pointer) \| theme (the theme's own place) |

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
| `timeoutSec` | `int` | `6` | how long a normal popup stays (s) |
| `timeoutLowSec` | `int` | `4` | how long a low-priority popup stays (s) |
| `timeoutCriticalSec` | `int` | `0` | how long a critical popup stays (s); 0 = until dismissed |
| `maxVisible` | `int` | `4` | popups on screen at once; the rest wait in the notification centre |
| `groupByApp` | `bool` | `true` | one popup per app (with a count) and the history grouped by app |
| `showIcons` | `bool` | `true` | the app's icon or the notification's picture |
| `style` | `string` | `"theme"` | popup look: theme \| card \| bubble \| line \| block \| tag \| compact |
| `position` | `string` | `"theme"` | theme \| top-left \| top \| top-right \| bottom-left \| bottom \| bottom-right |
| `dndSchedule` | `bool` | `false` | Do Not Disturb every day between dndFrom and dndTo |
| `dndFrom` | `string` | `"22:00"` |  |
| `dndTo` | `string` | `"07:00"` |  |
| `historyMax` | `int` | `100` |  |
| `sound` | `string` | `"message-new-instant"` | normal priority: a freedesktop sound name (Notifications.sounds), "" = none |
| `soundLow` | `string` | `""` | low priority sound, "" = none |
| `soundCritical` | `string` | `"window-attention"` | critical sound, "" = none |
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
| `style` | `string` | `"panel"` | panel (current), compact (denser), borderless (flat tiles, no outlines) |
| `width` | `int` | `330` | panel width in px (280..460) |
| `sections` | `list<string>` | `[]` |  |
| `tiles` | `list<string>` | `[]` |  |
| `sliders` | `list<string>` | `[]` |  |
| `toggles` | `list<string>` | `[]` |  |
| `folded` | `list<string>` | `["screen", "sound", "power"]` | cards folded to one line (click a card's title): screen, sound, power |
| `hidden` | `list<string>` | `["colorpicker", "mission", "airplane", "clipboard", "ocr"...` |  |

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
| `inactiveOpacity` | `real` | `1` |  |
| `dimInactive` | `bool` | `false` |  |
| `dimStrength` | `real` | `0.2` |  |
| `resizeOnBorder` | `bool` | `true` |  |
| `snap` | `bool` | `false` | floating windows snap to edges and each other |
| `hideCursorTyping` | `bool` | `false` |  |
| `titleBars` | `bool` | `true` | hyprbars: title bar with buttons on apps that draw none |
| `titleBarSize` | `string` | `"theme"` | title bar height: theme (its density) \| small \| medium \| large |
| `titleButtons` | `string` | `"right"` | title bar buttons on the right or left (close outermost) |
| `titleAlign` | `string` | `"center"` | window title in the bar: center \| left |
| `border` | `string` | `"theme"` | focused window's frame: theme (its own) \| accent \| gradient (accent to accent2) \| neon (accent with a glow) \| mono (text colour) \| rainbow \| sunset \| ocean \| custom (borderColors) |
| `borderAngle` | `int` | `45` | direction of a frame of several colours, in degrees |
| `borderColors` | `list<string>` | `["#ff7a59", "#7a5cff"]` | custom frame: two or three colours like "#ff7a59" |
| `borderAnimate` | `bool` | `false` | a frame of several colours turns (needs animations on Full; costs battery) |
| `rainbowSpeed` | `int` | `5` | turning frame: 1 slow .. 10 fast |
| `rainbowOnBattery` | `bool` | `false` | a turning frame keeps turning on battery (it redraws every frame); off = it stands still |
| `apps` | `var` | `[]` | [{ id, name, class (regex), open: normal\|float\|pin\|maximize\|fullscreen, workspace: 0 = any }] |

## keybinds

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `overrides` | `var` | `{}` |  |
| `custom` | `var` | `[]` | your shortcuts: [{ keys: "SUPER + D", action: "<action id>" }]; each runs `qs ipc call actions run <id>` |

## actions

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `list` | `var` | `[]` | shown in Spotlight, bar clicks or hot corners; see docs/decisions/0002-action-registry.md |

## weather

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `locations` | `var` | `[]` | saved places [{ name, region, country, latitude, longitude }]; the first is the default |
| `units` | `string` | `"celsius"` | "celsius" (km/h) or "fahrenheit" (mph) |
| `days` | `int` | `7` | days in the forecast list (0 = no daily list) |
| `hours` | `int` | `12` | hours in the hourly strip (0 = no hourly strip) |
| `details` | `list<string>` | `["feels", "humidity", "wind", "uv", "rain", "sun"]` | readings under the current conditions, in order |
| `refreshMin` | `int` | `15` | minutes between updates |

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
| `clock24` | `bool` | `true` | 24-hour time: the lock screen's, and a bar clock's until it has its own h24 |
| `seconds` | `bool` | `false` | seconds: the dock clock's hand, and a bar clock's until it has its own |
| `batteryPercent` | `string` | `"beside"` | the battery's percentage: inside (the icon) \| beside \| off |
| `windowTitle` | `bool` | `true` | the focused window's title after the app name |
| `items` | `var` | `{}` | item or copy ("clock", "clock#2") -> its settings (docs/bar.md) |
| `preset` | `string` | `"theme"` |  |
| `presets` | `var` | `{ minimal: { start: ["controls", "launcher", "workspaces"...` |  |
| `layout` | `var` | `{}` |  |
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
| `blur` | `int` | `0` | desktop only (a blurred copy in ~/.cache; for a video its still frame, not the video); 0 = sharp |
| `livePause` | `string` | `"fullscreen"` | a video wallpaper pauses behind "fullscreen" windows or any "windows" on its workspace |
| `liveOnBattery` | `bool` | `false` | a video wallpaper plays on battery too (about doubles idle power); off = paused |

## idle

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `lockMin` | `int` | `5` | minutes to lock; 0 = never |
| `sleepMin` | `int` | `20` | minutes to sleep on battery (the only value used without a battery counts as sleepOnPowerMin); 0 = never |
| `sleepOnPowerMin` | `int` | `0` | minutes to sleep on mains power; 0 = never |
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
| `newScreen` | `string` | `"right"` | a screen with no saved layout: right \| left \| above \| below (of the others) \| mirror |
| `imported` | `bool` | `false` |  |

## workspaces

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `mode` | `string` | `"dynamic"` | dynamic: made when needed on the screen you're on \| fixed: always there, each on its screen |
| `count` | `int` | `10` | fixed: how many (Super+1..0 reach the first ten) |
| `screens` | `var` | `{}` | fixed: workspace number -> output name; missing = the screen you're on |

## capture

| Setting | Type | Default | What it does |
| --- | --- | --- | --- |
| `folder` | `string` | `"~/Pictures/Screenshots"` |  |
| `recordFolder` | `string` | `"~/Videos/Recordings"` |  |
| `after` | `string` | `"edit"` | after a region/window/screen capture: edit (annotate in Satty) \| copy \| save (and copy) |
| `delay` | `int` | `0` | seconds before a full-screen capture |
| `audio` | `string` | `"none"` | recordings: none \| desktop \| mic |
| `notify` | `bool` | `true` | a notification with the picture after each capture |

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
