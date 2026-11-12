#!/usr/bin/env bash
# Checks for scripts/wallpaper-colours on pictures made here with ImageMagick (nothing on this computer changes).
# Run by tests/lint.sh (CI) or by hand: tests/wallpaper-colours.sh
# shellcheck disable=SC2016,SC2154,SC2329  # check takes its condition as a single-quoted string on purpose (eval runs it later)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
bin=$PWD/config/scripts/.local/bin
export HYPRISM_LIB=$PWD/config/scripts/.local/lib/hyprism
if ! command -v magick >/dev/null; then
    echo "skipped: ImageMagick isn't installed"
    exit 0
fi
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
fail=0
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

magick -size 200x120 xc:'#e8741a' -fill '#2060d0' -draw 'rectangle 0,0 50,40' "$t/orange.png"
magick -size 200x120 xc:'#d9b8e8' -fill '#b8e0d0' -draw 'rectangle 0,0 90,120' "$t/pastel.png"
magick -size 200x120 gradient:'#202020-#e0e0e0' "$t/grey.png"
dark=#141414 light=#f5f5f5

# ok_pair JSON SURFACE: two #rrggbb colours, each at least 3:1 against SURFACE
ok_pair() {
    python3 -I - "$1" "$2" <<'PY'
import json, re, sys
d = json.loads(sys.argv[1]); s = sys.argv[2]
def lum(h):
    c = [int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    c = [v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
def ratio(a, b):
    x, y = sorted((lum(a), lum(b)), reverse=True)
    return (x + 0.05) / (y + 0.05)
cols = [d.get("accent", ""), d.get("accent2", "")]
sys.exit(0 if all(re.fullmatch(r"#[0-9a-f]{6}", c) and ratio(c, s) >= 3 for c in cols) else 1)
PY
}
# hue_of #rrggbb: degrees
hue_of() { python3 -I -c 'import colorsys,sys; h=sys.argv[1]; print(round(colorsys.rgb_to_hls(*[int(h[i:i+2],16)/255 for i in (1,3,5)])[0]*360))' "$1"; }

for pic in orange pastel; do
    for m in dark light; do
        s=$dark
        [[ $m == light ]] && s=$light
        out=$("$bin/wallpaper-colours" "$t/$pic.png" "$m" 2>&1)
        check "$pic ($m): two colours, each 3:1 on the surface" 'ok_pair "$out" "$s"'
    done
done
out=$("$bin/wallpaper-colours" "$t/orange.png" dark | python3 -I -c 'import json,sys; print(json.load(sys.stdin)["accent"])')
h=$(hue_of "$out")
check "the orange picture's accent hue is orange (got $h degrees)" '((h >= 15 && h <= 45))'
out=$("$bin/wallpaper-colours" "$t/orange.png" dark '#0a1a2a')
check "a given surface is used" 'ok_pair "$out" "#0a1a2a"'
check "a grey picture prints {}" '[[ $("$bin/wallpaper-colours" "$t/grey.png" dark) == "{}" ]]'
check "a bad mode is refused" '! "$bin/wallpaper-colours" "$t/orange.png" sepia >/dev/null 2>&1'
cp "$t/orange.png" "$t/odd name (1)+x.png"
check "a path with spaces and brackets works" '[[ $("$bin/wallpaper-colours" "$t/odd name (1)+x.png" dark) == \{* ]]'

((fail == 0)) && echo "ok: wallpaper colours"
exit "$fail"
