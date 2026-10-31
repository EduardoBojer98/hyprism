import QtQuick

// A glass surface: translucent graphite (or white) tint, hairline stroke and a faint top-lit rim.
// Hyprland's layer blur (hypr/modules/rules.lua) provides the frosted background.
Rectangle {
    property bool strong: false
    property bool flat: false      // a tile on another glass panel: plain fill, no rim or edge

    radius: Theme.radius
    color: flat ? Theme.fill : strong ? Theme.glassStrong : Theme.glass
    border { color: Theme.stroke; width: flat ? 0 : 1 }

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
