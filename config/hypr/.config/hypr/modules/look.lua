-- How windows look, set by the active theme (Quickshell Themes.qml). ThemeSync writes the theme's
-- Hyprland values to settings/theme.lua and calls apply_theme() live with hyprctl eval. The
-- defaults below are Pebble's, for the first login before the shell has run.
local ok, saved = pcall(require, "settings.theme")
THEME = ok and type(saved) == "table" and saved or {}
local defaults = {
    theme = "pebble", gaps_in = 8, gaps_out = 16, border_size = 2, rounding = 14,
    active = { "b9cf8fcc" }, border_loop = false, border_speed = 5, inactive = "3d433fff",
    shadow = "soft", blur = false, motion = "ease", accent = "b9cf8f", accent2 = "8fa8a3",
    border_angle = 45, glow = "",
    -- title bars (plugins.lua): Pebble's surface, text, secondary text and raised tone; height from its density
    bar = "232624ff", bar_text = "e9ece6ff", bar_text_dim = "b0b7b0ff", bar_buttons_dim = "2d312eff",
    bar_font = "Archivo", bar_height = 31, bar_blur = false,
}
for k, v in pairs(defaults) do if THEME[k] == nil then THEME[k] = v end end

-- Shadows by name:
--   none   flat (Monolith, Console, Atlas)
--   soft   wide and soft: floating depth without a dark halo (Pebble, Glass, Reactor)
--   paper  short and light, like a sheet on a desk (no theme by default; Settings > Themes > Adjust)
--   hard   a solid offset block in the accent, no blur (Poster)
local SHADOWS = {
    none  = { enabled = false },
    soft  = { enabled = true, range = 28, render_power = 3, offset = "0 8", color = 0x55000000, color_inactive = 0x22000000 },
    paper = { enabled = true, range = 10, render_power = 2, offset = "0 3", color = 0x22000000, color_inactive = 0x14000000 },
}

function apply_theme()
    local colors = {}
    for _, c in ipairs(THEME.active) do colors[#colors + 1] = "rgba(" .. c .. ")" end
    local shadow = SHADOWS[THEME.shadow]
        or { enabled = true, range = 1, render_power = 1, offset = "9 9", sharp = true,
             color = "rgba(" .. THEME.accent .. "ff)", color_inactive = "rgba(000000aa)" }
    -- the neon frame: a glow in its colour around the focused window only (Hyprland tints the active window's shadow)
    if THEME.glow ~= "" then
        shadow = { enabled = true, range = 18, render_power = 2, offset = "0 0", sharp = false,
                   color = "rgba(" .. THEME.glow .. "99)", color_inactive = "rgba(00000000)" }
    end
    hl.config({
        general = {
            gaps_in = THEME.gaps_in, gaps_out = THEME.gaps_out, border_size = THEME.border_size,
            col = { active_border = { colors = colors, angle = THEME.border_angle }, inactive_border = "rgba(" .. THEME.inactive .. ")" },
        },
        decoration = {
            rounding = THEME.rounding,
            shadow = shadow,
            blur = { enabled = THEME.blur },
        },
    })
    apply_motion(THEME.motion)   -- modules/animations.lua
    if setup_plugins then setup_plugins() end   -- title bars in the theme's colours (plugins.lua, loaded after this)
end

hl.config({
    decoration = {
        rounding_power = 2.4,           -- squircle-like corners where a theme rounds them
        active_opacity = 1.0,
        blur = {
            size       = 10,
            passes     = 3,
            noise      = 0.015,
            contrast   = 1.0,
            brightness = 1.0,
            vibrancy   = 0.18,
            popups     = true,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
    -- xwayland, render and misc.vrr options: modules/monitors.lua (Settings > Displays > Advanced)
})
