-- Settings for plugins that ~/.local/bin/hypr-plugins builds and loads after Hyprland starts.
-- A plugin's options and Lua functions only exist once it is loaded, so everything here waits in
-- setup_plugins(): it runs now (a config reload, the plugins already loaded) and again from
-- hypr-plugins right after it loads them, and from apply_windows() when Settings changes.

-- Apps that draw their own minimise / maximise / close buttons, and overlays that must stay bare
local OWN_BUTTONS = "(?i)^(google-chrome.*|chromium.*|com\\.anthropic\\.claude|firefox|org\\.quickshell|code|com\\.microsoft\\.vscode|org\\.gnome\\..*|flameshot)$"
local BARE_TITLES = "^(Picture-in-Picture|JuhRadial MX|)$"

-- Buttons and rules are added once per Lua state: a config reload makes a new state and also
-- clears hyprbars' buttons, while later setup_plugins() calls (Settings) must not add them again
local added = false

function setup_plugins()
    local bars = hl.plugin.hyprbars
    if not bars then return end   -- not loaded (yet)

    local on = WINDOWS == nil or WINDOWS.titleBars ~= false
    hl.config({ plugin = { hyprbars = {
        enabled = on,
        bar_height = 28,
        bar_color = "rgba(18181ee6)",
        ["col.text"] = "rgba(ffffffcc)",
        bar_text_font = "Inter",
        bar_text_size = 10,
        bar_text_weight = 500,
        bar_text_align = "center",
        bar_blur = true,
        bar_part_of_window = true,
        bar_precedence_over_border = true,
        bar_buttons_alignment = "right",
        bar_padding = 10,
        bar_button_padding = 8,
        icon_on_hover = false,
        on_double_click = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']],
    } } })

    if added then return end
    added = true
    -- Buttons go right to left in the order added
    bars.add_button({ bg_color = "rgba(ff5f57ee)", fg_color = "rgba(1e1e1eff)", size = 14, icon = "✕",
                      action = "hyprctl dispatch 'hl.dsp.window.close()'" })
    bars.add_button({ bg_color = "rgba(ffffff26)", fg_color = "rgba(ffffffdd)", size = 14, icon = "□",
                      action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']] })
    bars.add_button({ bg_color = "rgba(ffffff26)", fg_color = "rgba(ffffffdd)", size = 14, icon = "–",
                      action = [[hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:minimized", follow = false })']] })
    -- the window menu (Quickshell WindowMenu.qml): snap layouts, other screen or desktop, float, opacity
    bars.add_button({ bg_color = "rgba(ffffff26)", fg_color = "rgba(ffffffdd)", size = 14, icon = "⋯",
                      action = "qs ipc call windowmenu open" })

    hl.window_rule({ name = "hyprbars-own-buttons", match = { class = OWN_BUTTONS }, ["hyprbars:no_bar"] = true })
    hl.window_rule({ name = "hyprbars-bare-titles", match = { title = BARE_TITLES }, ["hyprbars:no_bar"] = true })
end

-- For the window menu (Quickshell WindowMenu.qml): whether bars are drawn and which windows skip
-- them, so it can leave room for a bar when it snaps a window into place
function title_bar_info()
    local on = hl.plugin.hyprbars ~= nil and (WINDOWS == nil or WINDOWS.titleBars ~= false)
    return string.format('{"on":%s,"height":28,"skipClass":%q,"skipTitle":%q}', tostring(on), OWN_BUTTONS, BARE_TITLES)
end

setup_plugins()
