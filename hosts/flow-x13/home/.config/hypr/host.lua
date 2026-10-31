-- ROG Flow X13 + the shared Acer: at login the laptop starts on workspace 1 and the Acer on 2.
hl.workspace_rule({ workspace = "1", monitor = "eDP-1",    default = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", default = true })

-- The hinge: folding the screen back switches tablet mode (~/.local/bin/panel rotates and shows
-- the on-screen keyboard). Fixed binds, so Settings > Keyboard Shortcuts doesn't list them.
hl.bind("switch:on:AMD SFH tablet mode switch",  hl.dsp.exec_cmd("panel tablet on"),  { locked = true })
hl.bind("switch:off:AMD SFH tablet mode switch", hl.dsp.exec_cmd("panel tablet off"), { locked = true })
hl.on("hyprland.start", function()
    hl.exec_cmd("pgrep -x squeekboard || squeekboard")  -- on-screen keyboard, hidden until the bar button
end)
