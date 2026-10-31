#!/usr/bin/env bash
# One command to set up this desktop on Arch/CachyOS or Fedora. Safe to run again.
#
#   ./install.sh                 everything: packages, NVIDIA driver, configs, services, session and
#                                this computer's host steps (asks before system changes)
#   ./install.sh update          pull this repo, update the system, add new packages, relink, doctor
#   ./install.sh doctor          check this computer against the repo; changes nothing
#   ./install.sh undo            remove the links and offer to put the last backup back
#
#   --dry-run                    only show what would happen
#   --yes                        answer yes to every question (unattended)
#   --host NAME                  use hosts/NAME (default: the host whose host.conf lists this hostname)
#   --only LIST                  comma list of steps (packages, nvidia, links, services, session, host,
#                                ) and/or package modules (core, desktop, tools, look, apps, shell)
#
# Backups of files in the way: ~/.local/state/linux-setup/backups/<time>/, same layout as ~.
# KDE Plasma's own config is never linked over (see the KDE guard).
set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/linux-setup
MODULES=(core desktop tools look apps shell)

ARGS=("$@")   # kept for update, which re-runs itself after a pull
DRY=false YES=false HOST="" ONLY="" CMD=install
while (($#)); do
    case $1 in
        --dry-run) DRY=true ;;
        --yes|-y) YES=true ;;
        --host) HOST=${2:?--host needs a name}; shift ;;
        --only) ONLY=${2:?--only needs a list}; shift ;;
        doctor|undo|install|update) CMD=$1 ;;
        -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1 (see ./install.sh --help)" >&2; exit 2 ;;
    esac
    shift
done

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
bad()  { printf '\033[1;31mxx\033[0m %s\n' "$*"; PROBLEMS=$((PROBLEMS + 1)); }
ok()   { printf '\033[1;32mok\033[0m %s\n' "$*"; }
ask()  { $YES && return 0; $DRY && return 0; local r; read -r -p "$1 [y/N] " r; [[ $r == [yY]* ]]; }
# Every change goes through run, so --dry-run shows it instead
run()  { if $DRY; then printf '   would run: %s\n' "$*"; else "$@"; fi; }
PROBLEMS=0

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not with sudo (it asks for sudo when needed)." >&2; exit 1; }

# --- distro backend: distros/<ID>.sh, else one matching ID_LIKE ---------------------------------
# shellcheck disable=SC1091
. /etc/os-release
DISTRO=""
for id in ${ID:-} ${ID_LIKE:-}; do
    [[ -f $REPO/distros/$id.sh ]] && { DISTRO=$id; break; }
    [[ $id == cachyos || $id == endeavouros || $id == manjaro ]] && { DISTRO=arch; break; }
done
[[ -n $DISTRO ]] || { echo "No backend for ${PRETTY_NAME:-this distro}: add distros/${ID:-name}.sh (see distros/README.md)." >&2; exit 1; }
# shellcheck source=distros/arch.sh
. "$REPO/distros/$DISTRO.sh"
MAP=$REPO/packages/$DISTRO.txt

