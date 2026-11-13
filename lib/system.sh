# shellcheck shell=bash
# System changes (files in /etc, services). Every one is written down in $STATE/manifest with a copy of what
# was there before, so `./install.sh uninstall` can put the computer back.
#
#   sys_write PATH TEXT     write a root-owned file (skipped when it already says that)
#   sys_remove PATH         remove a file, keeping a copy
#   sys_enable UNIT...      enable and start services that exist and aren't enabled yet
#   sys_disable UNIT        disable one        sys_mask UNIT   mask one (nothing can start it)
#   sys_note TEXT           something uninstall can't undo by itself; shown to you instead

_sys_record() { $DRY || {
    mkdir -p "$STATE"
    echo "$*" >>"$STATE/manifest"
}; }
_sys_keep() { # one copy of the original, from before our first change
    local keep=$STATE/system$1
    [[ -e $1 && ! -e $keep ]] || return 0
    run mkdir -p "$(dirname "$keep")"
    run sudo cp -a "$1" "$keep"
}
_sys_unit_exists() { systemctl list-unit-files "$1" 2>/dev/null | grep -q "^$1"; } # no systemd (container) = no units

sys_write() {
    [[ $(cat "$1" 2>/dev/null) == "$2" ]] && return 0 # unreadable or missing = needs writing
    _sys_keep "$1"
    echo "   write $1"
    run sudo mkdir -p "$(dirname "$1")"
    $DRY || printf '%s\n' "$2" | sudo tee "$1" >/dev/null
    _sys_record "file $1"
}
sys_remove() {
    [[ -e $1 ]] || return 0
    _sys_keep "$1"
    run sudo rm -f "$1"
    _sys_record "file $1"
}
sys_enable() {
    local u
    for u in "$@"; do
        _sys_unit_exists "$u" || continue
        systemctl is-enabled -q "$u" 2>/dev/null && continue # already on
        run sudo systemctl enable --now "$u"
        _sys_record "enabled $u"
    done
}
sys_disable() {
    systemctl is-enabled -q "$1" 2>/dev/null || return 0 # already off or not there
    run sudo systemctl disable "$1"
    _sys_record "disabled $1"
}
sys_mask() {
    _sys_unit_exists "$1" || return 0
    [[ $(systemctl is-enabled "$1" 2>/dev/null) == masked ]] && return 0
    run sudo systemctl mask --now "$1"
    _sys_record "masked $1"
}
sys_note() { _sys_record "note $*"; }

# Services every desktop needs; hardware ones only where the hardware is
services() {
    say "Services"
    sys_enable NetworkManager.service
    if hw_has radio.bluetooth; then sys_enable bluetooth.service; fi
    # Docker, if you have it, starts on first use: started at boot it waits for the network
    if _sys_unit_exists docker.socket; then
        sys_enable docker.socket
        sys_disable docker.service
    fi
    return 0
}

# A firewall is on when ufw or firewalld runs, or nftables has rules.
# shortcut: nft needs root, so it is read with sudo -n (no password prompt); without it that one test says "no"
firewall_active() {
    systemctl is-active -q ufw.service firewalld.service 2>/dev/null && return 0
    [[ -n $(sudo -n nft list ruleset 2>/dev/null) ]]
}
# True when a firewall is worth offering: systemd is running (a container has neither systemd nor a firewall to set)
firewall_missing() { [[ -d /run/systemd/system ]] && ! firewall_active; }

# Offers a firewall when none is on: blocks incoming connections, allows outgoing (distro_firewall)
firewall() {
    firewall_missing || return 0
    say "Firewall"
    ask "No firewall is active. Turn one on (blocks incoming connections, allows outgoing)?" || return 0
    distro_firewall
}

# Undo everything in the manifest, newest first
system_undo() {
    [[ -s $STATE/manifest ]] || {
        say "No system changes on record."
        return 0
    }
    say "System changes Hyprism made:"
    sed 's/^/   /' "$STATE/manifest"
    ask "Undo them (files go back to what they were, services to their earlier state)?" || return 0
    local kind what
    while read -r kind what; do
        case $kind in
            file)
                if [[ -e $STATE/system$what ]]; then run sudo cp -a "$STATE/system$what" "$what"; else run sudo rm -f "$what"; fi
                ;;
            enabled) run sudo systemctl disable --now "$what" ;;
            disabled) run sudo systemctl enable "$what" ;;
            masked) run sudo systemctl unmask "$what" ;;
            note) echo "   by hand: $what" ;;
        esac
    done < <(tac "$STATE/manifest" | awk '!seen[$0]++')
    run rm -f "$STATE/manifest"
}
