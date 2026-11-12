-- Started with Hyprland only. These are not systemd services on purpose:
-- graphical-session.target is also reached in KDE, and these must not run there.
hl.on("hyprland.start", function()
    -- A test session (tests/nested.sh) is a window inside your real desktop: it gets the shell and a
    -- wallpaper only. No idle timer, mounts or services, which would act on the real session.
    if os.getenv("HYPRISM_TEST") then
        hl.exec_cmd("qs")
        hl.exec_cmd("hyprpaper")
        return
    end
    -- password prompts for apps: its user unit, else the binary (Arch: /usr/lib, Fedora: /usr/libexec)
    hl.exec_cmd("systemctl --user start hyprpolkitagent || if [ -x /usr/lib/hyprpolkitagent/hyprpolkitagent ]; then /usr/lib/hyprpolkitagent/hyprpolkitagent;"
        .. " elif [ -x /usr/libexec/hyprpolkitagent ]; then /usr/libexec/hyprpolkitagent; fi")
    hl.exec_cmd("hypr-plugins")                            -- repo plugins (title-bar minimise), ~/.local/bin/hypr-plugins
    hl.exec_cmd("qs")                                       -- Quickshell: bar, dock, OSD, notifications
    hl.exec_cmd("hyprpaper")                                -- wallpaper
    -- GTK look (light or dark, accent, icons, fonts): Quickshell's ThemeSync sets it from the theme once
    -- Settings have loaded. dconf is shared with KDE, and KDE re-applies Breeze at its own login.
    hl.exec_cmd("hypridle -c ~/.config/hypr/settings/hypridle.conf") -- lock / screen off / sleep (Settings > Lock & Sleep)
    hl.exec_cmd("command -v udiskie >/dev/null && udiskie --automount --notify --no-tray")  -- USB drives mount when plugged in
    hl.exec_cmd("wl-paste --watch clipstore store")         -- clipboard history (Super+V), ~/.local/bin/clipstore
    hl.exec_cmd("[ -f ~/.config/monswitch.conf ] && monswitch sync")                           -- align Hyprland to the actual monitor input on start/resume
    hl.exec_cmd("[ -f ~/.config/monswitch.conf ] && monswitch watch")                          -- follows input switches made on the monitor itself
    -- Give user services this session's display and Hyprland socket
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY DISPLAY HYPRLAND_INSTANCE_SIGNATURE __EGL_VENDOR_LIBRARY_FILENAMES"
        .. " XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
    -- Secret Service (browsers, Git, apps): unlock KWallet with the login password when it is installed,
    -- else start GNOME Keyring's secrets store. Neither needs a desktop environment around it.
    -- After the line above: run at the very start, ksecretd never joined the bus (2026-10-31 audit).
    hl.exec_cmd("sleep 1 && if [ -x /usr/lib/pam_kwallet_init ]; then /usr/lib/pam_kwallet_init; elif [ -x /usr/libexec/pam_kwallet_init ]; then /usr/libexec/pam_kwallet_init;"
        .. " elif command -v gnome-keyring-daemon >/dev/null; then gnome-keyring-daemon --start --components=secrets; fi")
    hl.exec_cmd("sleep 3 && startup-apps")                  -- ~/.config/autostart, Settings > Startup Apps
end)
