import QtQuick

// A liquid-glass surface: translucent dark tint, hairline stroke and a top-lit highlight.
// Hyprland's layer blur (hypr/modules/rules.lua) provides the frosted background.
Rectangle {
    property bool strong: false

    radius: Theme.radius
    color: strong ? Theme.glassStrong : Theme.glass
    border { color: Theme.stroke; width: 1 }

    Rectangle {
        anchors { fill: parent; margins: 1 }
        radius: parent.radius - 1
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.highlight }
            GradientStop { position: 0.5; color: "transparent" }
        }
    }
}
