# ADR 0003: screens are saved by description

Date: 2026-11-17. Status: accepted.

## Question

Layouts, workspace screens and "no bar / no dock here" were saved by connector name (`HDMI-A-1`). A dock, a
different USB-C port or a second monitor on the same port type then got the wrong layout. What identifies a screen?

## Decision

- A screen is saved under its **description** (`make model serial`, what Hyprland and Quickshell report). It follows
  the monitor to any port.
- When the description is empty, or two connected screens share it (two identical monitors without a serial), the
  **connector name** is used for those screens. `Displays.keyOf` decides; `Displays.matches(key, screen)` answers
  "does this saved key mean this screen?" for the bar, the dock and the workspace page.
- settings.json is the source. `SettingsSync` writes `displays.lua` from it; `monitors.lua` resolves each key.
- Settings format 7 renames the keys of `displays.layout`, `workspaces.screens`, `bar.hiddenOn` and
  `dock.hiddenOn` for the screens connected at that moment. Unknown connectors stay as they are. It waits until
  Hyprland has listed the screens. `bar.monitors` (a bar's own items for one screen) stays by connector name.

## Spike: `desc:` in Lua

`hl.monitor({ output = "desc:<description>" })` is accepted by Hyprland 0.57.2 without an error. The nested test
screens have empty descriptions, so a match on a real description could not be shown there (an empty description
matched every screen). So `monitors.lua` resolves in Lua: it looks through `hl.get_monitors()` (each has `name`
and `description`) and uses the connector. `get_monitors()` leaves out screens that are off or mirroring; for
those a key with a space falls back to `desc:<key>`, a plain word is taken as a connector. Not yet checked
against a real monitor.

## Consequences

- Presets (`displays.presets`) and auto-switch use the same keys.
- `laptop_panel()` and the `monswitch` hand-off (`SHARED`, a connector name) are unchanged for callers.
- Two identical monitors share the connector fallback, so swapping their cables swaps their layouts. Nothing in
  the description can tell them apart.
