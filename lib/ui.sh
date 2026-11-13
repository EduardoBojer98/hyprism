# shellcheck shell=bash
# Messages, questions, the dry-run wrapper, the log file and the failure summary. Sourced by install.sh.

STATE=${XDG_STATE_HOME:-$HOME/.local/state}/hyprism
OLD_STATE=${XDG_STATE_HOME:-$HOME/.local/state}/linux-setup # before 2.0; migration 0001 moves it
PROBLEMS=0 WARNINGS=0
FAILED=() # things that didn't work but shouldn't stop the run; listed at the end

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32mok\033[0m %s\n' "$*"; }
warn() {
    printf '\033[1;33m!!\033[0m %s\n' "$*" >&2
    WARNINGS=$((WARNINGS + 1))
}
# bad PROBLEM [FIX]: a doctor finding, with the command or step that fixes it
bad() {
    printf '\033[1;31mxx\033[0m %s\n' "$1"
    [[ -z ${2:-} ]] || printf '   fix: %s\n' "$2"
    PROBLEMS=$((PROBLEMS + 1))
}
ask() {
    if $DRY; then
        printf '   would ask: %s\n' "$1"
        return 0
    fi
    $YES && return 0
    local r
    read -r -p "$1 [y/N] " r
    [[ $r == [yY]* ]]
}
# Every change goes through run, so --dry-run shows it instead of doing it
run() { if $DRY; then printf '   would run: %s\n' "$*"; else "$@"; fi; }

is_checkout() { git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; } # false for an unpacked archive

# Everything printed from here on is also kept in a log file
start_log() {
    $DRY && return 0
    mkdir -p "$STATE/logs"
    LOG=$STATE/logs/$CMD-$(date +%Y%m%d-%H%M%S).log
    exec > >(tee -a "$LOG") 2>&1
    echo "hyprism $(cat "$REPO/VERSION") · $CMD · $(date)"
}

# A command failed and stopped the run: say which one and what to do next
on_fail() {
    local code=$?
    printf '\n\033[1;31mStopped\033[0m: this failed (exit %s, %s line %s):\n   %s\n' "$code" "${BASH_SOURCE[1]##*/}" "$1" "$2" >&2
    [[ -z ${LOG:-} ]] || echo "Full log: $LOG" >&2
    echo "Fix the cause and run the same command again: finished parts are skipped." >&2
    exit "$code"
}

# The end of a run: non-zero when something was skipped or failed along the way
finish() {
    if ((${#FAILED[@]})); then
        printf '\n\033[1;31mFinished with %s problem(s):\033[0m\n' "${#FAILED[@]}"
        printf '   %s\n' "${FAILED[@]}"
        [[ -z ${LOG:-} ]] || echo "Full log: $LOG"
        exit 1
    fi
    say "$1"
}
