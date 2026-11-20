-- How windows behave: layout, focus, inactive windows, moving and resizing and per-app rules.
-- Motion belongs to the theme (animations.lua presets, Settings > Themes > Motion).
-- Settings > Windows saves them in settings/windows.lua (Quickshell ThemeSync writes it and calls
-- apply_windows() live with `hyprctl eval`), so WINDOWS and apply_windows() are global.

-- Defaults for a fresh install, the same as the Settings app's (quickshell ConfigData.qml)
WINDOWS = { layout = "dwindle", newSplit = 0, smartSplit = false, masterNew = "slave", masterSide = "left",
            columnWidth = 0.5, followMouse = true, focusOnActivate = false, warpCursor = true,
            backAndForth = false, inactiveOpacity = 1, dimInactive = false, dimStrength = 0.2,
            resizeOnBorder = true, snap = false, hideCursorTyping = false, apps = {}, titleBars = true, maxButton = "float",
            edgeSnap = true, floatAll = false }
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

-- Edge snap, like Windows and GNOME: a floating window dropped with the pointer on a screen's outer edge fills
-- that half, in a corner that quarter, and on the top edge (away from the corners) it is maximised. The minimize
-- plugin calls snap_preview() while such a window is dragged near an edge (Quickshell SnapPreview.qml shows the
-- spot) and edge_snap() when it is dropped, with the pointer and the window's title bar height.
-- Settings > Windows > Snap to screen edges.
local SNAP_PARTS = { left = { 0, 0, 0.5, 1 }, right = { 0.5, 0, 0.5, 1 }, max = { 0, 0, 1, 1 },
                     topleft = { 0, 0, 0.5, 0.5 }, topright = { 0.5, 0, 0.5, 0.5 },
                     bottomleft = { 0, 0.5, 0.5, 0.5 }, bottomright = { 0.5, 0.5, 0.5, 0.5 } }

local function screen_size(m)
    local rot = m.transform % 2 == 1
    return (rot and m.height or m.width) / m.scale, (rot and m.width or m.height) / m.scale
end

-- the zone under the pointer and the window's box there ({x, y, w, h}, title bar included), or nil
local function snap_zone(x, y, bar)
    if not WINDOWS.edgeSnap then return nil end
    local m = hl.get_monitor_at({ x = x, y = y })
    if not m then return nil end
    local W, H = screen_size(m)
    -- an outer edge: no other screen just past it (the pointer stops there instead of crossing)
    local function outer(px, py)
        local o = hl.get_monitor_at({ x = px, y = py })
        local ow, oh = screen_size(o)
        return not (px >= o.x and px < o.x + ow and py >= o.y and py < o.y + oh)
    end
    local e, cw, ch = 3, math.max(48, W * 0.12), math.max(48, H * 0.15)   -- on the edge; corner reach
    local L = x <= m.x + e and outer(m.x - 4, y)
    local R = x >= m.x + W - 1 - e and outer(m.x + W + 4, y)
    local T = y <= m.y + e and outer(x, m.y - 4)
    local B = y >= m.y + H - 1 - e and outer(x, m.y + H + 4)
    local nl, nr, nt, nb = x < m.x + cw, x >= m.x + W - cw, y < m.y + ch, y >= m.y + H - ch
    local name = (L or T) and nl and nt and "topleft" or (R or T) and nr and nt and "topright"
        or (L or B) and nl and nb and "bottomleft" or (R or B) and nr and nb and "bottomright"
        or L and "left" or R and "right" or T and "max" or nil
    if not name then return nil end
    -- that part of the free area with the theme's gaps, the same as the window menu's Snap (WindowMenu.qml)
    local p, r, g, gi = SNAP_PARTS[name], m.reserved, THEME.gaps_out or 0, THEME.gaps_in or 0
    local ax, ay = m.x + r.left + g, m.y + r.top + g
    local aw, ah = W - r.left - r.right - 2 * g, H - r.top - r.bottom - 2 * g
    local x0 = ax + p[1] * aw + (p[1] > 0 and gi or 0)
    local x1 = ax + (p[1] + p[3]) * aw - (p[1] + p[3] < 0.999 and gi or 0)
    local y0 = ay + p[2] * ah + (p[2] > 0 and gi or 0)
    local y1 = ay + (p[2] + p[4]) * ah - (p[2] + p[4] < 0.999 and gi or 0)
    return name, { x = math.floor(x0), y = math.floor(y0), w = math.floor(x1 - x0), h = math.floor(y1 - y0) }
end

local preview_shown = nil
local function show_preview(name, box)
    local key = name and string.format("%d %d %d %d", box.x, box.y, box.w, box.h) or nil
    if key == preview_shown then return end
    preview_shown = key
    hl.exec_cmd(key and ("qs ipc call snappreview place " .. key) or "qs ipc call snappreview clear")
end

function snap_preview(x, y, bar)
    show_preview(snap_zone(x, y, bar))
end

function edge_snap(addr, x, y, bar)
    show_preview(nil)
    local name, box = snap_zone(x, y, bar)
    if not name then return end
    local win = "address:" .. addr
    if name == "max" then
        hl.dispatch(hl.dsp.window.center({ window = win }))   -- so it comes back centred, not under the bar
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle", window = win }))
        return
    end
    bar = bar or 0
    hl.dispatch(hl.dsp.window.resize({ x = box.w, y = box.h - bar, window = win }))
    hl.dispatch(hl.dsp.window.move({ x = box.x, y = box.y + bar, window = win }))
end

-- Super+T and the window menu's Floating: a window tiled and floated again comes back where you left it
-- (Hyprland keeps its floating size but centres it). Another window than the focused one just toggles.
local float_spot = {}
function float_toggle(addr)
    local a = hl.get_active_window()
    if a and addr and a.address ~= addr then a = nil end
    if not a then
        if addr then hl.dispatch(hl.dsp.window.float({ action = "toggle", window = "address:" .. addr })) end
        return
    end
    local win, was = "address:" .. a.address, a.floating   -- `a` is live: read it before the toggle
    if was and (a.fullscreen or 0) == 0 then float_spot[a.address] = { x = a.at.x, y = a.at.y } end
    hl.dispatch(hl.dsp.window.float({ action = "toggle", window = win }))
    local s = not was and float_spot[a.address]
    local m = s and hl.get_monitor_at({ x = s.x, y = s.y })
    if m then   -- only onto a screen that is still there
        local W, H = screen_size(m)
        if s.x >= m.x and s.x < m.x + W and s.y >= m.y and s.y < m.y + H then
            hl.dispatch(hl.dsp.window.move({ x = s.x, y = s.y, window = win }))
        end
    end
end

-- Chrome's tab drag closes a floating window and opens a new one where the tab is dropped (the minimize plugin
-- calls this for it): floating again at its old size under the pointer, or snapped if dropped on an edge
function tab_drop(addr, w, h, x, y)
    local win = "address:" .. addr
    hl.dispatch(hl.dsp.window.float({ action = "enable", window = win }))
    hl.dispatch(hl.dsp.window.resize({ x = w, y = h, window = win }))
    hl.dispatch(hl.dsp.window.move({ x = math.floor(x - w / 2), y = math.floor(y - 16), window = win }))
    edge_snap(addr, x, y, 0)
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
    -- every new window floating (the Control Center's Floating tile); the per-app rules below still apply
    if w.floatAll then app_rules[1] = hl.window_rule({ name = "settings-float-all", match = { class = ".*" }, float = true }) end
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
