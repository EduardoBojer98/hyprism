-- Logitech devices (modules/logitech): OpenLogi's agent applies your button, gesture and DPI settings.
-- Started here, not only by its unit's graphical-session.target link, so it runs without `systemctl --user enable`.
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start openlogi-agent.service")
end)
