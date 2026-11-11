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
        run "$helper" -S --needed --noconfirm "${aur[@]}"
    fi
}

# NVIDIA driver: CachyOS's chwd picks the right one for the kernel; plain Arch gets the open modules (Turing and newer)
distro_nvidia() {
    if command -v chwd >/dev/null; then
        run sudo chwd -a
    else run sudo pacman -S --needed --noconfirm nvidia-open-dkms nvidia-utils egl-wayland linux-headers; fi
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
