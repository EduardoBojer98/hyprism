-- Dark liquid glass: hairline borders, strong blur behind translucent surfaces, soft shadows.
local c = require("modules.colors")

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 12,
        border_size = 1,
        col = {
            active_border   = { colors = { "rgba(" .. c.blue .. "cc)", "rgba(ffffff33)", "rgba(" .. c.lavender .. "99)" }, angle = 135 },
            inactive_border = "rgba(ffffff14)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 16,
        rounding_power = 2.4,           -- squircle-like corners
        active_opacity   = 1.0,
        inactive_opacity = 0.96,
        shadow = {
            enabled      = true,
            range        = 28,
            render_power = 4,
            offset       = "0 6",
            color        = 0x66000000,
            color_inactive = 0x33000000,
        },
        blur = {
            enabled    = true,
            size       = 10,
            passes     = 3,
            noise      = 0.015,
            contrast   = 1.0,
            brightness = 0.85,
            vibrancy   = 0.25,
            popups     = true,
        },
        dim_inactive = false,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})
