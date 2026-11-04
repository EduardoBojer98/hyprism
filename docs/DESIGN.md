---
name: Rices
description: Thirteen whole-desktop designs for Hyprland + Quickshell. A rice changes structure, not just colour.
source: config/quickshell/.config/quickshell/Rices.qml (data), Theme.qml (tokens), ThemeSync.qml (Hyprland, hyprlock, GTK, Ghostty, wallpaper)
default: pebble
---

# Rices

## Idea

Most desktop "themes" (Omarchy, HyDE, ML4W) repaint the same layout. A rice here is a whole design:
where the bar is and what shape it has, whether there's a dock, how the launcher works, the
typefaces, the corners, the window frames, the shadow, the motion, the notification style, the lock
screen, the terminal palette and the wallpaper. The 13 rices share one engine and every component,
so a new rice is mostly data. Concepts as drawn before building: `docs/rice-concepts.html`.

The design rules came from the taste-skill's app-screen study (colour on state not chrome, flat tone
steps instead of lines and shadows, real type sizes, no ornament for its own sake) and from what the
Hyprland Hall of Fame entries do well (one idea carried through layout, type and motion).

## Anatomy of a rice (`Rices.qml`)

| Part | Values |
|---|---|
| `colour` | ground, surface, raised, line, text, muted, faint, accent, onAccent, accent2, ok, warn, err |
| `font` | ui, display (clocks, big numbers, titles), mono, size (body px), displayWeight |
| `shape` | radius, radiusSmall, line (panel border px), material: `solid` or `glass` |
| `bar` | kind (13 layouts in `Bar.qml`), edge, size, ws (workspace indicator in `BarWs.qml`) |
| `launcher` | placement (center, strip, corner, half, column, island, fullscreen), view (list, grid, start, inline), header (none, query) |
| `notify` | corner, kind (bubble, card, toast, paper, line, block, tag, subtitle) |
| `hypr` | gapsIn, gapsOut, border, rounding, active/inactive frame colours, shadow (none, soft, paper, hard), blur, motion |
| `lock`, `term`, `wall` | hyprlock design, Ghostty palette, `rice-wallpaper` design |

`Theme.qml` turns the active rice (plus your adjustments) into the tokens every component reads,
under the same names as before (`Theme.accent`, `Theme.radius`, `Theme.font`, …), so no component
knows which rice is on.

## The rices

| Rice | Ground / text / accent | Type | Shape | Bar | Motion |
|---|---|---|---|---|---|
| Pebble | `#16141f` / `#ece8f6` / `#ff9e7a` (+ `#9ad1c0`) | Outfit | r18, glass | three floating pills, dots | spring |
| Monolith | `#0b0c0a` / `#d7ddcc` / `#b6ff3b` | JetBrains Mono | r0, 2px frame | bottom text strip, filled numbers | instant |
| Console | `#05080f` / `#e9dcc0` / `#ffb000` | Martian Mono | r0, 1px | top readout + corner brackets | crisp |
| Workstation | `#0f1419` / `#e6edf3` / `#3b82f6` | IBM Plex Sans | r8 | bottom taskbar | ease |
| Poster | `#141414` / paper `#f4f1ea` / `#ff3b1f` (+ `#2d5bff`) | Archivo Black + Archivo | r0, 3px, hard shadow | paper bar, huge blocks | slam |
| Glass | `#141821` / `#f3f4f8` / `#5b9cff` | IBM Plex Sans | r12, glass | translucent menu bar + dock | ease |
| Canvas | `#1d1d20` / `#ffffff` / `#3584e4` | Cantarell | r14, no frame | black bar, centred clock | ease |
| Atlas | `#f2f2f0` / `#111111` / `#e30613` | Archivo | r0, 2px black | black rail on the right, squares | snappy |
| Noir | `#0d0d0d` / `#e9e4da` / `#f2d48a` | Fraunces + IBM Plex Sans | r0, hairline | letterbox bands, roman numerals | fade |
| Garden | `#141c16` / `#eef2e6` / `#9fd18b` (+ `#e8efe0`) | Outfit | r14 | one pale capsule at the bottom | spring |
| Zen | `#111113` / `#e8e8ea` / `#e8e8ea` | IBM Plex Sans | r10, no frame, wide gaps | the time and dots in the corner | ease |
| Mist | `#f3f3f1` / `#1a1a1a` / `#1a1a1a` | IBM Plex Sans | r6, hairline | one thin top line, ticks | ease |
| Halo | `#0e0f12` / `#eceef2` / `#8ab4ff` | Outfit | r16 | one small pill at the bottom | spring |

Measured contrast (WCAG 2): body text on surfaces 13.2:1 or more in every rice; secondary text 5.9:1
or more; text on an accent fill is forced to 4.5:1 or more by the engine (`Rices.resolve`), which
swaps in dark or light text when a rice's (or your) accent needs it.

## Rules

1. **Structure first, colour second.** A new rice earns its place by a different layout or behaviour,
   not a different palette. Palette-only variations go in Adjust, not in the list.
2. **Colour marks state.** The accent appears on the current workspace, selection, toggles that are
   on, the focused window's frame and the one thing to press. Panels stay in tone steps.
3. **Tone steps, not ornament.** Surfaces separate by ground → surface → raised. Lines only where the
   rice is about lines (Monolith, Atlas, Poster). Glass only in the rices about glass (Pebble, Glass).
4. **Type does the work.** Each rice has one UI face and at most one display face; numbers use
   tabular figures. Display faces are for the clock, the launcher query and lock-screen titles.
5. **Status colours stay apart from the accent** and always come with a word or icon.
6. **Motion has a character per rice** (instant, crisp, snappy, slam, ease, spring, fade) and stays
   short; `Scale all text` and `Animations` in Settings → Rices → Everywhere apply to every rice.
7. **Both screens.** Sizes are logical px: the laptop runs at 1.2 (1600×1000 logical), the Acer at 1.0.
   Bars and panels were checked on both (`rice` cycled with screenshots of each).

## Adjusting a rice

Settings → Rices → Adjust (or `Config.appearance.custom[rice]`): accent, accent2, radius, gapsIn,
gapsOut, border, barSize, font, size, motion, shadow, blur. `Rices.resolve` lays them over the rice;
Reset removes them. Adjustments are kept per rice, so switching away and back keeps them.

## Where the look reaches

| Target | How |
|---|---|
| Shell (bar, dock, launcher, panels, notifications, OSD, Settings, cheatsheet) | Theme tokens, live |
| Hyprland frames, gaps, rounding, shadow, blur, motion | `ThemeSync` → `hyprctl eval` + `hypr/settings/theme.lua` → `look.lua`, `animations.lua` |
| Lock screen | `hypr/settings/hyprlock-theme.conf` → `lockscreens/<rice.lock>.conf` |
| Terminal | `ghostty/theme.conf` → `themes/<Rice>`, font, opacity (see-through only in glass rices) |
| GTK apps | gsettings: light/dark, accent, icons, font, cursor |
| Wallpaper | `rice-wallpaper <design>` (ImageMagick, drawn once) → Wallpapers → hyprpaper |
| Screenshot selection | `screenshot` reads the accent from `theme.lua` |

Qt/KDE apps keep following KDE's own colour scheme on purpose, so the KDE session stays untouched.
