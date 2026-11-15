# shellcheck shell=bash
# Shared by screenshot and record: the capture settings (Config.capture in settings.json) and the one selection
# step (drag an area or click a window, with the screen frozen). Sourced after common.sh, never run.

SETTINGS=${HYPRISM_SETTINGS:-$HOME/.config/quickshell/settings.json}

# cap KEY: a Config.capture value, empty when unset or settings.json is missing
cap() { jq -r ".capture.$1 // empty" "$SETTINGS" 2>/dev/null || true; }

# folder KEY DEFAULT: the chosen folder with ~ expanded, created
folder() {
    local d
    d=$(cap "$1")
    d=${d:-$2}
    d=${d/#\~/$HOME}
    mkdir -p "$d" && echo "$d"
}

# Boxes for click-to-pick: every window showing now (on each screen's workspace, or a shown special one), newest focus
# first, as "x,y WxH" lines.
window_boxes() {
    jq -r -n --argjson m "$(hyprctl -j monitors)" --argjson c "$(hyprctl -j clients)" '
        ([$m[] | .activeWorkspace.id, (.specialWorkspace.id // 0)] | map(select(. != 0))) as $shown
        | [$c[] | select(.mapped and (.hidden | not) and (.workspace.id as $w | $shown | index($w)))]
        | sort_by(.focusHistoryID)[] | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'
}

# The selection colours follow the desktop theme
accent_colour() { grep -oE 'accent = "[0-9a-fA-F]{6}"' "$HOME/.config/hypr/settings/theme.lua" 2>/dev/null | grep -oE '[0-9a-fA-F]{6}' || echo ff9e7a; }

# pick: freeze the screen (hyprpicker -r -z, so menus and tooltips stay put) and let the user drag an area or click a
# window. Leaves "x,y WxH" in PICKED (a variable: the freeze's pid must stay in the caller's shell); fails (quietly) when cancelled. The freeze stays until pick_done, so the capture that
# follows sees the frozen picture; callers run pick_done when the capture is taken.
FREEZE_PID="" PICKED=""
pick() { # pick [windows]: windows = only a click on a window counts
    local accent r=()
    [[ ${1:-} == windows ]] && r=(-r)
    accent=$(accent_colour)
    if command -v hyprpicker >/dev/null; then
        hyprpicker -r -z >/dev/null 2>&1 &
        FREEZE_PID=$!
        sleep 0.35 # its layer must be up before slurp's, or the freeze would sit above the picker
    fi
    PICKED=$(window_boxes | slurp "${r[@]}" -d -c "${accent}ff" -b 0b0d0a66 -s "${accent}1f" -w 2 -B 00000000) || {
        pick_done
        return 1
    }
}
pick_done() {
    [[ -n $FREEZE_PID ]] && kill "$FREEZE_PID" 2>/dev/null || true
    FREEZE_PID=""
    return 0
}
