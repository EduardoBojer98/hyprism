-- Smoked glass: white hairline rims, strong blur behind translucent surfaces, soft shadows.
local c = require("modules.colors")
-- Accent and corner radius come from the shell's Appearance settings (Quickshell ThemeSync
-- writes settings/theme.lua and calls apply_theme() live). Defaults until it has run once.
local ok, saved = pcall(require, "settings.theme")
THEME = ok and saved or {}
local defaults = { accent = c.blue, rounding = 12, border = "rainbow", border_spin = 60, border_size = 2 }
for k, v in pairs(defaults) do if THEME[k] == nil then THEME[k] = v end end

-- Catppuccin colours around the wheel, ending where it starts so the turn has no seam
local RAINBOW = {}
for _, name in ipairs({ "red", "peach", "yellow", "green", "teal", "sapphire", "mauve", "pink", "red" }) do
    RAINBOW[#RAINBOW + 1] = "rgba(" .. c[name] .. "ff)"
end

function apply_theme()
    local active = THEME.border == "rainbow" and { colors = RAINBOW, angle = 0 }
        or { colors = { "rgba(" .. THEME.accent .. "cc)", "rgba(ffffff33)", "rgba(" .. c.lavender .. "99)" }, angle = 135 }
    hl.config({
        general = { border_size = THEME.border_size, col = { active_border = active } },
        decoration = { rounding = THEME.rounding },
    })
    -- borderangle "loop" turns the gradient forever; speed is tenths of a second per turn
    local spin = THEME.border == "rainbow" and THEME.border_spin > 0
    hl.animation({ leaf = "borderangle", enabled = spin, speed = spin and THEME.border_spin or 1, bezier = "linear", style = "loop" })
end

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 10,
        col = {
            inactive_border = "rgba(ffffff10)",
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
            range        = 32,          -- wide and soft: floating depth without a dark halo
            render_power = 3,
            offset       = "0 8",
            color        = 0x5a000000,
            color_inactive = 0x26000000,
        },
        blur = {
            enabled    = true,
            size       = 10,
            passes     = 3,
            noise      = 0.015,
            contrast   = 1.0,
            brightness = 1.0,   -- lighter smoke, like macOS
            vibrancy   = 0.18,
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
    -- X11 apps draw at the panel's real pixels instead of being stretched 1.2x on eDP-1
    -- (nearest-neighbour stretching made their text and icons look pixelated). They look a
    -- little smaller on the laptop screen; the 1x external monitor is unaffected.
    xwayland = {
        force_zero_scaling = true,
    },
})
apply_theme()
