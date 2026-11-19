# shellcheck shell=bash
# Packages: logical names from packages/manifest.txt and each active module's packages.txt, mapped to real
# names in packages/<distro>.txt.

PACKAGE_GROUPS=(core desktop tools look apps shell) # --only core,tools installs just those

# Full: the desktop plus Hyprism's apps and login screen. Base: the desktop only; your apps and login screen stay.
choose_profile() {
    [[ -n $(hw_get setup.profile) ]] && return 0
    say "Full setup or base?"
    echo "   Full: also Hyprism's apps (Nautilus, Text Editor, Loupe, Papers, Celluloid, Amberol, Resources…),"
    echo "         which follow the theme, and a themed login screen in place of your current one."
    echo "   Base: only the desktop (Hyprland, the shell, terminal, theming, tools); your own apps and login"
    echo "         screen stay as they are. Change later: ./install.sh --profile full (or base)."
    local p=base
    ask "Full setup?" && p=full
    echo "   setup: $p"
    hw_override setup.profile "$p"
}

want_group() {
    local g sel=false
    for g in "${PACKAGE_GROUPS[@]}"; do [[ ",$ONLY," == *",$g,"* ]] && sel=true; done
    if $sel; then [[ ",$ONLY," == *",$1,"* ]]; else [[ $1 != apps || ${PROFILE:-} != base ]]; fi # by name: always
}

wanted_names() {
    local name group m
    while read -r name group; do
        want_group "$group" && echo "$name"
    done < <(awk '!/^[[:space:]]*(#|$)/ { print $1, $2 }' "$REPO/packages/manifest.txt")
    for m in $(modules_on); do
        [[ -f $REPO/modules/$m/packages.txt ]] && awk '!/^[[:space:]]*(#|$)/ { print $1 }' "$REPO/modules/$m/packages.txt"
    done
    return 0
}
# "name" -> "source pkg1 pkg2 ..." from packages/<distro>.txt
lookup() { awk -v n="$1" '$1 == n { gsub(",", " ", $2); print $3, $2; exit }' "$MAP"; }

# install_names NAME...: install a few packages by logical name right now (a module step that needs more
# only on some hardware, e.g. the CUDA build where there is an NVIDIA card)
install_names() {
    local name src pkgs p todo
    for name in "$@"; do
        read -r src pkgs <<<"$(lookup "$name")"
        [[ -n ${src:-} && $src != none ]] || {
            warn "$name: no package for $DISTRO (see packages/$DISTRO.txt)"
            continue
        }
        todo=""
        for p in $pkgs; do distro_installed "$src" "$p" || todo+=" $p"; done
        [[ -n $todo ]] || continue
        distro_prepare "$src"
        # shellcheck disable=SC2086  # a list of package names
        distro_install "$src" $todo
    done
}

packages() {
    say "Packages for $PRETTY_NAME (packages/$DISTRO.txt)"
    declare -A batch=()
    local name src pkgs p why
    while read -r name; do
        read -r src pkgs <<<"$(lookup "$name")"
        [[ -n ${src:-} ]] || {
            warn "$name: not in packages/$DISTRO.txt"
            FAILED+=("package $name has no entry in packages/$DISTRO.txt")
            continue
        }
        [[ $src == none ]] && {
            warn "$name: no package for $DISTRO (see the comment in packages/$DISTRO.txt)"
            continue
        }
        for p in $pkgs; do
            distro_installed "$src" "$p" && continue
            if why=$(distro_unavailable "$src" "$p"); then warn "$p ($name) skipped: $why"; else batch[$src]+=" $p"; fi
        done
    done < <(wanted_names)
    ((${#batch[@]})) || {
        say "All packages are installed."
        return 0
    }
    # every source is named, so you see which third-party repos (AUR, COPR) are about to be trusted
    for src in "${!batch[@]}"; do printf '   %-28s%s\n' "$src:" "${batch[$src]}"; done
    ask "Install these?" || {
        warn "Skipped packages."
        FAILED+=("packages were skipped: ./install.sh --only packages")
        return 0
    }
    distro_prepare "${!batch[@]}"
    for src in "${!batch[@]}"; do
        # shellcheck disable=SC2086  # a list of package names
        distro_install "$src" ${batch[$src]} || FAILED+=("packages from $src did not install:${batch[$src]} (./install.sh --only packages tries again)")
    done
}
