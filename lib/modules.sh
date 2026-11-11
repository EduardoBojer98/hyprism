# shellcheck shell=bash
# Modules: optional parts for hardware or uses that not every computer has (modules/<name>/).
# A module is on when its `detect` says the hardware is there, or when you turned it on yourself
# (--with NAME, kept in hardware.toml under [override] as module.NAME = true).
#
#   detect         bash, exit 0 when this computer has the hardware (reads hardware.toml through hw_get)
#   packages.txt   extra packages by logical name
#   home/          files linked into ~ like config/
#   steps/NN-*.sh  system changes, asked one by one; they use run, sys_write, sys_enable… so --dry-run
#                  shows them and uninstall can undo them
#   doctor         extra checks for ./install.sh doctor
#   README.md      what it is for (line 3 is the one-line summary `./install.sh modules` shows)

module_names() {
    local d
    for d in "$REPO"/modules/*/; do
        d=$(basename "$d")
        [[ $d == _* ]] || echo "$d"
    done | LC_ALL=C sort # the same order everywhere: steps of "nvidia" run before "nvidia-hybrid"
}

module_on() {
    case $(hw_get "module.$1") in
        true) return 0 ;;
        false) return 1 ;;
    esac
    [[ -f $REPO/modules/$1/detect ]] && (. "$REPO/modules/$1/detect") >/dev/null 2>&1 # a failing detect means "not here"
}

modules_on() {
    local m
    for m in $(module_names); do module_on "$m" && echo "$m"; done
    return 0
}

modules_list() {
    local m state why
    for m in $(module_names); do
        if module_on "$m"; then state="on " why=detected; else state="off" why="not found"; fi
        [[ -n $(hw_get "module.$m") ]] && why="your choice"
        printf '  %s  %-18s %-13s %s\n' "$state" "$m" "($why)" "$(sed -n '3p' "$REPO/modules/$m/README.md" 2>/dev/null)" # no README = no summary
    done
    echo "Turn one on or off: ./install.sh --with NAME  or  --without NAME"
}

# Each step's checksum is kept once it has run, so later runs only offer new or changed steps
step_id() { echo "$(basename "$(dirname "$(dirname "$1")")")-$(basename "$1")"; }
step_sum() { sha256sum "$1" | cut -c1-16; }
step_done() { [[ $(cat "$STATE/steps/$(step_id "$1")" 2>/dev/null) == "$(step_sum "$1")" ]]; } # no record = not run

module_steps() {
    local m s again=false
    [[ ",$ONLY," == *",modules,"* ]] && again=true
    for m in $(modules_on); do
        for s in "$REPO/modules/$m"/steps/[0-9][0-9]-*.sh; do
            [[ -f $s ]] || continue
            if [[ -n $STEP ]]; then
                [[ $m/${s##*/} == "$STEP" ]] || continue
            elif ! $again && step_done "$s"; then
                continue
            fi
            say "Module $m: ${s##*/}"
            awk 'NR == 1 { next } /^#/ { sub(/^# ?/, "   "); print; next } { exit }' "$s"
            ask "Do this?" || {
                warn "Skipped ${s##*/} (./install.sh --only modules offers it again)"
                continue
            }
            # a step is plain bash run here, so it can use run, ask, sys_write, hw_get and the distro functions
            if (
                set -euo pipefail
                # shellcheck disable=SC2034  # for the step
                MODULE=$REPO/modules/$m
                # shellcheck disable=SC1090
                . "$s"
            ); then
                $DRY || {
                    mkdir -p "$STATE/steps"
                    step_sum "$s" >"$STATE/steps/$(step_id "$s")"
                }
            else
                FAILED+=("module $m, step ${s##*/} failed")
            fi
        done
    done
}
