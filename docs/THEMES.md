# Themes

A theme is a whole desktop design: colours, fonts, corners, the bar and dock layout, how panels open, the lock
screen, the terminal colours and the wallpaper. Every theme has a dark and a light half.

## Switch

```bash
theme
```

lists them. `theme atlas` switches. Or Settings → Appearance → Themes, which shows a preview of each. It applies
at once, with no logout: Hyprland's borders and gaps, the bar and dock, menus, notifications, the lock screen,
GTK apps, the terminal and the wallpaper all follow.

Settings → Appearance → **Adjust** changes one theme's accent, corners, gaps, font and motion without touching
its files. **Light or dark** picks each theme's own default, or one mode for all.

## Where a theme lives

Each theme is one folder:

```
themes/reactor/
  theme.json      every value of the design
  wallpaper.sh    how its two wallpapers are drawn (or pictures: reactor.png, reactor-light.png)
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

For a quick variation without files, use Settings → Appearance → Theme Builder: it saves the difference from an
existing theme in `settings.json`.

## What is in theme.json

| Part | What it sets |
|---|---|
| `name`, `about`, `order` | Its name, one line about it, and its place in the list |
| `dark` | `true` if this half is the dark one |
| `colour` | 13 colours: `ground` (desktop, bar), `surface` (panels), `raised` (controls), `line`, `text`, `muted`, `faint`, `accent`, `onAccent` (text on the accent), `accent2`, `ok`, `warn`, `err` |
| `alt` | The other half: its `dark`, `colour`, `term`, `wall`, and window border colours (`hypr.active`, `hypr.inactive`) |
| `font` | `ui`, `display` (clocks, big numbers), `mono`, `size` in px, `displayWeight` |
| `shape` | `radius`, `radiusSmall`, `line` (panel border px), `material`: `solid` or `glass` |
| `bar` | Edge, size, floating or attached, fill, how items speak (`voice`: `icons`, `mixed`, `words`, `caps`), workspace style, and the items in `start`, `center`, `end` |
| `dock` | Edge, shape, hover effect, running mark, fill |
| `popup` | Panel depth (`soft`, `hard`, `glow`, `none`), decoration, tile style |
| `motion` | How panels open: `enter` and `exit` in ms, `curve`, `travel`, `scale`, `press` |
| `launcher`, `notify` | Launcher placement and look; where notifications appear and their shape |
| `hypr` | Window gaps, border, rounding, border colours, shadow, blur, animation preset |
| `lock` | Lock screen clock style and alignment |
| `term` | The terminal's colours: `background`, `foreground`, `cursor`, `cursorText`, `selection`, `selectionText`, and `palette` (16 colours) |
| `wall` | The wallpaper's name: a picture `<wall>.png` in the folder, or a recipe with that name in `wallpaper.sh` |

The design rules behind the shipped themes are in [DESIGN.md](DESIGN.md).

## Wallpaper

Put a picture in the theme folder named after `wall` (and after `alt.wall` for the other half): `mine.png`,
`mine-light.jpg`. Or write `wallpaper.sh`, a small ImageMagick recipe; the shipped themes do this so the
wallpaper always matches the palette and no pictures are stored in the repo. Settings → Wallpaper is for using
your own pictures regardless of the theme.

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
notifications, on-screen display, Settings), the lock screen, GTK 3 and 4 apps, the Ghostty terminal, the app
picker (fuzzel), the cursor and icon theme, and the wallpaper. Qt apps, the login screen, btop and the shell
prompt are the next targets (roadmap C3).
