# Redesign plan: rices

Status: **proposal, waiting for approval** (2026-11-04). Nothing below is built yet.

## Why the last pass failed

It changed colours, not design. Five "neon themes" were the same bar, the same dock, the same
panels and the same glass, repainted, with a glow on top. A real setup (Omarchy, HyDE, ML4W, the
Hyprland Hall of Fame) changes the **structure** from look to look: where the bar is and what shape it
has, whether there's a dock, how the launcher is laid out, the typefaces, the corners, how windows
sit and how things move.

## The idea: a rice is a whole desktop

A **rice** bundles every decision that makes a desktop look like itself. Switching rice (`rice NAME`,
or Settings → Rices) swaps all of them at once, live:

| Layer | What a rice decides |
|---|---|
| Layout | Bar: top / bottom / **left rail** / **none**; attached, floating or islands; which modules where. Dock: none / bottom / side. Dashboard: on or off. |
| Workspaces | Indicator: numbers, dots, blocks, bars, rail squares |
| Launcher | Command list / centred panel with greeting / full-height drawer / full-screen poster grid |
| Notifications | Corner, shape (block, card, pill, text-only) |
| Type | UI face, display face (clock, greeting, lock), mono face |
| Shape | Corner radius (0 … 22), border style (none / 1px / thick / double), gaps |
| Surface | Flat solid, tonal panel, or glass + blur (only where the rice is about glass) |
| Colour | Its own palette (ground, surface, raised, text, muted, accent, status), dark or light |
| Windows | Hyprland gaps, border width and colours, rounding, shadow (none, soft, hard offset), blur on/off |
| Motion | Hyprland animation preset (instant, snappy slide, gentle spring, poster slam) + shell durations |
| Lock screen | Its own hyprlock design |
| Wallpaper | Its own, drawn in code for the rice (ImageMagick/SVG), so nothing is downloaded or borrowed |
| Apps | Ghostty palette + font, GTK light/dark + accent, cursor, icons |

User tweaks (Settings) apply **on top of** the active rice and survive a rice switch only where they
are personal (keyboard, monitors, power, apps). Look settings reset to the rice's own.

## What gets removed

- The 5 neon colour themes, `NeonEdge`, the "Neon" tints/designs, the neon notification and lock
  designs, the palette preview page (all from this branch).
- The 13 calm colour-only themes and the accent palette picker: colour now belongs to a rice. A rice
  can still offer variants (e.g. light/dark) where it makes sense.
- Per-surface "design galleries" that only recolour (Menu Bar / Dock / Launcher designs): replaced by
  the rice's own layout, with a few real per-surface options kept (bar position, dock on/off).

## What stays (function, not look)

Settings app pages for system things (displays, network, Bluetooth, sound, power, ASUS, keyboard,
input, idle, apps, startup, clipboard, keybinds), Control Center logic, notifications backend,
clipboard, calendar/weather data, Mission Control, screenshot tool, monswitch, install logic.
These get restyled through tokens; their behaviour doesn't change.

## The six rices (concepts: docs/rice-concepts.html)

| Rice | Bar | Launcher | Dock | Windows | Type · colour | Motion |
|---|---|---|---|---|---|---|
| **Monolith** | bottom, attached, text only | command strip on the top edge | none | radius 0, 2px frame, 2px gaps | JetBrains Mono · #0b0c0a / lime #b6ff3b | near-instant |
| **Folio** (light) | left rail: serif clock, i–iv workspaces | centred card with a typeset greeting | none | radius 4, hairline, 12px gaps | Instrument Serif + IBM Plex Sans · stone / ultramarine | slow ease-out |
| **Console** | none: top readout + corner brackets, dashboard on Super+D | centred readout panel | none | radius 0, 1px amber on focus | Martian Mono · blue-black / amber | crisp, flicker-in |
| **Pebble** | three floating pills, stretching dots | rounded panel with app grid | floating | radius 18, soft shadow, glass | Outfit · dusk violet / peach / sea green | springy |
| **Workstation** | bottom taskbar: start, search, tasks, clock | start menu from the corner | the taskbar | radius 8, title bars (hyprbars) | IBM Plex Sans · slate / blue | quick ease |
| **Poster** | top, paper white, huge workspace numbers | half-screen cobalt field, huge query | none | radius 0, 3px black frame, hard offset shadow | Archivo Black + Archivo · charcoal / red / cobalt | slam-in |

