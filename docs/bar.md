# The bar

One bar engine draws every theme's bar, on any screen edge. What sits in it is a list of **items**. Each item is
its own small folder, and each has its own settings.

## Where things are

| What | Where |
|---|---|
| An item | `config/quickshell/.config/quickshell/bar/items/<id>/` |
| Which items are in the bar, and in which section | Settings → Menu Bar (`bar.layout` in `settings.json`; the theme's own list until you edit) |
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

## The same item more than once

Every item can sit in the bar as often as you like (only the dock, `apps`, is one of a kind). Each copy is an
**instance** with settings of its own: the first is the plain id (`clock`), the next ones are `clock#2`, `clock#3`…
In Settings → Menu Bar → "Add to the bar", an item already on the bar is added again as a new copy, and Selected item
edits only the copy you picked. A copy's settings go when it leaves the last list it was on.

```json
"bar": {
  "layout": { "start": ["clock#2"], "center": [], "end": ["sysinfo", "sysinfo#2", "clock"] },
  "items": {
    "clock":     { "seconds": true },
    "clock#2":   { "time": false, "weekday": "long", "month": "long", "year": true },
    "sysinfo#2": { "metrics": ["cpu_freq", "cpu_temp"], "mode": "detailed" }
  }
}
```

The ids work the same in `bar.monitors` and `bar.presets`. Copies that open a panel each open it beside themselves,
and only the one that opened it lights up.

## The clock

What each clock shows: time on or off, 24-hour, seconds, date on or off, weekday / day / month / year, which comes
first and what goes between, or a Qt date pattern of your own (`"ddd d MMM, HH:mm"`). Settings → Menu Bar → Selected
item has the switches and a live preview; the keys are in
[the clock's README](../config/quickshell/.config/quickshell/bar/items/clock/README.md). `bar.clock24` and
`bar.seconds` are what a clock uses until it has its own (`bar.clock24` is also the lock screen's).

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

**Actions:** `"default"` (the item's own behaviour), `"none"`, `"action:<id>"` (any action of Settings → Actions:
a built-in such as `action:dnd` or one of yours), `"panel:<name>"` (`controlcenter`, `launcher`,
`notifications`, `calendar`, `weather`, `system`, `power`, `clipboard`, `cheatsheet`; same as `action:panel-<name>`),
`"settings:<page>"`, `"volume"`, `"brightness"` (for scroll), and `"run:<command>"` for a command of your own
(a failure shows a notification).

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
Readings: per-core CPU, frequency, load, temperature, memory, swap, disk space and disk I/O, network, GPU use, shared GPU memory (an integrated GPU's memory is shown without a warning), dGPU state (a sleeping card shows "Sleeping" and is never woken), battery watts, fans (`metrics list` prints the names). `cpu`, `memory` and `gpu` are single-reading items on the same service; `sysinfo` combines them and more (its settings page has a switch, order and warn / only-above levels per reading). Readings come from one small program,
`metrics` (`metrics once` prints them all as JSON), which runs only while a bar shows one of them.

## One layout, starting points and screens

The bar is one layout for every screen and every theme: `bar.layout` holds its items, edge, size, floating and the
dock's place. Until you change something it is empty and the bar follows the theme; your first edit in
Settings → Menu Bar (or Settings → Dock → Position) copies what is on screen into it. "Use the theme's" empties it again.

| Key (`bar` in `settings.json`) | What it does |
|---|---|
| `layout` | `{ "edge": "top", "size": 34, "floating": true, "dock": "bar", "start": [ids], "center": [ids], "end": [ids] }`; `{}` = the theme's own. `size` is any px (Settings: Slim 26, Regular 34, Tall 44, Huge 56, or 24–56 on the slider). `dock` is `bar` or an edge. It survives theme switches |
| `presets` | the "Start from" buttons in Settings → Menu Bar: name → `{ "start": [ids], "center": [ids], "end": [ids] }`. A click copies the items into the layout; nothing stays linked |
| `monitors` | screen name → `{ "start": [ids], "center": [ids], "end": [ids] }`, that screen's own items (`bar.monitors`) ("Its own items" in Settings → Screens). Older files named a preset here; that still reads |
| `hiddenOn` | screens without a bar ("No bar" in Settings → Screens) |

Built in (an older file gets any that are missing back; one you edited is never overwritten):

| Preset | start | center | end |
|---|---|---|---|
| `minimal` | controls, launcher, workspaces | clock | status, battery, power |
| `full` | controls, launcher, workspaces, window | clock, date, weather | sysinfo, media, updates, tray, keyboard, notifications, status, battery, power |
| `laptop` | controls, launcher, workspaces | clock | sysinfo, brightness, power-profile, updates, keyboard, notifications, status, battery |
| `external` | controls, launcher, workspaces, window | clock, date | sysinfo, weather, media, updates, tray, notifications, status, power |

An id that isn't an item is skipped. Example, a laptop with an external monitor:

```json
"bar": {
  "monitors": { "DP-1": { "start": ["launcher", "workspaces"], "center": ["clock"], "end": ["tray"] } }
}
```

`DP-1` shows its own three lists; every other screen follows `layout`. Settings → Menu Bar → Item settings edits the settings
above for any item in the layout.
