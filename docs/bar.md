# The bar

One bar engine draws every theme's bar, on any screen edge. What sits in it is a list of **items**. Each item is
its own small folder, and each has its own settings.

## Where things are

| What | Where |
|---|---|
| An item | `config/quickshell/.config/quickshell/bar/items/<id>/` |
| Which items are in the bar, and in which section | Settings → Menu Bar (kept per theme in `settings.json`, `appearance.custom`) |
| Your settings for one item | `~/.config/quickshell/settings.json`, under `bar` → `items` → `<id>` |
| An item's default settings | its `defaults.json` |

Settings → Menu Bar and the file are the same thing: the app writes `settings.json`, and the shell reloads the
file when you edit it by hand.

## An item's folder

```
bar/items/weather/
  Item.qml         what it draws
  defaults.json    its name and glyph for Settings, and its default settings
  README.md        what it shows and which settings it has
```

Nothing else lists the items: a folder with `Item.qml` and `defaults.json` is an item.

## Settings every item understands

Put them under `bar.items.<id>` in `settings.json`. Leave one out to keep the item's default.

| Setting | Values | What it does |
|---|---|---|
| `enabled` | `true` / `false` | `false` hides the item everywhere |
| `icon` | one glyph | Another icon instead of the item's own |
| `format` | text with `{value}` and `{word}` | Your own label, for example `"{value} outside"` |
| `click` | an action | What a click does |
| `rightClick` | an action | What a right-click does (nothing by default) |
| `scroll` | an action | What the scroll wheel does |
| `tooltip` | `true` / `false` | `false` turns the hover hint off |
| `warn` | a number | At or above it, the item turns amber and gains a `!` |
| `critical` | a number | At or above it, the item turns red and gains `!!` |
| `interval` | seconds | How often an item that measures something reads again |

**Actions:** `"default"` (the item's own behaviour), `"none"`, `"panel:<name>"` (`controlcenter`, `launcher`,
`notifications`, `calendar`, `weather`, `system`, `power`, `clipboard`, `cheatsheet`), `"settings:<page>"`,
`"volume"`, `"brightness"` (for scroll), and `"run:<command>"` for a command of your own.

Example:

```json
"bar": {
  "items": {
    "weather":    { "format": "{value} outside", "click": "panel:calendar", "warn": 30 },
    "brightness": { "enabled": false },
    "power":      { "rightClick": "run:loginctl lock-session" }
  }
}
```

Or from a terminal:

```bash
qs ipc call config set bar items '{"weather":{"warn":30}}'
```

## Add an item

1. Copy `bar/items/_template/` to `bar/items/<id>/` (lower-case, no leading underscore).
2. `Item.qml`: set `glyph`, `word`, `value` and what a click does. Set `level` if `warn` / `critical` should apply.
3. `defaults.json`: its name, glyph and default settings. `README.md`: two lines on what it shows.
4. `./install.sh --only links`, then add it to a section in Settings → Menu Bar.

## System readings

The `sysinfo` item shows any readings you pick, in your order: see
[its README](../config/quickshell/.config/quickshell/bar/items/sysinfo/README.md) for the list and its settings.
`cpu`, `memory` and `gpu` are single-reading items on the same service. Readings come from one small program,
`metrics` (`metrics once` prints them all as JSON), which runs only while a bar shows one of them.

## Presets and screens

A preset is a named layout: which items sit in `start`, `center` and `end`. Settings → Menu Bar → Layout picks one,
and "Save current layout as…" keeps the layout shown in the editor under a name of your own (letters, digits and
dashes). With a preset chosen, the editor changes that preset; with "Theme's own" it changes the theme's layout.

| Key (`bar` in `settings.json`) | What it does |
|---|---|
| `preset` | `"theme"` (default): the theme's own layout. Any other value names an entry of `presets` |
| `presets` | name → `{ "start": [ids], "center": [ids], "end": [ids] }` |
| `monitors` | screen name → preset name. A screen not listed, or set to `""`, follows `preset` |
| `hiddenOn` | screens without a bar ("No bar" in Settings → Screens) |

Built in (an older file gets any that are missing back; one you edited is never overwritten):

| Preset | start | center | end |
|---|---|---|---|
| `minimal` | launcher, workspaces | clock | status, battery, power |
| `full` | launcher, workspaces, window | clock, date, weather | sysinfo, media, tray, keyboard, notifications, status, battery, power |
| `laptop` | launcher, workspaces | clock | sysinfo, brightness, power-profile, keyboard, notifications, status, battery |
| `external` | launcher, workspaces, window | clock, date | sysinfo, weather, media, tray, notifications, status, power |

An id that isn't an item is skipped. Example, a laptop with an external monitor:

```json
"bar": {
  "preset": "laptop",
  "monitors": { "DP-1": "external" }
}
```

`eDP-1` follows `preset` (`laptop`); `DP-1` shows `external`. Settings → Menu Bar → Item settings edits the settings
above for any item in the layout.
