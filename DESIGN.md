---
name: linux-setup shell
description: Dark frosted-glass Quickshell desktop shell for Hyprland, built from floating glass complications.
colors:
  glass: "rgba(13, 13, 20, 0.42)"
  glass-strong: "rgba(13, 13, 20, 0.70)"
  stroke: "rgba(255, 255, 255, 0.10)"
  highlight: "rgba(255, 255, 255, 0.07)"
  fill: "rgba(255, 255, 255, 0.07)"
  fill-hover: "rgba(255, 255, 255, 0.12)"
  fill-active: "rgba(255, 255, 255, 0.18)"
  ink: "#eceffa"
  ink-soft: "rgba(237, 240, 250, 0.64)"
  ink-muted: "#6e738d"
  macchiato-blue: "#8aadf4"
  macchiato-blue-wash: "rgba(138, 173, 244, 0.18)"
  macchiato-blue-edge: "rgba(138, 173, 244, 0.70)"
  macchiato-lavender: "#b7bdf8"
  on-accent: "#0f1117"
  signal-amber: "#eed49f"
  signal-peach: "#f5a97f"
  signal-red: "#ed8796"
  state-green: "#a6da95"
typography:
  display:
    fontFamily: "Inter"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 0.95
    fontFeature: "tnum"
  title:
    fontFamily: "Inter"
    fontSize: "13px"
    fontWeight: 600
  body:
    fontFamily: "Inter"
    fontSize: "13px"
    fontWeight: 400
  label:
    fontFamily: "Inter"
    fontSize: "12px"
    fontWeight: 600
    fontFeature: "tnum"
  caption:
    fontFamily: "Inter"
    fontSize: "11px"
    fontWeight: 400
  gauge:
    fontFamily: "Inter"
    fontSize: "11px"
    fontWeight: 600
    fontFeature: "tnum"
  icon:
    fontFamily: "JetBrainsMono Nerd Font"
    fontSize: "16px"
rounded:
  sm: "12px"
  md: "16px"
  lg: "22px"
  full: "9999px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "10px"
  lg: "12px"
  capsule-x: "14px"
  clock-x: "22px"
components:
  capsule:
    backgroundColor: "{colors.glass}"
    textColor: "{colors.ink}"
    rounded: "{rounded.full}"
    padding: "0 14px"
    height: "40px"
  capsule-hover:
    backgroundColor: "rgba(31, 33, 46, 0.55)"
  capsule-active:
    backgroundColor: "{colors.macchiato-blue-wash}"
  workspace-pill:
    backgroundColor: "{colors.fill}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label}"
    rounded: "{rounded.sm}"
    width: "24px"
    height: "24px"
  workspace-pill-active:
    backgroundColor: "{colors.macchiato-blue}"
    textColor: "{colors.on-accent}"
    width: "34px"
  ring-gauge:
    textColor: "{colors.ink}"
    typography: "{typography.gauge}"
    size: "32px"
  glass-panel:
    backgroundColor: "{colors.glass-strong}"
    textColor: "{colors.ink}"
    rounded: "{rounded.lg}"
  pill-button:
    backgroundColor: "{colors.fill}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: "0 14px"
    height: "30px"
  pill-button-primary:
    backgroundColor: "{colors.macchiato-blue}"
    textColor: "{colors.on-accent}"
  toggle:
    backgroundColor: "{colors.fill-active}"
    rounded: "{rounded.full}"
    width: "42px"
    height: "24px"
  toggle-on:
    backgroundColor: "{colors.macchiato-blue}"
  slider:
    backgroundColor: "{colors.fill}"
    textColor: "{colors.on-accent}"
    rounded: "{rounded.full}"
    height: "32px"
---

# Design System: linux-setup shell

## Overview

**Creative North Star: "Glass Complications"**

The shell is a set of separate floating instruments over the wallpaper, each a dark frosted object that reads one live thing. Hyprland blurs whatever sits behind every `qs-*` layer; the QML only lays a near-black tint, a hairline white stroke and a soft top-lit highlight over that blur. Nothing is opaque, nothing is edge-to-edge. The top bar is the clearest example: capsules float 10px below the screen edge with 8px gaps where the wallpaper shows through, and the clock in the centre carries the largest type.

Ink is white. Colour is a signal, not decoration: Macchiato blue says "this is where you are / this is open", amber and red say "this value has left normal range". Everything else, including rings, glyphs and labels, stays in white or a neutral soft white. Numbers are always tabular so live values do not jitter.

Density is calm but rich. Type stays between 11px and 20px; rank comes from size and weight, never from colour. Motion is short and eased out (220ms default, OutCubic), with one slower 600ms ease on gauge values so temperature changes glide instead of jumping.

**Key Characteristics:**
- Dark frosted glass over compositor blur: tint + 1px white stroke + top highlight.
- Separate pill-shaped complications with gaps, never one strip.
- White ink; blue only for active/open; amber/red only off-normal.
- Inter with tabular figures; JetBrainsMono Nerd Font for icons.
- Ring gauges that carry real values.

