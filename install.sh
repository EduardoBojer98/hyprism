#!/usr/bin/env bash
# Install this repo's dotfiles into ~ with GNU Stow. Safe to re-run.
#
#   ./install.sh            back up anything in the way, then link every package in home/
#   ./install.sh --system   also install packages and run system/NN-*.sh, plus
#                           system/hosts/<hostname>/ on that computer (asks once, uses sudo)
#   ./install.sh --dry-run  only show what would be backed up and linked
#   ./install.sh --undo     remove the links and put the latest backup back
#
# Backups go to ~/.local/state/linux-setup/backups/<timestamp>/ with the same layout as ~.
# Nothing here touches KDE Plasma's config (see the KDE guard below).
set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/linux-setup
PACKAGES=$(cd "$REPO/home" && ls -d */ | tr -d / | tr '\n' ' ')

say() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ask() { read -r -p "$1 [y/N] " reply; [[ $reply == [yY]* ]]; }

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not with sudo." >&2; exit 1; }
command -v stow >/dev/null || { echo "GNU Stow is missing: sudo pacman -S stow" >&2; exit 1; }

# KDE guard: refuse to link anything over Plasma's own files
if (cd "$REPO/home" && find . -path '*/.config/*' | grep -qE '/(kdeglobals|kwin[^/]*|plasma[^/]*|kded[^/]*|kscreen[^/]*)$'); then
    echo "A package contains KDE Plasma config. Refusing, so KDE stays untouched." >&2
    exit 1
fi

# Files in the way: they exist in ~ but aren't already this repo's file
conflicts() {
    local pkg f rel target
    for pkg in $PACKAGES; do
        while IFS= read -r f; do
            rel=${f#"$REPO/home/$pkg/"}
            target=$HOME/$rel
            if [[ -e $target || -L $target ]] && [[ $(readlink -f "$target") != "$(readlink -f "$f")" ]]; then
                echo "$rel"
            fi
        done < <(find "$REPO/home/$pkg" -type f)
    done
}

undo() {
    say "Removing links for: $PACKAGES"
    stow -D -d "$REPO/home" -t "$HOME" $PACKAGES
    local last
    last=$(cat "$STATE/last-backup" 2>/dev/null || true)
    if [[ -n $last && -d $last ]]; then
        say "Latest backup: $last"
        (cd "$last" && find . -type f -o -type l) | sed 's|^\./|  |'
        if ask "Restore these files into your home folder?"; then
            cp -a "$last/." "$HOME/"
            say "Restored."
        fi
    else
        say "No backup to restore."
    fi
}

case ${1:-} in
    --undo) undo; exit 0 ;;
    --system)
        # system/NN-*.sh for every computer, then system/hosts/<hostname>/*.sh for this one only
        host=$(cat /etc/hostname 2>/dev/null || hostname)
        steps=("$REPO"/system/[0-9][0-9]-*.sh)
        [[ -d $REPO/system/hosts/$host ]] && steps+=("$REPO"/system/hosts/"$host"/[0-9][0-9]-*.sh)
        say "System steps (need sudo):"; printf '  %s\n' "${steps[@]#"$REPO"/}"
        if ask "Run them now?"; then
            # NN-*.user.sh steps run as you (their installers ask for sudo themselves)
            for s in "${steps[@]}"; do
                if [[ $s == *.user.sh ]]; then bash "$s"; else sudo bash "$s"; fi
            done
        fi
        ;;
    --dry-run|"") ;;
    *) sed -n '2,10p' "$0"; exit 2 ;;
esac

mapfile -t clash < <(conflicts)

if [[ ${1:-} == --dry-run ]]; then
    say "Would back up ${#clash[@]} file(s)"; ((${#clash[@]})) && printf '  %s\n' "${clash[@]}"
    say "Would link: $PACKAGES"
    stow -n -v -R -d "$REPO/home" -t "$HOME" $PACKAGES 2>&1 | grep '^LINK' | grep -v 'reverts previous action' | sed 's/^/  /' || true
    say "(already linked items are not listed)"
    exit 0
fi

if ((${#clash[@]})); then
    backup=$STATE/backups/$(date +%Y%m%d-%H%M%S)
    say "Backing up ${#clash[@]} file(s) to $backup"
    for rel in "${clash[@]}"; do
        mkdir -p "$backup/$(dirname "$rel")"
        mv "$HOME/$rel" "$backup/$rel"
        echo "  $rel"
    done
    mkdir -p "$STATE"
    echo "$backup" > "$STATE/last-backup"
fi

say "Linking: $PACKAGES"
stow -R -d "$REPO/home" -t "$HOME" $PACKAGES

# Secret scan before every commit in this repo (see .githooks/pre-commit)
git -C "$REPO" config core.hooksPath .githooks

say "Done. Log out and pick Hyprland at the login screen. Undo: ./install.sh --undo"
