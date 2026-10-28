-- Acer XZ322QU S on top, laptop panel centred below it (same layout as in KDE).
-- 1920x1200 / 1.2 = 1600x1000 logical, so the panel starts at x = (2560 - 1600) / 2 = 480.

hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "0x0",    scale = 1,   vrr = 2 }) -- VRR only in fullscreen
hl.monitor({ output = "eDP-1",    mode = "1920x1200@120", position = "480x1440", scale = 1.2 })
hl.monitor({ output = "",         mode = "preferred",     position = "auto",   scale = "auto" }) -- anything else

-- Workspaces 1-5 live on the big screen, 6-10 on the laptop.
-- When the Acer is switched to the work PC, Hyprland moves 1-5 to the laptop by itself.
for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor   = i <= 5 and "HDMI-A-1" or "eDP-1",
        default   = (i == 1 or i == 6),
    })
end
