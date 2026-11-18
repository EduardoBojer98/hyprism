-- How windows behave: layout, focus, inactive windows, moving and resizing and per-app rules.
-- Motion belongs to the theme (animations.lua presets, Settings > Themes > Motion).
-- Settings > Windows saves them in settings/windows.lua (Quickshell ThemeSync writes it and calls
-- apply_windows() live with `hyprctl eval`), so WINDOWS and apply_windows() are global.

-- Defaults for a fresh install, the same as the Settings app's (quickshell ConfigData.qml)
WINDOWS = { layout = "dwindle", newSplit = 0, smartSplit = false, masterNew = "slave", masterSide = "left",
            columnWidth = 0.5, followMouse = true, focusOnActivate = false, warpCursor = true,
            backAndForth = false, inactiveOpacity = 1, dimInactive = false, dimStrength = 0.2,
            resizeOnBorder = true, snap = false, hideCursorTyping = false, apps = {}, titleBars = true, maxButton = "float",
            edgeSnap = true }
local ok, saved = pcall(require, "settings.windows")
if ok and type(saved) == "table" then for k, v in pairs(saved) do WINDOWS[k] = v end end

-- Rules made from WINDOWS.apps; switched off before they are made again (Hyprland can't delete one)
local app_rules = {}

-- The maximise button: title bars (plugins.lua), a double click on one, and apps' own buttons (the minimize
-- plugin passes those on with the window's state). Settings > Windows > Maximise button: "float" floats a tiled
-- window, centred, like a normal desktop, maximises a floating one and brings it back on the next click
-- (Super+T or the window menu tile it again); "fill" fills the screen and back.
function maximise_button(addr, floating, fullscreen)
    local a = hl.get_active_window()
    if addr == nil then
        if not a then return end
        addr, floating, fullscreen = a.address, a.floating, a.fullscreen
    end
    if a and a.address ~= addr then a = nil end   -- an app's button on a window that isn't focused: no size to go by
    local win = "address:" .. addr
    if (fullscreen or 0) > 0 then   -- maximised or fullscreen: back to a normal window first, either mode
        hl.dispatch(hl.dsp.window.fullscreen({ action = "toggle", mode = fullscreen == 1 and "maximized" or "fullscreen", window = win }))
        return
    end
    if WINDOWS.maxButton == "fill" or floating then   -- a floating window: maximised, the next click brings it back
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle", window = win }))
    else
        -- the size it had tiled, but never close to the whole screen: a window you can see around.
        -- Read before floating: `a` is live and floating gives it Hyprland's last floating size
        local m, sx, sy = a and a.monitor, a and a.size and a.size.x, a and a.size and a.size.y
        hl.dispatch(hl.dsp.window.float({ action = "enable", window = win }))
        if m and sx then
            local W, H = m.width / m.scale, m.height / m.scale
            hl.dispatch(hl.dsp.window.resize({ x = math.floor(math.min(sx, W * 0.7)), y = math.floor(math.min(sy, H * 0.75)), window = win }))
        end
        hl.dispatch(hl.dsp.window.center({ window = win }))
    end
end

-- Edge snap, like Windows and GNOME: a floating window dropped with the pointer on a screen's outer left or right
-- edge fills that half, on the top edge it is maximised. The minimize plugin calls this when a drag ends, with
-- the pointer and the window's title bar height. Settings > Windows > Snap to screen edges.
function edge_snap(addr, x, y, bar)
    if not WINDOWS.edgeSnap then return end
    local m = hl.get_monitor_at({ x = x, y = y })
    if not m then return end
    local rot = m.transform % 2 == 1
    local W, H = (rot and m.height or m.width) / m.scale, (rot and m.width or m.height) / m.scale
    -- an outer edge: no other screen just past it (the pointer stops there instead of crossing)
    local function outer(px, py)
        local o = hl.get_monitor_at({ x = px, y = py })
        local ow, oh = (o.transform % 2 == 1 and o.height or o.width) / o.scale, (o.transform % 2 == 1 and o.width or o.height) / o.scale
        return not (px >= o.x and px < o.x + ow and py >= o.y and py < o.y + oh)
    end
    local e = 3   -- px from the edge that count as on it
    local side = x <= m.x + e and outer(m.x - 4, y) and 0 or x >= m.x + W - 1 - e and outer(m.x + W + 4, y) and 0.5
    local win = "address:" .. addr
    if y <= m.y + e and outer(x, m.y - 4) then
        hl.dispatch(hl.dsp.window.center({ window = win }))   -- so it comes back centred, not under the bar
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle", window = win }))
    elseif side then
        -- that half of the free area, with the theme's gaps, the same as the window menu's Snap (WindowMenu.qml)
        local r, g, gi = m.reserved, THEME.gaps_out or 0, THEME.gaps_in or 0
        local ax, ay = m.x + r.left + g, m.y + r.top + g
        local aw, ah = W - r.left - r.right - 2 * g, H - r.top - r.bottom - 2 * g
        local x0 = ax + side * aw + (side > 0 and gi or 0)
        local x1 = ax + (side + 0.5) * aw - (side == 0 and gi or 0)
        local y0 = ay + (bar or 0)
        hl.dispatch(hl.dsp.window.resize({ x = math.floor(x1 - x0), y = math.floor(ay + ah - y0), window = win }))
        hl.dispatch(hl.dsp.window.move({ x = math.floor(x0), y = math.floor(y0), window = win }))
    end
end

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
