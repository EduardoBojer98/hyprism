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
    match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|com.gabm.satty)$" },
    float = true,
})

hl.window_rule({
    name  = "float-picture-in-picture",
    match = { title = "^Picture-in-Picture$" },
    float = true,
})
