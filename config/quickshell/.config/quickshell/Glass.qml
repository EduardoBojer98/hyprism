import QtQuick

// A panel surface in the active theme's material (Theme.material):
//   solid  a flat tone step with the theme's border (most themes)
//   glass  translucent over Hyprland's blur, with a faint top rim (Pebble, Glass)
// The name is historical; every surface in the shell is one of these.
Rectangle {
    id: surface
    property bool strong: false    // panels with text: more opaque glass
    property bool flat: false      // a tile on another panel: plain fill, no edge

    radius: Theme.radius
    color: flat ? Theme.fill : strong ? Theme.glassStrong : Theme.glass
    border { color: Theme.stroke; width: flat ? 0 : Theme.line }

    // glass: light catches the top edge (a sheen fading down) and the rim (a hairline brighter at the top)
    Rectangle {
        visible: Theme.glassy && !surface.flat
        anchors { fill: parent; margins: 1 }
        radius: Math.max(0, parent.radius - 1)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, Theme.light ? 0.30 : 0.075) }
            GradientStop { position: 0.45; color: "transparent" }
        }
    }
    Rectangle {
        visible: Theme.glassy && !surface.flat
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border { width: 1; color: Qt.rgba(1, 1, 1, Theme.light ? 0.5 : 0.10) }
    }
}
