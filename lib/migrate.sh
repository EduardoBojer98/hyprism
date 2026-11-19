# shellcheck shell=bash
# Updates, migrations and rollback.
#
# A migration (migrations/NNNN-what.sh) is a small one-time change that carries an existing install over to a
# new layout. Each runs once, in number order; the ones that ran are remembered in $STATE/migrations/.
# A fresh install has nothing to carry over, so it marks them all as done without running them.

migrations() {
    local m id
    $DRY || mkdir -p "$STATE/migrations" # a dry run leaves no state, or the real run wouldn't count as fresh
    for m in "$REPO"/migrations/[0-9][0-9][0-9][0-9]-*.sh; do
        [[ -f $m ]] || continue
        id=$(basename "$m" .sh)
        [[ -e $STATE/migrations/$id ]] && continue
        if $FRESH; then
            $DRY || touch "$STATE/migrations/$id"
            continue
        fi
        say "Migration $id"
        awk 'NR == 1 { next } /^#/ { sub(/^# ?/, "   "); print; next } { exit }' "$m"
        # not inside `if ( … )`: bash ignores set -e there, so a failing line would go on and be marked done
        local rc saved
        saved=$(trap -p ERR)
        trap - ERR
        set +e
        (
            set -euo pipefail
            # shellcheck disable=SC1090
            . "$m"
        )
        rc=$?
        set -e
        eval "$saved"
        if ((rc == 0)); then
            $DRY || touch "$STATE/migrations/$id"
        else
            FAILED+=("migration $id failed (it runs again on the next update)")
            return 0 # later migrations may build on this one
        fi
    done
}

# The official Hyprland plugins are built only here, never at login (the newest release for this Hyprland)
plugins_build() {
    local bin=$REPO/config/scripts/.local/bin/hypr-plugins
    [[ -x $bin ]] && command -v g++ >/dev/null && command -v Hyprland >/dev/null || return 0
    [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || return 0 # needs the running Hyprland: it names the version to build for
    say "Building the Hyprland plugins"
    run "$bin" build || FAILED+=("hypr-plugins build failed (the line above says why)")
}

# After a pull: a running shell keeps the old QML and font files open, so start a fresh one
shell_restart() {
    [[ -n ${HYPRISM_PULLED:-} && -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && pgrep -x qs >/dev/null || return 0
    say "Restarting the shell"
    run fc-cache -f
    # every instance of ~/.config/quickshell on this display, not a test desktop: `qs kill` stops one, and the
    # shell's own reload when the links change can leave two
    local i
    if $DRY; then run qs kill; else for i in 1 2 3; do qs kill >/dev/null 2>&1 || break; done; fi
    run hyprctl dispatch 'hl.dsp.exec_cmd("qs")' >/dev/null
}

update() {
    if [[ -z ${HYPRISM_PULLED:-} ]] && git -C "$REPO" rev-parse -q --verify '@{u}' >/dev/null 2>&1; then # no upstream = nothing to pull
        # untracked files don't count: a pull that would overwrite one stops by itself
        if [[ -n $(git -C "$REPO" status --porcelain --untracked-files=no) ]]; then
            warn "The repo has local changes: not pulling (commit or stash them; your own changes belong in ~/.config/hypr/user.lua and the other files in docs/USER-GUIDE.md, \"Your own config\")"
        else
            local before
            before=$(git -C "$REPO" rev-parse HEAD)
            say "Pulling Hyprism ($(channel_now) channel)"
            run git -C "$REPO" pull --ff-only ||
                FAILED+=("could not pull: this copy has commits the $(channel_now) channel doesn't (git log @{u}..HEAD lists them)")
            if [[ $(git -C "$REPO" rev-parse HEAD) != "$before" ]]; then
                echo "$before" >"$STATE/previous-commit" # what `rollback` returns to
                # the pull may have changed this script: carry on with the new one
                exec env HYPRISM_PULLED=1 "$REPO/install.sh" update "${ARGS[@]}"
            fi
        fi
    fi
    say "Updating the system"
    distro_update || FAILED+=("the system update failed")
    if command -v flatpak >/dev/null && [[ -n $(flatpak list --columns=application 2>/dev/null) ]]; then
        say "Updating Flatpak apps"
        local fy=()
        $YES && fy=(-y --noninteractive)
        run flatpak update "${fy[@]}" || FAILED+=("the Flatpak update failed")
    fi
    migrations
    detect_write
    packages
    links
    shell_restart
    plugins_build
    module_steps # only new or changed ones; each asks first
    $DRY || doctor || FAILED+=("the doctor found problems (above)")
}

# Channels: stable follows the branch main (released and tested), dev follows develop (where work lands first;
# it can break). The channel is simply the branch this copy has checked out.
channel_branch() { case $1 in stable) echo main ;; dev) echo develop ;; *) return 1 ;; esac }
channel_now() {
    case $(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null) in
        main) echo stable ;;
        develop) echo dev ;;
        *) echo none ;;
    esac
}

