-- Monitor layout comes from settings/displays.lua, which the Settings app writes.
-- DISPLAYS and apply_displays() are global so the Settings app and ~/.local/bin/panel can change
-- things at runtime with `hyprctl eval`.

-- No file yet (fresh install): every screen at its preferred mode until Settings saves a layout.
local ok, saved = pcall(require, "settings.displays")
DISPLAYS = ok and type(saved) == "table" and saved or {}

local function monitor(name, overrides)
    local spec = { output = name }
    for k, v in pairs(DISPLAYS[name] or {}) do spec[k] = v end
    for k, v in pairs(overrides or {}) do spec[k] = v end
    hl.monitor(spec)
end

function apply_displays()
    for name in pairs(DISPLAYS) do monitor(name) end
end

-- Laptop panel rotation for tablet mode: hyprctl eval 'laptop_panel(1)' (0 normal … 3 = 270°).
-- Touchscreen and stylus rotate with it.
function laptop_panel(transform)
    if DISPLAYS["eDP-1"] then DISPLAYS["eDP-1"].transform = transform end
    monitor("eDP-1", { transform = transform })
    hl.config({ input = { touchdevice = { transform = transform }, tablet = { transform = transform } } })
end

apply_displays()
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" }) -- any other screen

-- Workspaces open on the screen you're working on; pin some to a screen in hosts/<hostname>.lua.
