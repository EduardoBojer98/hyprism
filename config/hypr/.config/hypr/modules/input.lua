-- Keyboard, touchpad and pointer settings come from settings/input.lua (Settings app).
-- INPUT and apply_input() are global so the Settings app can apply changes with `hyprctl eval`.

-- Defaults for a fresh install; Settings > Keyboard & Touchpad writes settings/input.lua.
INPUT = { kb_layout = "us", kb_variant = "", kb_options = "grp:alt_shift_toggle", repeat_rate = 25,
          repeat_delay = 600, sensitivity = 0, natural_scroll = true, tap_to_click = true }
local ok, saved = pcall(require, "settings.input")
if ok and type(saved) == "table" then for k, v in pairs(saved) do INPUT[k] = v end end

function apply_input()
    hl.config({
        input = {
            kb_layout    = INPUT.kb_layout,
            kb_variant   = INPUT.kb_variant,
            kb_options   = INPUT.kb_options,
            repeat_rate  = INPUT.repeat_rate,
            repeat_delay = INPUT.repeat_delay,
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
-- Three fingers up opens Mission Control, like macOS
hl.gesture({ fingers = 3, direction = "up", action = { finish = function() hl.dispatch(hl.dsp.exec_cmd("qs ipc call overview toggle")) end } })
