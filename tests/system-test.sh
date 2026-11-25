#!/usr/bin/env bash
# System-steps test: an install in a throwaway Arch container that boots systemd, so the steps that change the
# system (services, the firewall, the greeter's switch from the old login manager, files in /etc) really run,
# and uninstall must put every one of them back.
#
#   1. a stand-in old login manager (fakedm) is the display manager
#   2. install twice on the laptop-intel computer from tests/detect.sh, with the dev module
#   3. greetd is the login manager, fakedm is off, the /etc files are written, Docker starts on first use,
#      a firewall is on; the second run adds nothing to the record of system changes
#   4. uninstall: every unit is back to how it was (new ones off), fakedm is the login manager again,
#      files Hyprism added are gone and the ones it changed are the originals again, and the record is cleared
#
# Run from the repo:  tests/system-test.sh   (or tests/all.sh system)
# The container gets SYS_ADMIN (to mount its own cgroups for systemd) and NET_ADMIN (the firewall, in its
# own network), not --privileged; nothing on this computer changes.
set -euo pipefail

if [[ ${1:-} != inside ]]; then
    cd "$(dirname "$0")/.."
    name=hyprism-system-test-$$
    trap 'docker rm -f "$name" >/dev/null 2>&1' EXIT
    docker run -d --name "$name" --cap-add SYS_ADMIN --cap-add NET_ADMIN \
        --security-opt seccomp=unconfined --security-opt apparmor=unconfined --cgroupns=private \
        --tmpfs /run --tmpfs /run/lock --tmpfs /tmp -e container=docker -v "$PWD":/mnt/repo:ro \
        archlinux:latest bash -c 'mount -o remount,rw /sys/fs/cgroup && exec /usr/lib/systemd/systemd' >/dev/null
    for _ in $(seq 30); do
        state=$(docker exec "$name" systemctl is-system-running 2>/dev/null || true)
        [[ $state == running || $state == degraded ]] && break
        sleep 1
    done
    [[ $state == running || $state == degraded ]] || {
        echo "xx systemd did not start in the container ($state)"
        exit 1
    }
    docker exec "$name" bash /mnt/repo/tests/system-test.sh inside
    exit
fi

fail() {
    echo "xx $*"
    exit 1
}
pacman -Syu --noconfirm --needed sudo git which >/dev/null
useradd -m -s /bin/bash tester
echo 'tester ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/tester
git config --global --add safe.directory '*'
mkdir -p /opt/elsewhere && cp -a /mnt/repo /opt/elsewhere/my-setup && chown -R tester: /opt/elsewhere
repo=/opt/elsewhere/my-setup
git -C $repo rev-parse --git-dir >/dev/null 2>&1 ||
    sudo -u tester -H bash -c "cd $repo && rm -f .git && git init -q && git add -A && git -c user.name=t -c user.email=t@t commit -qm test"
bash $repo/tests/detect.sh make /opt/fixtures
as() { sudo -u tester -H env HYPRISM_ROOT=/opt/fixtures/laptop-intel bash -c "cd $repo && $1"; }
state=/home/tester/.local/state/hyprism
units=(NetworkManager.service docker.socket docker.service ufw.service greetd.service fakedm.service)
is_enabled() { # enabled, disabled, masked… or absent (not installed)
    local s
    s=$(systemctl is-enabled "$1" 2>/dev/null) || true
    [[ -z $s || $s == not-found ]] && s=absent
    echo "$s"
}
enabled() { # one line per unit: its name and whether it starts at boot
    local u
    for u in "${units[@]}"; do echo "$u $(is_enabled "$u")"; done
}
dm() { basename "$(readlink /etc/systemd/system/display-manager.service)"; }

echo "===== BEFORE: an old login manager"
printf '[Service]\nExecStart=/usr/bin/sleep infinity\n[Install]\nAlias=display-manager.service\n' >/etc/systemd/system/fakedm.service
systemctl daemon-reload
systemctl enable -q fakedm.service
before=$(enabled)
[[ $(dm) == fakedm.service ]] || fail "the stand-in login manager is not the display manager"

echo "===== INSTALL (twice)"
as './install.sh --yes --with dev' >/tmp/install1.log 2>&1 || {
    tail -20 /tmp/install1.log
    fail "the install ended with an error"
}
cp $state/manifest /tmp/manifest1
as './install.sh --yes --with dev' >/tmp/install2.log 2>&1 || fail "the second install ended with an error"
cmp -s $state/manifest /tmp/manifest1 || {
    diff /tmp/manifest1 $state/manifest
    fail "the second install recorded more system changes"
}

echo "===== INSTALLED"
[[ $(dm) == greetd.service ]] || fail "greetd is not the display manager ($(dm))"
! systemctl is-enabled -q fakedm.service || fail "the old login manager is still enabled"
{ grep -q session.sh /etc/greetd/config.toml && grep -q "exec regreet" /etc/greetd/session.sh; } || fail "/etc/greetd does not start ReGreet"
[[ -f /etc/systemd/logind.conf.d/50-hyprism-lid.conf ]] || fail "the laptop's lid file is missing"
systemctl is-enabled -q docker.socket || fail "docker.socket is not enabled"
! systemctl is-enabled -q docker.service || fail "docker.service starts at boot"
systemctl is-enabled -q NetworkManager.service || fail "NetworkManager is not enabled"
systemctl is-enabled -q ufw.service || fail "no firewall was switched on"
written=$(sed -n 's/^file //p' $state/manifest | sort -u)
declare -A kept=() # each written file's original, as Hyprism kept it before writing
for f in $written; do
    kept[$f]=""
    [[ -e $state/system$f ]] && kept[$f]=$(md5sum <"$state/system$f")
done
echo "ok: $(wc -l <$state/manifest) system changes on record"

echo "===== UNINSTALL"
as './install.sh uninstall --yes' >/tmp/uninstall.log 2>&1 || {
    tail -20 /tmp/uninstall.log
    fail "uninstall ended with an error"
}
while read -r u was; do
    now=$(is_enabled "$u")
    if [[ $was == absent ]]; then
        [[ $now != enabled ]] || fail "$u was installed here and is still enabled after uninstall"
    else
        [[ $now == "$was" ]] || fail "$u is $now after uninstall, was $was"
    fi
done <<<"$before"
[[ $(dm) == fakedm.service ]] || fail "the old login manager is not back ($(dm))"
for f in $written; do
    if [[ -n ${kept[$f]} ]]; then # there was one before Hyprism's: the original is back
        [[ $(md5sum <"$f") == "${kept[$f]}" ]] || fail "$f is not the original after uninstall"
    else
        [[ ! -e $f ]] || fail "$f (Hyprism's own) is still there after uninstall"
    fi
done
[[ ! -e $state/manifest && ! -e $state/system ]] || fail "the record of system changes was not cleared"
echo "PASSED (system steps: $(wc -w <<<"$written") files, ${#units[@]} units)"
