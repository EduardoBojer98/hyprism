import QtQuick

// A glass surface: translucent graphite (or white) tint, hairline stroke and a faint top-lit rim.
// Hyprland's layer blur (hypr/modules/rules.lua) provides the frosted background.
// neon: the hairline becomes a glowing accent gradient (NeonEdge). Panels (strong) turn it on with
// Settings > Appearance > Neon edges; bar, dock and launcher with their "Neon" colour.
Rectangle {
    property bool strong: false
    property bool flat: false      // a tile on another glass panel: plain fill, no rim or edge
    property bool neon: strong && Config.appearance.neonPanels

    radius: Theme.radius
    color: flat ? Theme.fill : strong ? Theme.glassStrong : Theme.glass
    border { color: Theme.stroke; width: flat || neon ? 0 : 1 }

    NeonEdge { visible: parent.neon && !parent.flat; radius: parent.radius }

    Rectangle {
        visible: !parent.flat
        anchors { fill: parent; margins: 1 }
        radius: parent.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.highlight }
            GradientStop { position: 0.35; color: "transparent" }
        }
    }
}
