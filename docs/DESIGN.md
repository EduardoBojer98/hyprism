---
name: Graphite Glass
description: Compact dark frosted-glass Quickshell shell for Hyprland, one consistent visual language across every surface.
source: config/quickshell/.config/quickshell/Theme.qml (tokens), Glass.qml (surface), ThemeSync.qml (pushes them to Hyprland, hyprlock, GTK, Ghostty, fuzzel)
colors:            # dark mode; light mode mirrors these with black alphas on white frost
  theme: "Theme.themes: [base, text, accent] for dark and light per theme (midnight #161821 default)"  # Settings > Appearance > Theme
  glass: "tint × 1.05, alpha 0.28 + 0.6 × glassOpacity"   # bar items, dock, OSD
  glass-strong: "tint × 0.82, alpha 0.5 + 0.7 × glassOpacity"  # panels with text
  menu: "tint × 0.95, alpha 0.97"                         # lists, menus, tooltips
  stroke: "rgba(255, 255, 255, 0.10)"
  stroke-strong: "rgba(255, 255, 255, 0.22)"
  highlight: "rgba(255, 255, 255, 0.07)"                  # top rim, fades out by 35%
  fill / hover / active: "rgba(255, 255, 255, 0.06 / 0.10 / 0.16)"
  text: "#f3f4f8"
  subtext: "rgba(255, 255, 255, 0.62)"
  muted: "rgba(255, 255, 255, 0.40)"
  accent: "palette: Azure #5b9cff, Iris #8f86ff, Orchid #c58af9, Rose #ff7aa2, Red #ff5f57, Coral #ff8a5c, Amber #f7c85b, Champagne #e2c08d, Matcha #8fd16a, Mint #5ee0b5, Lagoon #3cc7c0, Glacier #7cc8ff, Silver #b9c0cc (deeper variants in light mode), or any custom hex"
  accent-text: "#1d1d1f on accents brighter than luminance 0.62, white otherwise"
  warning: "#ffd60a (dark) / #c27c00 (light)"
  error: "#ff453a"
type: { family: Inter, caption: 11, label: 12, body: 13, title: 15, heading: 20, display: 26 }
radius: { small: 8, default: 12, large: 14 }   # × radiusScale
space: [4, 8, 12, 16, 24]
sizes: { bar: 30, bar-item: 22, row: 34, control: 28, cc-width: 330, cc-gap: 8, cc-pad: 10 }
motion: { fast: 120ms, default: 200ms, slow: 600ms, easing: OutCubic }
---

# Graphite Glass

## Idea

Neutral graphite glass floating over a blurred wallpaper. Everything is compact, monochrome and
quiet; the accent appears only where something is selected, on, or under the pointer in a menu.
Depth comes from Hyprland's blur, a 1px hairline and a soft shadow, never from heavy fills.

## Surfaces