Research behind them: docs/RESEARCH.md (Omarchy, HyDE and ML4W vary colour per theme but not structure;
the Hall of Fame winners carry a whole idea through layout, art and motion).

## Architecture

```
config/quickshell/.config/quickshell/
  rices/<id>.json          one file per rice: tokens + layout + hyprland + apps (data, no code)
  Rice.qml                 singleton: loads the active rice, exposes tokens (replaces Theme's palette part)
  Theme.qml                derives everything from Rice (kept as the one place components read)
  layouts/
    TopBar.qml             horizontal bar (attached / floating / islands), from today's Bar.qml
    RailBar.qml            NEW vertical rail (left or right): workspaces, clock, status, pinned apps
    Corner.qml             NEW minimal corner pill for bar-less rices
    Dashboard.qml          NEW full dashboard panel (clock, calendar, media, system, toggles)
    workspaces/*.qml       indicators: Numbers, Dots, Blocks, RailSquares
  launchers/
    CommandList.qml        mono list at the top (Monolith)
    Drawer.qml             full-height side drawer (Console)
    Greeting.qml           centred panel with a typeset greeting (Editorial)
    PosterGrid.qml         full-screen grid with huge type (Poster)
config/hypr/.config/hypr/
  rices/<id>.lua           Hyprland look + animation preset per rice (sourced by look.lua)
  lockscreens/<id>.conf    one lock design per rice
config/ghostty/.config/ghostty/themes/<Rice>   terminal palette per rice
config/wallpapers/…/rices/<id>.png             generated by scripts/rice-wallpapers (ImageMagick), committed
config/scripts/.local/bin/rice                 `rice` lists, `rice NAME` switches (like `theme` today)
```

`ThemeSync.qml` keeps its job: push the active rice to Hyprland (`hyprctl eval` + `settings/rice.lua`),
hyprlock, GTK, Ghostty, fuzzel, Satty selection colour, wallpaper.

## Plugins (hypr.land/plugins)

Only plugins that change how the desktop feels, built with `hyprpm` by `hypr-plugins` (already used
for the title-bar minimise plugin). Each rice lists the plugins it wants; a missing plugin only means
that effect is off, never a broken session. Shortlist pending the research notes; candidates:
`hyprexpo` (workspace overview grid), `borders-plus-plus` (double borders for the Poster rice),
`hyprtrails`/`hyprfocus` (motion accents, Orbit only), `hyprbars` (title bars where a rice wants them).

## Phases (each ends with a live check, screenshots of both monitors and a commit)

1. **Strip**: remove the neon layer and colour-only themes; Theme reads from a Rice singleton with
   one rice (today's Graphite Glass, as "Glass"), so nothing visually breaks.
2. **Rice engine**: rice JSON schema + loader + `rice` command + Settings → Rices gallery with live
   previews; Hyprland side (`rices/<id>.lua`), Ghostty, GTK, lock, wallpaper sync.
3. **New layout pieces**: RailBar, Corner, Dashboard, workspace indicators, four launcher layouts,
   notification corners/shapes.
4. **The rices**, one at a time, each designed to its direction sheet and checked on screen:
   fonts installed and recorded in packages, wallpaper generated, lock design, terminal palette.
5. **Plugins** chosen per rice, added to `hypr-plugins`, documented.
6. **Polish and proof**: every rice on both monitors (1.2× laptop, 1× Acer), tablet mode, light/dark
   where offered, keyboard-only use, cheatsheet, Settings pages restyled; independent review; docs
   (DESIGN.md rewritten around rices, README rice table, AUDIT update).

Rules carried over: free/open source only, fonts and plugins recorded in `packages/`, nothing copied
from other dotfiles, KDE untouched, login never at risk (a broken rice falls back to Glass).
