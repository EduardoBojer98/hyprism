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
    echo "Hyprism installs on Arch Linux and its family (CachyOS, EndeavourOS, Manjaro) or Fedora 44+; ${PRETTY_NAME:-this distro} isn't one of them. (Porting: add distros/${ID:-name}.sh, see distros/README.md.)" >&2
    exit 1
}
# shellcheck source=distros/arch.sh
. "$REPO/distros/$DISTRO.sh"
distro_supported || exit 1
MAP=$REPO/packages/$DISTRO.txt
export DISTRO
