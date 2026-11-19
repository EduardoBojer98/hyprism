#!/usr/bin/env bash
# lib/modules.sh's step runner against a made-up module in a throwaway folder: a step that ends with exit 3
# ("not yet") is neither a failure nor remembered, so the next run offers it again.
# shellcheck disable=SC2016,SC2034  # checks are eval'd strings; the globals are lib/modules.sh's
set -euo pipefail
cd "$(dirname "$0")/.."
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
fail=0
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

mkdir -p "$t/repo/modules/demo/steps"
echo 'exit 3' >"$t/repo/modules/demo/steps/10-wait.sh"
echo 'true' >"$t/repo/modules/demo/steps/20-done.sh"
# shellcheck source=lib/modules.sh
. lib/modules.sh
REPO=$t/repo STATE=$t/state ONLY='' STEP='' DRY=false FAILED=()
say() { echo "say: $*"; }
warn() { echo "warn: $*"; }
ask() { return 0; }
modules_on() { echo demo; }

module_steps >"$t/run1" 2>&1
module_steps >"$t/run2" 2>&1
check "a waiting step is not a failure" '((${#FAILED[@]} == 0))'
check "a waiting step is not remembered" '[[ ! -e $t/state/steps/demo-10-wait.sh ]]'
check "a finished step is remembered" '[[ -e $t/state/steps/demo-20-done.sh ]]'
check "the next run offers the waiting step again" 'grep -q "10-wait.sh waits" "$t/run2"'
check "the next run doesn't offer the finished one" '! grep -q "20-done" "$t/run2"'
exit "$fail"
