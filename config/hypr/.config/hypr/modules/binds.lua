-- Keybinds. SUPER is the main key; SHIFT means "move" or "bigger version".
-- Every bind has an id; Settings > Keyboard Shortcuts changes or turns off binds by id, saved
-- in settings/keybinds.lua as { id = "SUPER + K" } or { id = false }. Hyprland's bind
-- description carries "id|group|label" so the Settings page can list them (hyprctl -j binds).
local mod      = "SUPER"
local terminal = "ghostty +new-window"  -- opens in the running Ghostty (see ghostty/config)
local function key(k) return mod .. " + " .. k end
local exec = hl.dsp.exec_cmd

local ok, overrides = pcall(require, "settings.keybinds")
if not ok or type(overrides) ~= "table" then overrides = {} end
-- Settings writes settings/apps.lua (terminal command); the value is only accepted if it is plain text.
local aok, apps = pcall(require, "settings.apps")
if aok and type(apps) == "table" and type(apps.terminal) == "string" and apps.terminal:match("^[%w +._/-]+$") then terminal = apps.terminal end

-- Hardware binds exist only where the hardware does. `v` is what hardware.toml says (a name, true/false);
-- nil means it was never detected, so keep the bind (an install without hardware.toml loses nothing).
local function has(v)
    if v == nil then return true end
    return v ~= "" and v ~= false
end
local function file_exists(path)
    local f = io.open(path)
    if f then f:close() end
    return f ~= nil
end
local config = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")

