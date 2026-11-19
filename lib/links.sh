# shellcheck shell=bash
# Links: config/<app>/ and each active module's home/ are linked into ~ with GNU Stow, file by file, so files
# that apps write themselves stay out of the repo. Files in the way are moved to a backup first.

# Each folder that mirrors ~
link_sources() {
    local d m
    for d in "$REPO"/config/*/; do echo "${d%/}"; done
    for m in $(modules_on); do [[ -d $REPO/modules/$m/home ]] && echo "$REPO/modules/$m/home"; done
    return 0
}

# Files in the way: they exist in ~ and aren't already this repo's file
conflicts() {
    local src f rel target
    while read -r src; do
        while IFS= read -r f; do
            rel=${f#"$src/"}
            target=$HOME/$rel
            if [[ -e $target || -L $target ]] && [[ $(readlink -f "$target") != "$(readlink -f "$f")" ]]; then echo "$rel"; fi
        done < <(find "$src" -type f)
    done < <(link_sources)
}

links() {
    if ! command -v stow >/dev/null; then
        $DRY && {
            say "GNU Stow isn't installed yet (the packages step installs it), so the links can't be listed."
            return 0
        }
        FAILED+=("GNU Stow is missing: ./install.sh --only core, then --only links")
        return 0
    fi
    # links left behind by files or modules that no longer exist: dead, and pointing into this repo
    local l
    while IFS= read -r l; do
        [[ $(readlink -m "$l") == "$REPO"/* ]] || continue
        say "Old link: ~/${l#"$HOME/"}"
        run rm "$l"
    done < <(find "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/lib" "$HOME/.local/share/fonts" "$HOME/Pictures" -maxdepth 4 -xtype l 2>/dev/null || true) # a missing folder has no links

    unlink_off_modules

    local clash rel backup src
    mapfile -t clash < <(conflicts)
    if ((${#clash[@]})); then
        backup=$STATE/backups/$(date +%Y%m%d-%H%M%S)
        say "Backing up ${#clash[@]} file(s) in the way to $backup"
        for rel in "${clash[@]}"; do
            echo "   $rel"
            run mkdir -p "$backup/$(dirname "$rel")"
            run mv "$HOME/$rel" "$backup/$rel"
        done
    fi

    say "Linking config/ and the active modules into ~"
    while read -r src; do
        if $DRY; then
            stow -n -v --no-folding -R -d "$(dirname "$src")" -t "$HOME" "$(basename "$src")" 2>&1 | grep '^LINK' | grep -v 'reverts previous action' | sed 's/^/   would /' || true # nothing to link is fine
        else
            stow --no-folding -R -d "$(dirname "$src")" -t "$HOME" "$(basename "$src")"
        fi
    done < <(link_sources)

    # Hyprland's Lua can't list a folder, so the modules' Lua files are named in an index it reads
    local index=$HOME/.config/hypr/hardware/index list
    list=""
    [[ -d $HOME/.config/hypr/hardware ]] && list=$(find "$HOME/.config/hypr/hardware" -name '*.lua' -printf '%f\n' | sed 's/\.lua$//' | sort)
    if [[ -z $list ]]; then # nothing to load: no index, as on a fresh install
        [[ ! -e $index ]] || run rm "$index"
    elif [[ $list != "$(cat "$index" 2>/dev/null)" ]]; then # no index yet = write it
        run mkdir -p "$(dirname "$index")"
        $DRY || printf '%s\n' "$list" >"$index"
    fi

    # Files the Settings app owns start from the defaults; your own choices are never overwritten
    local settings=$HOME/.config/hypr/settings f
    [[ -d $settings ]] || run mkdir -p "$settings"
    for f in "$REPO"/config/hypr/.config/hypr/defaults/*.conf; do [[ -e $settings/$(basename "$f") ]] || run cp "$f" "$settings/"; done
    # shortcut: the first wallpaper is a fixed file until themes become folders (roadmap C1)
    [[ -e $settings/wallpaper || ! -e $HOME/Pictures/Wallpapers/glass-night.png ]] || run ln -s "$HOME/Pictures/Wallpapers/glass-night.png" "$settings/wallpaper"
    [[ -e $HOME/.config/fuzzel/theme.ini ]] || { run mkdir -p "$HOME/.config/fuzzel" && run cp "$REPO/config/fuzzel/.config/fuzzel/theme-default.ini" "$HOME/.config/fuzzel/theme.ini"; }
    # secret scan before commits (only in a checkout, not an unpacked archive)
    if is_checkout && [[ $(git -C "$REPO" config core.hooksPath) != .githooks ]]; then
        run git -C "$REPO" config core.hooksPath .githooks
    fi
}

# A module that is off now (its hardware is gone, or --without): its links come out of ~, so its settings stop
# applying. Only links that point at that module's own files are removed.
unlink_off_modules() {
    local on dir m f target
    on=" $(modules_on | tr '\n' ' ') "
    for dir in "$REPO"/modules/*/home; do
        m=$(basename "$(dirname "$dir")")
        [[ $on == *" $m "* ]] && continue
        while IFS= read -r f; do
            target=$HOME/${f#"$dir/"}
            [[ -L $target && $(readlink -f "$target") == "$(readlink -f "$f")" ]] || continue
            say "Module $m is off: removing ~/${f#"$dir/"}"
            run rm "$target"
        done < <(find "$dir" -type f)
    done
    return 0
}

backups_list() {
    local d
    for d in "$STATE"/backups/*/; do
        [[ -d $d ]] || continue
        printf '  %s  (%s files)\n' "$(basename "$d")" "$(find "$d" -type f -o -type l | wc -l)"
    done
    echo "Uninstall puts them all back (the oldest copy of each file wins); only one: ./install.sh uninstall --backup NAME"
}

# Remove the links, then offer a backup (the newest unless --backup names one)
unlink_all() {
    local src last
    say "Removing the links"
    while read -r src; do run stow -D -d "$(dirname "$src")" -t "$HOME" "$(basename "$src")"; done < <(link_sources)
    unlink_off_modules
    # every backup, newest first, so the oldest copy of a file (yours, from before Hyprism) is the one that stays
    local sets=() d
    if [[ -n $BACKUP ]]; then
        [[ -d $STATE/backups/$BACKUP ]] && sets=("$STATE/backups/$BACKUP")
    elif [[ -d $STATE/backups ]]; then
        mapfile -t sets < <(find "$STATE/backups" -mindepth 1 -maxdepth 1 -type d | sort -r)
    fi
    if ((${#sets[@]})); then
        say "Backups: ${sets[*]##*/}"
        for d in "${sets[@]}"; do (cd "$d" && find . -type f -o -type l); done | sed 's|^\./|   |' | sort -u
        if ask "Put these files back into your home folder?"; then
            for d in "${sets[@]}"; do run cp -a "$d/." "$HOME/"; done
        fi
    else
        say "No backup to restore."
    fi
    return 0
}

# What Hyprism generated in ~ is moved aside, never deleted
generated_aside() {
    local aside f
    aside=$STATE/removed-$(date +%Y%m%d-%H%M%S)
    for f in .config/hypr/settings .config/hypr/hardware/index .config/quickshell/settings.json .config/ghostty/theme.conf .config/fuzzel/theme.ini .config/hyprism; do
        [[ -e $HOME/$f ]] || continue
        run mkdir -p "$aside/$(dirname "$f")"
        run mv "$HOME/$f" "$aside/$f"
    done
    say "Your settings and generated files are kept in $aside"
}
