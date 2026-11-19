#!/usr/bin/env bash
# Hyprism: one command to set up this desktop on Arch/CachyOS or Fedora. Safe to run again.
#
#   ./install.sh              install: looks at the hardware, then packages, links, services and the
#                             modules this computer needs (asks before every system change)
#   ./install.sh update       pull Hyprism, update the system, run new migrations, relink, doctor
#   ./install.sh channel [stable|dev]
#                             show the update channel, or switch to it and update (stable = branch main,
#                             released; dev = branch develop, newest work, can break)
#   ./install.sh doctor       check this computer against the repo; changes nothing
#   ./install.sh detect       look at the hardware again and print hardware.toml
#   ./install.sh modules      list the optional modules and which are on (--json: for Settings)
#   ./install.sh rollback     go back to the Hyprism version from before the last update
#   ./install.sh backups      list the backups of files that were in the way
#   ./install.sh uninstall    remove the links, put a backup back, undo the system changes
#
#   --dry-run                 only show what would happen (questions are listed, not asked)
#   --yes                     answer yes to every question (unattended)
#   --no-trust                answer no to the questions that trust other people's code or give root-level
#                             rights: AUR builds, COPR and RPM Fusion repos, the docker group (with --yes too)
#   --only LIST               comma list of steps (packages, links, services, defaults, firewall, modules)
#                             and/or package groups (core, desktop, tools, look, apps, shell)
#   --profile full|base       full: Hyprism's apps and themed login screen too; base: only the desktop,
#                             your own apps and login screen stay (asked at the first install, remembered)
#   --with LIST               turn modules on, whatever detection says (remembered)
#   --without LIST            turn modules off (remembered)
#   --step MODULE/FILE        run just that one module step again
#   --backup NAME             with uninstall: the backup to put back (default: the newest)
#
# Logs: ~/.local/state/hyprism/logs/    Backups: ~/.local/state/hyprism/backups/<time>/
# What it found on this computer: ~/.config/hyprism/hardware.toml
set -Eeuo pipefail # -E: the failure summary (on_fail) also fires inside functions

REPO=$(cd "$(dirname "$0")" && pwd)
ARGS=("$@") # kept for update, which re-runs itself after a pull
DRY=false YES=false TRUST=true JSON=false ONLY="" WITH="" WITHOUT="" BACKUP="" STEP="" PROFILE="" CHANNEL="" CMD=install
usage() {
    awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
    exit "${1:-0}"
}
while (($#)); do
    case $1 in
        --dry-run) DRY=true ;;
        --yes | -y) YES=true ;;
        --no-trust) TRUST=false ;;
        --json) JSON=true ;;
        --only | --with | --without | --backup | --step | --profile)
            [[ -n ${2:-} ]] || {
                echo "$1 needs a value" >&2
                exit 2
            }
            case $1 in
                --only) ONLY=$2 ;;
                --with) WITH=$2 ;;
                --without) WITHOUT=$2 ;;
                --backup) BACKUP=$2 ;;
                --step) STEP=$2 ONLY=modules ;;
                --profile)
                    [[ $2 == full || $2 == base ]] || {
                        echo "--profile is full or base" >&2
                        exit 2
                    }
                    PROFILE=$2
                    ;;
            esac
            shift
            ;;
        install | update | doctor | detect | modules | rollback | backups | uninstall) CMD=$1 ;;
        undo) CMD=uninstall ;; # the name before 2.0
        channel)
            CMD=channel
            if [[ ${2:-} == stable || ${2:-} == dev ]]; then
                CHANNEL=$2
                shift
            elif [[ -n ${2:-} && ${2:-} != -* ]]; then
                echo "The channels are stable and dev" >&2
                exit 2
            fi
            ;;
        -h | --help) usage ;;
        *)
            echo "Unknown option: $1" >&2
            usage 2 >&2
            ;;
    esac
    shift
