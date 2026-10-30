-- Dark liquid glass: hairline borders, strong blur behind translucent surfaces, soft shadows.
local c = require("modules.colors")
-- Accent and corner radius come from the shell's Appearance settings (Quickshell ThemeSync
-- writes settings/theme.lua and calls apply_theme() live). Defaults until it has run once.
local ok, saved = pcall(require, "settings.theme")
THEME = ok and saved or { accent = c.blue, rounding = 16 }

function apply_theme()
    hl.config({
        general = { col = {
            active_border = { colors = { "rgba(" .. THEME.accent .. "cc)", "rgba(ffffff33)", "rgba(" .. c.lavender .. "99)" }, angle = 135 },
        } },
        decoration = { rounding = THEME.rounding },
    })
end

hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 12,
        border_size = 1,
        col = {
            inactive_border = "rgba(ffffff14)",
        },
        resize_on_border = true,
        layout = "dwindle",
    },

    decoration = {
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
apply_theme()
