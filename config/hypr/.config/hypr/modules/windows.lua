-- How windows behave: layout, focus, inactive windows, moving and resizing and per-app rules.
-- Motion belongs to the theme (animations.lua presets, Settings > Themes > Motion).
-- Settings > Windows saves them in settings/windows.lua (Quickshell ThemeSync writes it and calls
-- apply_windows() live with `hyprctl eval`), so WINDOWS and apply_windows() are global.

-- Defaults for a fresh install, the same as the Settings app's (quickshell ConfigData.qml)
WINDOWS = { layout = "dwindle", newSplit = 0, smartSplit = false, masterNew = "slave", masterSide = "left",
            columnWidth = 0.5, followMouse = true, focusOnActivate = false, warpCursor = true,
            backAndForth = false, inactiveOpacity = 0.96, dimInactive = false, dimStrength = 0.2,
            resizeOnBorder = true, snap = false, hideCursorTyping = false, apps = {}, titleBars = true }
local ok, saved = pcall(require, "settings.windows")
if ok and type(saved) == "table" then for k, v in pairs(saved) do WINDOWS[k] = v end end

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
