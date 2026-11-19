#!/usr/bin/env bash
# lib/system.sh against a throwaway folder, with sudo and systemctl faked: what uninstall puts back.
# Changes nothing outside a temp folder.
# shellcheck disable=SC2016,SC2032  # checks are eval'd strings; systemctl is a fake on purpose
set -euo pipefail
cd "$(dirname "$0")/.."
t=$(mktemp -d)
trap 'rm -rf "$t"' EXIT
fail=0
check() { if eval "$2"; then echo "ok: $1"; else
    echo "xx $1"
    fail=1
fi; }

# the fakes: commands run as they are, systemctl only writes down what it was asked
DRY=false STATE=$t/state
run() { "$@"; }
sudo() { "$@"; }
say() { :; }
ask() { return 0; }
systemctl() {
    case $1 in
        list-unit-files) echo "$2 enabled" ;;
        is-enabled) [[ -e $t/on-${*: -1} ]] ;;
        *) echo "$*" >>"$t/systemctl.log" ;;
    esac
}
# shellcheck source=lib/system.sh
. lib/system.sh

exec 3>&1 1>/dev/null # sys_write says what it writes; only the results below are shown
# a file we made, rewritten by a later run: undo removes it, not puts our first text back
sys_write "$t/new.conf" one
sys_write "$t/new.conf" two
# a file that was there: undo puts the original back, even after two changes
echo original >"$t/old.conf"
sys_write "$t/old.conf" one
sys_write "$t/old.conf" two
# a login manager switch: the old one off, greetd on from the next boot
touch "$t/on-gdm.service"
sys_disable gdm.service
sys_enable_boot greetd.service

system_undo
exec 1>&3
check "a file we made is removed" '[[ ! -e $t/new.conf ]]'
check "a file that was there gets its original back" '[[ $(cat "$t/old.conf") == original ]]'
check "greetd is switched off without stopping it" 'grep -qx "disable greetd.service" "$t/systemctl.log"'
check "the old login manager is switched back on" 'grep -qx "enable gdm.service" "$t/systemctl.log"'
check "greetd goes off before the old one comes on" '[[ $(grep -nx "disable greetd.service" "$t/systemctl.log" | cut -d: -f1) -lt $(grep -nx "enable gdm.service" "$t/systemctl.log" | cut -d: -f1) ]]'
check "the kept originals are cleared" '[[ ! -e $STATE/system ]]'
exit "$fail"
