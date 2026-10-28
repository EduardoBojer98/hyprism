-- Started with Hyprland only. These are not systemd services on purpose:
-- graphical-session.target is also reached in KDE, and these must not run there.
hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent") -- password prompts for apps
    hl.exec_cmd("mako")                                     -- notifications (stopgap)
    hl.exec_cmd("hypridle")                                 -- lock / screen off / sleep
    hl.exec_cmd("wl-paste --watch cliphist store")          -- clipboard history
    hl.exec_cmd("monswitch watch")                          -- follows Acer input switches made on the monitor
end)