| Surface | Look |
|---|---|
| Bar | 30px frosted strip (`rgba(18,18,23,0.40)` + blur) with a 1px bottom hairline. Items are 22px tall with a 7px-radius hover highlight. Status icons show their state: Wi-Fi as drawn signal bands lit to the strength, volume by level, Bluetooth dim until a device connects, the keyboard layout as its own hairline keycap item (click: list of layouts with full names, scroll: next layout), temperatures as a `subtext` chip / card icon with only the number coloured, and the battery drawn macOS-style (hairline body, fill to the charge, green while charging, red when low, bolt or plug beside it). The system logo at the far left opens the utility menu. |
| Workspaces | One recessed `fill` pill (22px, hairline) with a 22px slot per desktop on that screen: numbers in 11px, `muted` when empty, `text` when busy, warning when urgent, `fillHover` plate on hover. An accent pill slides to the current desktop (number in `accentText`). Scroll on it to step through desktops. |
| Dock | Strong-radius glass island; icons stay put (no magnification): hover shows a `fillHover` plate behind the icon, press dips it to 0.9. One 4px dot per window (up to 3), bright when focused, dim when minimised, warning colour when urgent. A launching app breathes until its window shows. Pinned apps drag sideways to reorder (neighbours glide aside); a divider separates unpinned running apps. One shared tooltip above the island, after 350ms, then instant between icons. Right-click lists the app's windows, then actions. |
| Control Center | One strong-glass panel (18px radius, 10px padding) of `fill` tiles with 8px gaps, top to bottom: a 2×2 grid of 52px connection tiles (Wi-Fi, Bluetooth, Focus, Night Light: 32px toggle disc, name, status, chevron when it has a list); four 66px quick toggles (icon, name, status; white when on); a 64px media row while something plays; Display (built-in, then each external monitor by name over DDC/CI) / Sound / Microphone as 26px pill sliders (icon inside the fill mutes, value at the right end; short device names open the device list); Power mode; four labelled shortcut tiles (Screenshot, Settings, Lock, Power); then notifications. No battery here: the bar shows it. |
| Spotlight | A 48px strong-glass search pill (18px text, placeholder "Search apps, files, settings and more") beside one glass capsule of four 36px round mode buttons (subtext glyph, `fillActive` plate and accent glyph on the current one). Results: Top Hit (the best score of any group), then one header per group in the order from Settings; the current row gets a `fillActive` plate, like the app grid and clipboard. Mixed search shows at most 5 files; Files mode shows them all. Before you type (start view "Suggestions"): three 52px `fill` glance tiles (weather, next calendar event, last copied), "Frequently used" (8 apps by launch count, topped up with the dock's pinned apps), "Recent" (settings pages, actions and files opened lately) and six quick actions in a 3-column grid; arrows move through them, Enter opens. |
| Calendar | 340px strong-glass popup under the clock: today as a 40px accent number with weekday, month and ISO week; month title with ‹ Today › chips (scroll changes month); a 7-column grid of 30px day discs (accent disc today, accent ring on the selected day, weekends in subtext, holidays in `error`) with up to three 4px event dots; the selected day's events and the next four coming up. Holidays come from date.nager.at (cached per country and year), observances and moon phases are computed locally; all switchable in Settings > Calendar. |
| Menus | Utility menu, dock menu, tray menus (TrayMenu.qml, drawn by the shell), dropdowns: `menu` colour, 26–28px rows, accent fill with white text under the pointer, ✓ for the current choice, chevrons for submenus. |
| Notifications | 344px cards on strong glass at 14px radius, 32px app icon; slide in 60px with a fade, leave by fading and drifting right. Folded cards peek out underneath. |
| Popups | Everything floats 8px below the bar (CursorPopup `topReserve: 38`), opens with a 120ms fade and 0.96→1 scale; Esc or a click anywhere outside it, on any monitor, closes it. |
| Windows | 4px inner / 10px outer gaps, rounding from Settings (12), squircle power 2.4, soft 32px shadow offset 8px. Desktops slide (slidefade 12%), windows pop in from 92%. |
| Lock screen | Wallpaper blurred and dimmed to 72%; date (20px semibold) over a 104px Inter Display clock near the top; name and a 240×38 glass password pill near the bottom. |

## Rules

- Build shell surfaces from `Glass` and `Theme` tokens in a `qs-*` layer namespace so Hyprland
  blurs them. Never hard-code a colour a token already covers.
- Accent = selected, on, or highlighted menu row. Not decoration, not headings.
- Warning and error only past a defined threshold (temperatures, low battery, failed lock).
- Tabular figures on every live number. Nothing below 10px; secondary text uses `subtext`/`muted`.
- One row tall → full pill or 7–8px radius; containers 12–14px. Borders are 1px.
- Motion eases with `Theme.anim` / `animFast`; nothing bounces or grows on hover. `Config.appearance.animations`
  off makes all shell motion instant.
- Keep it light on the GPU: no per-item shadows or blur layers inside the shell; Hyprland's one
  blur pass per layer does the frosting.

## Neon themes (2026-11)

Three high-energy themes sit beside the calm ones. Same glass, same tokens, same components; only
the palette and the window border change. Preview: `docs/palette-preview.html`.

| Theme | Base | Text | Accent (signature) | Accent 2 (support) | Success / warning / error |
|---|---|---|---|---|---|
| **Radioactive** (default) | `#0b0d0a` | `#eef2e6` | `#e4ff1a` radioactive yellow | `#00e5ff` electric cyan | `#4ade80` / `#ff9f1c` / `#ff4d6d` |
| **Molten** | `#100b0a` | `#f7eee8` | `#ff6b1a` blazing orange | `#ff3dbb` hot magenta | `#34d399` / `#ffd60a` / `#ff4040` |
| **Cyber** | `#0a0b14` | `#eef0ff` | `#00e5ff` electric cyan | `#ff2bd6` magenta | `#3ee07f` / `#ffc53d` / `#ff4d5e` |
| **Acid** | `#090c0b` | `#ecf5ee` | `#5dff3a` acid green | `#b56cff` ultraviolet | `#2dd4bf` / `#ffb020` / `#ff4f6d` |
| **Synthwave** | `#0e0a14` | `#f3ecff` | `#ff2e97` hot pink | `#8f6bff` electric violet | `#3ee07f` / `#ffc53d` / `#ff5a3c` |

Contrast on the base (WCAG 2, measured): body text 17:1 in all three; accents and accent 2 6.1:1 or
better; status colours 5.6:1 or better; text on an accent fill 5.9:1 or better (Molten's orange is the
lowest of the first three; Synthwave's pink is 4.9:1). Everything passes AA (4.5:1); body text passes AAA (7:1). `Theme.accentText` picks dark or
white text by real WCAG luminance, so a new accent can't end up with unreadable button text.

### Rules

1. **Neon marks state, never area.** The accent shows on the focused workspace, the focused
   window's border, selections, the launcher field, toggles that are on, progress fills, the lock
   clock. Panels stay near-black glass. No accent backgrounds bigger than a pill or a selected row.
2. **Body text is never neon.** Text uses `text` / `subtext` / `muted`. Accent text only for short
   labels (group headings, a filter, a link), at semibold or larger.
3. **Accent 2 is a partner, not a second brand.** It only appears in the border gradient, glows,
   code keywords (terminal) and the lock-screen glow.
4. **Status colours stay apart from the accents** (different hue in every neon theme) and always
   come with an icon or word, so they work for colour-blind eyes too.
5. **Glow is reserved for one thing at a time:** the focused window (Hyprland shadow in the
   accent at 33% alpha, 22px, no offset) and the focused workspace pill. Unfocused windows keep a
   faint hairline and a plain dark shadow.
6. **Motion stays fast:** 120 / 200 / 600 ms in the shell, Hyprland springs and `easeOutQuint`
   (`modules/animations.lua`). Nothing bounces; the neon border doesn't spin (the rainbow style still can).

### Neon surfaces (any theme)

`NeonEdge.qml` draws a 1.5px ring from accent to accent 2 at 45° with a soft accent glow. It replaces
the hairline wherever a surface asks for it:

| Surface | How to turn it on | Ready-made designs |
|---|---|---|
| Panels, menus, pop-ups, cheatsheet, Settings window | Settings → Appearance → **Neon edges** (`appearance.neonPanels`, on by default) | — |
| Menu bar | Colour **Neon** (`bar.tint`): dark surface, glowing edge on floating / islands / tabs / compact, a glowing line under a strip | Neon, Neon line, Neon islands, Neon tabs, Neon bottom |
| Dock | Colour **Neon** (`dock.tint`) | Neon, Neon island, Neon panel |
| Spotlight | Colour **Neon** (`launcher.tint`) | Neon, Neon card |
| Notifications | Style **Neon** (always glowing), or Card with Neon edges on | — |
| Lock screen | Design **Neon** (`lockscreens/neon.conf`): accent clock with glow, gradient password field | — |

The neon surface colour is the theme base at 93% opacity (`Theme.surface("neon")`), darker than glass,
so the edge and the text stay crisp over any wallpaper. Every neon option works with every theme,
calm or neon, light or dark.

### One source of truth, every app

| Value | Defined in | Reaches |
|---|---|---|
| Palette (`[base, text, accent, accent2]`, `status`) | `Theme.qml` → `Theme.themes` | Bar, dock, panels, launcher, notifications, OSD, cheatsheet, Settings (direct) |
| Accent, accent 2, border style, rounding, gaps | `ThemeSync.qml` → `hypr/settings/theme.lua` | Hyprland border gradient + glow (`look.lua`), screenshot selection colour (`screenshot`) |
| Accent, rounding, font | `ThemeSync.qml` → `hypr/settings/hyprlock-theme.conf` | Lock screen |
| Terminal theme | `Theme.themes[*].term` → `ghostty/theme.conf` | Ghostty (`config/ghostty/.config/ghostty/themes/`) |
| Light/dark, accent, icons, cursor | `ThemeSync.qml` → `gsettings` | GTK 3/4 apps, Satty's own buttons |
| Colours | `ThemeSync.qml` → `fuzzel/theme.ini` | Emoji picker |
| Annotation colours | `config/satty/.config/satty/config.toml` | Screenshot editor (fixed neon set, readable on any picture) |
| Type, spacing, radius, motion | `Theme.qml` | Shell surfaces; Hyprland rounding via theme.lua |

Qt/KDE apps keep following KDE's own colour scheme on purpose, so the KDE session stays untouched.

### Screens

Same logical sizes on both screens: the laptop runs at 1.2 scale (1600×1000 logical), the Acer at
1.0 (2560×1440). Text sizes are logical pixels, so 13px body text is about 15.6 physical px on the
laptop and 13px on the 32" screen; both read comfortably at their viewing distances. Touch targets
in panels are at least 34px rows / 28px controls (`rowHeight`, `controlHeight`).
