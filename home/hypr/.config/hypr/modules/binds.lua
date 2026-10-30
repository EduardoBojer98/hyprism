-- Keybinds. SUPER is the main key; SHIFT means "move" or "bigger version".
-- Every bind has an id; Settings > Keyboard Shortcuts changes or turns off binds by id, saved
-- in settings/keybinds.lua as { id = "SUPER + K" } or { id = false }. Hyprland's bind
-- description carries "id|group|label" so the Settings page can list them (hyprctl -j binds).
local mod      = "SUPER"
local terminal = "ghostty"
local function key(k) return mod .. " + " .. k end
local exec = hl.dsp.exec_cmd

local ok, overrides = pcall(require, "settings.keybinds")
if not ok or type(overrides) ~= "table" then overrides = {} end

local binds = {}
-- fixed = not editable in Settings (mouse, hardware switches)
local function add(id, group, label, keys, run, opts) binds[#binds + 1] = { id = id, group = group, label = label, keys = keys, run = run, opts = opts } end

-- Apps
add("terminal",  "Apps", "Terminal",                     key("Return"), exec(terminal))
-- Spotlight at the cursor: tap Super alone (fires on release, only if no other key was pressed)
add("spotlight-tap", "Apps", "Spotlight (tap Super)",    "SUPER + Super_L", exec("qs ipc call launcher toggle"), { release = true })
add("spotlight", "Apps", "Spotlight",                    key("Space"), exec("qs ipc call launcher toggle"))
add("files-app", "Apps", "File manager",                 key("E"), exec("dolphin"))
add("settings",  "Apps", "Settings",                     key("I"), exec("qs ipc call settings toggle"))
add("browser",   "Apps", "Web browser",                  key("B"), exec("firefox"))
add("clipboard", "Apps", "Clipboard history",            key("V"), exec("qs ipc call clipboard toggle"))
add("emoji",     "Apps", "Emoji picker",                 key("period"), exec("emojipick"))
add("find-files","Apps", "Spotlight: files",             key("SHIFT + Space"), exec("qs ipc call launcher files"))
add("all-apps",  "Apps", "All applications",             key("A"), exec("qs ipc call launcher apps"))
add("control-center", "Apps", "Control Center",          key("C"), exec("qs ipc call controlcenter toggle"))
add("notifications", "Apps", "Notification centre",       key("N"), exec("qs ipc call notifications toggle"))
add("dnd",           "Apps", "Do Not Disturb on / off",   key("SHIFT + N"), exec("qs ipc call notifications dnd"))

-- Windows
add("close",      "Windows", "Close window",             key("Q"), hl.dsp.window.close())
add("fullscreen", "Windows", "Fullscreen",               key("F"), hl.dsp.window.fullscreen({ action = "toggle" }))
add("maximise",   "Windows", "Maximise",                 key("SHIFT + F"), hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
add("float",      "Windows", "Float / tile",             key("T"), hl.dsp.window.float({ action = "toggle" }))
add("split",      "Windows", "Swap split direction",     key("J"), hl.dsp.layout("togglesplit"))
add("minimise",   "Windows", "Minimise (restore from the dock)", key("H"), hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    add("focus-" .. dir, "Windows", "Focus " .. dir,     key(dir), hl.dsp.focus({ direction = dir }))
    add("move-" .. dir,  "Windows", "Move window " .. dir, key("SHIFT + " .. dir), hl.dsp.window.move({ direction = dir }))
end
add("drag",   "Windows", "Drag window",                  key("mouse:272"), hl.dsp.window.drag(),   { mouse = true, fixed = true })
add("resize", "Windows", "Resize window",                key("mouse:273"), hl.dsp.window.resize(), { mouse = true, fixed = true })

-- Workspaces: SUPER+1..0 go there, SUPER+SHIFT+1..0 send the window there
for i = 1, 10 do
    local k = tostring(i % 10)
    add("workspace-" .. i, "Workspaces", "Go to workspace " .. i,          key(k), hl.dsp.focus({ workspace = i }))
    add("send-" .. i,      "Workspaces", "Send window to workspace " .. i, key("SHIFT + " .. k), hl.dsp.window.move({ workspace = i }))
end
add("workspace-previous", "Workspaces", "Previous workspace",        key("Tab"), hl.dsp.focus({ workspace = "previous" }))
add("workspace-next-wheel", "Workspaces", "Next workspace (wheel)",  key("mouse_down"), hl.dsp.focus({ workspace = "e+1" }), { fixed = true })
add("workspace-prev-wheel", "Workspaces", "Previous workspace (wheel)", key("mouse_up"), hl.dsp.focus({ workspace = "e-1" }), { fixed = true })
add("scratchpad",      "Workspaces", "Show / hide scratchpad",       key("S"), hl.dsp.workspace.toggle_special("scratch"))
add("send-scratchpad", "Workspaces", "Send window to scratchpad",    key("SHIFT + S"), hl.dsp.window.move({ workspace = "special:scratch" }))

-- Screenshots and colour picker
add("screenshot",          "Screen", "Screenshot an area to a file", "Print", exec("hyprshot -m region -o ~/Pictures/Screenshots"))
add("screenshot-annotate", "Screen", "Screenshot an area and annotate", "SHIFT + Print", exec([[grim -g "$(slurp)" - | satty --filename -]]))
add("ocr",                 "Screen", "Copy text from the screen",    key("SHIFT + T"), exec("screentext"))
add("colour-picker",       "Screen", "Colour picker",                key("SHIFT + C"), exec("hyprpicker -a"))

-- Shared Acer: hand it to the work PC and back (~/.local/bin/monswitch)
add("monitor-switch", "Screen", "Hand the Acer to the work PC and back", key("M"), exec("monswitch toggle"))

-- Hinge and lid (~/.local/bin/panel)
add("tablet-on",  "Hardware", "Tablet mode on",  "switch:on:AMD SFH tablet mode switch",  exec("panel tablet on"),  { locked = true, fixed = true })
add("tablet-off", "Hardware", "Tablet mode off", "switch:off:AMD SFH tablet mode switch", exec("panel tablet off"), { locked = true, fixed = true })
add("lid-close",  "Hardware", "Lid closed",      "switch:on:Lid Switch",                  exec("panel lid close"),  { locked = true, fixed = true })
add("lid-open",   "Hardware", "Lid opened",      "switch:off:Lid Switch",                 exec("panel lid open"),   { locked = true, fixed = true })

-- Session
add("lock",   "Session", "Lock the screen",  key("L"), exec("loginctl lock-session"))
add("reload", "Session", "Reload Hyprland",  key("SHIFT + R"), exec("hyprctl reload"))
add("logout", "Session", "Log out",          key("SHIFT + E"), exec("hyprshutdown"))

-- Media, volume and brightness keys (laptop and Keychron)
local held = { locked = true, repeating = true }
local osd = " && qs ipc call osd brightness $(brightnessctl -m | cut -d, -f4 | tr -d %)"
add("volume-up",       "Media", "Volume up",       "XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), held)
add("volume-down",     "Media", "Volume down",     "XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      held)
add("mute",            "Media", "Mute",            "XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
add("mic-mute",        "Media", "Mute microphone", "XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
add("brightness-up",   "Media", "Brightness up",   "XF86MonBrightnessUp",   exec("brightnessctl -e4 -n2 set 5%+" .. osd),           held)
add("brightness-down", "Media", "Brightness down", "XF86MonBrightnessDown", exec("brightnessctl -e4 -n2 set 5%-" .. osd),           held)
add("next",            "Media", "Next track",      "XF86AudioNext",         exec("playerctl next"),       { locked = true })
add("previous",        "Media", "Previous track",  "XF86AudioPrev",         exec("playerctl previous"),   { locked = true })
add("play",            "Media", "Play / pause",    "XF86AudioPlay",         exec("playerctl play-pause"), { locked = true })
add("pause",           "Media", "Play / pause (pause key)", "XF86AudioPause", exec("playerctl play-pause"), { locked = true })

for _, b in ipairs(binds) do
    local keys = b.keys
    local o = overrides[b.id]
    if not (b.opts and b.opts.fixed) and o ~= nil then keys = o end
    if keys then
        local opts = {}
        for k, v in pairs(b.opts or {}) do if k ~= "fixed" then opts[k] = v end end
        opts.description = b.id .. "|" .. b.group .. "|" .. b.label .. "|" .. ((b.opts and b.opts.fixed) and "fixed" or "") .. "|" .. b.keys
        hl.bind(keys, b.run, opts)
    end
end

-- Settings > Keyboard Shortcuts switches here while it records keys, so Hyprland lets every
-- combination through to the page. Ctrl+Alt+Escape always gets back out.
hl.define_submap("keyrecord", function()
    hl.bind("CTRL + ALT + Escape", hl.dsp.submap("reset"))
end)
