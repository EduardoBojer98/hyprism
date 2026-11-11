-- Touch screens and 2-in-1s (modules/tablet). Folding the screen back switches tablet mode:
-- ~/.local/bin/panel rotates the screen and shows the on-screen keyboard.
-- Fixed binds, so Settings > Keyboard Shortcuts doesn't list them.
local switch = HW.input.tablet_switch
if switch and switch ~= "" then
    hl.bind("switch:on:" .. switch,  hl.dsp.exec_cmd("panel tablet on"),  { locked = true })
    hl.bind("switch:off:" .. switch, hl.dsp.exec_cmd("panel tablet off"), { locked = true })
end
hl.on("hyprland.start", function()
    hl.exec_cmd("command -v squeekboard >/dev/null && { pgrep -x squeekboard || squeekboard; }") -- hidden until the bar button
end)
