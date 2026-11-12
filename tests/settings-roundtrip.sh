#!/usr/bin/env bash
# Settings round trip in a test desktop: a value set through the shell lands in settings.json, a value written into
# the file lands in the shell, and a bad value is refused. Needs a desktop session (it opens the window of
# tests/nested.sh, and closes it again at the end), so tests/lint.sh does not run it. By hand: tests/settings-roundtrip.sh
# shellcheck disable=SC2016  # check takes its condition as a single-quoted string on purpose (eval runs it later)
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
nested=tests/nested.sh
fail=0
# check NAME CONDITION: the condition is evaluated here, so it may use the variables set above it
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }
trap '$nested stop >/dev/null 2>&1' EXIT

$nested start >/dev/null || {
    echo "xx the test session did not start"
    exit 1
}
# shellcheck disable=SC1091
. "${XDG_RUNTIME_DIR:?}/hyprism-nested/env"
file=$T/.config/quickshell/settings.json
ipc() { $nested ipc "$@" 2>&1; }
# in_file KEY VALUE-AS-JSON (after 1.5 s: the shell ignores a file change within 1 s of its own write): write it into the file the way an editor would (temp file, then move over)
in_file() {
    sleep 1.5
    jq --argjson v "$2" "$1 = \$v" "$file" >"$file.tmp" && mv "$file.tmp" "$file"
}
# wait_for COMMAND EXPECTED: the command's output equals EXPECTED within 5 seconds
wait_for() {
    for _ in $(seq 25); do
        [[ $(eval "$1") == "$2" ]] && return 0
        sleep 0.2
    done
    return 1
}

ipc config set bar preset minimal >/dev/null
wait_for 'jq -r .bar.preset "$file"' minimal
check "a value set in the shell lands in settings.json" '[[ $(jq -r .bar.preset "$file") == minimal ]]'
in_file .bar.preset '"full"'
check "a value written into settings.json reaches the shell" 'wait_for "ipc config get bar preset" "\"full\""'

ipc config set bar items '{"cpu":{"warn":50}}' >/dev/null
wait_for 'jq -c .bar.items "$file"' '{"cpu":{"warn":50}}'
check "bar.items set in the shell lands in settings.json" '[[ $(jq -c .bar.items "$file") == "{\"cpu\":{\"warn\":50}}" ]]'
in_file .bar.items '{"memory":{"warn":60}}'
check "bar.items written into settings.json reaches the shell" 'wait_for "ipc config get bar items" "{\"memory\":{\"warn\":60}}"'

out=$(ipc config set bar margin 9999)
check "an invalid value is refused" '[[ $out != ok ]]'
check "the refused value was not saved" '[[ $(jq -r .bar.margin "$file") != 9999 ]]'

exit "$fail"
