#!/usr/bin/env bash
# A test desktop in a window: Hyprland and the shell from THIS checkout, in a throwaway home folder, running
# inside your real session. For seeing a change work before it is applied for real.
#
#   tests/nested.sh start          link this checkout into a throwaway home and open the window
#   tests/nested.sh shot NAME      screenshot of the test desktop -> prints the PNG's path
#   tests/nested.sh ipc ARGS...    qs ipc call ARGS... in the test shell (e.g. ipc config set appearance theme atlas)
#   tests/nested.sh hypr ARGS...   hyprctl ARGS... in the test session
#   tests/nested.sh key NAMES...   press keys in the test desktop (xkb names: Tab, Next, Return…)
#   tests/nested.sh errors         the test shell's warnings and errors (nothing printed = clean)
#   tests/nested.sh stop           close the window and delete the throwaway home
#
# Under Hyprland the window sits on a virtual screen of its own (1920x1200, or HYPRISM_TEST_SIZE=WxH), so it
# never covers your work. HYPRISM_TEST_NAME=x runs a second, separate session (pass it to every command).
# Kept away from the real session: its own D-Bus session, GTK settings kept in memory, and stand-ins on the
# PATH for every command that would act on the real machine (pkill, systemctl, brightness, power, DDC…),
# which only write what they were asked to do into <home>/shims.log.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
run=${XDG_RUNTIME_DIR:?needs a graphical session}
name=${HYPRISM_TEST_NAME:-main} # several sessions can run side by side under different names
[[ $name =~ ^[a-z0-9]+$ ]] || {
    echo "HYPRISM_TEST_NAME: lower-case letters and digits only" >&2
    exit 2
}
state=$run/hyprism-nested-$name
usage() {
    awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
    exit "${1:-0}"
}
need_running() {
    [[ -f $state/env ]] || {
        echo "no test session: tests/nested.sh start" >&2
        exit 1
    }
    # shellcheck disable=SC1091
    . "$state/env"
}
inside() { env HOME="$T" XDG_CONFIG_HOME="$T/.config" XDG_STATE_HOME="$T/.local/state" XDG_DATA_HOME="$T/.local/share" \
    XDG_CACHE_HOME="$T/.cache" WAYLAND_DISPLAY="$SOCK" HYPRLAND_INSTANCE_SIGNATURE="$SIG" PATH="$T/shims:$T/.local/bin:$PATH" "$@"; }

