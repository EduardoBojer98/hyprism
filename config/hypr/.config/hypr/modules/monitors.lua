-- Monitor layout comes from settings/displays.lua, which the Settings app writes.
-- DISPLAYS and apply_displays() are global so the Settings app and ~/.local/bin/panel can change
-- things at runtime with `hyprctl eval`.

-- No file yet (fresh install): every screen at its preferred mode until Settings saves a layout.
local ok, saved = pcall(require, "settings.displays")
DISPLAYS = ok and type(saved) == "table" and saved or {}

-- A monitor shared with another computer (~/.local/bin/monswitch): while the other computer has it, it
-- mirrors a screen here so it keeps a signal. monswitch writes settings/shared.lua at the hand-off and
-- removes it after; it is read here so the hand-off survives a reload or anything re-applying these rules.
local sok, shared = pcall(require, "settings.shared")
SHARED = sok and type(shared) == "table" and shared or nil

local function monitor(name, overrides)
    local spec = { output = name, mode = "preferred", position = "auto", scale = "auto" }
    for k, v in pairs(DISPLAYS[name] or {}) do spec[k] = v end
    for k, v in pairs(overrides or {}) do spec[k] = v end
    if SHARED and SHARED.output == name then
        spec = { output = name, mode = SHARED.mode, position = "auto", scale = 1, mirror = SHARED.mirror }
    end
    hl.monitor(spec)
end

function apply_displays()
    for name in pairs(DISPLAYS) do monitor(name) end
    if SHARED and not DISPLAYS[SHARED.output] then monitor(SHARED.output) end
end

-- Laptop panel rotation for tablet mode: hyprctl eval 'laptop_panel(1)' (0 normal … 3 = 270°).
-- Touchscreen and stylus rotate with it.
function laptop_panel(transform)
    local panel = HW.display.internal
    if not panel or panel == "" then return end -- a desktop has no panel to turn
    if DISPLAYS[panel] then DISPLAYS[panel].transform = transform end
    monitor(panel, { transform = transform })
    hl.config({ input = { touchdevice = { transform = transform }, tablet = { transform = transform } } })
end

apply_displays()
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" }) -- any other screen

-- Workspaces open on the screen you're working on; pin some to a screen in host.lua (hosts/<host>/home/.config/hypr/host.lua).

-- A laptop with another screen: the laptop starts on workspace 1 and the first other screen on 2.
-- (Screens plugged in later take the next free workspace by themselves.)
local panel, others = HW.display.internal, HW.display.external or {}
if panel and panel ~= "" and others[1] then
    hl.workspace_rule({ workspace = "1", monitor = panel, default = true })
    hl.workspace_rule({ workspace = "2", monitor = others[1], default = true })
end
