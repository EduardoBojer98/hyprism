# shellcheck shell=bash
# More old "linux-setup" names go: the shell now writes gtk-3.0/hyprism.css and gtk-4.0/hyprism.css (at its next
# start), so the old linux-setup.css files and the line in each gtk.css that imports them are removed, and
# ~/.local/share/linux-setup is removed when it only holds the old drawn wallpapers (themes/*.png).
# Nothing else is touched.
for v in gtk-3.0 gtk-4.0; do
    dir=$HOME/.config/$v
    run rm -f "$dir/linux-setup.css"
    if [[ -f $dir/gtk.css ]] && grep -qE "^@import ['\"]linux-setup\.css['\"];\$" "$dir/gtk.css"; then
        run sed -i -E "/^@import ['\"]linux-setup\.css['\"];\$/d" "$dir/gtk.css"
    fi
done
old=$HOME/.local/share/linux-setup
if [[ -d $old ]] && [[ -z $(find "$old" -mindepth 1 ! -path "$old/themes" ! -path "$old/themes/*.png" 2>/dev/null) ]]; then
    run rm -f "$old"/themes/*.png
    run rmdir "$old/themes" "$old"
fi
