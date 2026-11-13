# shellcheck shell=bash
# Updates, migrations and rollback.
#
# A migration (migrations/NNNN-what.sh) is a small one-time change that carries an existing install over to a
# new layout. Each runs once, in number order; the ones that ran are remembered in $STATE/migrations/.
# A fresh install has nothing to carry over, so it marks them all as done without running them.

migrations() {
    local m id
    mkdir -p "$STATE/migrations"
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
        if (
            set -euo pipefail
            # shellcheck disable=SC1090
            . "$m"
        ); then
            $DRY || touch "$STATE/migrations/$id"
        else
            FAILED+=("migration $id failed (it runs again on the next update)")
            return 0 # later migrations may build on this one
        fi
    done
}

# The official Hyprland plugins are built only here, never at login (pinned commit: see hypr-plugins --help)
plugins_build() {
    local bin=$REPO/config/scripts/.local/bin/hypr-plugins
    [[ -x $bin ]] && command -v g++ >/dev/null && command -v Hyprland >/dev/null || return 0
    [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || return 0 # needs the running Hyprland: it names the version to build for
    say "Building the Hyprland plugins"
    run "$bin" build || FAILED+=("hypr-plugins build failed (hypr-plugins --help says how to pin a new Hyprland version)")
}

update() {
    if [[ -z ${HYPRISM_PULLED:-} ]] && git -C "$REPO" rev-parse -q --verify '@{u}' >/dev/null 2>&1; then # no upstream = nothing to pull
        if [[ -n $(git -C "$REPO" status --porcelain) ]]; then
            warn "The repo has local changes: not pulling (commit or stash them)"
        else
            local before
            before=$(git -C "$REPO" rev-parse HEAD)
            say "Pulling Hyprism"
            run git -C "$REPO" pull --ff-only
            if [[ $(git -C "$REPO" rev-parse HEAD) != "$before" ]]; then
                echo "$before" >"$STATE/previous-commit" # what `rollback` returns to
                # the pull may have changed this script: carry on with the new one
                exec env HYPRISM_PULLED=1 "$REPO/install.sh" update "${ARGS[@]}"
            fi
        fi
    fi
    say "Updating the system"
    distro_update || FAILED+=("the system update failed")
    migrations
    detect_write
    packages
    links
    plugins_build
    module_steps # only new or changed ones; each asks first
    $DRY || doctor || FAILED+=("the doctor found problems (above)")
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
