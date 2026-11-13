# How do I change...

Each entry gives the Settings way (`Super+I`, then page → row) and the file or command way. The file is
`~/.config/quickshell/settings.json`; the shell reloads it when you save it. A key you leave out keeps its default
(defaults: `config/quickshell/.config/quickshell/ConfigData.qml`). A bad value is ignored and the shell logs why
(see [troubleshooting.md](troubleshooting.md)).

A one-line way to set a key from a terminal: `qs ipc call config set SECTION KEY 'JSON'`, for example
`qs ipc call config set bar hiddenOn '["DP-1"]'`.

`<theme>` below means the id of the theme in use, for example `reactor`.

## Look

**The theme.** Settings → Appearance → Themes. Or `theme` (lists them) and `theme atlas`. File: `appearance.theme`.

**Light or dark.** Settings → Appearance → Themes → Light or dark. File: `appearance.mode` = `"theme"` (each theme's
own), `"light"` or `"dark"`.

**The accent colour.** Settings → Appearance → Themes → Adjust → Accent colour. File:
`appearance.custom.<theme>.accent` = `"#ff9e7a"`. It is kept per theme.

**My own theme.** Settings → Appearance → Theme Builder (no files). Or copy a folder:
`cp -r ~/.local/share/hyprism/themes/_template ~/.config/hyprism/themes/mine`, edit `theme.json`, run `theme mine`.
See [THEMES.md](THEMES.md).

**The wallpaper.** Settings → Appearance → Wallpaper (folders, slideshow, blur). File: `wallpaper.folders`
(list of folders), `wallpaper.current` (one picture), `wallpaper.slideshow`, `wallpaper.interval` (minutes).
`appearance.wallpaper` = `false` keeps your wallpaper instead of the theme's own.

**Font and text size.** Settings → Appearance → Themes → Adjust → Font, Text size, Scale all text. File:
`appearance.custom.<theme>.font`, `appearance.custom.<theme>.size` (px), and `appearance.fontScale` (1 = normal).

**The cursor.** Settings → Appearance → Cursor (theme, size, add a theme). File: `appearance.cursorTheme`,
`appearance.cursorSize`.

## The bar and the dock

**Which items are in the bar.** Settings → Menu Bar → Items (drag between start, centre and end). File:
`appearance.custom.<theme>.barItems` = `{ "start": [...], "center": [...], "end": [...] }`, or pick a preset with
`bar.preset`. Item ids: the folder names in `config/quickshell/.config/quickshell/bar/items/`.

**One item's icon, label, click, warn level.** Settings → Menu Bar → Item settings. File: `bar.items.<id>`:

```json
"bar": { "items": { "weather": { "icon": "", "format": "{value} outside", "click": "panel:calendar", "warn": 30 } } }
```

All keys: [bar.md](bar.md).

**The system-info readings.** Same page, item `sysinfo`. File: `bar.items.sysinfo.metrics`, for example
`["cpu", "cpu_temp", "ram"]`; also `mode`, `interval`, `onlyAbove`, `thresholds` (levels per reading, set on the same page). The list of readings:
[the sysinfo README](../config/quickshell/.config/quickshell/bar/items/sysinfo/README.md).

**A different bar on my second screen.** Settings → Menu Bar → Screens. File: `bar.monitors` =
`{ "DP-1": "external" }` (screen name → preset; presets are in [bar.md](bar.md)).

**Hide the bar on one screen.** Settings → Menu Bar → Screens. File: `bar.hiddenOn` = `["DP-1"]`. Screen names:
`hyprctl monitors`.

**The bar on another edge.** Settings → Menu Bar → Place → Position. File: `appearance.custom.<theme>.barEdge` =
`"top"`, `"bottom"`, `"left"` or `"right"`.

**The dock on or off, pinned apps.** Settings → Dock (Show the dock, Pinned apps). File: `dock.enabled`,
`dock.pinned` (desktop entry ids), `dock.hiddenOn` (screens without a dock), `dock.autoHide`. Its place:
`appearance.custom.<theme>.dock` = `"bar"`, `"bottom"`, `"left"`, `"right"` or `"top"`.
Inside the bar only Open windows, Combine, Show open apps and Pinned apps apply; Settings → Dock hides the rest.
**Dock widgets.** Settings → Dock → Widgets (floating dock only). File: `dock.widgets`, ids in order: `clock`, `date`,
`weather`, `media`, `volume`, `battery`, `load`, `network`, `screenshot`, `trash` (right-click twice to empty),
`downloads`. Each reads only while it is on the dock.

## Keys, input, screens

