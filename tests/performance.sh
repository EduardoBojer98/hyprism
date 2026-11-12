#!/usr/bin/env bash
# Performance budget for an idle shell. Starts a test session (name "p", tests/nested.sh), closes the welcome, lets
# it settle for 20 s, then measures the test shell's process (the `qs` whose environment has the test home):
# CPU over 30 s, resident memory, and the helper processes it started that are still running.
# Needs a desktop session (nested.sh opens a window), so it is not part of tests/lint.sh.
#
#   tests/performance.sh        prints the three numbers, ok:/xx per budget, exit 1 when over
set -euo pipefail
cd "$(dirname "$0")/.."

MAX_CPU=2.0 # idle CPU, percent of one core over 30 s: an idle bar must not keep a core warm
MAX_MB=450  # resident memory of the shell (qs), in MB
MAX_WATCH=0 # `metrics watch` processes: the default theme's bar has no item that needs one

export HYPRISM_TEST_NAME=p
nested=tests/nested.sh
trap '$nested stop >/dev/null 2>&1 || true' EXIT
$nested start >/dev/null
$nested ipc welcome close >/dev/null 2>&1 || true
sleep 20

# shellcheck disable=SC1091
. "${XDG_RUNTIME_DIR:?}/hyprism-nested-p/env" # sets T, the test home
pid=
for p in $(pgrep qs || true); do
    if tr '\0' '\n' <"/proc/$p/environ" 2>/dev/null | grep -qx "HOME=$T"; then
        pid=$p
        break
    fi
done
[[ -n $pid ]] || {
    echo "xx no qs process for the test home $T" >&2
    exit 1
}

ticks() { awk '{ sub(/^.*\) /, ""); print $12 + $13 }' "/proc/$pid/stat"; } # utime + stime, after the command's ")"
t0=$(ticks)
sleep 30
t1=$(ticks)
cpu=$(awk -v d=$((t1 - t0)) -v hz="$(getconf CLK_TCK)" 'BEGIN { printf "%.2f", d / (30 * hz) * 100 }')
mb=$(awk '/^VmRSS:/ { printf "%d", $2 / 1024 }' "/proc/$pid/status")

# every process below the shell: `metrics watch`, sleep, sh -c
descendants() { ps -eo pid=,ppid= | awk -v root="$pid" '{ p[$1] = $2 } END { for (c in p) { x = c; while (x in p) { if (p[x] == root) { print c; break } x = p[x] } } }'; }
helpers=$(for c in $(descendants); do tr '\0' ' ' <"/proc/$c/cmdline" 2>/dev/null && echo; done)
watch=$(grep -c 'metrics watch' <<<"$helpers" || true)
other=$(grep -cE '(^| )(sleep|sh -c)( |$)' <<<"$helpers" || true)

fail=0
verdict() { if awk -v a="$2" -v b="$3" 'BEGIN { exit !(a <= b) }'; then echo "ok: $1 $2 (budget $3)"; else
    echo "xx $1 $2 (budget $3)"
    fail=1
fi; }
verdict "idle CPU, % of one core:" "$cpu" "$MAX_CPU"
verdict "resident memory, MB:" "$mb" "$MAX_MB"
verdict "metrics watch processes:" "$watch" "$MAX_WATCH"
echo "info: sleep / sh -c helpers running: $other"
exit "$fail"
