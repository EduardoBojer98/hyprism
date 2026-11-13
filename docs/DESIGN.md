---
name: Themes
description: Seven whole-desktop designs for Hyprland + Quickshell. A theme sets look and motion; every layout option works in every theme.
source: themes/<id>/theme.json (data), Themes.qml (reads the folders), Theme.qml (tokens), ThemeSync.qml (Hyprland, hyprlock, GTK, Ghostty, wallpaper), LockScreen.qml (lock layout)
default: reactor
---

# Themes

## Idea

A theme is a whole design: the bar's look and its own default items, the dock's shape, how panels sit
and move, the typefaces, corners, window frames, shadows, notification style, lock screen, terminal
palette and wallpaper. Layout is yours: Settings moves the bar to any edge, floats it, picks its items
and places the dock, and every option works in every theme. The seven themes share one engine and every
component, so a new theme is data only.

The design rules come from the installed design and animation skills (impeccable, emil-design-eng,
animate, choreograph, animation-performance, taste-skill app screens): colour marks state, tone steps
over ornament, one icon language, motion that confirms an action and never makes you wait.

## Anatomy of a theme (`themes/<id>/theme.json`)

| Part | Values |
|---|---|
| `colour` | ground, surface, raised, line, text, muted, faint, accent, onAccent, accent2, ok, warn, err |
| `font` | ui, display (clocks, big numbers), mono, size (body px), displayWeight |
| `shape` | radius, radiusSmall, line (panel border px), material: `solid` or `glass` |
| `bar` | edge, size, floating, segmented (a pill per section), fill (glass, surface, ground, ink, none), line, voice (icons, words, mixed, caps), mono, ws (dots, filled, text, numbers, blocks, squares), clock (plain, accent, display), decor (brackets), start / center / end items |
| `dock` | edge (its own place; the bar's edge puts it inside the bar), shape (pill, tile, block), hover (lift, grow, plate), mark (line, dot, bar), fill |
| `popup` | depth: soft (blurred shadow), hard (offset block), glow (accent haze), none (frame only); decor: brackets, topline; tiles: solid or wash (Control Center tiles that are on) |
| `motion` | enter / exit ms, curve (cubic bezier), travel px out of the trigger's side, start scale, press scale |
| `launcher`, `notify` | placement, view (home = suggestions first), header (query set large), select (wash or inverse), prompt; corner, kind |
| `hypr` | gaps, border, rounding, active/inactive frame colours, shadow, blur, window motion preset |
| `lock`, `term`, `wall` | lock clock style + alignment, Ghostty palette, `theme-wallpaper` design |

`Theme.qml` turns the active theme plus Settings (bar edge, size, floating, items; dock edge and size;
animation level) into tokens. No component knows which theme is on.

## The themes

| Theme | Ground / text / accent | Type | Shape · depth | Bar (own edge) | Dock | Motion |
|---|---|---|---|---|---|---|
| Pebble | `#16141f` / `#ece8f6` / `#ff9e7a` (+ `#9ad1c0`) | Outfit | r18, glass · soft | top, three floating glass pills, dots | glass pill, icons lift | 240/150 ms, slight overshoot, 10 px, scale 0.94 |
| Monolith | `#0b0c0a` / `#d7ddcc` / `#b6ff3b` | JetBrains Mono | r0, 1-2 px lines · accent top line on panels | top tmux-style status line: workspaces, app icons (the dock), the focused window, icon + value items, rules, an inverse lime clock block | inside the bar | 90/60 ms fade, no travel |
| Console | `#05080f` / `#e9dcc0` / `#ffb000` | Martian Mono | r0, 1 px amber · glow + panel brackets | top, framed caps readout, rules, corner brackets | square block, bottom | 140/80 ms snap, 4 px, scale 0.98 |
| Poster | `#141414` / paper `#f4f1ea` / `#ff3b1f` (+ `#2d5bff`) | Archivo Black + Archivo | r0, 3 px · hard offset | top, paper, huge workspace blocks, big clock | paper block, hard shadow, lift | 200/110 ms expo-out, 28 px slam |
| Glass | `#0f131c` / `#f4f6fb` / `#5b9cff` (+ `#8f86ff`) | IBM Plex Sans | r16, glass with a lit rim · soft, tinted tiles | top, a floating glass bar, centred clock | glass tile, magnify | 220/140 ms strong ease-out, 6 px, 0.97 |
| Atlas | `#f2f2f0` / `#111111` / `#e30613` | Archivo | r0, 2 px · none | top, black strip, heavy clock, red squares | black block, bottom | 160/100 ms, 14 px |
| Reactor | `#0c0d08` / `#f3f6df` / `#e4ff1a` (+ `#ff6b0a`) | Archivo + Martian Mono numerals | r10, 1 px · glow + accent top line | top, a floating strip, inverse acid clock block | tile, bottom | 180/110 ms strong ease-out, 8 px, 0.97 |

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
6. **Depth belongs to the world.** Soft shadows only in the glass themes, the hard offset block only in
   Poster (the one neo-brutalist world), frames alone in the line themes.
7. **Both screens.** Sizes are logical px: the laptop runs at 1.2 (1600×1000 logical), the Acer at 1.0;
   panels are capped to the room between bar and dock and kept on their monitor.

## Light and dark

Every theme has both halves: the dark themes (Pebble, Monolith, Console, Glass, Reactor) have a light version and the
light ones (Poster, Atlas) a dark one, as `alt` in `theme.json` (colours, window frame colours, `term`, `wall`).
Settings → Appearance → Light or dark: Theme's (each theme's own), Light or Dark for all of them; GTK apps,
the terminal, window frames, the lock screen and the wallpaper follow.

