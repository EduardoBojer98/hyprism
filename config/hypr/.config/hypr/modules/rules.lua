-- Window rules (Hyprland 0.53+ syntax: a name, a match table, then effects).

hl.window_rule({
    name  = "suppress-maximize-events", -- apps can't maximize themselves out of the tiling layout
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "float-small-tools",
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|org.opengamingcollective.rog-control-center)$" },
    float = true,
})

-- Frosted glass behind the Quickshell bar, dock, OSD and notifications
hl.layer_rule({
    name  = "blur-shell",
    match = { namespace = "^qs-.*$" },  -- rules must match the whole name
    blur         = true,
    blur_popups  = true,   -- Control Center and menus are popups of the bar
    ignore_alpha = 0.05,  -- blur even behind the very transparent glass
})

-- Satty, the screenshot editor (~/.local/bin/screenshot): floating, centred, sized to the screen
-- it opens on (its own --resize ignores the laptop's 1.2 scale and overflows), opens instantly.
hl.window_rule({
    name   = "screenshot-editor",
    match  = { class = "^com\\.gabm\\.satty$" },
    float  = true,
    size   = "(monitor_w*0.86) (monitor_h*0.86)",
    center = true,
    no_anim = true,
})

-- Drop-down terminal (~/.local/bin/dropterm, Super+`): its own special workspace, wide and short, at the top
hl.window_rule({
    name      = "dropterm",
    match     = { class = "^linuxsetup\\.dropterm$" },
    workspace = "special:drop",
    float     = true,
    size      = "(monitor_w*0.72) (monitor_h*0.48)",
    move      = "(monitor_w*0.14) (monitor_h*0.06)",
})

hl.window_rule({
    name  = "float-picture-in-picture",
    match = { title = "^Picture-in-Picture$" },
    float = true,
})

hl.window_rule({
    name   = "settings-app",
    match  = { class = "^org\\.quickshell$", title = "^Settings$" },
    float  = true,
    size   = "1020 700",
    center = true,
})

-- JuhRadial MX radial menu (Logitech MX Master): the daemon places it at the cursor itself
hl.window_rule({
    name = "juhradial-overlay",
    match = { title = "^(JuhRadial MX)$" },
    float = true, pin = true, no_blur = true, no_shadow = true, no_anim = true, border_size = 0,
})
