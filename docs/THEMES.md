# Themes: how they work and how to make one

A theme is a whole desktop design: colours, type, shape, the bar's and dock's look, panel depth, motion, window
frames, notifications, launcher, lock screen, terminal palette and wallpaper. Layout (where the bar and dock sit,
their size and items) is yours and works in every theme. The rules every theme follows are in
[DESIGN.md](DESIGN.md).

## Where things live

| Piece | File | Who writes it |
|---|---|---|
| The seven built-in themes, as data | `config/quickshell/.config/quickshell/Themes.qml` | the repo |
| Your own themes | `~/.config/quickshell/settings.json` → `appearance.userThemes` (only the parts you changed) | Settings → Appearance → Theme Builder |
| Your adjustments to any theme (accent, corners, gaps, font, bar and dock place…) | `settings.json` → `appearance.custom.<theme>` | Settings → Appearance, Menu Bar, Dock |
| Tokens every component reads | `Theme.qml` | computed from the active theme + your adjustments |
| Everything outside the shell | `ThemeSync.qml` → Hyprland (`settings/theme.lua`), lock screen (`settings/hyprlock-theme.conf`), GTK 3/4 (gsettings + `gtk-*/linux-setup.css`), Ghostty (`ghostty/theme.conf`), emoji picker (`fuzzel/theme.ini`), wallpaper (`theme-wallpaper`) | on every change, live |
| Terminal palettes | `config/ghostty/.config/ghostty/themes/<Theme>` and `<Theme> Light/Dark` | the repo |
| Wallpapers | `config/scripts/.local/bin/theme-wallpaper` (one ImageMagick design per id, drawn once) | the repo |

One change flows one way: Settings → `settings.json` → `Themes.resolve()` → `Theme` tokens → every component,
and `ThemeSync` → every app outside the shell. No component checks which theme is on; no colour is written
anywhere else (`tests/lint.sh` fails on a hex colour outside `Themes.qml` / `Theme.qml`).

## Make one in Settings (no files)

Settings → Appearance → **Theme Builder**: pick a starting theme, name it, then change any part. It applies live,
is saved as only the parts you changed, and appears in the gallery like the built-in ones. Editing a built-in theme
there makes your copy; the shipped one never changes. Delete or rename it on the same page. "Save as a theme" on
the Appearance, Menu Bar and Dock pages turns your adjustments into a theme too.

Bad values are ignored part by part (`Themes.makeUser` keeps the base's value), and text on an accent colour is
switched to dark or white when the theme's own choice is under WCAG AA (4.5:1).

## Make a built-in one (by hand)

1. Copy a block in `Themes.qml` `builtIn` and give it a new `id` and `name`. Every part is described at the top
   of the file; keep all 13 colour keys in `colour` and in `alt.colour` (the other half: light for a dark theme).
2. Add its terminal palettes: `config/ghostty/.config/ghostty/themes/<term>` and `<alt.term>`.
3. Add its wallpaper designs (`wall`, `alt.wall`) to `theme-wallpaper` and bump `VERSION` there and
   `wallVersion` in `Themes.qml` together.
4. Add a row to the tables in `docs/DESIGN.md` and `README.md`.
5. `tests/lint.sh`: checks every theme half for missing colours, contrast (text 7:1, secondary 4.5:1, faint 3:1
   on panels; 4.5:1 on the accent), and that its terminal palette and wallpaper exist.
6. `./install.sh --only links` links the new palette files; `theme <id>` switches to it.

## Tokens (`Theme.qml`)

| Group | Tokens |
|---|---|
| Colour | `base` (ground), `surfaceColor`, `raised`, `text`, `subtext`, `muted`, `accent`, `accent2`, `accentText`, `accentWash`, `success`, `warning`, `error`, `errorText`, `stroke`, `strokeStrong`, `fill`, `fillHover`, `fillActive`, `selected`, `onSelected`, `thumb`, `onImage` |
| Surfaces | `glass`, `glassStrong`, `menu`, `sidebar`, `highlight`, `backdrop` (behind full-screen modes), `shadow`, `tileOn*` (Control Center tiles that are on) |
| Type | `font`, `displayFont`, `displayWeight`, `monoFont`, `iconFont`, `fontCaption`, `fontLabel`, `fontSize`, `fontTitle`, `fontHeading`, `fontDisplay`, `fontHero` (all scaled by Settings → Text size; caption ≥ 11 px, label ≥ 12 px) |
| Shape and space | `radiusSmall`, `radius`, `radiusLarge`, `radiusPanel`, `line`, `spaceXs`…`spaceXl`, `rowHeight`, `controlHeight`, `popupGap` |
| Bar and dock | `barEdge`, `barSize`, `barFloating`, `barLayout`, `barInk`, `barDim`, `dockEdge`, `dockInBar`, `reserve(side)` |
| Depth | `depth` (soft, hard, glow, none), `shadowBlur`, `shadowOffset` |
| Motion | `enter`, `exit`, `curve`, `travel`, `startScale`, `pressScale`, `animFast`, `anim` (Settings → Animations: Full, Reduced = short fades, Off) |
