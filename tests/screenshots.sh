#!/usr/bin/env bash
# Retakes the README pictures from the current code, in a throwaway nested test desktop (tests/nested.sh, session
# "r", 2400x1500): docs/screenshots/themes/<id>-<mode>.webp for every theme and both modes (launcher open over
# the wallpaper), then docs/screenshots/features/*.webp, all in Reactor dark. Needs ImageMagick (magick).
# Hyprland's "started without start-hyprland" banner is gone after one config reload, so the script reloads once.
# Not part of tests/lint.sh: it opens a window and takes a minute or two. Run by hand: tests/screenshots.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export HYPRISM_TEST_NAME=r HYPRISM_TEST_SIZE=2400x1500
n=tests/nested.sh
out=$PWD/docs/screenshots
scratch=${XDG_RUNTIME_DIR:?needs a graphical session}/hyprism-shots
mkdir -p "$scratch" "$out/themes" "$out/features"
trap '$n stop >/dev/null 2>&1 || true' EXIT

$n start
$n hypr reload >/dev/null
sleep 3
$n ipc welcome close >/dev/null
sleep 1

# snap NAME DIR [magick args...]: screenshot -> DIR/NAME.webp (copied out of the test home right away)
snap() {
    local png
    png=$($n shot "$1")
    cp "$png" "$scratch/$1.png"
    magick "$scratch/$1.png" "${@:3}" -quality 82 "$out/$2/$1.webp"
    echo "wrote $2/$1.webp"
}

for dir in themes/*/; do
    id=$(basename "$dir")
    [[ $id == _template ]] && continue
    for mode in dark light; do
        $n ipc config set appearance theme "$id" >/dev/null
        $n ipc config set appearance mode "$mode" >/dev/null
        for _ in $( # up to 30 s for the theme's own wallpaper
            seq 60
        ); do
            wp=$($n ipc config get wallpaper current 2>/dev/null | tr -d '"' || true) # the shell prints it quoted
            [[ $wp == *"$id"* && -f $wp ]] && break
            sleep 0.5
        done
        [[ $wp == *"$id"* && -f $wp ]] || echo "warning: no wallpaper for $id $mode (got: $wp)" >&2
        sleep 2
        $n ipc launcher toggle >/dev/null
        sleep 1.5
        snap "$id-$mode" themes
        $n key Escape
        sleep 1
    done
done

# Features: Reactor dark
$n ipc config set appearance theme reactor >/dev/null
$n ipc config set appearance mode dark >/dev/null
sleep 3

# panel NAME OPEN CLOSE: run the open command, shoot, run the close command (both are "ipc ..." argument strings)
panel() {
    # shellcheck disable=SC2086  # the commands are word lists on purpose
    $n ipc $2 >/dev/null
    sleep 2
    snap "$1" features
    # shellcheck disable=SC2086
    $n ipc $3 >/dev/null
    sleep 1
}
panel welcome "welcome open" "welcome close"
$n ipc launcher toggle >/dev/null
sleep 1
$n ipc launcher mode actions >/dev/null
sleep 1.5
snap menu features
$n ipc launcher toggle >/dev/null
sleep 1
panel control-center "controlcenter toggle" "controlcenter toggle"
panel system "system toggle" "system toggle"
panel settings-themes "settings open appearance" "settings close"
panel settings-bar "settings open bar" "settings close"
panel notifications "notifications toggle" "notifications toggle"
panel power "power toggle" "power toggle"
panel cheatsheet "cheatsheet toggle" "cheatsheet toggle"

# the bar with the system-info item, cropped to the top 120 px
$n ipc config set appearance custom '{"reactor":{"barItems":{"start":["launcher","workspaces"],"center":["clock"],"end":["sysinfo","weather","status"]}}}' >/dev/null
$n ipc config set bar items '{"sysinfo":{"metrics":["cpu","cpu_temp","ram","net"]}}' >/dev/null
sleep 3
snap bar-sysinfo features -crop 100%x120+0+0 +repage
$n ipc config set appearance custom '{}' >/dev/null
$n ipc config set bar items '{}' >/dev/null

echo "errors:"
$n errors
