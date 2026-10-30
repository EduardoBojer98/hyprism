---
name: Graphite Glass
description: Compact dark frosted-glass Quickshell shell for Hyprland, macOS-inspired, one visual language for every surface.
source: home/quickshell/.config/quickshell/Theme.qml (tokens), Glass.qml (surface)
colors:            # dark mode; light mode mirrors these with black alphas on white frost
  tint: "midnight rgb(0.085, 0.095, 0.13) · graphite rgb(0.11, 0.11, 0.12) · mocha rgb(0.13, 0.11, 0.10)"  # Settings > Dark tint
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
| Bar | 30px frosted strip (`rgba(18,18,23,0.40)` + blur) with a 1px bottom hairline. Items are 22px tall with a 7px-radius hover highlight. |
| Workspaces | A dot per desktop (6px, muted when empty, subtext when busy, 8px on hover); the current one is a 22×14 white capsule with its number. Urgent = warning colour. |
| Dock | Strong-radius glass island; icons stay put (no magnification): hover shows a `fillHover` plate behind the icon, press dips it to 0.9. One 4px dot per window (up to 3), bright when focused, dim when minimised, warning colour when urgent. A launching app breathes until its window shows. Pinned apps drag sideways to reorder (neighbours glide aside); a divider separates unpinned running apps. One shared tooltip above the island, after 350ms, then instant between icons. Right-click lists the app's windows, then actions. |
| Control Center | One strong-glass panel (18px radius, 10px padding) holding `fill` tiles with 8px gaps: Wi-Fi / Bluetooth / Focus rows (30px toggle disc + name + status) beside a media-or-battery tile; a row of 58px quick toggles (icon over a 10px label, white when on); one tile with the Display, Sound and Microphone sliders (6px tracks, device name opens its list); Power mode; a footer with battery and small round buttons. Lists open under the toggles. |
| Menus | Utility menu, dock menu, tray menus (TrayMenu.qml, drawn by the shell), dropdowns: `menu` colour, 26–28px rows, accent fill with white text under the pointer, ✓ for the current choice, chevrons for submenus. |
| Notifications | 344px cards on strong glass at 14px radius, 32px app icon; slide in 60px with a fade, leave by fading and drifting right. Folded cards peek out underneath. |
| Popups | Everything floats 8px below the bar (CursorPopup `topReserve: 38`), opens with a 120ms fade and 0.96→1 scale. |
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
