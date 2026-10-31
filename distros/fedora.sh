# shellcheck shell=bash
# Fedora backend for install.sh: package manager calls only. Sourced, not run.
# Sources in packages/fedora.txt: repo, copr:OWNER/PROJECT, rpmfusion-free, rpmfusion-nonfree,
# vendor:BASEURL (signing key below), flatpak:APP-ID.

# Vendor repos: base URL -> signing key
declare -A VENDOR_KEYS=(
    [https://dl.google.com/linux/chrome/rpm/stable/x86_64]=https://dl.google.com/linux/linux_signing_key.pub
    [https://packages.microsoft.com/yumrepos/vscode]=https://packages.microsoft.com/keys/microsoft.asc
)

distro_installed() {
    case $1 in
        flatpak:*) flatpak info "$2" >/dev/null 2>&1 ;;
        *) rpm -q "$2" >/dev/null 2>&1 ;;
    esac
}

rpmfusion() {   # rpmfusion free|nonfree
    rpm -q "rpmfusion-$1-release" >/dev/null 2>&1 && return 0
    run sudo dnf install -y "https://mirrors.rpmfusion.org/$1/fedora/rpmfusion-$1-release-$(rpm -E %fedora).noarch.rpm"
}

# Enable every COPR, RPM Fusion, vendor repo and Flathub the packages need, once
distro_prepare() {
    local src name key
    for src in "$@"; do
        case $src in
            copr:*)
                rpm -q dnf-plugins-core >/dev/null 2>&1 || run sudo dnf install -y dnf-plugins-core
                run sudo dnf copr enable -y "${src#copr:}" ;;
            rpmfusion-free) rpmfusion free ;;
            rpmfusion-nonfree) rpmfusion free; rpmfusion nonfree ;;
            vendor:*)
                key=${VENDOR_KEYS[${src#vendor:}]:-}
                [[ -n $key ]] || { warn "No signing key known for ${src#vendor:}: add it to distros/fedora.sh"; continue; }
                name=$(echo "${src#vendor:}" | sed -E 's|https?://||; s|[^A-Za-z0-9]+|-|g')
                [[ -f /etc/yum.repos.d/$name.repo ]] && continue
                if $DRY; then echo "   would write /etc/yum.repos.d/$name.repo"; else
                    printf '[%s]\nname=%s\nbaseurl=%s\nenabled=1\ngpgcheck=1\ngpgkey=%s\n' "$name" "$name" "${src#vendor:}" "$key" |
                        sudo tee "/etc/yum.repos.d/$name.repo" >/dev/null
                fi ;;
            flatpak:*)
                command -v flatpak >/dev/null || run sudo dnf install -y flatpak
                run flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo ;;
        esac
    done
}

distro_install() {
    local src=$1; shift
    case $src in
        flatpak:*) run flatpak install --user -y flathub "$@" ;;
        *) run sudo dnf install -y "$@" ;;
    esac
}

# NVIDIA driver from RPM Fusion; akmods builds the module for each kernel (Secure Boot: enroll the key)
distro_nvidia() {
    rpmfusion free; rpmfusion nonfree
    run sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    say "Wait a few minutes for akmods to build the module, then reboot. With Secure Boot see /usr/share/doc/akmods/README.secureboot"
}
