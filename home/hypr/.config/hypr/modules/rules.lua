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
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|com.gabm.satty|org.opengamingcollective.rog-control-center)$" },
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
