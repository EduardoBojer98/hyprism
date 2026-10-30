# Per-machine overrides

`hyprland.lua` loads `hosts/<hostname>.lua` last, if it exists (`cat /etc/hostname`).
Use it for things that differ between computers, for example a second PC:

```lua
-- hosts/work-desktop.lua
hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })
```

This laptop has `hosts/rog-flow-x13.lua` (which workspace starts on which screen).