# Under Hyprland the test window goes onto a virtual screen of its own, far from your real ones: it gets a
# full-size desktop (so Settings fits), keeps drawing (a window on a hidden workspace would not), and never
# covers your work or takes your pointer.
SCREEN=hyprism-test-$name
park() {
    [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || return 0
    local win=""
    local others # test screens already there: each new one goes further right, so they never overlap
    others=$(hyprctl monitors -j | jq '[.[] | select(.name | startswith("hyprism-test"))] | length')
    hyprctl output create headless "$SCREEN" >/dev/null || return 0
    hyprctl eval "hl.monitor({ output = \"$SCREEN\", mode = \"${HYPRISM_TEST_SIZE:-1920x1200}@60\", position = \"$((20000 + others * 6000))x20000\", scale = 1 })" >/dev/null || true
    for _ in $(seq 20); do
        # the nested compositor's window that isn't parked on a test screen yet (another session's already is)
        win=$(jq -rn --argjson m "$(hyprctl monitors -j)" --argjson c "$(hyprctl clients -j)" \
            '($m | map(select(.name | startswith("hyprism-test")) | .id)) as $parked | $c[] | select(.class == "aquamarine" and (.monitor as $i | $parked | index($i) | not)) | .address' | tail -1)
        [[ -n $win ]] && break
        sleep 0.25
    done
    [[ -n $win ]] || return 0
    hyprctl dispatch "hl.dsp.window.move({ monitor = \"$SCREEN\", follow = false, window = \"address:$win\" })" >/dev/null || true
}

case ${1:-} in
    start)
        [[ -n ${WAYLAND_DISPLAY:-} ]] || {
            echo "start this from inside a Wayland session" >&2
            exit 1
        }
        [[ ! -f $state/env ]] || {
            echo "a test session is already running: tests/nested.sh stop" >&2
            exit 1
        }
        mkdir -p "$state"
        T=$(mktemp -d "$run/hyprism-home.XXXXXX")
        mkdir -p "$T/shims" "$T/.config" "$T/.local/state" "$T/.local/share" "$T/.cache"
        for c in pkill killall systemctl loginctl hypridle hyprlock gsettings brightnessctl ddcutil asusctl powerprofilesctl \
            nmcli bluetoothctl wpctl playerctl udiskie monswitch powermode notify-send xdg-open gtk-launch hyprshutdown sudo; do
            printf '#!/bin/sh\necho "%s $*" >>"%s/shims.log"\n' "$c" "$T" >"$T/shims/$c"
            chmod +x "$T/shims/$c"
        done
        env HOME="$T" XDG_CONFIG_HOME="$T/.config" XDG_STATE_HOME="$T/.local/state" "$repo/install.sh" --yes --only links >"$T/install.log" 2>&1 || {
            echo "linking failed: $T/install.log" >&2
            exit 1
        }
        # compositor sockets (wayland-N) and Hyprland instance folders that exist now; the new ones are ours
        seen() { find "$run" -maxdepth 2 \( -name 'wayland-[0-9]*' ! -name '*.lock' -o -path "$run/hypr/*" \) -prune -printf '%p\n' 2>/dev/null | sort; }
        before=$(seen)
        env HOME="$T" XDG_CONFIG_HOME="$T/.config" XDG_STATE_HOME="$T/.local/state" XDG_DATA_HOME="$T/.local/share" XDG_CACHE_HOME="$T/.cache" \
            PATH="$T/shims:$T/.local/bin:$PATH" HYPRISM_TEST=1 GSETTINGS_BACKEND=memory HYPRISM_LIB="$T/.local/lib/hyprism" \
            setsid dbus-run-session -- Hyprland -c "$T/.config/hypr/hyprland.lua" >"$T/hyprland.log" 2>&1 &
        echo $! >"$state/pid"
        SIG="" SOCK=""
        for _ in $(seq 40); do
            sleep 0.5
            new=$(comm -13 <(echo "$before") <(seen) || true)
            SIG=$(grep "^$run/hypr/" <<<"$new" | head -1 | xargs -r basename || true)
            SOCK=$(grep -E '/wayland-[0-9]+$' <<<"$new" | head -1 | xargs -r basename || true)
            [[ -n $SIG && -n $SOCK ]] && break
        done
        [[ -n $SIG && -n $SOCK ]] || {
            echo "the test session did not start: $T/hyprland.log" >&2
            exit 1
        }
        printf 'T=%q\nSIG=%q\nSOCK=%q\n' "$T" "$SIG" "$SOCK" >"$state/env"
        park
        sleep 4 # the shell needs a moment to draw
        echo "test session up: home $T, display $SOCK"
        ;;
    shot)
        need_running
        out=$T/${2:-shot}.png
        inside grim "$out"
        echo "$out"
        ;;
    ipc)
        need_running
        shift
        inside qs ipc call "$@"
        ;;
    hypr)
        need_running
        shift
        inside hyprctl "$@"
        ;;
    key)
        need_running
        shift
        for k in "$@"; do inside wtype -k "$k"; done # key names as in xkb: Tab, Next (Page Down), Return, Escape…
        ;;
    errors)
        need_running
        inside qs log 2>/dev/null | grep -E ' (WARN|ERROR|CRITICAL|FATAL)' | grep -v 'org.freedesktop.Notifications\|StatusNotifierWatcher' | sed 's/\x1b\[[0-9;]*m//g' | sort | uniq -c | sort -rn | head -40 || true
        ;;
    stop)
        need_running
        inside hyprctl dispatch 'hl.dsp.exit()' >/dev/null 2>&1 || kill "$(cat "$state/pid")" 2>/dev/null || true
        sleep 1
        pkill -f "Hyprland -c $T/" 2>/dev/null || true
        hyprctl output remove "$SCREEN" >/dev/null 2>&1 || true # not running under Hyprland = no virtual screen
        [[ $T == "$run"/hyprism-home.* ]] && rm -rf "$T"
        rm -rf "$state"
        echo "test session closed"
        ;;
    -h | --help) usage ;;
    *) usage 2 >&2 ;;
esac
