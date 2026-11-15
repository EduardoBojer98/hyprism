# shellcheck shell=bash
# Four themes left the desktop (Atlas, Console, Glass, Reactor); Pebble, Poster and Monolith stay. Their links in
# ~/.local/share/hyprism/themes/ and their drawn wallpapers in ~/.cache/hyprism/wallpapers/ now point at nothing.
# Broken links of the theme folders are removed; the cached pictures are removed (they are drawn again on demand).
# Your choice of theme moves to the closest one by itself (Settings does that on the next start).
d=$HOME/.local/share/hyprism/themes
for t in atlas console glass reactor; do
    while IFS= read -r -d '' f; do
        [[ -L $f && ! -e $f ]] && run rm -f "$f"
    done < <(find "$d/$t" -depth -print0 2>/dev/null)
    [[ -d $d/$t ]] && run find "$d/$t" -depth -type d -empty -delete
    for f in "${XDG_CACHE_HOME:-$HOME/.cache}"/hyprism/wallpapers/"$t"-*.png; do
        [[ -f $f ]] && run rm -f "$f"
    done
done
true
