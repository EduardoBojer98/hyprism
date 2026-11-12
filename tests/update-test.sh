#!/usr/bin/env bash
# Update test in a throwaway Arch container: a computer set up with the previous release (v1.1.0) is brought to
# this code with the new installer, the way a user's update does it.
#
#   1. the old release installs (its own installer, from a full clone at the tag)
#   2. that clone is moved to the new code and the new installer runs
#   3. exit 0; migrations 0001 and 0002 ran, once; the old state folder is gone; no dead link is left in
#      ~/.config; the doctor is clean; a second run runs no migration
#
# Needs the repo's history and the tag v1.1.0 (CI checks out with fetch-depth: 0 and fetch-tags: true).
# A git worktree has no history inside the container: the test says so and passes without running.
#
# Run from the repo:  docker run --rm -v "$PWD":/mnt/repo:ro archlinux:latest bash /mnt/repo/tests/update-test.sh [NEW_REF]
# NEW_REF is the commit or branch of the mounted repo to update to (default: its HEAD).
# (CI does the same: .github/workflows/ci.yml)
set -euo pipefail
new_ref=${1:-HEAD}
if [[ -f /mnt/repo/.git ]]; then
    echo "skipped: the mounted repo has no history (a worktree)"
    exit 0
fi
pacman -Syu --noconfirm --needed sudo git which >/dev/null
useradd -m -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/tester
git config --global --add safe.directory '*'
git -C /mnt/repo rev-parse --verify -q v1.1.0 >/dev/null || {
    echo "xx the tag v1.1.0 is missing (git fetch --tags; CI: fetch-tags: true)"
    exit 1
}
new_sha=$(git -C /mnt/repo rev-parse --verify "$new_ref^{commit}")
old=/opt/hyprism-old
fail() {
    echo "xx $*"
    exit 1
}
# as COMMAND [PROFILE]: run as the test user, on that made-up computer when a profile is given
as() { sudo -u tester -H env ${2:+HYPRISM_ROOT="/opt/fixtures/$2"} bash -c "cd $old && $1"; }

echo "===== OLD RELEASE (v1.1.0)"
mkdir $old && chown tester: $old
as "git clone -q /mnt/repo . && git checkout -q -B main v1.1.0"
as './install.sh --yes --host default'

echo "===== SAME FOLDER, NEW CODE ($new_ref = ${new_sha:0:9})"
as "git remote add new /mnt/repo && git fetch -q new $new_sha && git checkout -q -B main $new_sha"
bash $old/tests/detect.sh make /opt/fixtures
as './install.sh --yes' desktop-amd 2>&1 | tee /tmp/update.log || fail "the new installer ended with an error"
for m in 0001-state-folder 0002-hosts-to-modules; do
    [[ $(grep -c "Migration $m" /tmp/update.log) == 1 ]] || fail "migration $m was not named exactly once in the output"
    [[ -e /home/tester/.local/state/hyprism/migrations/$m ]] || fail "migration $m left no record"
done
[[ ! -e /home/tester/.local/state/linux-setup ]] || fail "the old state folder (linux-setup) is still there"
dead=$(find /home/tester/.config -xtype l)
[[ -z $dead ]] || fail "dead links under ~/.config:"$'\n'"$dead"
as './install.sh doctor' desktop-amd || fail "the doctor found problems"
as './install.sh --yes' desktop-amd >/tmp/second.log 2>&1 || fail "the second run ended with an error"
! grep -q '^.*Migration ' /tmp/second.log || fail "a second run ran a migration again"
echo "PASSED (update from v1.1.0 to ${new_sha:0:9})"
