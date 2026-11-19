# Redesign round 4: research

2026-11-19. r/unixporn could not be fetched (blocked); used GitHub READMEs and mirrors of popular rices: caelestia,
noctalia, DankMaterialShell, end-4, Ax-Shell, Ambxst, HyDE, ML4W, JaKooLit.

## Desktop patterns per theme

- Pebble (calm): workspace pill that stretches (have it), popouts tied to the bar, notification stacks with peek
  edges, OSD pill (have it), art-tinted media card.
- Poster (loud): hard shadows that collapse on press, big-numeral OSD over a chunky segmented bar (done:
  `osd.style numeral`), colour-edge notification cards, bento Control Center, giant power menu with key hints.
- Monolith (terminal): `[1] 2 3` workspaces, HUD brackets that draw in, ASCII OSD (done: `osd.style ascii`),
  log-style notifications, boot-log lock screen, sparklines, `>` launcher mode.
- Avoided: glass and neon everywhere, stock Catppuccin/Tokyo palettes, wallpaper-driven palettes without limits,
  a dynamic island for everything, decorative widgets.

## Terminal and shell

- Ghostty 1.4 (`ghostty +show-config --default --docs`): `custom-shader` with cursor uniforms (`iCurrentCursor`,
  `iPreviousCursor`, `iTimeCursorChange`, `iFocus`); a shader runs a frame loop while the terminal has focus
  (`custom-shader-animation`). Done: own trail shader, opt-in, full motion and AC only. Shader packs seen:
  sahaj-b/ghostty-cursor-shaders (MIT), hackr-sh/ghostty-shaders (no licence: not bundled).
- Native: cursor style/blink, background opacity, padding (done); `background-blur` uses ext-background-effect-v1
  on Wayland (Hyprland blurs on its own: not added); quick-terminal animation is macOS only (not added).
- fish/starship: starship `enable_transience` (done), greeting (done: fastfetch, Pokémon). fzf.fish, `done`
  (unreliable on Wayland), atuin (history database): not added, new packages for little gain.
- Not done (ideas for later): Poster hard shadows collapsing on press, Monolith brackets drawing in, per-theme
  fastfetch presets, starship prompt presets per theme.
