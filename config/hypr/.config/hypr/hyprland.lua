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

for _, name in ipairs({ "hardware", "env", "monitors", "input", "look", "animations", "binds", "rules", "windows", "plugins", "autostart" }) do
    require("modules." .. name)
end

-- Hardware modules (modules/<name>/home/.config/hypr/hardware/<name>.lua in the repo) run last, so they can
-- add binds and rules for hardware this computer has. install.sh links them and lists them in the index,
-- because Lua here can't list a folder. Loaded without pcall, so a mistake shows up in hyprctl configerrors.
-- dofile with the full path, not require: Hyprland looks for required files beside the real hyprland.lua
-- (in the repo), and these live in ~/.config/hypr/hardware/.
local folder = os.getenv("HOME") .. "/.config/hypr/hardware/"
local index = io.open(folder .. "index")
if index then
    for name in index:lines() do
        if name ~= "" then dofile(folder .. name .. ".lua") end
    end
    index:close()
end