## Colors

A near-monochrome white-on-dark-glass palette with Catppuccin Macchiato hues held back as signals.

### Primary
- **Macchiato Blue** (`macchiato-blue`): the only "you are here" colour. Active workspace pill fill, Control Center tile icon discs when on, toggle on, primary pill button, selected list rows, the dock launcher on hover/open, the dock running indicator. Its wash (`macchiato-blue-wash`) and edge (`macchiato-blue-edge`) form an open capsule: the status or power capsule while its panel is showing.

### Tertiary
- **Macchiato Lavender** (`macchiato-lavender`): lives only in Hyprland's active window border gradient (blue to translucent white to lavender, 135 degrees). The QML token `accent2` exists but no shell surface uses it.

### Neutral
- **Glass Tint** (`glass`): bar capsules, dock, OSD. Sits over Hyprland blur.
- **Strong Glass** (`glass-strong`): Control Center, launcher, power menu, notifications, Settings: any surface with lots of text.
- **Hairline** (`stroke`): 1px border on every glass surface and secondary button.
- **Top Light** (`highlight`): the top half of every glass surface, fading to transparent at 50%.
- **Fills** (`fill`, `fill-hover`, `fill-active`): idle, hovered and pressed controls on glass; also slider tracks and idle workspace pills.
- **White Ink** (`ink`): primary text, glyphs, ring arcs at normal values, slider fill (at 0.92 opacity).
- **Soft Ink** (`ink-soft`): secondary text such as date, weather city, window title, CPU/GPU labels, keyboard layout. Neutral white at 64%, deliberately no blue cast.
- **Muted Ink** (`ink-muted`): empty workspaces, muted volume, inactive hints.
- **On-Accent Ink** (`on-accent`): text and icons sitting on blue or white fills.

### Signals
- **Amber** (`signal-amber`): a value at its warn threshold (ring gauges at 80 by default); unsaved Settings changes.
- **Peach** (`signal-peach`): urgent workspace (at 0.3 alpha), critical notification border, Performance power profile.
- **Red** (`signal-red`): alert threshold (ring at 90), low battery (15% or less, not charging), no network, the Shut down item.
- **Green** (`state-green`): charging battery in the Control Center, Quiet power profile.

### Named Rules
**The Two-Signal Rule.** Blue means active or open; amber, peach and red mean out of normal range. A value in normal range is white. If a colour does not answer one of those two questions, it should not be on screen.

**The Neutral Subtext Rule.** Secondary text is white at reduced alpha, never a tinted grey. A blue-grey subtext reads as a second accent on dark glass.

## Typography

**Display Font:** Inter
**Body Font:** Inter
**Icon Font:** JetBrainsMono Nerd Font (Material Design Icons code points)

**Character:** One neutral grotesque at small sizes, with weight doing the ranking. Icons come from one icon font so their stroke weight stays the same everywhere.

### Hierarchy
- **Display** (700, 20px, line-height 0.95, tabular): the bar clock only; also the launcher search text at 20px regular.
- **Title** (600, 13px): focused app name, weather temperature, notification titles.
- **Body** (400, 13px, the `Theme.fontSize`): menu items, list rows, general panel text.
- **Label** (600, 12px, tabular for numbers): workspace numbers, battery percentage, CPU/GPU labels, pill buttons.
- **Caption** (400, 11px): date under the clock, weather city and condition. The floor.
- **Gauge** (600, 11px, tabular): the value inside a ring, with a degree sign.
- **Icon** (16px default): status glyphs. 15px in chips, menus and slider tracks, 18px for weather, 20 to 22px in the dock, OSD and Control Center header.

### Named Rules
**The Tabular Figures Rule.** Every live number (clock, temperatures, battery, workspace ids) sets `features: { "tnum": 1 }`. Values that tick must not shift their neighbours.

**The 11px Floor Rule.** No text below 11px. The only 10px use (a keycap hint in the launcher) is drift, not precedent.

**The Rank-By-Size Rule.** Importance is shown by size and weight: the clock is the one 20px bold element in the bar. Do not promote anything with colour instead.

## Layout

The top bar is a 64px-tall transparent layer with an inner area inset 10px from the top, 12px from the sides and 14px from the bottom. Three groups: a left row (workspaces, focused app, weather), a capsule centred on the screen (clock), and a right row (temperatures, tray, status, power). Capsules in a row sit 8px apart. Inside a capsule, content is a vertically centred row with 10px spacing by default (12px in the status capsule, 8px in temperatures, 4px in the tray) and 14px horizontal padding (22px for the clock, 12px for the icon-only power capsule).

Popups hang 12px below their bar anchor. Panels use internal margins of 7 to 12px; the Control Center is 380px wide, notifications 360px, the OSD a 260 by 48px pill 110px above the bottom edge. Hyprland windows use 5px inner and 12px outer gaps, which match the shell's 12px edge inset.

The bar is the same on both screens (laptop 1920x1200, Acer 2560x1440). On the screen without focus, the focused-app capsule shows that screen's visible window at 0.7 opacity.

