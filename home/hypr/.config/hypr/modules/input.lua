-- Keyboard, touchpad and pointer settings come from settings/input.lua (Settings app).
-- INPUT and apply_input() are global so the Settings app can apply changes with `hyprctl eval`.

INPUT = require("settings.input")

function apply_input()
    hl.config({
        input = {
            kb_layout    = INPUT.kb_layout,
            kb_variant   = INPUT.kb_variant,
            kb_options   = INPUT.kb_options,
            repeat_rate  = INPUT.repeat_rate,
            repeat_delay = INPUT.repeat_delay,
            follow_mouse = 1,
            sensitivity  = INPUT.sensitivity,
            touchpad = {
                natural_scroll = INPUT.natural_scroll,
                tap_to_click   = INPUT.tap_to_click,
            },
            -- Keep the touchscreen and stylus on the laptop panel, not stretched over both screens
            touchdevice = { output = "eDP-1" },
            tablet      = { output = "eDP-1" },
        },
    })
end

apply_input()

-- Three-finger swipe on the touchpad switches workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
