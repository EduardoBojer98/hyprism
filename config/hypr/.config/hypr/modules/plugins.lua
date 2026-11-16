-- Settings for plugins that ~/.local/bin/hypr-plugins builds and loads after Hyprland starts.
-- A plugin's options and Lua functions only exist once it is loaded, so everything here waits in
-- setup_plugins(): it runs now (a config reload, the plugins already loaded) and again from
-- hypr-plugins right after it loads them, and from apply_windows() when Settings changes.

-- Apps that draw their own minimise / maximise / close buttons, and overlays that must stay bare
local OWN_BUTTONS = "(?i)^(google-chrome.*|chromium.*|com\\.anthropic\\.claude|firefox|org\\.quickshell|code|com\\.microsoft\\.vscode|org\\.gnome\\..*)$"
local BARE_TITLES = "^(Picture-in-Picture|)$"

-- Buttons and rules are added once per Lua state: a config reload makes a new state and also
-- clears hyprbars' buttons, while later setup_plugins() calls (Settings) must not add them again
local added = false

-- The bar's height: Settings > Windows > Title bar size, or the theme's (THEME.bar_height, from its density)
local function bar_height()
    local w = WINDOWS or {}
    return ({ small = 24, medium = 28, large = 34 })[w.titleBarSize] or THEME.bar_height or 28
end

-- The title's colour, focused and not, as window rules: hyprbars redraws a title only when its rule colour
-- changes (a new plugin:hyprbars:col.text waits for the next title change). Hyprland can't delete a rule, so
-- the old pair is switched off, and a new pair is made only when the colours change.
local title_rules, title_key = {}, nil
local function title_colours()
    local key = THEME.bar_text .. THEME.bar_text_dim
    if key == title_key then return end
    for _, r in ipairs(title_rules) do r:set_enabled(false) end
    title_key = key
    local n = #title_rules
    title_rules = {
        hl.window_rule({ name = "hyprbars-title-" .. n, match = { class = ".*" }, ["hyprbars:title_color"] = "rgba(" .. THEME.bar_text_dim .. ")" }),
        -- later rules win: the focused window's title in the full text colour
        hl.window_rule({ name = "hyprbars-title-focus-" .. n, match = { class = ".*", focus = true }, ["hyprbars:title_color"] = "rgba(" .. THEME.bar_text .. ")" }),
    }
end

function setup_plugins()
    local bars = hl.plugin.hyprbars
    if not bars then return end   -- not loaded (yet)

    local w = WINDOWS or {}
    local on = w.titleBars ~= false
    local height = bar_height()
    -- the bar, its title and the unfocused windows' buttons follow the theme live (look.lua apply_theme calls this)
    hl.config({ plugin = { hyprbars = {
        enabled = on,
        bar_height = height,
        bar_color = "rgba(" .. THEME.bar .. ")",
        ["col.text"] = "rgba(" .. THEME.bar_text .. ")",
        inactive_button_color = "rgba(" .. THEME.bar_buttons_dim .. ")",
        bar_text_font = THEME.bar_font,
        bar_text_size = height <= 25 and 9 or height <= 31 and 10 or 11,   -- points; Settings > Windows previews the same
        bar_text_weight = 500,
        bar_text_align = w.titleAlign == "left" and "left" or "center",
        bar_blur = THEME.bar_blur == true,
        bar_part_of_window = true,
        bar_precedence_over_border = true,
        bar_buttons_alignment = w.titleButtons == "left" and "left" or "right",
        bar_padding = 10,
        bar_button_padding = 8,
        icon_on_hover = false,
        on_double_click = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
    } } })
    title_colours()

    if added then return end
    added = true
    -- Buttons go from the aligned edge inwards in the order added (close outermost). hyprbars keeps a button's
    -- colours until the next config reload and has no way to change them, so they can't follow a theme switch:
    -- solid discs whose glyph contrasts with the disc itself read on every bar, light or dark. Unfocused
    -- windows' buttons do follow the theme (inactive_button_color above).
    bars.add_button({ bg_color = "rgba(ff5f57ff)", fg_color = "rgba(1e1e1eff)", size = 14, icon = "✕",
                      action = "hyprctl dispatch 'hl.dsp.window.close()'" })
    bars.add_button({ bg_color = "rgba(868b92ff)", fg_color = "rgba(1e1e1eff)", size = 14, icon = "□",
                      action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']] })
    bars.add_button({ bg_color = "rgba(868b92ff)", fg_color = "rgba(1e1e1eff)", size = 14, icon = "–",
                      action = [[hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:minimized", follow = false })']] })
    -- the window menu (Quickshell WindowMenu.qml): snap layouts, other screen or desktop, float, opacity
    bars.add_button({ bg_color = "rgba(868b92ff)", fg_color = "rgba(1e1e1eff)", size = 14, icon = "⋯",
                      action = "qs ipc call windowmenu open" })

    hl.window_rule({ name = "hyprbars-own-buttons", match = { class = OWN_BUTTONS }, ["hyprbars:no_bar"] = true })
    hl.window_rule({ name = "hyprbars-bare-titles", match = { title = BARE_TITLES }, ["hyprbars:no_bar"] = true })
end

-- For the window menu (Quickshell WindowMenu.qml): whether bars are drawn and which windows skip
-- them, so it can leave room for a bar when it snaps a window into place
function title_bar_info()
    local on = hl.plugin.hyprbars ~= nil and (WINDOWS == nil or WINDOWS.titleBars ~= false)
    return string.format('{"on":%s,"height":%d,"skipClass":%q,"skipTitle":%q}', tostring(on), bar_height(), OWN_BUTTONS, BARE_TITLES)
end

setup_plugins()