# channel [stable|dev]: print the channel; with a name, switch this copy to it, then update
channel() {
    local want=$1 branch now
    now=$(channel_now)
    if [[ -z $want ]]; then
        echo "$now ($(git -C "$REPO" rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'not a git copy'))"
        return 0
    fi
    branch=$(channel_branch "$want")
    [[ $want != "$now" ]] || return 0 # nothing to switch (./install.sh update pulls)
    is_checkout || {
        FAILED+=("this copy isn't a git clone, so it can't switch channels (git clone the repo instead)")
        return 0
    }
    if [[ -n $(git -C "$REPO" status --porcelain --untracked-files=no) ]]; then
        FAILED+=("the repo has local changes: commit or stash them, then switch")
        return 0
    fi
    say "Switching Hyprism to the $want channel (branch $branch)"
    [[ $want == stable ]] && echo "   Stable is older than dev: what dev's migrations changed in your settings stays as it is."
    ask "Switch to $want?" || return 0
    run git -C "$REPO" fetch -q origin "+refs/heads/$branch:refs/remotes/origin/$branch" || {
        FAILED+=("could not fetch $branch from origin (offline?)")
        return 0
    }
    if git -C "$REPO" rev-parse -q --verify "refs/heads/$branch" >/dev/null; then
        run git -C "$REPO" switch -q "$branch"
        run git -C "$REPO" branch -q -u "origin/$branch"
    else
        run git -C "$REPO" switch -q -c "$branch" --track "origin/$branch"
    fi
    $DRY && return 0
    git -C "$REPO" merge -q --ff-only "origin/$branch" ||
        warn "Your $branch has commits origin/$branch doesn't: left as it is (git log @{u}..HEAD lists them)"
    rm -f "$STATE/previous-commit" # rollback undoes an update, not a switch: switch back instead
    # the other branch may have changed this script: the rest of the update runs with its own
    local pass=()
    $YES && pass+=(--yes)
    exec env HYPRISM_PULLED=1 "$REPO/install.sh" update "${pass[@]}"
}

# Back to the Hyprism version from before the last update. System packages are not touched: for those use your
# distro's snapshots (the doctor says whether you have them).
rollback() {
    local prev
    prev=$(cat "$STATE/previous-commit" 2>/dev/null || true) # no file = never updated
    [[ -n $prev ]] || {
        say "Nothing to roll back to: no update has been recorded."
        return 0
    }
    say "Going back to $(git -C "$REPO" log -1 --format='%h %s' "$prev")"
    echo "   now: $(git -C "$REPO" log -1 --format='%h %s')"
    ask "Roll back?" || return 0
    run git -C "$REPO" reset --keep "$prev" # --keep refuses rather than losing local edits
    run rm -f "$STATE/previous-commit"
    links
    echo "Migrations are not reversed: they only move files to where the newer version expects them."
    echo "Your next ./install.sh update brings the newer version back."
}
