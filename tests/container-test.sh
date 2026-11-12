#!/usr/bin/env bash
# Fresh-install test in a throwaway container (archlinux:latest or fedora:latest), as a normal user, with the
# repo cloned to an unusual path. The hardware is one of the made-up computers from tests/detect.sh, so the
# result doesn't depend on the machine running the test.
#
#   1. every hardware profile: a dry run picks the right modules and changes nothing
#   2. a real install twice, then a third dry run must want to change nothing (idempotent)
#   3. the doctor is clean
#   4. a forced failure ends non-zero with a summary
#   5. uninstall puts the home folder back exactly as it was
#
# Run from the repo:  docker run --rm -v "$PWD":/mnt/repo:ro archlinux:latest bash /mnt/repo/tests/container-test.sh
# (CI does the same for both distros: .github/workflows/ci.yml)
set -euo pipefail
# shellcheck disable=SC1091
. /etc/os-release
case $ID in
    arch) pacman -Syu --noconfirm --needed sudo git which >/dev/null ;;
    fedora) dnf -y -q install sudo git which hostname procps-ng findutils >/dev/null ;;
    *)
        echo "Unsupported: $ID"
        exit 2
        ;;
esac
useradd -m -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/tester
git config --global --add safe.directory '*'
mkdir -p /opt/elsewhere && cp -a /mnt/repo /opt/elsewhere/my-setup && chown -R tester: /opt/elsewhere # the tree as it is, uncommitted work too
repo=/opt/elsewhere/my-setup
# a worktree's .git points outside the container: make the copy a plain repo of its own
git -C $repo rev-parse --git-dir >/dev/null 2>&1 ||
    sudo -u tester -H bash -c "cd $repo && rm -f .git && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm test"
bash $repo/tests/detect.sh make /opt/fixtures
# as PROFILE COMMAND: run as the test user on that made-up computer
as() { sudo -u tester -H env HYPRISM_ROOT="/opt/fixtures/$1" bash -c "cd $repo && $2"; }
snapshot() { (cd /home/tester && find . -path ./.local/state -prune -o \( -type f -o -type l \) -printf '%p %l\n' | sort); }

echo "===== MODULES PER PROFILE (dry runs)"
expect_modules() { # expect_modules PROFILE "module module ..."
    local got
    got=$(as "$1" './install.sh --dry-run --yes' | sed -n 's/.*modules: *//p' | head -1 | xargs)
    [[ $got == "$2" ]] || {
        echo "xx $1: expected modules '$2', got '$got'"
        exit 1
    }
    echo "ok: $1 -> ${2:-none}"
}
before=$(snapshot)
expect_modules vm ""
expect_modules desktop-amd "ddc-monitor"
expect_modules desktop-nvidia "ddc-monitor nvidia"
expect_modules laptop-intel "laptop"
expect_modules laptop-hybrid-nvidia "asus ddc-monitor laptop logitech nvidia nvidia-hybrid tablet"
expect_modules hidpi-single "laptop"
expect_modules multi-monitor "ddc-monitor"
# the optional modules resolve their packages on this distro (a dry run with all three switched on)
opt=$(as desktop-nvidia './install.sh --dry-run --yes --with dev,gaming,ai')
for want in mise steam gamemode mangohud ollama docker; do
    grep -qw "$want" <<<"$opt" || {
        echo "xx optional modules: $want is not in the install plan"
        exit 1
    }
done
grep -q 'ai: 10-gpu.sh' <<<"$opt" || {
    echo "xx the ai module's GPU step was not offered on the NVIDIA profile"
    exit 1
}
echo "ok: dev, gaming and ai resolve their packages"
[[ $(snapshot) == "$before" ]] || {
    echo "xx a dry run changed the home folder"
    exit 1
}

echo "===== RUN 1 (desktop-amd)"
as desktop-amd './install.sh --yes'
echo "===== RUN 2"
as desktop-amd './install.sh --yes'
echo "===== IDEMPOTENT"
left=$(as desktop-amd './install.sh --dry-run --yes' | grep -E 'would run:|would ask:|^   write ' || true)
[[ -z $left ]] || {
    echo "a third run would still change things:"
    echo "$left"
    exit 1
}
echo "===== DOCTOR"
as desktop-amd './install.sh doctor'
echo "===== LINKS, LOG, HARDWARE FILE"
as desktop-amd "test \"\$(readlink -f ~/.config/hypr/hyprland.lua)\" = $repo/config/hypr/.config/hypr/hyprland.lua"
as desktop-amd 'ls ~/.local/state/hyprism/logs/install-*.log >/dev/null && grep -q "form = \"desktop\"" ~/.config/hyprism/hardware.toml'
as desktop-amd './install.sh modules'

echo "===== THE DOCTOR FINDS WHAT IS BROKEN (and says how to fix it)"
# broken COMMAND-THAT-BREAKS EXPECTED-TEXT: the doctor must fail, name the problem and give a fix; then repair
broken() {
    local out
    as desktop-amd "$1"
    if out=$(as desktop-amd './install.sh doctor' 2>&1); then
        echo "xx the doctor passed although: $1"
        exit 1
    fi
    if ! grep -q "$2" <<<"$out" || ! grep -q 'fix: ' <<<"$out"; then
        echo "xx the doctor did not report '$2' with a fix after: $1"
        echo "$out" | tail -5
        exit 1
    fi
    echo "ok: doctor reports: $2"
    as desktop-amd './install.sh --yes --only links >/dev/null 2>&1; rm -f ~/.config/hypr/stray.lua'
}
broken 'rm ~/.config/hypr/hyprland.lua' 'not linked'
broken 'rm ~/.local/bin/theme && cp config/scripts/.local/bin/theme ~/.local/bin/theme' 'copy instead of link'
broken 'rm ~/.config/fuzzel/fuzzel.ini && echo changed > ~/.config/fuzzel/fuzzel.ini' 'differs from the repo'
broken 'echo "-- mine" > ~/.config/hypr/stray.lua' "isn't from the repo"
broken 'echo "{ not json" > ~/.config/quickshell/settings.json' "isn't valid JSON"
as desktop-amd 'rm -f ~/.config/quickshell/settings.json'
broken 'rm ~/.config/hyprism/hardware.toml' 'never looked at'
as desktop-amd './install.sh detect >/dev/null'
as desktop-amd 'rm -rf ~/.local/state/hyprism/backups' # the breakages above made backups; uninstall would put those files back
as desktop-amd './install.sh doctor' >/dev/null

echo "===== A FAILURE IS REPORTED"
echo "no-such-package-xyz      core      test: a package that can't be mapped" >>$repo/packages/manifest.txt
if as desktop-amd './install.sh --yes --only packages' >/tmp/fail.log 2>&1; then
    echo "xx a failed package still ended with exit 0"
    exit 1
fi
grep -q 'Finished with 1 problem' /tmp/fail.log
sed -i '$d' $repo/packages/manifest.txt

echo "===== UNINSTALL"
as desktop-amd './install.sh uninstall --yes' | tail -4
left=$(snapshot | grep -v '^\./\.bash' || true)
[[ -z $left ]] || {
    echo "xx uninstall left files in the home folder:"
    echo "$left"
    exit 1
}
echo "PASSED ($PRETTY_NAME)"