# --- host: --host, else the host.conf listing this hostname, else default -------------------------
hostname=$(cat /etc/hostname 2>/dev/null || uname -n)
if [[ -z $HOST ]]; then
    HOST=default
    for conf in "$REPO"/hosts/*/host.conf; do
        HOSTNAMES=""; # shellcheck disable=SC1090
        . "$conf"
        [[ " $HOSTNAMES " == *" $hostname "* ]] && { HOST=$(basename "$(dirname "$conf")"); break; }
    done
fi
HOSTDIR=$REPO/hosts/$HOST
[[ -d $HOSTDIR ]] || { echo "No such host: hosts/$HOST" >&2; exit 1; }
export REPO DISTRO HOST

# --only: which steps run and which package modules count
want_step() { [[ -z $ONLY ]] && return 0; [[ ",$ONLY," == *",$1,"* ]] && return 0
              [[ $1 == packages ]] && for m in "${MODULES[@]}"; do [[ ",$ONLY," == *",$m,"* ]] && return 0; done; return 1; }
want_module() { local m sel=false
                for m in "${MODULES[@]}"; do [[ ",$ONLY," == *",$m,"* ]] && sel=true; done
                ! $sel || [[ ",$ONLY," == *",$1,"* ]]; }

# --- packages -----------------------------------------------------------------------------------
# Logical names wanted: manifest lines in the chosen modules, plus the host's packages.txt
wanted_names() {
    awk '!/^[[:space:]]*(#|$)/ { print $1, $2 }' "$REPO/packages/manifest.txt" | while read -r name module; do
        want_module "$module" && echo "$name"
    done
    [[ -f $HOSTDIR/packages.txt ]] && awk '!/^[[:space:]]*(#|$)/ { print $1 }' "$HOSTDIR/packages.txt"
    return 0
}
# "name" -> "source pkg1 pkg2 ..." from packages/<distro>.txt
lookup() { awk -v n="$1" '$1 == n { gsub(",", " ", $2); print $3, $2; exit }' "$MAP"; }

packages() {
    say "Packages for $PRETTY_NAME (packages/$DISTRO.txt), host $HOST"
    declare -A batch=()
    local name src pkgs p missing=()
    while read -r name; do
        read -r src pkgs <<< "$(lookup "$name")"
        [[ -n ${src:-} ]] || { warn "$name: not in packages/$DISTRO.txt"; continue; }
        [[ $src == none ]] && { warn "$name: no package for $DISTRO (see the comment in packages/$DISTRO.txt)"; continue; }
        for p in $pkgs; do distro_installed "$src" "$p" || batch[$src]+=" $p"; done
    done < <(wanted_names)
    ((${#batch[@]})) || { say "All packages are installed."; return 0; }
    for src in "${!batch[@]}"; do printf '   %-28s%s\n' "$src:" "${batch[$src]}"; done
    ask "Install these?" || { warn "Skipped packages."; return 0; }
    distro_prepare "${!batch[@]}"
    for src in "${!batch[@]}"; do
        # shellcheck disable=SC2086
        distro_install "$src" ${batch[$src]} || missing+=("$src")
    done
    ((${#missing[@]} == 0)) || warn "Some installs failed (${missing[*]}); ./install.sh doctor lists what's missing."
}

nvidia() {
    lspci 2>/dev/null | grep -iE 'vga|3d' | grep -qi nvidia || return 0
    if [[ -e /proc/driver/nvidia ]]; then say "NVIDIA driver is loaded."; return 0; fi
    say "NVIDIA GPU found, driver not loaded"
    ask "Install the NVIDIA driver now (changes kernel modules; reboot afterwards)?" && distro_nvidia
    return 0
}

# --- links (GNU Stow, file by file so app-written files stay out of the repo) --------------------
# Each package dir: config/<app> and the host's home/
link_sources() { local d; for d in "$REPO"/config/*/; do echo "${d%/}"; done; [[ -d $HOSTDIR/home ]] && echo "$HOSTDIR/home"; return 0; }

