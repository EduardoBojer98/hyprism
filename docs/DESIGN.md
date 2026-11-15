---
name: Themes
description: Three whole-desktop designs for Hyprland + Quickshell. A theme sets look and motion; every layout option works in every theme.
source: themes/<id>/theme.json (data), Themes.qml (reads the folders), Theme.qml (tokens), ThemeSync.qml (Hyprland, hyprlock, GTK, Ghostty, wallpaper), LockScreen.qml (lock layout)
default: pebble
---

# Themes

## Idea

A theme is a whole design: the bar's look and its own default items, the dock's shape, how panels sit
and move, the typefaces, corners, window frames, shadows, notification style, lock screen, terminal
palette and wallpaper. Layout is yours: Settings moves the bar to any edge, floats it, picks its items
and places the dock, and every option works in every theme. The three themes share one engine and every
component, so a new theme is data only.

The design rules come from the installed design and animation skills (impeccable, emil-design-eng,
animate, choreograph, animation-performance, taste-skill app screens): colour marks state, tone steps
over ornament, one icon language, motion that confirms an action and never makes you wait.

## Anatomy of a theme (`themes/<id>/theme.json`)

| Part | Values |
|---|---|
| `colour` | ground, surface, raised, line, text, muted, faint, accent, onAccent, accent2, ok, warn, err |
| `font` | ui, display (clocks, big numbers), mono, size (body px), displayWeight |
| `shape` | radius, radiusSmall, line (panel border px), material: `solid` or `glass`, density: `compact`, `regular` or `roomy` (spacing in bars, panels and lists) |
| `bar` | edge, size, floating, segmented (a pill per section), fill (glass, surface, ground, ink, none), line, sep (rules between items), voice (icons, words, mixed, caps), mono, ws (dots, filled, text, numbers, blocks, squares), clock (plain, accent, display, block), decor (brackets), start / center / end items |
| `dock` | edge (its own place; the bar's edge puts it inside the bar), shape (pill, tile, block), hover (lift, grow, plate), mark (line, dot, bar), fill |
| `popup` | depth: soft (blurred shadow), hard (offset block), glow (accent haze), none (frame only); decor: brackets, topline; tiles: solid or wash (Control Center tiles that are on) |
| `motion` | enter / exit ms, curve (cubic bezier), travel px out of the trigger's side, start scale, press scale |
| `launcher`, `notify` | placement, view (home = suggestions first), header (query set large), select (wash or inverse), prompt; corner, kind |
| `hypr` | gaps, border, rounding, active/inactive frame colours, shadow, blur, window motion preset, frame: `accent`, `gradient` or `rainbow` |
| `lock`, `term`, `wall` | lock clock style + alignment, Ghostty palette, `theme-wallpaper` design |

`Theme.qml` turns the active theme plus Settings (bar edge, size, floating, items; dock edge and size;
animation level) into tokens. No component knows which theme is on.

## The themes

Three audiences: Pebble is calm (the default for new installs), Poster is loud, Monolith lives in the terminal.
Atlas, Console, Glass and Reactor are gone; an old id maps on its own (`Config.qml` `renamedThemes`: glass to
Pebble, atlas to Poster, console and reactor to Monolith) and migration 0006 removes their links.

| | Pebble: calm | Poster: loud | Monolith: terminal |
|---|---|---|---|
| Ground / text / accent | `#171918` / `#e9ece6` / `#b9cf8f` (+ `#8fa8a3`) | `#141414` / ink `#141414` on paper `#f4f1ea` / `#ff3b1f` (+ `#2d5bff`) | `#090a08` / `#dde3d2` / `#b6ff3b` (+ `#ff6a3d`) |
| Type | Archivo, light numerals (weight 300), 14 px | Archivo Black + Archivo, 14 px | JetBrains Mono, Martian Mono numerals (700), 13 px |
| Shape · depth | r14, 1 px lines, solid · soft shadow | r0, 3 px lines · hard offset block | r0, 1 px lines · none; accent corner brackets on panels |
| Density | roomy | regular | regular |
| Bar | top, 38 px, floating, dots, plain clock | top, 52 px, attached paper strip, workspace blocks, big clock | top, 34 px, attached, tmux-style status line with apps inside, rules, dim labels with bright values, inverse lime clock block flush right |
| Dock | bottom, pill, icons lift | bottom, block, hard shadow, lift | inside the top bar |
| Motion | 220/140 ms ease-out, 6 px, scale 0.98 | 200/110 ms expo-out, 28 px slam | 140/90 ms expo-out, 4 px |
| Windows | gaps 8/16, 2 px, r14, soft shadow, ease | gaps 8/16, 3 px, r0, hard shadow, slam | gaps 4/8, 2 px, r0, no shadow, snappy |
| Window frame | accent | accent | rainbow |

Contrast (WCAG 2): body text on surfaces 13.2:1 or more; secondary text 5.9:1 or more; text on an accent
fill is forced to 4.5:1 or more by `Themes.resolve`.

## Rules

1. **Structure is yours, character is the theme's.** Every theme supports every bar edge, size, float,
   item set and dock placement. A theme earns its place by its look and motion, not by a fixed layout.
2. **Colour marks state.** The accent is on the current workspace, selection, toggles that are on, the
   focused window's frame and the one thing to press. Panels stay in tone steps.
3. **One icon language.** Material Design Icons from the bundled Nerd Font for every shell glyph; tray
   icons are drawn in the bar's ink (Settings → Icons can keep app colours); app icons from the icon theme.
4. **Type does the work.** One UI face, at most one display face; tabular figures for numbers.
5. **Motion confirms, never delays.** Panels open out of the trigger's side on the theme's curve, exit
   faster than they enter, animate only transform and opacity, and take input from the first frame; a
   closing panel takes none. Keyboard-opened panels have no travel worth waiting for. Settings →
   Animations: Full (the theme's), Reduced (90 ms fades, nothing moves), Off.
6. **Depth belongs to the world.** Soft shadows only in Pebble, the hard offset block only in
   Poster (the one neo-brutalist world), frames alone in Monolith.
7. **Both screens.** Sizes are logical px: the laptop runs at 1.2 (1600×1000 logical), the Acer at 1.0;
   panels are capped to the room between bar and dock and kept on their monitor.

## Light and dark

Every theme has both halves: the dark themes (Pebble, Monolith) have a light version and the
light one (Poster) a dark one, as `alt` in `theme.json` (colours, window frame colours, `term`, `wall`).
Settings → Appearance → Light or dark: Theme's (each theme's own), Light or Dark for all of them; GTK apps,
the terminal, window frames, the lock screen and the wallpaper follow.

| Theme | Other half: ground / text / accent | Wallpaper |
|---|---|---|
| Pebble | light `#e4e6e1` / `#1b1e1c` / `#4d6a35` | pebble-light |
| Monolith | light `#e8eae1` / `#191c15` / ink `#22300a` with lime `#b6ff3b` on it (reverse video) | monolith-light |
| Poster | dark `#141414` / `#f4f1ea` / `#ff4a2e` | poster |

## Your own themes

Copy a theme folder into `~/.config/hyprism/themes/<id>/` and edit its `theme.json`; see [THEMES.md](THEMES.md). A
folder with the id of a shipped theme replaces it. There is no in-app builder.

## Adjusting a theme

Settings → Appearance → Themes → Adjust (or `Config.appearance.custom[theme]`): accent, accent2, radius,
gapsIn, gapsOut, border, font, size, window motion, shadow, blur. These are kept per theme, so an edit made in one
theme never changes another. `Themes.resolve` lays them over the theme and ignores a bad value; Reset removes them.
The bar and dock are not part of Adjust: they are one global layout (`bar.layout`, see [bar.md](bar.md)) that
survives a theme switch. The window frame colour is Settings → Window Look → Border: Theme's, Accent, Gradient or Rainbow.

## Where the look reaches

| Target | How |
|---|---|
| Shell (bar, dock, panels, launcher, notifications, OSD, Settings) | Theme tokens, live |
| Hyprland frames, gaps, rounding, shadow, blur, motion | `ThemeSync` → `hyprctl eval` + `hypr/settings/theme.lua` |
| Lock screen | `LockScreen.qml` layout → `hypr/settings/hyprlock-theme.conf`; Settings preview draws the same list |
| Terminal | `ghostty/theme.conf` → `themes/<Theme>` |
| GTK apps | gsettings: light/dark, accent, icons, font, cursor |
| Wallpaper | `theme-wallpaper <design>` (ImageMagick, drawn once) → hyprpaper |
