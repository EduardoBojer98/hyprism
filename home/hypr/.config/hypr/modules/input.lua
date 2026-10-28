hl.config({
    input = {
        kb_layout  = "us,rs",
        kb_variant = ",latin",
        kb_options = "grp:alt_shift_toggle", -- Alt+Shift switches US <-> Serbian Latin

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
        },

        -- Keep the touchscreen and stylus on the laptop panel, not stretched over both screens
        touchdevice = { output = "eDP-1" },
        tablet      = { output = "eDP-1" },
    },
})

-- Three-finger swipe on the touchpad switches workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
