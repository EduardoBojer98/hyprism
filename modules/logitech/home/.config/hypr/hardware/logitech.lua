-- Logitech devices (modules/logitech): OpenLogi's agent applies your button, gesture and DPI settings.
-- Started here, not only by its unit's graphical-session.target link, so it runs without `systemctl --user enable`.
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start openlogi-agent.service")
end)

-- shortcut: OpenLogi 0.9.0's Actions Ring overlay dies on a screen change at a fractional scale and then
-- busy-loops (github.com/AprilNEA/OpenLogi/issues/1989); a fresh one is fine and the agent respawns it in ~1 s.
-- Drop this once that issue is fixed.
for _, event in ipairs({ "monitor.added", "monitor.removed" }) do
    hl.on(event, function()
        hl.exec_cmd("pkill -f '^/usr/bin/openlogi-overlay'")
    end)
end
