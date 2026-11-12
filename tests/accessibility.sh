#!/usr/bin/env bash
# Accessibility checks: shared controls carry Accessible.* names; counts the click targets that do not yet.
# Run by tests/lint.sh (CI) or by hand: tests/accessibility.sh
# shellcheck disable=SC2016  # check takes its condition as a single-quoted string on purpose (eval runs it later)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
qs=config/quickshell/.config/quickshell
fail=0
# check NAME CONDITION: the condition is evaluated here, so it may use the variables set above it
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

shared="Toggle Choice Chip PillButton ArrowButton Slider Dropdown TextField BarItem NotificationCard"
for f in $shared; do
    check "$f has an accessible role and name" "grep -q 'Accessible.role' $qs/$f.qml && grep -q 'Accessible.name' $qs/$f.qml"
done
check "BarIndicator names itself" "grep -q 'Accessible.name' $qs/BarIndicator.qml"
check "BarFocus has the bar focus handler" "grep -q 'target: \"bar\"' $qs/BarFocus.qml"

# Files with a click target and no Accessible.* at all: information only, to be driven down.
# allow: file, reason (one line each)
allow="
ThemePreview.qml:a picture of a theme, not a control
DragItem.qml:a drag handle, the move up / down buttons are the accessible way
"
n=0
list=""
for f in "$qs"/*.qml; do
    b=${f##*/}
    grep -q 'MouseArea' "$f" || continue
    grep -q 'onClicked' "$f" || continue
    ! grep -q 'Accessible\.' "$f" || continue
    grep -q "^$b:" <<<"$allow" && continue
    n=$((n + 1))
    list="$list $b"
done
echo "note: $n QML files have a click target and no Accessible.* (none of them fail the check yet)"
echo "note: $list"

((fail == 0)) && echo "ok: accessibility"
exit "$fail"
