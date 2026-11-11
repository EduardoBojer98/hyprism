# shellcheck shell=bash
# Fedora backend for install.sh: package manager calls only. Sourced, not run.
# Sources in packages/fedora.txt: repo, copr:OWNER/PROJECT, rpmfusion-free, rpmfusion-nonfree.

distro_installed() { rpm -q "$2" >/dev/null 2>&1; }

rpmfusion() { # rpmfusion free|nonfree
    rpm -q "rpmfusion-$1-release" >/dev/null 2>&1 && return 0
    run sudo dnf install -y "https://mirrors.rpmfusion.org/$1/fedora/rpmfusion-$1-release-$(rpm -E %fedora).noarch.rpm"
}

# Enable every COPR and RPM Fusion repo the packages need, once
distro_prepare() {
    local src
    for src in "$@"; do
        case $src in
            copr:*)
                rpm -q dnf-plugins-core >/dev/null 2>&1 || run sudo dnf install -y dnf-plugins-core
                run sudo dnf copr enable -y "${src#copr:}"
                ;;
            rpmfusion-free) rpmfusion free ;;
            rpmfusion-nonfree)
                rpmfusion free
                rpmfusion nonfree
                ;;
        esac
    done
}

distro_install() {
    shift
    run sudo dnf install -y "$@"
}

# NVIDIA driver from RPM Fusion; akmods builds the module for each kernel (Secure Boot: enroll the key)
distro_nvidia() {
    rpmfusion free
    rpmfusion nonfree
    run sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    say "Wait a few minutes for akmods to build the module, then reboot. With Secure Boot see /usr/share/doc/akmods/README.secureboot"
}

distro_update() {
    local y=()
    $YES && y=(-y)
    run sudo dnf upgrade --refresh "${y[@]}"
}
