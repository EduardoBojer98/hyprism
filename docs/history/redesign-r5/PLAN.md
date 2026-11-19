# Redesign round 5: plan

2026-11-19. Goal: each theme should be recognisable from any single panel, not just from its colours.

## What the screenshots show (nested, all three themes: desktop, Control Center, launcher)

- Colour, radius, frame and font differ, but the **structure** is the same everywhere. The launcher is the same
  icon grid with category chips, the Control Center is the same 4-column tile grid, and notifications are the same
  card in a different corner.
- Pebble reads as "default dark UI". Its panels are small and grey, and nothing feels soft or tactile.
- Poster has the strongest identity (frame, colour blocks, display type), but its Control Center is still a small
  white tile grid.
- Monolith's bar is right, but the launcher and Control Center are a dark copy of Pebble's. Nothing there reads
  as a terminal or HUD.
- Left over from round 4: Poster press shadows, Monolith brackets drawing in, terminal presets per theme.

## Rule for every track

- A new look is a **variant picked by a theme.json key**, like `osd.style`. The variant's code lives in the
  component, and the three themes pick different ones.
- No new settings. The user picks the theme; the theme picks the variants.
- Every variant must work in light and dark, at narrow widths, with the keyboard, and in reduced motion.
- Each track edits only its own theme.json key, on its own line, so the tracks merge cleanly.

## Tracks (independent: separate files)

### A. Launcher (`Launcher*.qml`; theme.json `launcher.layout`)

- **Pebble `grid`**:
  - A large rounded search pill with a soft shadow.
  - A "Recent" row above the grid.
  - Icons sit on squircle plates; the selection is a soft wash that springs in.
- **Poster `sheet`**:
  - The typed query is the header, in the display font at about 48 px.
  - Results are a big list: a bold name and a category tag.
  - The selection is an inverse block with a hard offset shadow.
  - A first-letter index runs down the left edge.
- **Monolith `prompt`**:
  - A `❯ query_` line with a blinking block caret.
  - Results are a text list with dim index numbers (`01`), small icons and a `>` marker on the selection.
  - Key hints are written as `[enter] open  [tab] mode`. Matches are highlighted in accent.

### B. Control Center (`ControlCenter*.qml`; theme.json `popup.layout`)

- **Pebble `cards`**:
  - Grouped soft cards with fat pill sliders and the icon inside the track.
  - The media card is tinted by the album art.
  - Toggles are rounded tiles with a subtitle.
- **Poster `bento`**:
  - A bento grid of different-sized tiles. Wi-Fi and Bluetooth are wide; on-tiles are solid colour blocks.
  - Every tile has a hard shadow that collapses on press.
  - Section labels are in the display font.
- **Monolith `hud`**:
  - Section headers like `// sound` and ascii meters for the sliders (`vol [████████░░] 80`).
  - Toggles look like `[x] wifi  Hyprism-5G` and power mode like `mode: <balanced>`.
  - Bracket corners draw in when the panel opens.

### C. Notifications (`Notification*.qml`; theme.json `notify.kind`, which already exists)

- **Pebble `card`**:
  - Stacked cards with peek edges: a group shows 2 card edges behind the top card.
  - The app icon sits in a soft circle; cards slide in with a fade.
- **Poster `block`**:
  - A thick accent bar on the left, the title in the display font, a hard shadow.
  - Cards slide in from the left with a small overshoot.
  - The urgent card is red.
- **Monolith `line`**:
  - Log lines, newest on top like `tail -f`: `23:19 [firefox] Download done — file.zip`.
  - Actions are written as `[open] [dismiss]`. A new line types in.

### D. Lock screen and power menu (`LockScreen.qml`, `LockPreview.qml`, `PowerMenu.qml`)

- **Pebble**: a centred big clock over a blurred wallpaper, a greeting, a media pill and a soft password pill.
- **Poster**:
  - A stacked giant clock on the left over a colour-block composition.
  - The power menu has giant blocks with key hints (`L` lock, `S` sleep, `R` restart, `P` power off).
- **Monolith**:
  - A boot-log intro (`[ ok ] session locked`) that types in, then a `login: eduardo` / `password: ****_`
    prompt.
  - The power menu is a numbered list (`1) lock  2) sleep ...`).

### E. Terminal presets per theme (`ThemeSync.qml` starship and fastfetch, `config/starship`, `config/fastfetch`)

- **Pebble**: rounded pills (today's prompt) and a rounded card frame.
- **Poster**: square blocks with no rounded caps, bold section heads in caps (`HARDWARE`), a thicker rail.
- **Monolith**: `[~/dir] [git:main]` brackets with no powerline glyphs, a `+--` ascii frame and `>` bullets.
- ThemeSync picks the preset by theme, the same way it already swaps the palette.

### F. Signature motion (shared controls: `PillButton`, `Chip`, `Toggle`, `PopupDepth`, `Glass`)

- **Poster**: the hard shadow collapses on press (the control moves 3–4 px into its shadow).
- **Monolith**: bracket corners draw in on open (`popup.decor brackets`), and focus moves as a reticle.
- **Pebble**: a small spring overshoot on open, and a press that sinks softly.
- Reduced motion turns all of these off.

## Done means

- In every track, each theme's variant is screenshotted in the test desktop (`tests/nested.sh`) in light and dark,
  and judged against the description above.
- These pass: `tests/lint.sh`, `tests/accessibility.sh`, `tests/no-hardcode.sh`, `tests/settings-coverage.py`
  and `tests/docs.sh`.
- `CHANGELOG.md` is updated, and `docs/THEMES.md` documents the new keys.
- Before/after screenshots go into `docs/history/redesign-r5/`.