local binds = {}
-- fixed = not editable in Settings (mouse, hardware switches)
local function add(id, group, label, keys, run, opts) binds[#binds + 1] = { id = id, group = group, label = label, keys = keys, run = run, opts = opts } end

-- Apps
add("terminal",  "Apps", "Terminal",                     key("Return"), exec(terminal))
add("dropterm",  "Apps", "Drop-down terminal",           key("grave"), exec("dropterm"))
-- Spotlight at the cursor: tap Super alone (fires on release, only if no other key was pressed)
add("spotlight-tap", "Apps", "Spotlight (tap Super)",    "SUPER + Super_L", exec("qs ipc call launcher toggle"), { release = true })
add("spotlight", "Apps", "Spotlight",                    key("Space"), exec("qs ipc call launcher toggle"))
add("files-app", "Apps", "File manager",                 key("E"), exec("gtk-launch \"$(xdg-mime query default inode/directory)\""))  -- Settings > Default Apps
add("settings",  "Apps", "Settings",                     key("I"), exec("qs ipc call settings toggle"))
add("browser",   "Apps", "Web browser",                  key("B"), exec("gtk-launch \"$(xdg-settings get default-web-browser)\""))  -- Settings > Default Apps
add("clipboard", "Apps", "Clipboard history",            key("V"), exec("qs ipc call clipboard toggle"))
add("emoji",     "Apps", "Emoji picker",                 key("period"), exec("emojipick"))
add("find-files","Apps", "Spotlight: files",             key("SHIFT + Space"), exec("qs ipc call launcher files"))
add("all-apps",  "Apps", "All applications",             key("A"), exec("qs ipc call launcher apps"))
add("control-center", "Apps", "Control Center",          key("C"), exec("qs ipc call controlcenter toggle"))
add("notifications", "Apps", "Notification centre",       key("N"), exec("qs ipc call notifications toggle"))
add("dnd",           "Apps", "Do Not Disturb on / off",   key("SHIFT + N"), exec("qs ipc call notifications dnd"))
add("overview",      "Windows", "Mission Control",          key("W"), exec("qs ipc call overview toggle"))
add("cheatsheet",    "Apps", "Keyboard shortcuts (this list)", key("slash"), exec("qs ipc call cheatsheet toggle"))
add("layout-next",   "Keyboard", "Next keyboard layout",      key("CTRL + Space"), exec("hyprctl switchxkblayout all next"))

-- Windows
add("close",      "Windows", "Close window",             key("Q"), hl.dsp.window.close())
add("fullscreen", "Windows", "Fullscreen",               key("F"), hl.dsp.window.fullscreen({ action = "toggle" }))
add("maximise",   "Windows", "Maximise",                 key("SHIFT + F"), hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }))
add("float",      "Windows", "Float / tile",             key("T"), function() float_toggle() end)   -- windows.lua: back where it floated
add("split",      "Windows", "Swap split direction",     key("J"), hl.dsp.layout("togglesplit"))
add("minimise",   "Windows", "Minimise (restore from the dock)", key("H"), hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
add("window-menu", "Windows", "Window menu: snap, move, opacity", key("Z"), exec("qs ipc call windowmenu open"))
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
-- Caps Lock and Num Lock: Hyprland tells the shell when the key is let go, and the shell reads the new state
-- for its pop-up and the bar (the keys still work as usual). Once a lock is on, its own modifier (CAPS / MOD2)
-- is held on the release too, so each key has a bind with and without it.
add("caps-osd",    "Keyboard", "Caps Lock note",       "Caps_Lock",        exec("qs ipc call keyboard locks"), { release = true, non_consuming = true, fixed = true })
add("caps-osd-on", "Keyboard", "Caps Lock note (on)",  "CAPS + Caps_Lock", exec("qs ipc call keyboard locks"), { release = true, non_consuming = true, fixed = true })
add("num-osd",     "Keyboard", "Num Lock note",        "Num_Lock",         exec("qs ipc call keyboard locks"), { release = true, non_consuming = true, fixed = true })
add("num-osd-on",  "Keyboard", "Num Lock note (on)",   "MOD2 + Num_Lock",  exec("qs ipc call keyboard locks"), { release = true, non_consuming = true, fixed = true })
-- Alt+Tab: hold Alt, Tab through the open windows (most recent first), let go to switch (AltTab.qml)
add("window-switch",      "Windows", "Switch windows (hold Alt)", "ALT + Tab", exec("qs ipc call alttab next"))
add("window-switch-back", "Windows", "Switch windows backwards",  "ALT + SHIFT + Tab", exec("qs ipc call alttab prev"))
add("workspace-empty",    "Workspaces", "Next empty workspace",      key("CTRL + down"), hl.dsp.focus({ workspace = "empty" }))
add("workspace-next-wheel", "Workspaces", "Next workspace (wheel)",  key("mouse_down"), hl.dsp.focus({ workspace = "e+1" }), { fixed = true })
add("workspace-prev-wheel", "Workspaces", "Previous workspace (wheel)", key("mouse_up"), hl.dsp.focus({ workspace = "e-1" }), { fixed = true })
add("scratchpad",      "Workspaces", "Show / hide scratchpad",       key("S"), hl.dsp.workspace.toggle_special("scratch"))
add("send-scratchpad", "Workspaces", "Send window to scratchpad",    key("ALT + S"), hl.dsp.window.move({ workspace = "special:scratch" }))

-- Screenshots (~/.local/bin/screenshot: grim + slurp, edited in Satty) and colour picker.
-- In the editor: Enter copies and saves, Ctrl+S saves, Esc cancels.
-- The screen freezes while you pick: drag an area or click a window. What happens next (annotate, copy, save) is
-- Settings > Screenshots (Config.capture).
add("screenshot",          "Screen", "Screenshot: drag an area or click a window", "ALT + SHIFT + S", exec("screenshot"))
add("capture-bar",         "Screen", "Capture bar: area, window, screen, delay, record", "Print", exec("qs ipc call capture toggle"))
add("screenshot-copy",     "Screen", "Screenshot an area, copy only", "CTRL + Print", exec("screenshot area --copy"))
add("screenshot-screen",   "Screen", "Screenshot this screen", "SHIFT + Print", exec("screenshot screen"))
add("screenshot-window",   "Screen", "Screenshot a window (click it)", key("Print"), exec("screenshot window"))
add("screenshot-all",      "Screen", "Screenshot both screens", "CTRL + SHIFT + Print", exec("screenshot all"))
add("screenshot-delay",    "Screen", "Screenshot in 5 seconds", "ALT + Print", exec("screenshot delay 5"))
add("screenshot-pin",      "Screen", "Pin an area of the screen on top", key("CTRL + S"), exec("screenshot pin"))
add("task-manager",       "Apps",   "Task manager",                 "CTRL + SHIFT + Escape", exec("qs ipc call system taskmanager"))
add("ocr",                 "Screen", "Copy text from the screen",    key("SHIFT + T"), exec("screentext"))
add("record",              "Screen", "Record the screen (again: stop)", key("ALT + R"), exec("record screen"))
add("record-area",         "Screen", "Record an area (again: stop)", key("ALT + SHIFT + R"), exec("record area"))
add("colour-picker",       "Screen", "Colour picker",                key("SHIFT + C"), exec("hyprpicker -a"))
add("displays-switch",    "Screen", "Display switcher: extend, mirror, one screen, presets", key("P"), exec("qs ipc call displays switcher"))

-- Shared monitor: hand it to the other computer and back (~/.local/bin/monswitch; off without ~/.config/monswitch.conf)
if file_exists(config .. "/monswitch.conf") then
    add("monitor-switch", "Screen", "Hand the shared monitor over and back", key("M"), exec("monswitch toggle"))
end

-- Lid (~/.local/bin/panel); a convertible's tablet-mode switch is bound by the tablet module (modules/tablet)
add("lid-close",  "Hardware", "Lid closed",      "switch:on:Lid Switch",                  exec("panel lid close"),  { locked = true, fixed = true })
add("lid-open",   "Hardware", "Lid opened",      "switch:off:Lid Switch",                 exec("panel lid open"),   { locked = true, fixed = true })
if has(HW.power.profiles) then
    add("power-mode", "Hardware", "Next power mode (Quiet, Balanced, Performance)", key("F5"), exec("powermode next"))
end

-- Keyboard access to the bar (Quickshell BarFocus)
add("focus-bar", "Desktop", "Move the keyboard to the bar (arrows, Enter, Esc)", key("F6"), exec("qs ipc call bar focus"))
add("focus-dock", "Desktop", "Move the keyboard to the dock (arrows, Enter, menu key, Esc)", key("SHIFT + F6"), exec("qs ipc call dock focus"))

-- Session
add("lock",  "Session", "Lock the screen",  key("L"), exec("loginctl lock-session"))
add("reload", "Session", "Reload Hyprland",  key("SHIFT + R"), exec("hyprctl reload"))
add("logout", "Session", "Log out",          key("SHIFT + E"), exec("hyprshutdown"))

-- Media, volume and brightness keys (laptop and Keychron)
local held = { locked = true, repeating = true }
local osd = " && qs ipc call osd brightness $(brightnessctl -m | cut -d, -f4 | tr -d %)"
add("volume-up",       "Media", "Volume up",       "XF86AudioRaiseVolume",  exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), held)
add("volume-down",     "Media", "Volume down",     "XF86AudioLowerVolume",  exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      held)
add("mute",            "Media", "Mute",            "XF86AudioMute",         exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
add("mic-mute",        "Media", "Mute microphone", "XF86AudioMicMute",      exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
if has(HW.power.backlight) then
    add("brightness-up",   "Media", "Brightness up",   "XF86MonBrightnessUp",   exec("brightnessctl -e4 -n2 set 5%+" .. osd),           held)
    add("brightness-down", "Media", "Brightness down", "XF86MonBrightnessDown", exec("brightnessctl -e4 -n2 set 5%-" .. osd),           held)
end
-- Keyboard backlight: needs the device name, so only when it was detected
local kbd = HW.power.kbd_backlight
if type(kbd) == "string" and kbd:match("^[%w:._-]+$") then
    add("kbd-brightness-up",   "Media", "Keyboard backlight up",   "XF86KbdBrightnessUp",   exec("brightnessctl -d " .. kbd .. " set +1"), held)
    add("kbd-brightness-down", "Media", "Keyboard backlight down", "XF86KbdBrightnessDown", exec("brightnessctl -d " .. kbd .. " set 1-"), held)
end
add("next",            "Media", "Next track",      "XF86AudioNext",         exec("playerctl next"),       { locked = true })
add("previous",        "Media", "Previous track",  "XF86AudioPrev",         exec("playerctl previous"),   { locked = true })
add("play",            "Media", "Play / pause",    "XF86AudioPlay",         exec("playerctl play-pause"), { locked = true })
add("pause",           "Media", "Play / pause (pause key)", "XF86AudioPause", exec("playerctl play-pause"), { locked = true })

-- Your shortcuts (Settings > Keyboard Shortcuts > Add shortcut): each runs an action from the shell's registry.
-- Keys and the action id are plain text only (the same check as the terminal command above).
if type(overrides.custom) == "table" then
    for i, c in ipairs(overrides.custom) do
        if type(c) == "table" and type(c.keys) == "string" and c.keys:match("^[%w_+: ]+$")
            and type(c.action) == "string" and c.action:match("^[%w-]+$") then
            local name = type(c.name) == "string" and (c.name:gsub("|", "")) or c.action
            add("custom-" .. i, "Custom", name, c.keys, exec("qs ipc call actions run " .. c.action))
        end
    end
end

-- Shortcuts apps ask for through the GlobalShortcuts portal (xdg-desktop-portal-hyprland registers them; hyprctl
-- globalshortcuts lists them as "appid:id"). Settings > Keyboard Shortcuts > From apps gives them keys; the bind
-- hands press and release to the app. Plain text only, like your shortcuts.
if type(overrides.portal) == "table" then
    for i, c in ipairs(overrides.portal) do
        if type(c) == "table" and type(c.keys) == "string" and c.keys:match("^[%w_+: ]+$")
            and type(c.name) == "string" and c.name:match("^[%w._:+@ -]+$") and c.name:find(":") then
            local label = type(c.label) == "string" and (c.label:gsub("|", "")) or c.name
            add("portal-" .. i, "From apps", label, c.keys, hl.dsp.global(c.name))
        end
    end
end

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
