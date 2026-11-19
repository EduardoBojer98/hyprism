# shellcheck shell=bash
# Picks the distro backend (distros/<id>.sh) and its package map. The only place that reads /etc/os-release.

# shellcheck disable=SC1091
. /etc/os-release
DISTRO=""
for id in ${ID:-} ${ID_LIKE:-}; do
    [[ -f $REPO/distros/$id.sh ]] && {
        DISTRO=$id
        break
    }
done
[[ -n $DISTRO ]] || {
    echo "Hyprism installs on Arch Linux, CachyOS, EndeavourOS or Fedora 44+; ${PRETTY_NAME:-this distro} isn't one of them. (Porting: add distros/${ID:-name}.sh, see distros/README.md.)" >&2
    exit 1
}
# shellcheck source=distros/arch.sh
. "$REPO/distros/$DISTRO.sh"
distro_supported || exit 1
# Supported: Arch, CachyOS, EndeavourOS (Arch's own packages) and Fedora 44+, on x86_64. Others are warned, not refused.
[[ ${ID:-} != manjaro ]] || warn "Manjaro is untested: its packages trail Arch's by weeks, so Hyprland or Quickshell may be too old for this config"
[[ $(uname -m) == x86_64 ]] || warn "$(uname -m) is untested: Hyprism is built and tested on x86_64; some packages may be missing"
MAP=$REPO/packages/$DISTRO.txt
export DISTRO
