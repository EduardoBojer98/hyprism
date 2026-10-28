-- Keybinds. SUPER is the main key; SHIFT means "move" or "bigger version".
local mod      = "SUPER"
local terminal = "alacritty" -- Ghostty replaces this in the apps phase
local function key(k) return mod .. " + " .. k end
local exec = hl.dsp.exec_cmd

-- Apps
hl.bind(key("Return"), exec(terminal))
hl.bind(key("Space"),  exec("fuzzel"))
hl.bind(key("E"),      exec("dolphin"))
hl.bind(key("B"),      exec("firefox"))
hl.bind(key("V"),      exec("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))

-- Windows
hl.bind(key("Q"),         hl.dsp.window.close())
hl.bind(key("F"),         hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(key("SHIFT + F"), hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
hl.bind(key("T"),         hl.dsp.window.float({ action = "toggle" }))
hl.bind(key("J"),         hl.dsp.layout("togglesplit"))
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(key(dir),             hl.dsp.focus({ direction = dir }))
    hl.bind(key("SHIFT + " .. dir), hl.dsp.window.move({ direction = dir }))
end
hl.bind(key("mouse:272"), hl.dsp.window.drag(),   { mouse = true })
hl.bind(key("mouse:273"), hl.dsp.window.resize(), { mouse = true })

-- Workspaces: SUPER+1..0 go there, SUPER+SHIFT+1..0 send the window there
for i = 1, 10 do
    local k = tostring(i % 10)
    hl.bind(key(k),             hl.dsp.focus({ workspace = i }))
    hl.bind(key("SHIFT + " .. k), hl.dsp.window.move({ workspace = i }))
end
hl.bind(key("Tab"),        hl.dsp.focus({ workspace = "previous" }))
hl.bind(key("mouse_down"), hl.dsp.focus({ workspace = "e+1" }))
hl.bind(key("mouse_up"),   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(key("S"),          hl.dsp.workspace.toggle_special("scratch"))
hl.bind(key("SHIFT + S"),  hl.dsp.window.move({ workspace = "special:scratch" }))

-- Screenshots and colour picker
hl.bind("Print",           exec("hyprshot -m region -o ~/Pictures/Screenshots"))
hl.bind("SHIFT + Print",   exec([[grim -g "$(slurp)" - | satty --filename -]]))
hl.bind(key("SHIFT + C"),  exec("hyprpicker -a"))

-- Shared Acer: hand it to the work PC and back (~/.local/bin/monswitch)
hl.bind(key("M"),          exec("monswitch toggle"))

-- Session
hl.bind(key("L"),          exec("loginctl lock-session"))
hl.bind(key("SHIFT + R"),  exec("hyprctl reload"))
hl.bind(key("SHIFT + E"),  exec("hyprshutdown"))

-- Media, volume and brightness keys (laptop and Keychron)
local held = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), held)
hl.bind("XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      held)
hl.bind("XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   exec("brightnessctl -e4 -n2 set 5%+"),                  held)
hl.bind("XF86MonBrightnessDown", exec("brightnessctl -e4 -n2 set 5%-"),                  held)
hl.bind("XF86AudioNext",         exec("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",         exec("playerctl previous"),   { locked = true })
hl.bind("XF86AudioPlay",         exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause",        exec("playerctl play-pause"), { locked = true })
