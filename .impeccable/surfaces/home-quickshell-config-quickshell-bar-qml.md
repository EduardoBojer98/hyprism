---
version: 1
slug: "home-quickshell-config-quickshell-bar-qml"
primary_target: "home/quickshell/.config/quickshell/Bar.qml"
related_targets: []
---

# Surface: top bar (Quickshell Bar.qml)

Scope: the always-visible top bar on both screens of the Hyprland desktop. Mode: operate.
Audience/job: Eduardo glancing at system state while coding and browsing on laptop + 32" Acer.
Must show: workspaces, focused app, weather (user-set city, Open-Meteo), clock + date, CPU and GPU (iGPU)
temperatures, tray, status (Wi-Fi, Bluetooth, volume, battery) that opens the Control Center, power menu.
Constraints: light on battery (sysfs reads every few seconds, weather every 15 min), 11 px text floor.
Open: weather city is set in the future Settings app; until then a default city.

## Direction contract

THESIS: The bar is a row of separate floating glass complications, each a self-contained live readout; it refuses the single edge-to-edge strip of identical icon+text modules.
OWN-WORLD: Dark frosted capsules (near-black tint over Hyprland blur, hairline white stroke, soft top highlight, soft offset shadow) floating 10 px below the edge with gaps showing wallpaper between them. Inter, tabular figures. White ink; Macchiato blue only for the active workspace and an open module; amber/red only when a value leaves normal range (hot CPU/GPU, low battery, no network). Ring gauges carry real values.
STORY: At a glance he sees where he is (workspace, app), the time, the weather, whether the machine runs hot, and connectivity/battery; one click on the status capsule opens the Control Center.
FIRST VIEWPORT: Left: workspaces capsule, focused-app capsule, weather capsule. Centre: clock capsule, the largest type. Right: temps capsule (two rings + values), tray capsule, status capsule, power. Raises: blue only for active/open; colour only off-normal; tabular figures; rank by size and weight.
FORM: Glass Complications, candidate 3 of 7 on the ordered list, seed:17681ba325125157
FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
