# shellcheck shell=bash
# Arch Linux and CachyOS backend for install.sh: package manager calls only. Sourced, not run.
# Sources in packages/arch.txt: repo, cachyos (CachyOS repo; the AUR on plain Arch), aur.

aur_helper() { command -v paru || command -v yay; }

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
    local src=$1; shift
    local repo=() aur=() p helper
    for p in "$@"; do
        # cachyos: from the repo when this system has it (CachyOS), else from the AUR (plain Arch)
        if [[ $src == repo ]] || { [[ $src == cachyos ]] && pacman -Si "$p" >/dev/null 2>&1; }; then repo+=("$p"); else aur+=("$p"); fi
    done
    ((${#repo[@]} == 0)) || run sudo pacman -S --needed --noconfirm "${repo[@]}"
    if ((${#aur[@]})); then
        helper=$(aur_helper) || { warn "Skipped (no AUR helper): ${aur[*]}"; return 0; }
        run "$helper" -S --needed --noconfirm "${aur[@]}"
    fi
}

# NVIDIA driver: CachyOS's chwd picks the right one for the kernel; plain Arch gets the open modules (Turing and newer)
distro_nvidia() {
    if command -v chwd >/dev/null; then run sudo chwd -a
    else run sudo pacman -S --needed --noconfirm nvidia-open-dkms nvidia-utils egl-wayland linux-headers; fi
}
