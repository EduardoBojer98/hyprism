-- Hyprland entry point. Each part of the config lives in modules/<name>.lua.
-- Syntax reference: https://wiki.hypr.land/Configuring/Start/ (Lua config, Hyprland 0.56+)

for _, name in ipairs({ "env", "monitors", "input", "look", "animations", "binds", "rules", "autostart" }) do
    require("modules." .. name)
end

-- Per-machine overrides: hosts/<hostname>.lua runs last, so it can replace monitors,
-- binds or anything else for one computer (e.g. a second PC without the Acer).
local f = io.open("/etc/hostname")
local host = f and f:read("l") or ""
if f then f:close() end
local hostfile = io.open(os.getenv("HOME") .. "/.config/hypr/hosts/" .. host .. ".lua")
if hostfile then
    hostfile:close()
    require("hosts." .. host)
end
