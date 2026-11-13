# shellcheck shell=bash
# The project is called Hyprism now: backups and records move from ~/.local/state/linux-setup
# to ~/.local/state/hyprism. Nothing is deleted.
[[ -d $OLD_STATE ]] || exit 0
for f in "$OLD_STATE"/* "$OLD_STATE"/.[!.]*; do
    [[ -e $f ]] || continue
    if [[ -e $STATE/$(basename "$f") ]]; then
        run mv "$f" "$STATE/$(basename "$f").from-linux-setup"
    else
        run mv "$f" "$STATE/"
    fi
done
run rmdir "$OLD_STATE"
