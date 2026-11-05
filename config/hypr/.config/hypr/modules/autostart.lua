-- Started with Hyprland only. These are not systemd services on purpose:
-- graphical-session.target is also reached in KDE, and these must not run there.
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent || /usr/lib/hyprpolkitagent/hyprpolkitagent")  -- password prompts for apps (its user unit: same on Arch and Fedora)
    hl.exec_cmd("hypr-plugins")                            -- repo plugins (title-bar minimise), ~/.local/bin/hypr-plugins
    hl.exec_cmd("qs")                                       -- Quickshell: bar, dock, OSD, notifications
    hl.exec_cmd("hyprpaper")                                -- wallpaper
    -- GTK look (light or dark, accent, icons, fonts): Quickshell's ThemeSync sets it from the theme once
    -- Settings have loaded. dconf is shared with KDE, and KDE re-applies Breeze at its own login.
    hl.exec_cmd("hypridle -c ~/.config/hypr/settings/hypridle.conf") -- lock / screen off / sleep (Settings > Lock & Sleep)
    hl.exec_cmd("command -v udiskie >/dev/null && udiskie --automount --notify --no-tray")  -- USB drives mount when plugged in
    hl.exec_cmd("wl-paste --watch clipstore store")         -- clipboard history (Super+V), ~/.local/bin/clipstore
    hl.exec_cmd("[ -f ~/.config/monswitch.conf ] && monswitch sync")                           -- align Hyprland to the actual monitor input on start/resume
    hl.exec_cmd("[ -f ~/.config/monswitch.conf ] && monswitch watch")                          -- follows Acer input switches made on the monitor
    -- Give user services this session's display and Hyprland socket, then restart the ones that
    -- started too early to see it (JuhRadial MX finds the cursor and focused app through them).
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE __EGL_VENDOR_LIBRARY_FILENAMES"
        .. " XDG_CURRENT_DESKTOP XDG_SESSION_TYPE && systemctl --user try-restart juhradialmx-daemon.service")
    -- Unlock the KDE wallet with the login password, so the Secret Service (browsers, Git, apps)
    -- works here too (Plasma does this through an autostart entry that only shows in KDE).
    -- After the line above: run at the very start, ksecretd never joined the bus (2026-10-31 audit).
    hl.exec_cmd("sleep 1 && [ -x /usr/lib/pam_kwallet_init ] && /usr/lib/pam_kwallet_init")
    hl.exec_cmd("sleep 3 && startup-apps")                  -- ~/.config/autostart, Settings > Startup Apps (JuhRadial MX, Flameshot, ...)
end)
