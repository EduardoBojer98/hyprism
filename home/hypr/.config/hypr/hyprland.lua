-- Hyprland entry point. Each part of the config lives in modules/<name>.lua.
-- Syntax reference: https://wiki.hypr.land/Configuring/Start/ (Lua config, Hyprland 0.56+)

for _, name in ipairs({ "env", "monitors", "input", "look", "animations", "binds", "rules", "autostart" }) do
    require("modules." .. name)
end
