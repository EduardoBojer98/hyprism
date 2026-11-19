# Redesign round 4: plan

From AUDIT.md. The audit found a mature system: every setting wired, no broken or visual-only control, idle cost
near zero. So this round is a hardening and consistency pass, not a new look. Reopening the round-3 theme designs
needs new evidence; the screenshots gave none.

## Directions per theme (judged on the sweep screenshots)

- Pebble (calm): (a) keep: river-stone greys, lichen accent, wash tiles, soft depth; (b) warmer paper tone;
  (c) glass material. Chosen: (a). It is the default and reads calm already; (b) blurs it into Poster's paper,
  (c) costs blur on every panel for no gain in a solid wallpaper world.
- Poster (loud): (a) keep: paper and ink, red block selection, hard offset shadows, slam motion; (b) add a second
  display face; (c) dark-first. Chosen: (a). It is the only neo-brutalist world; a second face breaks "at most one
  display face".
- Monolith (terminal, owner's live theme): (a) keep: neon HUD, mono everywhere, accent segments, brackets;
  (b) amber CRT palette; (c) no glow. Chosen: (a); the owner lives in it. Its one id check becomes data.

## Token and motion changes

- Glyph scale: glyphXs 12, glyphS 14, glyph 16, glyphL 20, iconLarge 32; fontBadge 9. Five steps instead of 12.
- Motion: `easing` everywhere a small change animates; `pulse` (breathing), `blink` (cursor), `pop`/`popFade`/
  `stagger`/`popFrom`/`popOvershoot` (group entrance, full motion only).
- `popup.segments` theme data instead of a theme-id check.
- Guard: `tests/no-hardcode.sh` fails on literal durations, OutCubic and font sizes.

## Tasks (in order; all by the lead, the files are small and shared, so no parallel writers)

1. Tokens + guard (Theme.qml, 23 component files, tests/no-hardcode.sh). Test: lint, sweep. Done 5bf0857.
2. Real controls (BuiltinActions, Conditions, Inputs, Osk, Bar). Test: nested CC screenshot. Done e681bbc.
3. Warnings: ThemePreview before the wallpaper exists; Wi-Fi row teardown. Test: `nested.sh errors`.
4. Keyboard-only walk: launcher, Control Center, Settings; fix any missing focus ring.
5. Second screen at 1.2 (`nested.sh screens2`) shots; fix what looks off.
6. Docs: DESIGN.md tokens and motion, THEMES.md (done for segments), CHANGELOG.
7. Verification: lint, `tests/all.sh`, performance vs baseline, `/code-review high` on develop..redesign.

## Risks

- Glyph consolidation moves some icons by 1-2 px (15 to 14, 17 to 16, 19/22 to 20). Checked on screenshots.
- Inputs switches touch devices on at shell start: a user who turned the touchpad off and restarts the shell gets
  it back on. Intended ("not saved", Inputs.qml header) and now matches the tile.
- No settings keys or file layouts change, so no migration and no format bump.
