# Themes

A theme is a whole desktop design: colours, fonts, corners, spacing, the bar and dock look, how panels open, the lock
screen, the terminal colours and the wallpaper. Every theme has a dark and a light half.

Three ship: **Pebble** (calm, the default for new installs), **Poster** (loud) and **Monolith** (terminal). Atlas,
Console, Glass and Reactor were removed; if you used one, you get its successor (glass to Pebble, atlas to Poster,
console and reactor to Monolith) with your adjustments moved over.

## Switch

```bash
theme
```

lists them. `theme poster` switches. Or Settings → Appearance → Themes, which shows a preview of each. It applies
at once, with no logout: Hyprland's borders and gaps, the bar and dock, menus, notifications, the lock screen,
GTK apps, the terminal and the wallpaper all follow.

Settings → Appearance → **Adjust** changes one theme's accent, corners, gaps, font and motion without touching
its files. **Light or dark** picks each theme's own default, or one mode for all.

## Where a theme lives

Each theme is one folder:

```
themes/pebble/
  theme.json      every value of the design
  wallpaper.sh    how its two wallpapers are drawn (or pictures: pebble.png, pebble-light.png)
```

| Folder | Whose |
|---|---|
| `themes/<id>/` in the repo (linked to `~/.local/share/hyprism/themes/`) | the shipped themes |
| `~/.config/hyprism/themes/<id>/` | yours; one with the same id as a shipped theme replaces it |

Nothing else lists the themes. A folder with a `theme.json` is a theme.

## Make your own

```bash
cp -r ~/.local/share/hyprism/themes/_template ~/.config/hyprism/themes/mine
```

Edit `~/.config/hyprism/themes/mine/theme.json`, then:

```bash
theme mine
```

`theme` reads the folders again each time, so edit and run it again to see a change. A part you leave out, or
get wrong, falls back to a safe value instead of breaking the desktop. Text placed on your accent colour is
corrected to stay readable.

For a quick variation without files, use Settings → Appearance → Themes → Adjust. It changes one theme's accent,
corners, gaps, font and motion and is kept in `settings.json`; there is no builder.

## What is in theme.json

