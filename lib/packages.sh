# shellcheck shell=bash
# Packages: logical names from packages/manifest.txt and each active module's packages.txt, mapped to real
# names in packages/<distro>.txt.

PACKAGE_GROUPS=(core desktop tools look apps shell) # --only core,tools installs just those

want_group() {
    local g sel=false
    for g in "${PACKAGE_GROUPS[@]}"; do [[ ",$ONLY," == *",$g,"* ]] && sel=true; done
    ! $sel || [[ ",$ONLY," == *",$1,"* ]]
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

packages() {
    say "Packages for $PRETTY_NAME (packages/$DISTRO.txt)"
    declare -A batch=()
    local name src pkgs p
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
        for p in $pkgs; do distro_installed "$src" "$p" || batch[$src]+=" $p"; done
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
        distro_install "$src" ${batch[$src]} || FAILED+=("packages from $src did not install:${batch[$src]}")
    done
}
