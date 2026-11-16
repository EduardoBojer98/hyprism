#!/usr/bin/env bash
# Checks for scripts/wallpaper-still on clips made here with ffmpeg (writes only to a temporary cache).
# Run by tests/lint.sh (CI) or by hand: tests/wallpaper-still.sh
# shellcheck disable=SC2016,SC2154  # check takes its condition as a single-quoted string on purpose (eval runs it later)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
bin=$PWD/config/scripts/.local/bin
export HYPRISM_LIB=$PWD/config/scripts/.local/lib/hyprism
if ! command -v ffmpeg >/dev/null; then
    echo "skipped: ffmpeg isn't installed"
    exit 0
fi
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
export XDG_CACHE_HOME=$t/cache
fail=0
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

ffmpeg -nostdin -loglevel error -f lavfi -i "testsrc2=s=320x180:d=2" -pix_fmt yuv420p "$t/odd name (1).mp4"
ffmpeg -nostdin -loglevel error -f lavfi -i "color=red:s=64x64:d=0.3" -pix_fmt yuv420p "$t/short.WEBM"
v=$t/odd\ name\ \(1\).mp4
want=$XDG_CACHE_HOME/hyprism/live/$(printf %s "$v" | md5sum | cut -c1-32).jpg

check "a picture is its own still" '[[ $("$bin/wallpaper-still" /some/pic.png) == /some/pic.png ]]'
out=$("$bin/wallpaper-still" "$v")
check "a video's still is named after the md5 of its path (what Wallpapers.qml computes)" '[[ $out == "$want" ]]'
check "the still is a JPEG" '[[ $(head -c 3 "$want" | od -An -tx1 | tr -d " ") == ffd8ff ]]'
before=$(stat -c %Y "$want")
sleep 1
"$bin/wallpaper-still" "$v" >/dev/null
check "a still is made only once" '[[ $(stat -c %Y "$want") == "$before" ]]'
check "a clip shorter than 1 s (upper-case extension) still gets a frame" '[[ -s $("$bin/wallpaper-still" "$t/short.WEBM") ]]'
check "a missing video prints an empty line" '[[ $("$bin/wallpaper-still" "$t/nope.mkv" | wc -c) == 1 ]]'
check "one line per file, in order" '[[ $("$bin/wallpaper-still" /a.jpg "$t/nope.mov" /b.png | paste -sd "|") == "/a.jpg||/b.png" ]]'

((fail == 0)) && echo "ok: wallpaper still"
exit "$fail"