done
[[ $EUID -ne 0 ]] || {
    echo "Run as your normal user, not with sudo (it asks for sudo when needed)." >&2
    exit 1
}
export REPO

for part in ui detect distro packages modules links system defaults migrate doctor; do
    # shellcheck source=/dev/null
    . "$REPO/lib/$part.sh"
done

want_step() {
    [[ -z $ONLY || ",$ONLY," == *",$1,"* ]] && return 0
    [[ $1 == packages ]] && for g in "${PACKAGE_GROUPS[@]}"; do [[ ",$ONLY," == *",$g,"* ]] && return 0; done
    return 1
}

# An install that is already there gets migrations; a new one starts at today's layout
FRESH=true
[[ -d $STATE || -d $OLD_STATE || -L $HOME/.config/hypr/hyprland.lua ]] && FRESH=false

# Hardware first: everything after this asks hardware.toml
if $DRY; then # a dry run detects into a throwaway copy, so nothing in ~ changes
    real=$HW_FILE
    HW_FILE=$(mktemp)
    trap 'rm -f "$HW_FILE"' EXIT
    [[ -f $real ]] && cp "$real" "$HW_FILE"
fi
case $CMD in install | update | channel | detect) detect_write ;; esac
[[ -s $HW_FILE || $CMD == doctor ]] || detect_write # the first modules / backups call; the doctor reports a missing file instead
for m in ${WITH//,/ }; do
    [[ -d $REPO/modules/$m ]] || {
        echo "No such module: $m (./install.sh modules lists them)" >&2
        exit 2
    }
    hw_override "module.$m" true
done
for m in ${WITHOUT//,/ }; do hw_override "module.$m" false; done
[[ -z $PROFILE ]] || hw_override setup.profile "$PROFILE"
# the first install asks (only when it installs packages or modules); later runs use the saved answer
if [[ $CMD == install ]] && { want_step packages || want_step modules; }; then choose_profile; fi
PROFILE=$(hw_get setup.profile) # "" = an install from before the choice: apps as before, no greeter

case $CMD in
    doctor) doctor ;;
    detect) cat "$HW_FILE" ;;
    modules) if $JSON; then modules_json; else modules_list; fi ;;
    backups) backups_list ;;
    rollback)
        start_log
        trap 'on_fail $LINENO "$BASH_COMMAND"' ERR
        rollback
        finish "Rolled back."
        ;;
    uninstall)
        start_log
        trap 'on_fail $LINENO "$BASH_COMMAND"' ERR
        unlink_all
        system_undo
        generated_aside
        finish "Hyprism is removed from this account. Packages stay installed; the repo folder is yours to delete."
        ;;
    update)
        start_log
        trap 'on_fail $LINENO "$BASH_COMMAND"' ERR
        update
        finish "Updated."
        ;;
    channel)
        if [[ -z $CHANNEL ]]; then
            channel ""
        else
            start_log
            trap 'on_fail $LINENO "$BASH_COMMAND"' ERR
            channel "$CHANNEL"
            finish "Channel: $(channel_now)."
        fi
        ;;
    install)
        start_log
        trap 'on_fail $LINENO "$BASH_COMMAND"' ERR
        say "Hyprism $(cat "$REPO/VERSION") on $PRETTY_NAME$($DRY && echo ' (dry run: nothing changes)')"
        echo "   computer: $(hw_get machine.form), $(hw_get machine.vendor) $(hw_get machine.product)"
        echo "   graphics: $(hw_get gpu.vendors)   modules: $(modules_on | tr '\n' ' ')"
        command -v sudo >/dev/null || FAILED+=("sudo is not installed: system steps can't run")
        migrations
        if want_step packages; then packages; fi
        if want_step links; then links; fi
        if want_step services; then services; fi
        if want_step defaults; then default_apps; fi
        if want_step firewall; then firewall; fi
        if want_step modules; then module_steps; fi
        finish "Done. Log out and pick Hyprland at the login screen. ./install.sh doctor checks the result."
        ;;
esac
