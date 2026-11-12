#!/usr/bin/env bash
# Static checks for the desktop's own code, run by CI (.github/workflows/ci.yml) and by hand:
#   tests/lint.sh
# QML parses (Qt 6 qmlformat), the Hyprland Lua parses (luac -p), colours come only from the theme files,
# every theme passes tests/themes.py (contrast, its terminal palette and wallpaper exist), and the scripts
# with logic pass tests/scripts.sh.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
q=config/quickshell/.config/quickshell
fail=0
problem() {
    echo "xx $*"
    fail=1
}

# --- QML: the Qt 6 formatter refuses a file that doesn't parse (qmllint needs Quickshell's types; this doesn't)
fmt=""
for c in /usr/lib/qt6/bin/qmlformat /usr/lib/qt6/libexec/qmlformat /usr/lib/x86_64-linux-gnu/qt6/bin/qmlformat qmlformat6; do
    command -v "$c" >/dev/null && {
        fmt=$c
        break
    }
done
if [[ -z $fmt ]]; then
    problem "Qt 6 qmlformat not found (Arch: qt6-declarative, Fedora: qt6-qtdeclarative-devel)"
else
    for f in "$q"/*.qml "$q"/bar/items/*/*.qml; do "$fmt" "$f" >/dev/null 2>&1 || problem "QML doesn't parse: $f ($("$fmt" "$f" 2>&1 >/dev/null | head -1))"; done
fi

# --- Lua: every Hyprland file, the hosts' too
luac=$(command -v luac || command -v luac5.4 || true)
if [[ -z $luac ]]; then
    problem "luac not found (Arch: lua, Fedora: lua, Ubuntu: lua5.4)"
else
    for f in config/hypr/.config/hypr/*.lua config/hypr/.config/hypr/modules/*.lua config/hypr/.config/hypr/defaults/*.lua modules/*/home/.config/hypr/hardware/*.lua; do
        [[ -f $f ]] && { "$luac" -p "$f" 2>/dev/null || problem "Lua doesn't parse: $f"; }
    done
fi

# --- colours: hex values only in the theme data (Themes.qml), the tokens (Theme.qml) and lines marked "// palette"
while IFS= read -r hit; do problem "colour outside the theme files: $hit"; done < <(
    grep -nE '"#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?"' "$q"/*.qml | grep -vE "^$q/(Themes|Theme)\.qml:|// palette|//.*\"#" | cut -c1-160
)

# --- shell scripts: formatting and shellcheck, when the tools (or Docker) are here; CI always runs them
if { command -v shellcheck && command -v shfmt; } >/dev/null || command -v docker >/dev/null; then
    bash tests/format.sh | grep -v '^ok'
    ((PIPESTATUS[0] == 0)) || problem "shell formatting or shellcheck (above; tests/format.sh fix formats)"
fi

# --- themes, and the scripts with logic
python3 tests/themes.py || fail=1
bash tests/metrics.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1
bash tests/no-hardcode.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1
bash tests/hypr-config.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1
bash tests/detect.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1
bash tests/scripts.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1
bash tests/hardware-scripts.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1
bash tests/keybinds.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1
bash tests/accessibility.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1
bash tests/wallpaper-colours.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1
python3 tests/settings-reference.py --check || fail=1
bash tests/docs.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1

((fail == 0)) && echo "ok: QML, Lua, colours, themes and scripts"
exit "$fail"
