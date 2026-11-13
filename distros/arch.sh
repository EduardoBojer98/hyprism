# shellcheck shell=bash
# Arch Linux and CachyOS backend for install.sh: package manager calls only. Sourced, not run.
# Sources in packages/arch.txt: repo, cachyos (CachyOS repo; the AUR on plain Arch), aur.

aur_helper() { command -v paru || command -v yay; }

distro_supported() { return 0; }

# distro_installed SOURCE PACKAGE
distro_installed() { pacman -Qq "$2" >/dev/null 2>&1; }

# distro_prepare SOURCES...: nothing to enable on Arch; AUR packages need paru or yay
distro_prepare() {
    [[ " $* " == *" aur "* || " $* " == *" cachyos "* ]] && ! aur_helper >/dev/null &&
        warn "No AUR helper (paru or yay): AUR packages are skipped. CachyOS ships paru; on Arch see https://github.com/Morganamilo/paru"
    return 0
}

# distro_install SOURCE PACKAGES...
distro_install() {
    local src=$1
    shift
    local repo=() aur=() p helper
    for p in "$@"; do
        # cachyos: from the repo when this system has it (CachyOS), else from the AUR (plain Arch)
        if [[ $src == repo ]] || { [[ $src == cachyos ]] && pacman -Si "$p" >/dev/null 2>&1; }; then repo+=("$p"); else aur+=("$p"); fi
    done
    ((${#repo[@]} == 0)) || run sudo pacman -S --needed --noconfirm "${repo[@]}"
    if ((${#aur[@]})); then
        helper=$(aur_helper) || {
            warn "Skipped (no AUR helper): ${aur[*]}"
            return 0
        }
        printf '   %s (AUR: built from a user-submitted recipe)\n' "${aur[@]}"
        ask "Build and install these from the AUR?" || {
            warn "Skipped (AUR not trusted): ${aur[*]}"
            return 0
        }
        run "$helper" -S --needed --noconfirm "${aur[@]}"
    fi
}

# NVIDIA driver: CachyOS's chwd picks the right one for the kernel; plain Arch gets the open modules (Turing and newer)
distro_nvidia() {
    if command -v chwd >/dev/null; then
        run sudo chwd -a
    else run sudo pacman -S --needed --noconfirm nvidia-open-dkms nvidia-utils egl-wayland linux-headers; fi
}

# Firewall: ufw, deny incoming and allow outgoing. A failed ufw call (no kernel firewall in a container) is a warning.
distro_firewall() {
    distro_installed repo ufw || distro_install repo ufw
    {
        run sudo ufw default deny incoming &&
            run sudo ufw default allow outgoing &&
            run sudo ufw --force enable # --force: the question was asked above
    } || warn "ufw could not be switched on here"
    sys_enable ufw.service
}

# Full system update (AUR too when there's a helper); snap-pac snapshots before and after
distro_update() {
    local helper y=()
    $YES && y=(--noconfirm)
    if helper=$(aur_helper); then run "$helper" -Syu "${y[@]}"; else run sudo pacman -Syu "${y[@]}"; fi
}

# Doctor extras: snapshots before updates, so a bad system update can be undone from the boot menu
distro_doctor() {
    [[ $(findmnt -no FSTYPE / 2>/dev/null) == btrfs ]] || return 0 # snapshots need btrfs
    snapper list-configs 2>/dev/null | grep -qw root || warn "no snapper config for / : system updates can't be rolled back"
    pacman -Qq snap-pac >/dev/null 2>&1 || warn "snap-pac isn't installed: pacman updates aren't snapshotted"
    if pacman -Qq limine >/dev/null 2>&1 && ! pacman -Qq limine-snapper-sync >/dev/null 2>&1; then
        warn "limine-snapper-sync isn't installed: snapshots aren't in the boot menu"
    fi
}

# distro_kernel_args NAME ARGS: add kernel arguments under a name, so they can be found and removed later.
# shortcut: Limine only (CachyOS's default); other boot loaders get the line to add by hand
distro_kernel_args() {
    if command -v limine-update >/dev/null; then
        sys_write "/etc/limine-entry-tool.d/50-$1.conf" "KERNEL_CMDLINE[default]+=\" $2 \""
        run sudo limine-update
    else
        warn "Add these to your boot loader's kernel line yourself: $2"
        sys_note "kernel arguments you added by hand: $2"
    fi
}

# "Key   : value" lines (pacman -Qi) -> label<TAB>value for the keys asked (KEY=Label|KEY=Label), in that order
arch_pick() {
    awk -F' *: ' -v keys="$1" 'BEGIN { n = split(keys, k, "|") } NF > 1 { val = substr($0, index($0, ": ") + 2); gsub(/^ +/, "", $1); v[$1] = val }
        END { for (i = 1; i <= n; i++) { split(k[i], kl, "="); if (v[kl[1]] != "" && v[kl[1]] != "None") print kl[2] "\t" v[kl[1]] } }'
}

# distro_pkg_owners FILE...: FILE<TAB>PACKAGE for each file a package owns (one call for all files)
distro_pkg_owners() {
    pacman -Qo -- "$@" 2>/dev/null | sed -nE 's/^(.*) is owned by ([^ ]+) [^ ]+$/\1\t\2/p'
}

# distro_pkg_source PACKAGE...: PACKAGE<TAB>LABEL per package, where it came from: aur (not in any repo) or pacman
distro_pkg_source() {
    printf '%s\n' "$@" | awk -F'\t' 'NR == FNR { foreign[$0] = 1; next } { print $0 "\t" ($0 in foreign ? "aur" : "pacman") }' <(pacman -Qqm) -
}

# distro_pkg_versions PACKAGE...: PACKAGE<TAB>VERSION<TAB>SIZE per package (one call for all)
distro_pkg_versions() {
    pacman -Qi -- "$@" 2>/dev/null |
        awk -F' *: ' '/^Name/ { n = $2 } /^Version/ { v = $2 } /^Installed Size/ { print n "\t" v "\t" $2 }'
}

# distro_pkg_info PACKAGE: Label<TAB>value lines for the details panel
distro_pkg_info() {
    local qi from
    qi=$(pacman -Qi -- "$1")
    from=$(arch_pick 'Installed From=x' <<<"$qi" | cut -f2)
    case $from in
        "") from="AUR or built on this computer (not from a repository)" ;;
        cachyos*) from="CachyOS repository ($from)" ;;
        core | extra | multilib) from="Arch Linux repository ($from)" ;;
    esac
    printf 'Installed from\t%s\n' "$from"
    arch_pick 'Name=Package|Version=Version|Description=Package description|Licenses=Licence|Installed Size=Size on disk|Install Date=Installed on|Build Date=Built on|Install Reason=Why it is here|Required By=Needed by|Packager=Packaged by' <<<"$qi" |
        sed -E 's/\tExplicitly installed$/\tYou installed it/; s/\tInstalled as a dependency for another package$/\tAnother package needed it/'
}

# distro_pkg_url PACKAGE: homepage URL, or nothing
distro_pkg_url() { pacman -Qi -- "$1" | arch_pick 'URL=x' | cut -f2; }

# distro_pkg_remove_cmd PACKAGE: the removal command, as words on one line
distro_pkg_remove_cmd() { echo "sudo pacman -Rns -- $1"; }