### Named Rules
**The Separate Complications Rule.** Bar content lives in separate capsules with wallpaper showing between them. Do not join them into an edge-to-edge strip or put unrelated readouts in one capsule.

## Elevation & Depth

Depth comes from compositor blur plus translucency, then a soft drop shadow so things float. Hyprland's `blur-shell` layer rule blurs every `qs-*` namespace and its popups (size 10, 3 passes, brightness 0.85, vibrancy 0.25, `ignore_alpha` 0.05 so even the faint glass blurs). Over that, each surface layers its tint, a 1px hairline and a top highlight gradient.

### Shadow Vocabulary
- **Capsule float** (MultiEffect: black at 0.32, vertical offset 4, blur 0.6): every bar capsule. Soft and diffuse, not a hard edge.
- **Window shadow** (Hyprland: range 28, render power 4, offset 0 6, `0x66000000` active / `0x33000000` inactive): application windows.
- **Scrim** (black at 0.18 behind Control Center and Settings content areas; 0.35 behind the open launcher): separates a modal layer from the desktop.

### Named Rules
**The Glass Recipe Rule.** A shell surface is tint + 1px `stroke` + top `highlight` fading out by 50% height, over Hyprland blur. Never ship an opaque panel, and never a surface whose namespace does not start with `qs-` (it will not be blurred).

## Shapes

Everything is rounded, and anything one row tall is a full pill (`radius: height / 2`): capsules, buttons, toggles, sliders, the OSD, workspace pills. Containers step through three radii: 12px for rows and tiles inside panels, 16px for the default glass surface and Control Center tiles (matching Hyprland's window rounding of 16 with power 2.4), and 22px for large panels (Control Center, launcher, dock, power menu). Circular discs (34px, radius 17) hold tile icons. Borders are always 1px.

## Components

### Capsule (signature)
A floating glass complication, 40px tall, full pill.
- **Rest:** `glass` tint, hairline stroke, top highlight, capsule float shadow.
- **Hover (interactive only):** tint deepens to a darker blue-black at 0.55, 220ms colour ease.
- **Active (its panel is open):** blue wash fill with blue edge stroke.
- **Interaction:** click opens its panel; scroll on the status capsule changes volume by 5%.

### Workspace Pills
24px circles in the workspaces capsule; the current one stretches to 34px wide and fills with blue (width eases 220ms OutCubic). The number is the label style: on-accent ink when current, white when the workspace has windows, muted when empty. Hover is `fill-hover`; urgent is peach at 0.3.

### Ring Gauge (signature)
A 32px ring with a 2.5px round-capped stroke: a white track at 0.14 and an arc from twelve o'clock proportional to the value between min and max (30 to 100 for temperatures). The value sits inside at 11px DemiBold tabular with a degree sign, "–" when unknown. Arc and number turn amber at warn and red at alert. The arc moves with a 600ms OutCubic ease.

### Buttons
- **Shape:** full pill, 30px tall, 14px horizontal padding.
- **Secondary:** `fill` with hairline stroke, white 12px DemiBold label; hover goes to `fill-hover`.
- **Primary:** solid blue with on-accent label, no stroke; hover lightens blue by 8%.
- **Disabled:** 0.45 opacity.

### Chips
Transparent 26px pills with a 15px icon and optional 13px Medium label; hover `fill-hover`, active `fill-active`. Colour changes ease over 220ms.

### Toggle and Slider
- **Toggle:** 42 by 24 pill, `fill-active` off, blue on, 18px white knob that slides in 160ms OutCubic.
- **Slider:** 32px pill track in `fill`, white fill at 0.92 that never gets narrower than a circle, on-accent icon set inside the track at the left; scroll steps 5%.

### Glass Panel
Control Center, launcher, power menu, notifications and Settings use strong glass at 22px radius (16px for notification cards). Rows inside are 38px with 12px radius and `fill-hover` on hover. Danger actions tint only their icon red.

### Navigation (Dock)
A strong-glass island at 22px radius; 12px-radius icon tiles, the launcher tile filling blue on hover/open, a blue running dot, and 6px-radius tooltips.

## Do's and Don'ts

### Do:
- **Do** build every new shell surface from `Glass` (or `Capsule` in the bar) and the `Theme` tokens, in a `qs-*` layer namespace so Hyprland blurs it.
- **Do** keep values in normal range white and reach for `signal-amber` / `signal-red` only past a defined threshold.
- **Do** set tabular figures on every live number.
- **Do** use full pills for anything one row tall and 12 / 16 / 22px for containers.
- **Do** ease state changes over `Theme.anim` (220ms), OutCubic for movement.

### Don't:
- **Don't** use blue for decoration, branding or emphasis; it means active or open only.
- **Don't** set text below 11px or tint secondary text blue-grey.
- **Don't** make a shell surface opaque or join the bar capsules into a single strip.
- **Don't** use hard-edged offset shadows; the capsule shadow is soft (blur 0.6) and the only shadow the shell draws itself.
