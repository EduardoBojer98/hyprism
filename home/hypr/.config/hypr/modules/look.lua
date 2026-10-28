local c = require("modules.colors")

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 10,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(" .. c.blue .. "ff)", "rgba(" .. c.lavender .. "ff)" }, angle = 45 },
            inactive_border = "rgba(" .. c.surface0 .. "ff)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2,
        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = 0x66181926,
        },
        blur = {
            enabled  = true,
            size     = 6,
            passes   = 2,
            vibrancy = 0.17,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})
