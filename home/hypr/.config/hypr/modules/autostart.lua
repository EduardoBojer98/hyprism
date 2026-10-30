-- Started with Hyprland only. These are not systemd services on purpose:
-- graphical-session.target is also reached in KDE, and these must not run there.
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent") -- password prompts for apps
    hl.exec_cmd("qs")                                       -- Quickshell: bar, dock, OSD, notifications
    hl.exec_cmd("hyprpaper")                                -- wallpaper
    hl.exec_cmd("pgrep -x squeekboard || squeekboard")      -- on-screen keyboard, hidden until the bar button
    -- GTK look for this session. dconf is shared with KDE, and KDE re-applies Breeze at its own login.
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark"
        .. " && gsettings set org.gnome.desktop.interface color-scheme prefer-dark"
        .. " && gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark"
        .. " && gsettings set org.gnome.desktop.interface font-name 'Inter 11'"
        .. " && gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'")
    hl.exec_cmd("hypridle")                                 -- lock / screen off / sleep
    hl.exec_cmd("wl-paste --watch clipstore store")         -- clipboard history (Super+V), ~/.local/bin/clipstore
    hl.exec_cmd("[ -f ~/.config/monswitch.conf ] && monswitch watch")                          -- follows Acer input switches made on the monitor
    -- Give user services this session's display and Hyprland socket, then restart the ones that
    -- started too early to see it (JuhRadial MX finds the cursor and focused app through them).
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE"
        .. " XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user try-restart juhradialmx-daemon.service")
    hl.exec_cmd("command -v juhradial-mx >/dev/null && (pgrep -f juhradial-overlay.py || juhradial-mx)") -- MX Master radial menu
    hl.exec_cmd("sleep 3 && startup-apps")                  -- Settings > Startup Apps (after the shell is up)
end)
