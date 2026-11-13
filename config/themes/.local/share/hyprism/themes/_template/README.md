# Make a theme

1. Copy this folder to `~/.config/hyprism/themes/<id>/` (lower-case letters, digits and dashes). To ship it with
   Hyprism, copy it into the repo's `themes/` instead.
2. Edit `theme.json`. Every part is explained in `docs/THEMES.md`. A part you leave out keeps a safe default,
   so you can start with just `name`, `colour` and `alt.colour`.
3. Wallpaper: put a picture named `<id>.png` (and `<id>-light.png` or `<id>-dark.png` for the other half) in
   the folder, or write a recipe in `wallpaper.sh`.
4. `theme <id>` switches to it. `python3 tests/themes.py` checks its contrast.
