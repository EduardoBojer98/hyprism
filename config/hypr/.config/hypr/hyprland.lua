-- Hyprland entry point. Each part of the config lives in modules/<name>.lua.
-- Syntax reference: https://wiki.hypr.land/Configuring/Start/ (Lua config, Hyprland 0.56+)

for _, name in ipairs({ "env", "monitors", "input", "look", "animations", "binds", "rules", "autostart" }) do
    require("modules." .. name)
end

-- Per-machine overrides: host.lua comes from hosts/<host>/home/.config/hypr/host.lua (install.sh
-- links the chosen host's files), runs last, so it can replace monitors, binds or anything else.
-- Loaded only if present, without pcall, so a mistake in it shows up in hyprctl configerrors.
local hostfile = io.open(os.getenv("HOME") .. "/.config/hypr/host.lua")
if hostfile then hostfile:close(); require("host") end