**A keyboard shortcut (rebind, disable).** Settings → Input → Keyboard Shortcuts: click a shortcut's keys and
press new ones. File: `keybinds.overrides.<id>` = `{ "keys": "SUPER + K" }`; `"keys": ""` turns it off. The `<id>`
is the first word of each `add(...)` line in `config/hypr/.config/hypr/modules/binds.lua`. Mouse and hardware-switch
binds are fixed.

**A keyboard layout and the switch key.** Settings → Input → Keyboard & Touchpad → Keyboard layouts, Switch layouts
with. File: `input.layouts` = `[{ "code": "us", "variant": "" }, { "code": "de", "variant": "" }]` (up to 4),
`input.shortcut` = 0 Alt+Shift, 1 Ctrl+Shift, 2 Caps Lock, 3 none. `Super+Ctrl+Space` always works.

**Touchpad options.** Settings → Input → Keyboard & Touchpad → Touchpad. File: `input.naturalScroll`,
`input.tapToClick`, `input.disableWhileTyping`, `input.clickMethod` (`"clickfinger"` or `"buttonareas"`),
`input.scrollFactor`, `input.middleEmulation`, `input.dragLock`, `input.sensitivity`.

**Screen arrangement, scale, refresh rate, adaptive sync.** Settings → Displays → Screens (arrange, Resolution,
Refresh rate, Scale, Rotation) and → Advanced. File: `displays.layout.<screen>` =
`{ "mode": "2560x1440@144", "position": "0x0", "scale": 1, "transform": 0 }`; `displays.vrr` = `"off"`, `"on"`
or `"fullscreen"`; `displays.preferHighRefresh`.

**Lock and sleep times.** Settings → Power → Lock & Sleep. File: `idle.lockMin`, `idle.sleepMin` (on battery), `idle.sleepOnPowerMin` (plugged in; a desktop uses only this one) (minutes, 0 = never).

**Default apps.** A fresh install sets a file manager, browser, text editor, image and PDF viewer only where none is set (`./install.sh --only defaults`). Settings → Apps → Default Apps (browser, files, PDF, text, images, task manager). Command:
`xdg-settings set default-web-browser firefox.desktop`; `xdg-mime default org.kde.dolphin.desktop inode/directory`.
The **terminal** the `Super+Enter` key opens has no row in Settings: set `apps.terminal` in the file (plain text
only, for example `"ghostty +new-window"`).

**Startup apps.** Settings → Apps → Startup Apps. Command: `startup-apps add org.kde.dolphin` (a desktop entry id),
`startup-apps list`, `startup-apps remove FILE`. They live in `~/.config/autostart/`, not in `settings.json`.

**Notifications and Do Not Disturb.** Settings → Desktop & Widgets → Notifications. Key `Super+Shift+N`. File:
`notifications.dnd`, `notifications.timeoutSec`, `notifications.mutedApps`.

**Night light.** Settings → Displays → Screens → Night Light. File: `nightLight.mode` = `"off"`, `"on"`, `"sun"` or
`"schedule"`; `nightLight.temperature` (K), `nightLight.from`, `nightLight.to`.

**The on-screen display.** Settings → Desktop & Widgets → Notifications → On-screen display. File: `osd.volume`,
`osd.brightness`, `osd.micMute`, `osd.layout`, `osd.capsLock`, `osd.position` (`"bottom"`, `"top"`, `"center"`),
`osd.timeoutMs`.

## Power and hardware

**Power mode.** Settings → Power → Battery & Power → Power mode, or the Control Center. Key `Super+F5`. Command:
`powermode quiet|balanced|performance`.

**Battery charge limit.** Only where the `asus` module is on: Settings → Power → Battery & Power → Charge limit (60,
80 or 100 %). Command: `asusctl battery limit 80`. Other laptops: no row (the code gives none).

**Share a monitor with another computer.** Needs the `ddc-monitor` module. Settings → Displays → Shared Monitor,
which lists the inputs the monitor reports. Without the Settings app: `monswitch setup` asks the same questions in a terminal.
File: `monitorShare.enabled`, `monitorShare.output`, `monitorShare.thisInput`, `monitorShare.otherInput`. Key `Super+M`
hands it over.

**Run an app on the second graphics card.** `nv APP`, for example `nv blender`. For a Steam game, put
`nv %command%` in its launch options.

**Turn a hardware module on or off.** `./install.sh --with NAME` or `--without NAME`, then `./install.sh`.

**Correct a wrong hardware guess.** Add a line under `[override]` at the end of `~/.config/hyprism/hardware.toml`,
for example `display.internal = "eDP-2"` or `module.tablet = false`. Detection never changes that part.

## Starting over

**Reset one page or everything.** One page: its **Reset to defaults** button. Everything Settings wrote:

```bash
desktop-reset
```

Only the shell (theme, bar, dock, panels): `desktop-reset shell`. Your files are moved to
`~/.local/state/hyprism/reset-<time>/`, not deleted; copy one back to undo.
