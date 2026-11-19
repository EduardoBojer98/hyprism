# Redesign round 4: report

Branch `redesign` from `develop` 61ef5d2. Audit: [AUDIT.md](AUDIT.md). Plan: [PLAN.md](PLAN.md). State: [STATE.md](STATE.md).

## Summary

The audit found a mature desktop: 244 settings all wired, no broken or visual-only control, idle cost near zero,
three distinct themes that read well in all six halves. So this round hardened and unified instead of
redrawing: a complete token set with a lint guard, real state behind every Control Center tile, a reduced-motion
fix, and review fixes. No new look was forced on Pebble, Poster or Monolith (PLAN.md weighs the directions).

## Completed (verified)

- Tokens: motion (`easing`, `pulse`, `blink`, `pop`, `popFade`, `stagger`, `popFrom`, `popOvershoot`), five glyph
  steps (`glyphXs`..`glyphL`, `iconLarge`; were 12 sizes in 23 files), `fontBadge`. 44 `Easing.OutCubic` and every
  literal duration/size moved to tokens. Checked: lint, nested screenshots in Pebble/Poster/Monolith.
- Theme id out of the tokens: Monolith's accent segmented controls are `popup.segments` in theme.json.
- `tests/no-hardcode.sh` fails on a literal `duration:`, `Easing.OutCubic` or `pixelSize:` in the shell (tested
  with a planted file, single- and multi-line).
- Reduced motion: Launchpad's wave (scale 0.6 + overshoot) now runs only in full motion.
- Control Center: small tiles share one label size per grid (screenshot: Monolith and Pebble).
- Real controls: Wi-Fi, Bluetooth, Airplane, Touchscreen, On-screen keyboard tiles appear only with their
  hardware or program (new Conditions flags `touchscreen`, `osk`); OSK state read back from squeekboard; touchscreen
  state read from Hyprland at start; bar menu ticks your own toggles that are on. Checked: nested CC screenshot
  (Touch tile gone without a touchscreen), `nested.sh errors` clean of new warnings.
- Quick Look decodes pages near the shown size (x2 for scaled screens).
- Keyboard walk: Control Center, Settings sidebar and launcher show a focus ring / selection and move with keys.
- Second screen at 1.2 (`nested.sh screens2`): bar, dock and launcher fine.
- Per-theme OSD (theme.json `osd.style`, from the research in RESEARCH.md): Pebble thin bar, Poster big number over
  ten blocks, Monolith mono `[████░░] 70` meter. Checked: nested screenshots of all three.
- Settings > Appearance > Terminal (new `terminal` section, 7 keys): Ghostty cursor shape, blink, cursor trail (own
  shader `ghostty/shaders/hyprism-trail.glsl`, only in full motion and on AC), background, padding, live through
  `ghostty/theme.conf`; fish transient prompt and greeting (default, off, fastfetch, Pokémon) through
  `hyprism/fish.fish`. "Theme" takes each theme's `term.cursorStyle`/`blink`/`padding`. Checked in the test desktop:
  real Ghostty with the shader (trail drawn, no black window), `ghostty +validate-config`, the transient prompt,
  the greeting, the block cursor kept at the prompt (`shell-integration-features = no-cursor`).
- Pokémon greeting: `pokemon-colorscripts --random --no-title` (1 in 16 `--shiny`) as fastfetch's logo; package
  `pokemon-colorscripts-git` (cachyos repo; AUR on plain Arch; none on Fedora, where the distro logo shows).
  fastfetch card redesigned: icon per line in the palette's colours, usage bars for memory, disk, battery.
- Docs: DESIGN.md token table, THEMES.md `popup.segments`, CHANGELOG (Fixed).
- Review (`/code-review high` on develop..redesign): 8 findings; 6 fixed, 1 not needed (Wi-Fi device stays listed
  with the radio off), 1 skipped (a dead "Unavailable" branch kept for the Control Center editor).

## Partial

- Teardown warnings in ControlCenterWifiRow.qml:13,18,40 and Sys.qml:76 (undefined while a network goes away):
  harmless, not fixed.
- ThemePreview.qml:33 warns for theme wallpapers not drawn yet (the card shows the ground colour until drawn).
- DDC external-brightness slider stays optimistic (`--noverify`, no read-back): a read takes about a second.
- Touchpad tile: Hyprland has no read for a device's `enabled`, so the tile starts at "on" after a shell restart.

## Not verified (needs real hardware or the live desktop)

- pokemon-colorscripts itself: not installed here (needs sudo); tested with a stand-in that takes the same flags.
  The flags (`--random`, `--no-title`, `--shiny`) are from its docs, not run.
- The cursor trail's look over time (one frame caught mid-trail); its CPU while a terminal is focused (Ghostty: a
  frame loop, "generally less than 10%"), hence off by default and off on battery.

- On-screen keyboard tile: not clicked in the test desktop (busctl reaches the live session's squeekboard).
- Touchscreen read-back, Wi-Fi/Bluetooth gating on machines without those radios, NVIDIA, real multi-monitor,
  Fedora on metal, battery and power modes.
- No new QML files. One new file outside QML: `config/ghostty/.config/ghostty/shaders/hyprism-trail.glsl`, so run
  `./install.sh --only links` (merge steps below).

## Removed

- Nothing a user sees. The per-label auto-shrink in ControlCenterQuickToggle.qml was replaced by the grid's size.
- Hidden when unavailable (not removed): the five tiles above.

## Performance (tests/performance.sh, nested, idle 30 s, CPU % default bar / sysinfo bar)

- Baseline develop: 0.03 / 0.20, 178 / 333 MB. Redesign: 0.03 / 0.27 in the matched run; memory equal within noise
  (330-386 MB both).
- Spikes of 1.6-3.9 % came on both trees in alternating runs (develop 1.90/1.83, 1.57/2.93; redesign 0.03/3.90), so
  they are machine noise from the live session, not this branch. No timer or animation runs at idle in the new code
  (the OSD and Terminal options draw only when shown; the trail shader runs only in a focused terminal, opt-in).

## Tests

- `bash tests/lint.sh`: pass (includes no-hardcode, accessibility, theme contrast, settings reference, docs).
- `python3 tests/settings-coverage.py`: 244 options, 0 gaps. `bash tests/docs.sh`: pass.
- `tests/all.sh` baseline on develop: all six parts ok. Final on redesign (b1576bb): all six parts ok (lint, install-arch, install-fedora, update-arch, update-fedora, system).

## Merge and apply (owner)

```bash
cd ~/Documents/projects/linux-setup && git switch develop && git merge --ff-only redesign
```

```bash
./install.sh --only links
```

Then restart the shell (`qs kill` until none is left, then start `qs` again, or log out and in), and open a new
terminal. For the Pokémon greeting install its package:

```bash
./install.sh --only tools
```

Settings: one new section (`terminal`) whose keys all default from ConfigData, so older settings files need nothing;
no key moved or changed meaning, so no migration and no format bump. Theme files gained keys (`osd.style`,
`term.cursorStyle`, `blink`, `padding`); a theme without them keeps the old look.