| Theme | Other half: ground / text / accent | Terminal · wallpaper |
|---|---|---|
| Pebble | light `#f3eff8` / `#221d2e` / `#d9572f` | Pebble Light · pebble-light |
| Monolith | light `#eceee6` / `#1d2118` / `#4a7d00` | Monolith Light · monolith-light |
| Console | light `#f4efe3` / `#2a1f0a` / `#a35f00` | Console Light · console-light |
| Poster | dark `#141414` / `#f4f1ea` / `#ff4a2e` | Poster Dark · poster |
| Glass | light `#e9edf4` / `#141a26` / `#2f6fe0` | Glass Light · glass-light |
| Atlas | dark `#121212` / `#f2f2f0` / `#ff2a36` | Atlas Dark · atlas-dark |
| Reactor | light `#f5f6ea` / `#181a0e` / `#b14800` | Reactor Light · reactor-light |

## Your own themes

Settings → Appearance → Theme Builder makes a theme from any shipped one; you can change every part listed
above. It is saved in `Config.appearance.userThemes` as only the parts you changed (`{ name, base, colour: {…}, … }`)
and merged over its base by `Themes.makeUser`, which ignores a part of the wrong type or a bad colour.

## Adjusting a theme

Settings → Appearance → Themes → Adjust (or `Config.appearance.custom[theme]`): accent, accent2, radius,
gapsIn, gapsOut, border, font, size, window motion, shadow, blur. Settings → Menu Bar and Dock save into the
same place, also per theme: `barEdge`, `barSize`, `barFloating`, `barItems` ({ start, center, end }) and `dock`
(`bar` or an edge; the bar's edge puts the dock in the bar). So an edit made in one theme never changes another.
`Themes.resolve` lays them over the theme and ignores a bad value; Reset removes them. "Save as a theme" (on the
Appearance, Menu Bar and Dock pages) turns them into a theme of your own (`Themes.saveAs`: the parts that
differ from the base) and puts the theme you started from back as it shipped.

## Where the look reaches

| Target | How |
|---|---|
| Shell (bar, dock, panels, launcher, notifications, OSD, Settings) | Theme tokens, live |
| Hyprland frames, gaps, rounding, shadow, blur, motion | `ThemeSync` → `hyprctl eval` + `hypr/settings/theme.lua` |
| Lock screen | `LockScreen.qml` layout → `hypr/settings/hyprlock-theme.conf`; Settings preview draws the same list |
| Terminal | `ghostty/theme.conf` → `themes/<Theme>` |
| GTK apps | gsettings: light/dark, accent, icons, font, cursor |
| Wallpaper | `theme-wallpaper <design>` (ImageMagick, drawn once) → hyprpaper |
