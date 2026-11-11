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
    for f in "$q"/*.qml; do "$fmt" "$f" >/dev/null 2>&1 || problem "QML doesn't parse: $f ($("$fmt" "$f" 2>&1 >/dev/null | head -1))"; done
fi

# --- Lua: every Hyprland file, the hosts' too
luac=$(command -v luac || command -v luac5.4 || true)
if [[ -z $luac ]]; then
    problem "luac not found (Arch: lua, Fedora: lua, Ubuntu: lua5.4)"
else
    for f in config/hypr/.config/hypr/*.lua config/hypr/.config/hypr/modules/*.lua config/hypr/.config/hypr/defaults/*.lua hosts/*/home/.config/hypr/*.lua; do
        [[ -f $f ]] && { "$luac" -p "$f" 2>/dev/null || problem "Lua doesn't parse: $f"; }
    done
fi

# --- colours: hex values only in the theme data (Themes.qml), the tokens (Theme.qml) and lines marked "// palette"
while IFS= read -r hit; do problem "colour outside the theme files: $hit"; done < <(
    grep -nE '"#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?"' "$q"/*.qml | grep -vE "^$q/(Themes|Theme)\.qml:|// palette|//.*\"#" | cut -c1-160
)

# --- shell scripts: the same shellcheck CI runs (when shellcheck is installed)
if command -v shellcheck >/dev/null; then
    mapfile -t sh < <(for f in install.sh distros/*.sh hosts/*/steps/*.sh tests/*.sh .githooks/pre-commit config/scripts/.local/bin/*; do
        head -1 "$f" | grep -qE 'bash|sh' && echo "$f"
    done)
    shellcheck -S warning "${sh[@]}" || problem "shellcheck (above)"
fi

# --- themes, and the scripts with logic
python3 tests/themes.py || fail=1
bash tests/scripts.sh | grep -v '^ok'
((PIPESTATUS[0] == 0)) || fail=1

((fail == 0)) && echo "ok: QML, Lua, colours, themes and scripts"
exit "$fail"
