# ADR 0001: the bar stays on Quickshell

Date: 2026-11-11. Status: proposed (waits for the owner's OK at the audit checkpoint).

## Question

The brief asks for a fully modular bar with per-item settings, presets, per-monitor layouts and a system-info
module, edited from one config file and from the Settings app. Which technology?

## Options

| | Quickshell (now) | Waybar | AGS / Astal | eww |
|---|---|---|---|---|
| Already here | yes: bar, dock, panels, Settings, 16,500 lines | no | no | no |
| Modularity | one file per item is plain QML (`Loader` by id) | modules in one JSON + CSS + scripts | components in TypeScript | widgets in its own language |
| Settings app talks to it | same process, same `settings.json`, live | restart or signal on every change | separate process, needs a bridge | separate process |
| Theme tokens | shared live with every panel | CSS generated per change | generated | generated |
| Per-monitor bars | yes (one window per screen) | yes | yes | manual |
| Idle cost | measured 0.40 % of a core for the whole shell | low, plus one process per custom script | a JS runtime | low |
| New dependencies | none | waybar + a script per metric | gjs / node tooling, AUR on Arch | AUR on Arch, slow upstream |
| In Arch and Fedora repos | Arch extra; Fedora via the COPR already used | both | no | no |

## Decision

Keep Quickshell. Switching would add a dependency, split the theme into two systems, make the Settings app talk
to a second process, and throw away a working bar engine, with no gain a user can see. The gaps the audit found
(items with no settings of their own, no presets, three fixed metrics) are about how the items are organised, not
about the toolkit.

## What changes instead

- Each item becomes a folder: `bar/items/<id>/` with `Item.qml`, `defaults.json` and `README.md`.
- The item list is built from those folders, not from the theme file.
- `settings.json` gains `bar.items.<id>` (enabled, section, order, icon, format, interval, actions, tooltip,
  thresholds), `bar.presets` and `bar.monitors`.
- One `Metrics` service with a registry replaces the two sensor readers; the system-info item shows any registry
  entries the user picks.

## Trade-offs accepted

- Quickshell is younger than Waybar and its Fedora package comes from a COPR. Mitigation: CI installs it on both
  distros on every push.
- Contributors need QML rather than JSON + CSS. Mitigation: the item README template and a ten-line example item.
