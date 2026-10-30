-- Monitor layout comes from settings/displays.lua, which the Settings app writes.
-- DISPLAYS and apply_displays() are global so the Settings app and ~/.local/bin/panel can change
-- things at runtime with `hyprctl eval`.

DISPLAYS = require("settings.displays")

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

-- Workspaces are numbered 1, 2, 3, … in the order you open them. At login the laptop starts on
-- workspace 1 and the Acer on 2; any other number opens on the screen you're working on.
hl.workspace_rule({ workspace = "1", monitor = "eDP-1",    default = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", default = true })
