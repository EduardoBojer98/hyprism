-- How windows look, set by the active theme (Quickshell Themes.qml). ThemeSync writes the theme's
-- Hyprland values to settings/theme.lua and calls apply_theme() live with hyprctl eval. The
-- defaults below are Pebble's, for the first login before the shell has run.
local ok, saved = pcall(require, "settings.theme")
THEME = ok and type(saved) == "table" and saved or {}
local defaults = {
    theme = "pebble", gaps_in = 7, gaps_out = 14, border_size = 2, rounding = 18,
    active = { "ff9e7acc", "9ad1c0cc" }, inactive = "3a365000",
    shadow = "soft", blur = true, motion = "spring", accent = "ff9e7a", accent2 = "9ad1c0",
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
    hl.config({
        general = {
            gaps_in = THEME.gaps_in, gaps_out = THEME.gaps_out, border_size = THEME.border_size,
            col = { active_border = { colors = colors, angle = 45 }, inactive_border = "rgba(" .. THEME.inactive .. ")" },
        },
        decoration = {
            rounding = THEME.rounding,
            shadow = shadow,
            blur = { enabled = THEME.blur },
        },
    })
    apply_motion(THEME.motion)   -- modules/animations.lua
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
    -- X11 apps draw at the panel's real pixels instead of being stretched 1.2x on eDP-1
    -- (nearest-neighbour stretching made their text and icons look pixelated). They look a
    -- little smaller on the laptop screen; the 1x external monitor is unaffected.
    xwayland = {
        force_zero_scaling = true,
    },
    -- Fullscreen video made the Acer go black for a few seconds, like a source change: Hyprland
    -- switched its HDMI colorspace to BT.2020 (auto HDR) and sent a new content type. Neither
    -- screen here is HDR, so keep the signal the same in and out of fullscreen.
    render = {
        cm_auto_hdr       = 0,
        send_content_type = false,
    },
})
