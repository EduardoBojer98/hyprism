# shellcheck shell=bash
# Migration 0003 removed the import of the old linux-setup.css from each GTK gtk.css only when that import was alone
# on its line. Where it shared a line with another import, GTK still looks for the deleted file and apps warn about
# it. That one import is removed from ~/.config/gtk-3.0/gtk.css and gtk-4.0/gtk.css; the rest of the line stays.
for v in gtk-3.0 gtk-4.0; do
    f=$HOME/.config/$v/gtk.css
    # shellcheck disable=SC2015  # skip unless the file exists and has the import: both cases continue
    [[ -f $f ]] && grep -qE "@import ['\"]linux-setup\.css['\"];" "$f" || continue
    run sed -i -E "s/@import ['\"]linux-setup\.css['\"];//; T; /^[[:space:]]*\$/d" "$f"
done
