# shellcheck shell=bash
# Doctor: compares this computer with the repo and changes nothing. Every problem comes with its fix.
# Modules add their own checks in modules/<name>/doctor (plain bash using ok, warn, bad and hw_get).

doctor() {
    say "Doctor: Hyprism $(cat "$REPO/VERSION"), $PRETTY_NAME, $(hw_get machine.form) ($(hw_get machine.product))"
    echo "   modules on: $(modules_on | tr '\n' ' ')"
    local name src pkgs p
    while read -r name; do
        read -r src pkgs <<<"$(lookup "$name")"
        [[ -z ${src:-} ]] && {
            bad "package $name: not mapped in packages/$DISTRO.txt" "add a line for it to packages/$DISTRO.txt"
            continue
        }
        [[ $src == none ]] && continue
        for p in $pkgs; do distro_installed "$src" "$p" || bad "package missing: $p ($name, $src)" "./install.sh --only packages"; done
    done < <(wanted_names)

    local srcdir f rel target
    while read -r srcdir; do
        while IFS= read -r f; do
            rel=${f#"$srcdir/"}
            target=$HOME/$rel
            if [[ ! -e $target && ! -L $target ]]; then
                bad "not linked: ~/$rel" "./install.sh --only links"
            elif [[ $(readlink -f "$target") != "$(readlink -f "$f")" ]]; then
                if cmp -s "$target" "$f"; then
                    bad "copy instead of link: ~/$rel" "./install.sh --only links (the copy is backed up first)"
                else
                    bad "local file differs from the repo: ~/$rel" "move your changes into the repo file, then ./install.sh --only links"
                fi
            fi
        done < <(find "$srcdir" -type f)
    done < <(link_sources)

    # files in the managed folders that nothing in the repo provides (besides the ones Settings writes)
    local d l
    for d in .config/hypr .config/hypr/modules .config/quickshell .config/ghostty .config/fuzzel; do
        [[ -d $HOME/$d ]] || continue
        for f in "$HOME/$d"/*; do
            [[ -f $f && ! -L $f ]] || continue
            case ${f#"$HOME/"} in .config/quickshell/settings.json | .config/quickshell/settings.json.broken | .config/ghostty/theme.conf | .config/fuzzel/theme.ini) continue ;; esac
            bad "file in a managed folder that isn't from the repo: ~/${f#"$HOME/"}" "move it into config/ in the repo, or delete it"
        done
    done
    while IFS= read -r l; do
        [[ $(readlink -m "$l") == "$REPO"/* ]] && bad "dead link into the repo: ~/${l#"$HOME/"}" "./install.sh --only links"
    done < <(find "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/lib" -maxdepth 4 -xtype l 2>/dev/null || true) # a missing folder has no links

    if hw_has radio.bluetooth && _sys_unit_exists bluetooth.service && ! systemctl is-enabled -q bluetooth 2>/dev/null; then
        bad "service not enabled: bluetooth" "./install.sh --only services"
    fi
    if systemctl is-enabled -q docker.service 2>/dev/null; then bad "docker.service starts at boot" "./install.sh --only services (starts it on first use instead)"; fi
    if firewall_missing; then warn "no firewall is active (./install.sh --only firewall turns one on)"; fi
    distro_doctor
    if is_checkout; then
        [[ $(git -C "$REPO" config core.hooksPath) == .githooks ]] || bad "secret-scan hook not enabled" "./install.sh --only links"
        if [[ -n $(git -C "$REPO" status --porcelain) ]]; then warn "the repo has uncommitted changes (git -C $REPO status)"; fi
    fi

    local m s
    for m in $(modules_on); do
        for s in "$REPO/modules/$m"/steps/[0-9][0-9]-*.sh; do
            [[ -f $s ]] || continue
            if [[ ! -f $STATE/steps/$(step_id "$s") ]]; then
                warn "module $m: step ${s##*/} hasn't run (./install.sh --only modules)"
            elif ! step_done "$s"; then
                warn "module $m: step ${s##*/} changed since it ran (./install.sh --only modules)"
            fi
        done
        # shellcheck disable=SC1090
        [[ -f $REPO/modules/$m/doctor ]] && . "$REPO/modules/$m/doctor"
    done

    # the running desktop: Hyprland's own errors, the files Settings generates, stray helpers
    if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && command -v hyprctl >/dev/null; then
        local errs
        errs=$(hyprctl configerrors 2>/dev/null | grep -v '^[[:space:]]*$' || true) # no answer = not running
        [[ -z $errs ]] || bad "Hyprland reports config errors: $(head -1 <<<"$errs")" "hyprctl configerrors shows them all; desktop-reset puts Settings' files back to defaults"
    fi
    if command -v luac >/dev/null; then
        for f in "$HOME"/.config/hypr/settings/*.lua; do
            [[ -f $f ]] && ! luac -p "$f" 2>/dev/null && bad "a Settings file doesn't parse: ~/${f#"$HOME/"}" "delete it; Settings writes it again"
        done
    fi
    local sj=$HOME/.config/quickshell/settings.json
    if [[ -f $sj ]] && command -v jq >/dev/null && ! jq empty "$sj" 2>/dev/null; then
        bad "settings.json isn't valid JSON (the shell is running on defaults)" "fix the file, or: desktop-reset shell"
    fi
    [[ -f $sj.broken ]] && warn "a damaged settings.json was kept as settings.json.broken"
    if pgrep -x hypridle >/dev/null && ! pgrep -af '^hypridle' | grep -q 'settings/hypridle.conf'; then
        bad "hypridle runs without Settings' file" "log out and back in"
    fi
    for p in powermode monswitch; do # the whole command line, so nothing that merely mentions it counts
        (($(pgrep -fc "^[^ ]*bash [^ ]*/bin/$p watch\$" || true) > 1)) && bad "more than one '$p watch' is running" "log out and back in"
    done
    for p in mako dunst swaync; do
        pgrep -x "$p" >/dev/null && warn "$p is running: it takes the notifications the shell should show"
    done

    if ((PROBLEMS == 0 && WARNINGS == 0)); then
        ok "Everything matches the repo."
    elif ((PROBLEMS == 0)); then
        ok "No problems; $WARNINGS note(s) above to look at when you like."
    else
        echo "$PROBLEMS problem(s)$( ((WARNINGS)) && echo ", $WARNINGS note(s)"). Each has its fix on the line below it."
        return 1
    fi
}
