-- Keyboard, touchpad and pointer settings come from settings/input.lua (Settings app).
-- INPUT and apply_input() are global so the Settings app can apply changes with `hyprctl eval`.

-- Defaults for a fresh install; Settings > Keyboard & Touchpad writes settings/input.lua.
INPUT = { kb_layout = "us", kb_variant = "", kb_options = "", repeat_rate = 25,
          repeat_delay = 600, sensitivity = 0, natural_scroll = true, tap_to_click = true,
          disable_while_typing = true, clickfinger = true, scroll_factor = 1.0, middle_emulation = false, drag_lock = false,
          mouse_natural_scroll = false, mouse_scroll_factor = 1.0, accel_profile = "adaptive", left_handed = false, mouse_by_app = false, numlock = false,
          touch_output = "", touch_swipe = false, swipe_invert = false, swipe_create = false, swipe_forever = false }
local ok, saved = pcall(require, "settings.input")
if ok and type(saved) == "table" then for k, v in pairs(saved) do INPUT[k] = v end end

function apply_input()
    -- An app of the mouse's own sets it (mouse_by_app): leave speed, acceleration, buttons and wheel at libinput's defaults
    local own = INPUT.mouse_by_app
    hl.config({
        input = {
            kb_layout    = INPUT.kb_layout,
            kb_variant   = INPUT.kb_variant,
            kb_options   = INPUT.kb_options,
            repeat_rate  = INPUT.repeat_rate,
            repeat_delay = INPUT.repeat_delay,
            sensitivity  = own and 0 or INPUT.sensitivity,
            accel_profile = own and "" or INPUT.accel_profile,   -- "": the device's own profile
            left_handed  = (not own) and INPUT.left_handed,
            numlock_by_default = INPUT.numlock,
            natural_scroll = (not own) and INPUT.mouse_natural_scroll,   -- mice; the touchpad's own is below
            scroll_factor  = own and 1.0 or INPUT.mouse_scroll_factor,
            touchpad = {
                natural_scroll = INPUT.natural_scroll,
                tap_to_click   = INPUT.tap_to_click,
                disable_while_typing   = INPUT.disable_while_typing,
                clickfinger_behavior   = INPUT.clickfinger,   -- false: pressing in the pad's bottom corners clicks
                scroll_factor          = INPUT.scroll_factor,
                middle_button_emulation = INPUT.middle_emulation,
                drag_lock              = INPUT.drag_lock and 1 or 0,
            },
        },
    })
    -- Keep the touchscreen and stylus on one screen (Settings > Touch & Tablet; the laptop's own panel by default),
    -- not stretched over every screen
    local panel = INPUT.touch_output ~= "" and INPUT.touch_output or HW.display.internal
    if panel and panel ~= "" then
        hl.config({ input = { touchdevice = { output = panel }, tablet = { output = panel } } })
    end
    hl.config({ gestures = { workspace_swipe_touch = INPUT.touch_swipe, workspace_swipe_invert = INPUT.swipe_invert,
                             workspace_swipe_touch_invert = INPUT.swipe_invert, workspace_swipe_create_new = INPUT.swipe_create,
                             workspace_swipe_forever = INPUT.swipe_forever } })
end

apply_input()

-- Three-finger swipe on the touchpad switches workspaces
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
-- Three fingers up opens Mission Control, like macOS
hl.gesture({ fingers = 3, direction = "up", action = { finish = function() hl.dispatch(hl.dsp.exec_cmd("qs ipc call overview toggle")) end } })