| Part | What it sets |
|---|---|
| `name`, `about`, `order` | Its name, one line about it, and its place in the list |
| `dark` | `true` if this half is the dark one |
| `colour` | 13 colours: `ground` (desktop, bar), `surface` (panels), `raised` (controls), `line`, `text`, `muted`, `faint`, `accent`, `onAccent` (text on the accent), `accent2`, `ok`, `warn`, `err` |
| `alt` | The other half: its `dark`, `colour`, `term`, `wall`, and window border colours (`hypr.active`, `hypr.inactive`) |
| `font` | `ui`, `display` (clocks, big numbers), `mono`, `size` in px, `displayWeight` |
| `shape` | `radius`, `radiusSmall`, `line` (panel border px), `material`: `solid` or `glass`, `density`: `compact`, `regular` or `roomy` (spacing everywhere; default `regular`) |
| `bar` | Edge, size, floating or attached, fill, how items speak (`voice`: `icons`, `mixed`, `words`, `caps`), workspace style, `sep` (rules between items), `sepStyle` (`line`; `slash`: the rule leans like a HUD segment cut; `pip`: a small square), `dimLabels` (a readout's word or glyph dimmed, its value in ink), and the items in `start`, `center`, `end` |
| `dock` | Edge, shape, hover effect, running mark, fill |
| `osd` | `style`: `bar`, `numeral` (a big number over ten blocks) or `ascii` (a mono meter) |
| `popup` | Panel depth (`soft`, `hard`, `glow`, `none`), decoration, `decorColour` (`accent` or `accent2`: the colour of that decoration), tile style, `segments` (`text` or `accent`: the chosen part of a segmented control) |
| `motion` | How panels open: `enter` and `exit` in ms, `curve`, `travel`, `scale`, `press` |
| `feel` | Each theme's signature in full motion: `press` (`scale`; `sink`, a 1 px drop that springs back; `shadow`, the button pushes into a hard block in `accent2`) and `focus` (`ring`, or `reticle`: corner marks that close in) |
| `launcher`, `notify` | Launcher placement and look; where notifications appear and their shape |
| `launcher.layout` | The launcher's structure: `grid` (a big search pill on a soft shadow, a Recent row and app icons on squircle plates, a selection wash that springs in), `sheet` (the query as a display-font header, big rows with a first-letter index and a category tag, the selection an inverse block on a hard shadow) or `prompt` (a `❯ query` line with a block caret, numbered text rows with a `>` on the selection, matches in accent, `[enter] open` hints). Empty: the plain list. A style picked in Settings > Search & Launcher brings its own structure instead |
| `hypr` | Window gaps, border, rounding, border colours, shadow, blur, animation preset, `frame`: `accent`, `gradient` or `rainbow` (the focused window's frame) |
| `lock` | Lock screen clock style and alignment |
| `term` | The terminal's colours: `background`, `foreground`, `cursor`, `cursorText`, `selection`, `selectionText`, `palette` (16 colours), and its look: `cursorStyle` (`block`, `bar`, `underline`, `block_hollow`), `blink`, `padding` `[x, y]`, `prompt`: the starship prompt and fastfetch card preset (`rounded` pills, `blocks` on a heavy rail, `brackets` as an ascii HUD) |
| `wall` | The wallpaper's name: a picture `<wall>.png` in the folder, or a recipe with that name in `wallpaper.sh` |
| `icons` | The icon theme it starts with (a folder name; `Papirus` and `breeze` follow light and dark). Settings > Icons can pick another |
| `cursor` | The cursor theme it starts with (a folder name; empty = the system's). A missing one falls back to the system cursor. Settings > Cursor can pick another |

The design rules behind the shipped themes are in [DESIGN.md](DESIGN.md).

## Wallpaper

Put a picture in the theme folder named after `wall` (and after `alt.wall` for the other half): `mine.png`,
`mine-light.jpg`. Or write `wallpaper.sh`, a small ImageMagick recipe; the shipped themes do this so the
wallpaper always matches the palette and no pictures are stored in the repo. Settings → Wallpaper is for using
your own pictures regardless of the theme.

## Colours from your wallpaper

Settings → Wallpaper → "Colours from the wallpaper" lets the accent and second accent follow a picture you chose
yourself (`appearance.wallpaperColours`). It is off by default and does nothing while the wallpaper is one a theme
draws or ships. `wallpaper-colours IMAGE [dark|light] [SURFACE]` picks the colours; their lightness is adjusted
(hue stays) so each keeps at least 3:1 contrast on the theme's panels, and the text on an accent is still checked.
They are saved like your own adjustments for the active theme (`appearance.custom`), after remembering the accents
they replace. Switch the toggle off, go back to the theme's wallpaper or change theme, and the earlier accents
return. A picture with no colour in it (grey) changes nothing.

## Contrast is checked

```bash
python3 tests/themes.py
```

checks every shipped theme, both halves: body text 7:1, secondary text 4.5:1 and captions 3:1 against the panel
and the desktop; text on the accent 4.5:1; the accent, second accent and the ok / warn / error colours 3:1
against the panel; the bar's text on the bar; the terminal's text 7:1 and its six colours 3:1; and that the
wallpaper exists. CI runs it on every push. A theme added to `themes/` must pass.

## What follows the theme today

Hyprland (borders, gaps, rounding, shadow, blur, animation), the whole shell (bar, dock, launcher, menus,
notifications, on-screen display, Settings), the lock screen, GTK 3 and 4 apps, Qt apps (through `qt6ct`;
a Qt app that is already running takes the colours when you restart it), the Ghostty terminal, btop, the shell
prompt (starship), the app picker (fuzzel), the cursor and icon theme, and the wallpaper.

- btop: pick the theme once in btop's Options: `color_theme = "hyprism"`. If you have no `btop.conf`, one is
  written for you; yours is never edited.
- Prompt: the fish config points starship at `~/.config/hyprism/starship.toml`, a copy of `starship.toml` with
  the theme's colours in its `[palettes.hyprism]` block. New prompts pick it up at once.
- Qt: `~/.config/qt6ct/qt6ct.conf` is written only if you have none; your own is never overwritten.

Still to do: the login screen. It runs as another user before you log in and differs per distro's display
manager, so there is no one place for the theme to write to.
