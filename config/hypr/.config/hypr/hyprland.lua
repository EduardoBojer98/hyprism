-- Hyprland entry point. Each part of the config lives in modules/<name>.lua.
-- Syntax reference: https://wiki.hypr.land/Configuring/Start/ (Lua config, Hyprland 0.56+)

-- Every window rule the config makes, by name, so Settings > App Rules can list them (Hyprland
-- has no command for that); window_rules_json() is what it reads through `hyprctl repl`.
WINDOW_RULES = {}
local window_rule = hl.window_rule
hl.window_rule = function(rule) WINDOW_RULES[rule.name or #WINDOW_RULES + 1] = rule; return window_rule(rule) end

local function json(v)
    if type(v) == "table" then
        local out = {}
        for k, x in pairs(v) do out[#out + 1] = string.format("%q", tostring(k)) .. ":" .. json(x) end
        return "{" .. table.concat(out, ",") .. "}"
    end
    return type(v) == "string" and string.format("%q", v) or tostring(v)
end
function window_rules_json()
    local out = {}
    for _, rule in pairs(WINDOW_RULES) do out[#out + 1] = json(rule) end
    return "[" .. table.concat(out, ",") .. "]"
end

for _, name in ipairs({ "env", "monitors", "input", "look", "animations", "binds", "rules", "windows", "plugins", "autostart" }) do
    require("modules." .. name)
end

-- Per-machine overrides: host.lua comes from hosts/<host>/home/.config/hypr/host.lua (install.sh
-- links the chosen host's files), runs last, so it can replace monitors, binds or anything else.
-- Loaded only if present, without pcall, so a mistake in it shows up in hyprctl configerrors.
local hostfile = io.open(os.getenv("HOME") .. "/.config/hypr/host.lua")
if hostfile then hostfile:close(); require("host") end
