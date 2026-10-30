-- ROG Flow X13 + the shared Acer: at login the laptop starts on workspace 1 and the Acer on 2.
hl.workspace_rule({ workspace = "1", monitor = "eDP-1",    default = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", default = true })
