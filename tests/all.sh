#!/usr/bin/env bash
# Everything CI runs, on this computer, through Docker: the lint suite as CI runs it (in an Arch container,
# as root, on a copy), the install test on Arch and Fedora, and the update test (from the previous release;
# it skips itself in a git worktree). Changes nothing outside throwaway containers.
#   tests/all.sh             all four
#   tests/all.sh lint        only the lint suite          tests/all.sh arch | fedora   only that install test
#   tests/all.sh update      only the update test
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
want=${1:-all}
logs=$(mktemp -d)
fail=0
job() { # job NAME IMAGE COMMAND: run it, keep the log, print one line
    local name=$1 image=$2
    shift 2
    if docker run --rm -v "$PWD":/mnt/repo:ro "$image" bash -c "$*" >"$logs/$name.log" 2>&1; then
        echo "ok: $name"
    else
        echo "xx $name failed (log: $logs/$name.log)"
        grep -E '^xx|Stopped|Finished with' "$logs/$name.log" | head -10
        tail -5 "$logs/$name.log"
        fail=1
    fi
}
if [[ $want == all || $want == lint ]]; then
    job lint archlinux:latest 'pacman -Syu --noconfirm --needed qt6-declarative lua python jq shellcheck shfmt which >/dev/null 2>&1 && cp -a /mnt/repo /r && cd /r && bash tests/lint.sh'
fi
for distro in arch fedora; do
    [[ $want == all || $want == "$distro" ]] || continue
    image=archlinux:latest
    [[ $distro == fedora ]] && image=fedora:latest
    job "install-$distro" "$image" 'bash /mnt/repo/tests/container-test.sh'
done
if [[ $want == all || $want == update ]]; then
    job update archlinux:latest 'bash /mnt/repo/tests/update-test.sh'
fi
exit "$fail"
