-- How windows behave: layout, focus, inactive windows, moving and resizing, animations and per-app
-- rules. animations.lua sets the curves and the rest of the motion; the window and desktop
-- animations below replace its leaves with the style chosen in Settings.
-- Settings > Windows saves them in settings/windows.lua (Quickshell ThemeSync writes it and calls
-- apply_windows() live with `hyprctl eval`), so WINDOWS and apply_windows() are global.

-- Defaults for a fresh install, the same as the Settings app's (quickshell ConfigData.qml)
WINDOWS = { layout = "dwindle", newSplit = 0, smartSplit = false, masterNew = "slave", masterSide = "left",
            columnWidth = 0.5, followMouse = true, focusOnActivate = false, warpCursor = true,
            backAndForth = false, inactiveOpacity = 0.96, dimInactive = false, dimStrength = 0.2,
            resizeOnBorder = true, snap = false, hideCursorTyping = false, apps = {},
            animations = true, animOpen = "popin", animClose = "popin", animMove = "smooth",
            animWorkspace = "slidefade", animSpeed = "normal", titleBars = true }
local ok, saved = pcall(require, "settings.windows")
if ok and type(saved) == "table" then for k, v in pairs(saved) do WINDOWS[k] = v end end

hl.curve("bouncy", { type = "spring", mass = 1, stiffness = 210, dampening = 13 })

-- Animation styles: leaf settings for each choice (speed is tenths of a second, before animSpeed)
local OPEN = {
    popin  = { speed = 4.1, spring = "easy", style = "popin 92%" },
    slide  = { speed = 4,   bezier = "easeOutQuint", style = "slide" },
    gnomed = { speed = 4,   bezier = "easeOutQuint", style = "gnomed" },
    fade   = false,   -- only the fade (fadeIn) plays
}
local CLOSE = {
    popin  = { speed = 1.6, bezier = "almostLinear", style = "popin 94%" },
    slide  = { speed = 2.5, bezier = "easeOutQuint", style = "slide" },
    gnomed = { speed = 2,   bezier = "almostLinear", style = "gnomed" },
    fade   = false,
}
local MOVE = {
    smooth = { speed = 4.79, spring = "easy" },
    snappy = { speed = 2.5,  bezier = "easeOutQuint" },
    bouncy = { speed = 5,    spring = "bouncy" },
}
local WORKSPACE = {
    slidefade = { speed = 3.2, bezier = "easeOutQuint", style = "slidefade 12%" },
    slide     = { speed = 3.5, bezier = "easeOutQuint", style = "slide" },
    slidevert = { speed = 3.5, bezier = "easeOutQuint", style = "slidevert" },
    fade      = { speed = 3,   bezier = "almostLinear", style = "fade" },
}
local SPEED = { slow = 1.5, normal = 1, fast = 0.6 }

-- One leaf from a style table; nil or false (fade, none) turns the leaf off
local function anim(leaf, a)
    local mult = SPEED[WINDOWS.animSpeed] or 1
    if not a then hl.animation({ leaf = leaf, enabled = false, speed = 1, bezier = "linear" }); return end
    hl.animation({ leaf = leaf, enabled = true, speed = a.speed * mult, bezier = a.bezier, spring = a.spring, style = a.style })
end

function apply_animations()
    local w = WINDOWS
    hl.config({ animations = { enabled = w.animations } })
    anim("windowsIn", OPEN[w.animOpen])
    anim("windowsOut", CLOSE[w.animClose])
    anim("windowsMove", MOVE[w.animMove])
    -- "none" also skips the fade, so the window just appears or goes
    anim("fadeIn", w.animOpen ~= "none" and { speed = 1.73, bezier = "almostLinear" })
    anim("fadeOut", w.animClose ~= "none" and { speed = 1.46, bezier = "almostLinear" })
    for _, leaf in ipairs({ "workspaces", "workspacesIn", "workspacesOut" }) do anim(leaf, WORKSPACE[w.animWorkspace]) end
end

-- Rules made from WINDOWS.apps; switched off before they are made again (Hyprland can't delete one)
local app_rules = {}

function apply_windows()
    local w = WINDOWS
    hl.config({
        general    = { layout = w.layout, resize_on_border = w.resizeOnBorder, snap = { enabled = w.snap } },
        dwindle    = { force_split = w.newSplit, smart_split = w.smartSplit },
        master     = { new_status = w.masterNew, orientation = w.masterSide },
        scrolling  = { column_width = w.columnWidth },
        input      = { follow_mouse = w.followMouse and 1 or 0 },
        cursor     = { no_warps = not w.warpCursor, hide_on_key_press = w.hideCursorTyping },
        binds      = { workspace_back_and_forth = w.backAndForth },
        decoration = { inactive_opacity = w.inactiveOpacity, dim_inactive = w.dimInactive, dim_strength = w.dimStrength },
        misc       = { focus_on_activate = w.focusOnActivate },
    })
    apply_animations()
    if setup_plugins then setup_plugins() end   -- title bars on or off (plugins.lua, loaded after this)

    for _, r in ipairs(app_rules) do r:set_enabled(false) end
    app_rules = {}
    -- apps: { class = regex, open = "normal"|"float"|"pin" (floating, on top)|"maximize"|"fullscreen", workspace = 0 (any)..10 }
    for key, a in pairs(w.apps or {}) do
        if type(a) == "table" and type(a.class) == "string" and a.class ~= "" then
            local rule = { name = "settings-app-" .. key .. "-" .. a.class, match = { class = a.class } }
            if a.open == "float" then rule.float = true; rule.center = true
            elseif a.open == "maximize" then rule.maximize = true
            elseif a.open == "fullscreen" then rule.fullscreen = true end
            if a.pin or a.open == "pin" then rule.float = true; rule.center = true; rule.pin = true end
            if (tonumber(a.workspace) or 0) > 0 then rule.workspace = tostring(math.floor(a.workspace)) end
            app_rules[#app_rules + 1] = hl.window_rule(rule)
        end
    end
end

apply_windows()
