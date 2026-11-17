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

-- Saved layouts are keyed by a screen's description ("make model serial"), or by its connector name (HDMI-A-1)
-- when two screens share a description. Resolve a key to the connector now carrying it. get_monitors() leaves
-- out screens that are off or mirroring, so those fall back to Hyprland's own "desc:" selector (a key with a
-- space is a description; a plain word is a connector, which may simply be unplugged).
local function resolve(key)
    if key == nil or key == "" then return key end
    for _, m in ipairs(hl.get_monitors()) do
        if m.name == key or (m.description ~= "" and m.description == key) then return m.name end
    end
    return key:find("[^%w%-_.]") and ("desc:" .. key) or key
end

-- the key in DISPLAYS for a connector (by its name, or by the description of the screen on it)
local function key_of(name)
    if DISPLAYS[name] then return name end
    for _, m in ipairs(hl.get_monitors()) do
        if m.name == name and m.description ~= "" and DISPLAYS[m.description] then return m.description end
    end
    return name
end

local function monitor(key, overrides)
    local name = resolve(key)
    -- mirror and disabled are always said: Hyprland keeps an earlier value (a hand-off, a Mirror setting) otherwise
    local spec = { output = name, mode = "preferred", position = "auto", scale = "auto", mirror = "", disabled = false }
    for k, v in pairs(DISPLAYS[key] or {}) do spec[k] = v end
    for k, v in pairs(overrides or {}) do spec[k] = v end
    spec.mirror = resolve(spec.mirror)
    if SHARED and SHARED.output == name then
        spec = { output = name, mode = SHARED.mode, position = "auto", scale = 1, mirror = SHARED.mirror, disabled = false }
    end
    if SHARED and SHARED.output == name then HANDED = name end
    hl.monitor(spec)
end

-- A screen that stops mirroring isn't announced to apps again (no bar, no dock, no screenshots there), and a
-- reload doesn't even end the mirror. get_monitors() leaves a mirroring screen out, so a moment after applying,
-- every screen that should be its own but is missing is switched off and on once (an unplugged one: harmless).
local function reannounce()
    local shown = {}
    for _, m in ipairs(hl.get_monitors()) do shown[m.name] = true end
    local names = {}
    for key, d in pairs(DISPLAYS) do
        if key:sub(1, 1) ~= "_" and not d.disabled and (d.mirror or "") == "" then names[key] = true end
    end
    if HANDED then names[HANDED] = true end -- the shared monitor, when it isn't in the saved layout
    for key in pairs(names) do
        local name = resolve(key)
        if not shown[name] and not (SHARED and SHARED.output == name) then
            hl.monitor({ output = name, disabled = true })
            monitor(key)
        end
    end
end

-- Options live under DISPLAYS._options (Settings > Displays > Advanced); each falls back to the old behaviour.
local function option(key, default)
    local o = type(DISPLAYS._options) == "table" and DISPLAYS._options[key]
    if o == nil then return default end
    return o
end

function apply_displays()
    for name in pairs(DISPLAYS) do
        if name:sub(1, 1) ~= "_" then monitor(name) end
    end
    if SHARED and not DISPLAYS[key_of(SHARED.output)] then monitor(SHARED.output) end
    -- any other screen: beside the others (Settings > Displays > New screens), or showing the laptop panel's picture
    local new = option("newScreen", "right")
    local fallback = { output = "", mode = option("preferHighRefresh", true) and "highrr" or "preferred", scale = "auto",
                       position = ({ right = "auto-right", left = "auto-left", above = "auto-up", below = "auto-down" })[new] or "auto" }
    if new == "mirror" and HW.display.internal and HW.display.internal ~= "" then fallback.mirror = HW.display.internal end
    hl.monitor(fallback)
    hl.config({
        misc = { vrr = ({ off = 0, on = 1, fullscreen = 2 })[option("vrr", "off")] or 0 },
        -- Auto HDR switches an HDMI screen's colour space on fullscreen video, which can blank some screens
        -- for a few seconds; off keeps the signal the same in and out of fullscreen.
        render = { cm_auto_hdr = option("autoHdr", false) and 1 or 0,
                   -- Some screens treat a changed content type as a source change and go black briefly.
                   send_content_type = option("sendContentType", false) },
        -- X11 apps draw at real pixels instead of being stretched by the scale (stretching blurs their text).
        xwayland = { force_zero_scaling = option("xwaylandNativeScale", true) },
    })
    hl.timer(reannounce, { timeout = 600, type = "oneshot" })
end

-- Laptop panel rotation for tablet mode: hyprctl eval 'laptop_panel(1)' (0 normal … 3 = 270°).
-- Touchscreen and stylus rotate with it.
function laptop_panel(transform)
    local panel = HW.display.internal
    if not panel or panel == "" then return end -- a desktop has no panel to turn
    local key = key_of(panel)
    if DISPLAYS[key] then DISPLAYS[key].transform = transform end
    monitor(key, { transform = transform })
    hl.config({ input = { touchdevice = { transform = transform }, tablet = { transform = transform } } })
end

apply_displays()

-- Workspaces (Settings > Displays > Workspaces writes settings/workspaces.lua):
--   dynamic  made when needed on the screen you're working on, gone when empty
--   fixed    1..count always there, each on the screen it was given (none given = the screen you're on)
local wok, wsaved = pcall(require, "settings.workspaces")
WORKSPACES = wok and type(wsaved) == "table" and wsaved or { mode = "dynamic" }
if WORKSPACES.mode == "fixed" then
    local first = {} -- the lowest workspace on each screen is the one it shows at start
    for i = 1, math.min(tonumber(WORKSPACES.count) or 10, 10) do
        local screen = type(WORKSPACES.screens) == "table" and WORKSPACES.screens[tostring(i)] or nil
        local rule = { workspace = tostring(i), persistent = true }
        if type(screen) == "string" and screen ~= "" then
            screen = resolve(screen)
            rule.monitor = screen
            if not first[screen] then rule.default, first[screen] = true, true end
        end
        hl.workspace_rule(rule)
    end
else
    -- A laptop with another screen: the laptop starts on workspace 1 and the first other screen on 2.
    -- (Screens plugged in later take the next free workspace by themselves.)
    local panel, others = HW.display.internal, HW.display.external or {}
    if panel and panel ~= "" and others[1] then
        hl.workspace_rule({ workspace = "1", monitor = panel, default = true })
        hl.workspace_rule({ workspace = "2", monitor = others[1], default = true })
    end
end