# Files in the way: exist in ~ but aren't already this repo's file
conflicts() {
    local src f rel target
    while read -r src; do
        while IFS= read -r f; do
            rel=${f#"$src/"}; target=$HOME/$rel
            if [[ -e $target || -L $target ]] && [[ $(readlink -f "$target") != "$(readlink -f "$f")" ]]; then echo "$rel"; fi
        done < <(find "$src" -type f)
    done < <(link_sources)
}

# KDE guard: refuse to link anything over Plasma's own files
kde_guard() {
    if link_sources | xargs -I{} find {} -path '*/.config/*' | grep -qE '/(kdeglobals|kwin[^/]*|plasma[^/]*|kded[^/]*|kscreen[^/]*)$'; then
        echo "A config package contains KDE Plasma config. Refusing, so KDE stays untouched." >&2; exit 1
    fi
}

links() {
    kde_guard
    if ! command -v stow >/dev/null; then
        $DRY && { say "GNU Stow isn't installed yet (the packages step installs it), so the links can't be listed."; return 0; }
        warn "GNU Stow is missing: run ./install.sh --only core first."; return 1
    fi
    # Older installs linked whole folders (~/.config/hypr -> repo) or used home/ instead of config/:
    # drop those links (dangling ones or folder links into this repo); move_settings_home keeps your files
    local l t
    while IFS= read -r l; do
        t=$(readlink -f "$l" || true)
        if [[ ! -e $l ]] || { [[ -d $l && $t == "$REPO"/* ]]; }; then
            # a dangling link is ours if it points into this repo (or the old home/ layout); leave others alone
            [[ ! -e $l && $(readlink "$l") != *home/* && $(readlink -m "$l") != "$REPO"/* ]] && continue
            say "Old link: ~/${l#"$HOME/"}"; run rm "$l"
        fi
    done < <(find "$HOME/.config" "$HOME/.local/bin" "$HOME/Pictures" -maxdepth 3 -type l 2>/dev/null)
    move_settings_home

    mapfile -t clash < <(conflicts)
    if ((${#clash[@]})); then
        local backup; backup=$STATE/backups/$(date +%Y%m%d-%H%M%S)
        say "Backing up ${#clash[@]} file(s) in the way to $backup"
        for rel in "${clash[@]}"; do
            echo "   $rel"
            run mkdir -p "$backup/$(dirname "$rel")"
            run mv "$HOME/$rel" "$backup/$rel"
        done
        run mkdir -p "$STATE"
        $DRY || echo "$backup" > "$STATE/last-backup"
    fi

    say "Linking config/ and hosts/$HOST/home into ~"
    local src
    while read -r src; do
        if $DRY; then stow -n -v --no-folding -R -d "$(dirname "$src")" -t "$HOME" "$(basename "$src")" 2>&1 | grep '^LINK' | grep -v 'reverts previous action' | sed 's/^/   would /' || true
        else stow --no-folding -R -d "$(dirname "$src")" -t "$HOME" "$(basename "$src")"; fi
    done < <(link_sources)

    # Settings app files start from the defaults; your own choices are never overwritten
    local settings=$HOME/.config/hypr/settings
    run mkdir -p "$settings"
    for f in "$REPO"/config/hypr/.config/hypr/defaults/*.conf; do [[ -e $settings/$(basename "$f") ]] || run cp "$f" "$settings/"; done
    [[ -e $settings/wallpaper ]] || run ln -s "$HOME/Pictures/Wallpapers/glass-night.png" "$settings/wallpaper"
    [[ -e $HOME/.config/fuzzel/theme.ini ]] || run cp "$REPO/config/fuzzel/.config/fuzzel/theme-default.ini" "$HOME/.config/fuzzel/theme.ini"
    if [[ -d $HOSTDIR/defaults ]]; then
        while IFS= read -r f; do
            rel=${f#"$HOSTDIR/defaults/"}
            [[ -e $HOME/$rel ]] || { run mkdir -p "$HOME/$(dirname "$rel")"; run cp "$f" "$HOME/$rel"; }
        done < <(find "$HOSTDIR/defaults" -type f)
    fi
    run git -C "$REPO" config core.hooksPath .githooks   # secret scan before commits (.githooks/pre-commit)
}

# Settings written into the repo folder by an older install move to ~/.config, where they belong now
move_settings_home() {
    local pair from to
    for pair in "hypr/.config/hypr/settings:.config/hypr/settings" "quickshell/.config/quickshell/settings.json:.config/quickshell/settings.json" \
                "ghostty/.config/ghostty/theme.conf:.config/ghostty/theme.conf"; do
        from=$REPO/config/${pair%%:*}; to=$HOME/${pair#*:}
        [[ -e $from && ! -e $to ]] || continue
        say "Moving your Settings file $(basename "$from") to ~/${pair#*:}"
        run mkdir -p "$(dirname "$to")"; run mv "$from" "$to"
    done
}

# --- services and groups ------------------------------------------------------------------------
services() {
    say "Services"
    local s
    for s in bluetooth NetworkManager; do
        systemctl list-unit-files "$s.service" >/dev/null 2>&1 || continue
        systemctl is-enabled -q "$s" 2>/dev/null && continue
        run sudo systemctl enable --now "$s"
    done
    # Docker, if you have it, starts on first use: docker.service at boot waits for the network (~5 s)
    if systemctl list-unit-files docker.socket >/dev/null 2>&1; then
        systemctl is-enabled -q docker.socket 2>/dev/null || run sudo systemctl enable docker.socket
        if systemctl is-enabled -q docker.service 2>/dev/null; then
            say "Docker: starting on first use instead of at boot"
            run sudo systemctl disable docker.service
        fi
    fi
    return 0
}

# --- session: lid behaviour and Hyprland as the default login session (system files, asks) -------
session() {
    local lid=/etc/systemd/logind.conf.d/50-lid.conf
    local want=$'[Login]\nHandleLidSwitch=suspend-then-hibernate\nHandleLidSwitchExternalPower=suspend\nHandleLidSwitchDocked=ignore'
    if [[ $(cat "$lid" 2>/dev/null) != "$want" ]]; then
        say "Lid: suspend (then hibernate on battery), ignored with an external screen. KDE uses its own setting."
        if ask "Write $lid?"; then run sudo mkdir -p "$(dirname "$lid")"; $DRY || printf '%s\n' "$want" | sudo tee "$lid" >/dev/null; fi
    fi
    # Plasma Login: preselect Hyprland (KDE stays one click away). Other login screens remember your pick.
    if [[ -f /etc/plasmalogin.conf ]] && grep -qx 'Session=plasma' /etc/plasmalogin.conf; then
        ask "Make Hyprland the preselected session on the login screen?" && run sudo sed -i 's/^Session=plasma$/Session=hyprland/' /etc/plasmalogin.conf
    fi
    return 0
}

# --- host steps: hosts/<host>/steps/NN-*.sh, each asked separately ------------------------------
host_steps() {
    local s
    for s in "$HOSTDIR"/steps/[0-9][0-9]-*.sh; do
        [[ -f $s ]] || continue
        say "Host step ${s#"$REPO"/}"
        sed -n '2,4p' "$s" | sed 's/^#/  /'
        ask "Run it?" || { warn "Skipped ${s##*/}"; continue; }
        if [[ $s == *.user.sh ]]; then run bash "$s"; else run sudo --preserve-env=REPO,DISTRO,HOST bash "$s"; fi
    done
}

# --- update: repo, system, new packages, links -------------------------------------------------
update() {
    if [[ -z ${LINUX_SETUP_PULLED:-} ]] && git -C "$REPO" rev-parse -q --verify '@{u}' >/dev/null; then
        if [[ -n $(git -C "$REPO" status --porcelain) ]]; then warn "The repo has local changes: not pulling (commit or stash them)"
        else
            local before; before=$(git -C "$REPO" rev-parse HEAD)
            say "Pulling this repo"; run git -C "$REPO" pull --ff-only
            # a pull can change this script: carry on with the new one
            [[ $(git -C "$REPO" rev-parse HEAD) == "$before" ]] || exec env LINUX_SETUP_PULLED=1 "$REPO/install.sh" update "${ARGS[@]}"
        fi
    fi
    say "Updating the system"; distro_update
    if command -v flatpak >/dev/null; then run flatpak update -y; fi
    packages
    links
    $DRY || doctor
}

# --- doctor: compare this computer with the repo -------------------------------------------------
doctor() {
    say "Doctor: $PRETTY_NAME, host $HOST, repo $REPO"
    local name src pkgs p
    while read -r name; do
        read -r src pkgs <<< "$(lookup "$name")"
        [[ -z ${src:-} ]] && { bad "package $name: not mapped in packages/$DISTRO.txt"; continue; }
        [[ $src == none ]] && continue
        for p in $pkgs; do distro_installed "$src" "$p" || bad "package missing: $p ($name, $src)"; done
    done < <(wanted_names)

    local srcdir f rel target
    while read -r srcdir; do
        while IFS= read -r f; do
            rel=${f#"$srcdir/"}; target=$HOME/$rel
            if [[ ! -e $target && ! -L $target ]]; then bad "not linked: ~/$rel"
            elif [[ $(readlink -f "$target") != "$(readlink -f "$f")" ]]; then
                if cmp -s "$target" "$f"; then bad "copy instead of link: ~/$rel"; else bad "drifted (local file differs from repo): ~/$rel"; fi
            fi
        done < <(find "$srcdir" -type f)
    done < <(link_sources)

    # files in the managed folders that nothing in the repo provides (besides your Settings files)
    local d l
    for d in .config/hypr .config/hypr/modules .config/quickshell .config/ghostty .config/fuzzel; do
        [[ -d $HOME/$d ]] || continue
        for f in "$HOME/$d"/*; do
            [[ -f $f && ! -L $f ]] || continue
            case ${f#"$HOME/"} in .config/quickshell/settings.json|.config/ghostty/theme.conf|.config/fuzzel/theme.ini|.config/hypr/host.lua) continue ;; esac
            bad "untracked file in a managed folder: ~/${f#"$HOME/"}"
        done
    done
    [[ -L $HOME/.config/hypr || -L $HOME/.config/quickshell ]] && bad "old whole-folder links: run ./install.sh --only links"
    while IFS= read -r l; do
        [[ $(readlink -m "$l") == "$REPO"/* ]] && bad "dead link into the repo: ~/${l#"$HOME/"} (./install.sh --only links removes it)"
    done < <(find "$HOME/.config" "$HOME/.local/bin" -maxdepth 4 -xtype l 2>/dev/null)

    local s
    if systemctl list-unit-files bluetooth.service >/dev/null 2>&1 && ! systemctl is-enabled -q bluetooth 2>/dev/null; then bad "service not enabled: bluetooth"; fi
    if systemctl is-enabled -q docker.service 2>/dev/null; then bad "docker.service starts at boot (./install.sh --only services: start on first use)"; fi

    # snapshots before updates (README: "Roll back an update"); advice, not a mismatch with the repo
    if [[ $(findmnt -no FSTYPE / 2>/dev/null) == btrfs ]]; then
        snapper list-configs 2>/dev/null | grep -qw root || warn "no snapper config for / : updates can't be rolled back"
        if [[ $DISTRO == arch ]]; then
            pacman -Qq snap-pac >/dev/null 2>&1 || warn "snap-pac isn't installed: pacman updates aren't snapshotted"
            if pacman -Qq limine >/dev/null 2>&1 && ! pacman -Qq limine-snapper-sync >/dev/null 2>&1; then warn "limine-snapper-sync isn't installed: snapshots aren't in the boot menu"; fi
        fi
    fi
    [[ $(git -C "$REPO" config core.hooksPath) == .githooks ]] || bad "secret-scan hook not enabled (./install.sh --only links)"
    if [[ -n $(git -C "$REPO" status --porcelain) ]]; then bad "repo has uncommitted changes (git -C $REPO status)"; fi

    if ((PROBLEMS == 0)); then ok "Everything matches the repo."; else echo "$PROBLEMS problem(s). Most are fixed by ./install.sh"; return 1; fi
}

undo() {
    local src
    say "Removing the links"
    while read -r src; do run stow -D -d "$(dirname "$src")" -t "$HOME" "$(basename "$src")"; done < <(link_sources)
    local last; last=$(cat "$STATE/last-backup" 2>/dev/null || true)
    if [[ -n $last && -d $last ]]; then
        say "Latest backup: $last"; (cd "$last" && find . -type f -o -type l) | sed 's|^\./|   |'
        ask "Put these files back into your home folder?" && run cp -a "$last/." "$HOME/"
    else say "No backup to restore."; fi
}

case $CMD in
    doctor) doctor ;;
    undo) undo ;;
    update) update ;;
    install)
        say "$PRETTY_NAME ($DISTRO backend), host $HOST$($DRY && echo ', dry run')"
        want_step packages && packages
        want_step nvidia && nvidia
        want_step links && links
        want_step services && services
        want_step session && session
        want_step host && host_steps
        say "Done. Log out and pick Hyprland at the login screen; ./install.sh doctor checks the result."
        ;;
esac
