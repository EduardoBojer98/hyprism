# shellcheck shell=bash
# Shared helpers for the desktop scripts in ~/.local/bin. Sourced, never run; nothing happens at source time.
# Scripts load it from ~/.local/lib/hyprism (HYPRISM_LIB points tests at the repo copy).

# Help text is the script's own header comment, so help can't drift from the file ($0 = the calling script)
usage() {
    awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$(readlink -f "$0")"
    exit "${1:-0}"
}

# One way to fail: "script: message" on stderr, exit 1
die() {
    echo "${0##*/}: $*" >&2
    exit 1
}

# A line in ~/.local/state/hyprism/logs/<script>.log for later debugging; logging must never break the caller
log() {
    local dir=${XDG_STATE_HOME:-$HOME/.local/state}/hyprism/logs
    { (umask 077 && mkdir -p "$dir") && printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$dir/${0##*/}.log"; } 2>/dev/null || true # logging is best effort
}

# Fail early and by name when a tool is missing
need() {
    local c
    for c in "$@"; do command -v "$c" >/dev/null || die "$c is not installed"; done
}

# A desktop notification, or stderr in a text console or test; never fails the caller
notify() {
    if command -v notify-send >/dev/null; then
        notify-send -a "${0##*/}" "$@" || true # no notification daemon is not an error
    else
        echo "${0##*/}: $1${2:+: $2}" >&2
    fi
    return 0
}

# hwmon numbers change between boots; find the sensor folder by its name. Prints nothing when absent.
hwmon() {
    local h
    for h in /sys/class/hwmon/hwmon*; do
        [[ -r $h/name && $(<"$h/name") == "$1" ]] && {
            echo "$h"
            return 0
        }
    done
    return 0
}

# A key from the [Desktop Entry] group only (later groups are actions with their own Exec)
desktop_key() { awk -v k="$2" '/^\[/ { s = ($0 == "[Desktop Entry]") } s && index($0, k "=") == 1 { print substr($0, length(k) + 2); exit }' "$1"; }

# The repo folder, found through this script's link back into it
repo_root() { git -C "$(dirname "$(readlink -f "$0")")" rev-parse --show-toplevel; }
