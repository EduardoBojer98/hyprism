#!/usr/bin/env bash
# Fresh-install test in a throwaway container (archlinux:latest or fedora:latest), as a normal user,
# with the repo cloned to an unusual path: dry run, install twice, a third dry run must want to change
# nothing (idempotent), then the doctor must be clean.
# Run from the repo:  docker run --rm -v "$PWD":/mnt/repo:ro archlinux:latest bash /mnt/repo/tests/container-test.sh
# (CI does the same for both distros: .github/workflows/ci.yml)
set -euo pipefail
. /etc/os-release
case $ID in
    arch)   pacman -Syu --noconfirm --needed sudo git which >/dev/null ;;
    fedora) dnf -y -q install sudo git which hostname procps-ng >/dev/null ;;
    *) echo "Unsupported: $ID"; exit 2 ;;
esac
useradd -m -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/tester
git config --global --add safe.directory '*'
mkdir -p /opt/elsewhere && cp -a /mnt/repo /opt/elsewhere/my-setup && chown -R tester: /opt/elsewhere   # the tree as it is, uncommitted work too
as() { sudo -u tester -H bash -c "cd /opt/elsewhere/my-setup && $*"; }

echo "===== DRY RUN";  as './install.sh --dry-run --yes' | tail -15
echo "===== RUN 1";    as './install.sh --yes'
echo "===== RUN 2";    as './install.sh --yes'
echo "===== IDEMPOTENT"
left=$(as './install.sh --dry-run --yes' | grep 'would run:' || true)
[[ -z $left ]] || { echo "a third run would still change things:"; echo "$left"; exit 1; }
echo "===== DOCTOR";   as './install.sh doctor'
echo "===== LINKS";    as 'test "$(readlink -f ~/.config/hypr/hyprland.lua)" = /opt/elsewhere/my-setup/config/hypr/.config/hypr/hyprland.lua'
echo "PASSED ($PRETTY_NAME)"
