import QtQuick

// A panel surface in the active rice's material (Theme.material):
//   solid  a flat tone step with the rice's border (most rices)
//   glass  translucent over Hyprland's blur, with a faint top rim (Pebble, Glass)
// The name is historical; every surface in the shell is one of these.
Rectangle {
    id: surface
    property bool strong: false    // panels with text: more opaque glass
    property bool flat: false      // a tile on another panel: plain fill, no edge

    radius: Theme.radius
    color: flat ? Theme.fill : strong ? Theme.glassStrong : Theme.glass
    border { color: Theme.stroke; width: flat ? 0 : Theme.line }

    Rectangle {   // glass: faint light rim at the top
        visible: Theme.glassy && !surface.flat
        anchors { fill: parent; margins: 1 }
        radius: Math.max(0, parent.radius - 1)
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.highlight }
            GradientStop { position: 0.35; color: "transparent" }
        }
    }
}
