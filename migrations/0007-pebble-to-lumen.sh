# shellcheck shell=bash
# Pebble was redesigned as Lumen (2026-11-25). Pebble's links in ~/.local/share/hyprism/themes/pebble/ now point
# at nothing, and its drawn wallpapers in ~/.cache/hyprism/wallpapers/ are no longer used. Broken links and the
# emptied folder are removed, and the cached pictures (pebble-*.png). A saved "pebble" moves to Lumen by itself
# (Config.qml renamedThemes).
d=$HOME/.local/share/hyprism/themes/pebble
while IFS= read -r -d '' f; do
    [[ -L $f && ! -e $f ]] && run rm -f "$f"
done < <(find "$d" -depth -print0 2>/dev/null)
[[ -d $d ]] && run find "$d" -depth -type d -empty -delete
for f in "${XDG_CACHE_HOME:-$HOME/.cache}"/hyprism/wallpapers/pebble-*.png; do
    [[ -f $f ]] && run rm -f "$f"
done
true
