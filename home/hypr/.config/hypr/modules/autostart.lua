-- Started with Hyprland only. These are not systemd services on purpose:
-- graphical-session.target is also reached in KDE, and these must not run there.
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent") -- password prompts for apps
    hl.exec_cmd("qs")                                       -- Quickshell: bar, dock, OSD, notifications
    hl.exec_cmd("hyprpaper")                                -- wallpaper
    hl.exec_cmd("pgrep -x squeekboard || squeekboard")      -- on-screen keyboard, hidden until the bar button
    hl.exec_cmd("kdeconnect-indicator")                     -- phone integration, shows in the bar's tray
    -- GTK look for this session. dconf is shared with KDE, and KDE re-applies Breeze at its own login.
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark"
        .. " && gsettings set org.gnome.desktop.interface color-scheme prefer-dark"
        .. " && gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark"
        .. " && gsettings set org.gnome.desktop.interface font-name 'Inter 11'"
        .. " && gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono Nerd Font 11'")
    hl.exec_cmd("hypridle")                                 -- lock / screen off / sleep
    hl.exec_cmd("wl-paste --watch cliphist store")          -- clipboard history
    hl.exec_cmd("monswitch watch")                          -- follows Acer input switches made on the monitor
end)
