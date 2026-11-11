# shellcheck shell=bash
# Fedora backend for install.sh: package manager calls only. Sourced, not run.
# Sources in packages/fedora.txt: repo, copr:OWNER/PROJECT, rpmfusion-free, rpmfusion-nonfree.

distro_supported() {
    ((${VERSION_ID:-0} >= 44)) && return 0
    echo "Fedora ${VERSION_ID:-?} is too old: Hyprism needs Fedora 44 or newer (its Hyprland and Quickshell)." >&2
    return 1
}

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

# Doctor extras: nothing Fedora-specific yet
distro_doctor() { return 0; }

# distro_kernel_args NAME ARGS: grubby edits every installed kernel entry
distro_kernel_args() {
    run sudo grubby --update-kernel=ALL --args="$2"
    sys_note "kernel arguments added with grubby: $2 (remove: sudo grubby --update-kernel=ALL --remove-args=\"$2\")"
}

# distro_pkg_owners FILE...: FILE<TAB>PACKAGE for each file a package owns
# shortcut: one rpm call per file (a few seconds on a full menu); batch it if that gets slow
distro_pkg_owners() {
    local f pkg
    for f in "$@"; do
        pkg=$(rpm -qf --qf '%{NAME}\n' -- "$f" 2>/dev/null | head -1)
        [[ -n $pkg && $pkg != file ]] && printf '%s\t%s\n' "$f" "$pkg"
    done
    return 0
}

# distro_pkg_source PACKAGE...: PACKAGE<TAB>LABEL per package, where it came from
distro_pkg_source() { printf '%s\trpm\n' "$@"; }

# distro_pkg_versions PACKAGE...: PACKAGE<TAB>VERSION<TAB>SIZE per package
distro_pkg_versions() {
    local p name ver size
    for p in "$@"; do
        IFS=$'\t' read -r name ver size < <(rpm -q --qf '%{NAME}\t%{VERSION}\t%{SIZE}\n' -- "$p" 2>/dev/null | head -1)
        [[ -n ${name:-} ]] && printf '%s\t%s\t%s\n' "$name" "$ver" "$(numfmt --to=iec-i --suffix=B "$size")"
    done
    return 0
}

# distro_pkg_info PACKAGE: Label<TAB>value lines for the details panel
distro_pkg_info() {
    printf 'Installed from\t%s\n' "$(rpm -q --qf '%{FROM_REPO}' "$1" 2>/dev/null || echo "Fedora package")"
    rpm -q --qf 'Package\t%{NAME}\nVersion\t%{VERSION}-%{RELEASE}\nPackage description\t%{SUMMARY}\nLicence\t%{LICENSE}\nInstalled on\t%{INSTALLTIME:date}\n' "$1"
}

# distro_pkg_url PACKAGE: homepage URL, or nothing
distro_pkg_url() { rpm -q --qf '%{URL}' "$1"; }

# distro_pkg_remove_cmd PACKAGE: the removal command, as words on one line
distro_pkg_remove_cmd() { echo "sudo dnf remove $1"; }
