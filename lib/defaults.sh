# shellcheck shell=bash
# Default apps: on a fresh system "open a folder" or "open a link" may do nothing. For each role a default is set
# only where none is set yet (the user's choice is never overridden), to the first installed app of a short list.
# A second run changes nothing.

_app_installed() { # a .desktop file in any of the places apps are installed
    local d
    for d in /usr/share/applications /usr/local/share/applications "$HOME/.local/share/applications"; do
        [[ -f $d/$1 ]] && return 0
    done
    return 1
}
_first_app() { # the first installed of these .desktop names
    local a
    for a in "$@"; do _app_installed "$a" && {
        echo "$a"
        return 0
    }; done
    return 1
}

# default_role ROLE MIME[,MIME…] APP…: set each MIME type that has no default to the first installed APP
default_role() {
    local role=$1 mimes=$2 cur app m
    shift 2
    app=$(_first_app "$@") || app=
    for m in ${mimes//,/ }; do
        cur=$(xdg-mime query default "$m" 2>/dev/null || true)
        if [[ -n $cur ]]; then
            echo "   kept: $role ($m) is $cur"
        elif [[ -z $app ]]; then
            warn "no $role installed: nothing set for $m"
        else
            run xdg-mime default "$app" "$m" && echo "   default $role ($m): $app"
        fi
    done
}

default_apps() {
    if ! command -v xdg-mime >/dev/null || ! command -v xdg-settings >/dev/null; then
        warn "xdg-utils is not installed: default apps not set"
        return 0
    fi
    say "Default apps (only where none is set)"
    local browsers=(firefox.desktop google-chrome.desktop chromium.desktop brave-browser.desktop org.mozilla.firefox.desktop)
    local browser app
    browser=$(xdg-settings get default-web-browser 2>/dev/null || true)
    if [[ -n $browser ]]; then
        echo "   kept: web browser is $browser"
    elif app=$(_first_app "${browsers[@]}"); then
        run xdg-settings set default-web-browser "$app" && echo "   default web browser: $app"
        browser=$app
    else
        warn "no web browser installed: nothing set"
    fi
    default_role "file manager" inode/directory org.kde.dolphin.desktop org.gnome.Nautilus.desktop thunar.desktop
    default_role "text editor" text/plain org.kde.kate.desktop org.gnome.TextEditor.desktop code.desktop
    default_role "image viewer" image/png,image/jpeg org.kde.gwenview.desktop org.gnome.Loupe.desktop imv.desktop
    default_role "PDF viewer" application/pdf org.kde.okular.desktop org.gnome.Evince.desktop org.pwmt.zathura.desktop ${browser:+"$browser"}
}
