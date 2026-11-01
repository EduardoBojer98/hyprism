-- Smoked glass: white hairline rims, strong blur behind translucent surfaces, soft shadows.
-- Accent, corner radius and gaps come from the shell's Appearance settings (Quickshell ThemeSync
-- writes settings/theme.lua and calls apply_theme() live). Defaults until it has run once.
local ok, saved = pcall(require, "settings.theme")
THEME = ok and saved or {}
local defaults = { accent = "5b9cff",   -- Midnight's accent; Settings > Appearance saves your own
                   rounding = 12, border = "rainbow", border_spin = 60, border_size = 2, gaps = 10 }
for k, v in pairs(defaults) do if THEME[k] == nil then THEME[k] = v end end

-- Catppuccin Macchiato hues around the wheel (the only colours not taken from the shell's theme),
-- ending where they start so the turn has no seam
local c = { red = "ed8796", peach = "f5a97f", yellow = "eed49f", green = "a6da95", teal = "8bd5ca",
            sapphire = "7dc4e4", mauve = "c6a0f6", pink = "f5bde6" }
local RAINBOW = {}
for _, name in ipairs({ "red", "peach", "yellow", "green", "teal", "sapphire", "mauve", "pink", "red" }) do
    RAINBOW[#RAINBOW + 1] = "rgba(" .. c[name] .. "ff)"
end

function apply_theme()
    local active = THEME.border == "rainbow" and { colors = RAINBOW, angle = 0 }
        or { colors = { "rgba(" .. THEME.accent .. "cc)", "rgba(ffffff33)", "rgba(" .. THEME.accent .. "66)" }, angle = 135 }
    hl.config({
        general = { border_size = THEME.border_size, gaps_in = THEME.gaps // 2, gaps_out = THEME.gaps, col = { active_border = active } },
        decoration = { rounding = THEME.rounding },
    })
    -- borderangle "loop" turns the gradient forever; speed is tenths of a second per turn
    local spin = THEME.border == "rainbow" and THEME.border_spin > 0
    -- Hyprland refuses speeds above 100, so an older saved 120 ("Slow") is clamped
    hl.animation({ leaf = "borderangle", enabled = spin, speed = spin and math.min(THEME.border_spin, 100) or 1, bezier = "linear", style = "loop" })
end

hl.config({
    general = {
        col = {
            inactive_border = "rgba(ffffff10)",
        },
    },

    decoration = {
        rounding_power = 2.4,           -- squircle-like corners
        active_opacity   = 1.0,
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
apply_theme()
