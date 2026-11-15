#!/usr/bin/env bash
# The capture helpers (config/scripts/.local/lib/hyprism/capture.sh) against a made-up settings.json and a stand-in
# hyprctl: the settings are read, the folder is made, and click-to-pick boxes are the windows showing now.
#   tests/capture.sh
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
fail=0
expect() { if [[ $2 == "$3" ]]; then echo "ok: $1"; else
    echo "xx $1: expected '$3', got '$2'"
    fail=1
fi; }

mkdir -p "$t/bin"
cat >"$t/bin/hyprctl" <<'EOF'
#!/bin/sh
case "$*" in
*monitors*) echo '[{"activeWorkspace":{"id":1},"specialWorkspace":{"id":0}},{"activeWorkspace":{"id":4},"specialWorkspace":{"id":-98}}]' ;;
*clients*) echo '[{"mapped":true,"hidden":false,"workspace":{"id":1},"at":[0,0],"size":[800,600],"focusHistoryID":1},{"mapped":true,"hidden":false,"workspace":{"id":4},"at":[900,10],"size":[300,200],"focusHistoryID":0},{"mapped":true,"hidden":false,"workspace":{"id":2},"at":[1,1],"size":[5,5],"focusHistoryID":2},{"mapped":true,"hidden":false,"workspace":{"id":-98},"at":[50,50],"size":[100,100],"focusHistoryID":3}]' ;;
esac
EOF
chmod +x "$t/bin/hyprctl"
echo "{\"capture\":{\"folder\":\"$t/shots\",\"after\":\"copy\",\"audio\":\"both\"}}" >"$t/settings.json"

export HYPRISM_SETTINGS=$t/settings.json PATH="$t/bin:$PATH" HOME=$t
# shellcheck source=config/scripts/.local/lib/hyprism/capture.sh
. config/scripts/.local/lib/hyprism/capture.sh
expect "a setting is read" "$(cap after)" copy
expect "an unset setting is empty" "$(cap delay)" ""
expect "the folder is made and returned" "$(folder folder /nowhere)" "$t/shots"
if [[ -d $t/shots ]]; then echo "ok: the folder exists"; else
    echo "xx the folder was not made"
    fail=1
fi
expect "an unset folder falls back" "$(folder recordFolder "$t/videos")" "$t/videos"
expect "boxes: shown workspaces only, newest focus first" "$(window_boxes | paste -sd'|')" "900,10 300x200|0,0 800x600|50,50 100x100"
SETTINGS=$t/none.json
expect "no settings file is fine" "$(cap after)" ""
exit "$fail"
