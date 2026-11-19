#!/usr/bin/env bash
# Hyprism in one command: installs git if needed, clones (or updates) Hyprism, then runs ./install.sh.
#
#   curl -fsSL https://raw.githubusercontent.com/EduardoBojer98/hyprism/main/bootstrap.sh | bash
#   curl -fsSL .../bootstrap.sh | bash -s -- --dry-run      any install.sh option goes after "--"
#
#   HYPRISM_DIR=~/somewhere   where to clone (default ~/hyprism)
#   HYPRISM_BRANCH=develop    which branch (default main, the stable channel)
set -Eeuo pipefail

# all in one function, called on the last line: a download cut short runs nothing
main() {
    DIR=${HYPRISM_DIR:-$HOME/hyprism}
    BRANCH=${HYPRISM_BRANCH:-main}
    URL=https://github.com/EduardoBojer98/hyprism.git

    [[ $EUID -ne 0 ]] || {
        echo "Run as your normal user, not with sudo (it asks for sudo when needed)." >&2
        exit 1
    }

    if ! command -v git >/dev/null; then
        echo "==> Installing git"
        if command -v pacman >/dev/null; then
            sudo pacman -S --needed --noconfirm git
        elif command -v dnf >/dev/null; then
            sudo dnf install -y git
        else
            echo "Hyprism needs Arch, CachyOS or Fedora (no pacman or dnf found)." >&2
            exit 1
        fi
    fi

    if [[ -d $DIR/.git ]]; then
        echo "==> Hyprism is already in $DIR: updating it"
        git -C "$DIR" pull --ff-only
    elif [[ -e $DIR ]]; then
        echo "$DIR exists and isn't a Hyprism clone. Move it, or set HYPRISM_DIR=another/folder." >&2
        exit 1
    else
        echo "==> Cloning Hyprism ($BRANCH) into $DIR"
        git clone --branch "$BRANCH" "$URL" "$DIR"
    fi

    # curl | bash feeds this script on stdin, so install.sh's questions read from the terminal instead
    if [[ -t 0 ]] || ! { : </dev/tty; } 2>/dev/null; then
        exec "$DIR/install.sh" "$@"
    else
        exec "$DIR/install.sh" "$@" </dev/tty
    fi
}
main "$@"
