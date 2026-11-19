# shellcheck shell=bash
# Login screen: greetd runs ReGreet inside cage. ReGreet gets the active theme's GTK colours (hyprism.css) and
# the theme's icons and font; PAM unlocks KDE Wallet with the login password. The old display manager is
# disabled, greetd enabled; both take effect at the next boot (switching now would end this session).
for c in greetd regreet cage; do
    command -v "$c" >/dev/null || $DRY || {
        warn "$c isn't installed: login screen left as it is. ./install.sh --only packages installs it (Fedora has no ReGreet)."
        exit 0
    }
done

sys_write /etc/greetd/config.toml '[terminal]
vt = 1

[default_session]
command = "cage -s -m last -- regreet"
user = "greeter"'

# gsettings may be missing on a fresh system: fall back to the defaults below
icons=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d "'" || true)
font=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null | tr -d "'" || true)
sys_write /etc/greetd/regreet.toml "[GTK]
application_prefer_dark_theme = true
theme_name = \"adw-gtk3-dark\"
icon_theme_name = \"${icons:-Papirus-Dark}\"
font_name = \"${font:-Inter 11}\"

[commands]
reboot = [\"systemctl\", \"reboot\"]
poweroff = [\"systemctl\", \"poweroff\"]"

css=$HOME/.config/gtk-4.0/hyprism.css # ThemeSync's colours; a snapshot: the greeter can't read your home
[[ -r $css ]] && sys_write /etc/greetd/regreet.css "$(cat "$css")"

# KDE Wallet opens with the login password, as it did under the old login screen ("-": skipped if missing)
pam=/etc/pam.d/greetd
if [[ -r $pam ]] && ! grep -q pam_kwallet5 "$pam"; then
    sys_write "$pam" "$(cat "$pam")
-auth       optional    pam_kwallet5.so
-session    optional    pam_kwallet5.so auto_start"
fi

old=$(basename "$(readlink /etc/systemd/system/display-manager.service 2>/dev/null)")
if [[ $old != greetd.service ]] && _sys_unit_exists greetd.service; then # no systemd (container): nothing to switch
    [[ -n $old ]] && run sudo systemctl disable "$old"
    # one login manager at a time, so the old one goes first; if greetd won't enable, the old one comes back
    run sudo systemctl enable greetd.service || {
        [[ -n $old ]] && run sudo systemctl enable "$old"
        exit 1
    }
    sys_note "login screen switched to greetd at next boot; back: sudo systemctl disable greetd && sudo systemctl enable ${old:-<your old display manager>}"
fi
