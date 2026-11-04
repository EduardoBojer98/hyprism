import Quickshell
import QtQuick

// A small drawing of one rice for the Settings > Rices gallery: its wallpaper, its bar in its own
// shape and place, a window in its frame and corners, all in its colours. Click to switch.
Item {
    id: card
    required property var rice
    property bool chosen: false
    signal picked()

    readonly property var c: rice.colour
    readonly property var b: rice.bar
    readonly property real s: width / 200                 // drawing scale
    readonly property string wall: Quickshell.env("HOME") + "/.local/share/linux-setup/rices/" + rice.wall + "-v4.png"

    implicitHeight: shot.height + name.implicitHeight + 10

    Rectangle {
        id: shot
        width: parent.width
        height: width * 0.62
        radius: Theme.radiusSmall
        color: card.c.ground
        clip: true
        border { color: card.chosen ? Theme.accent : area.containsMouse ? Theme.strokeStrong : Theme.stroke; width: card.chosen ? 2 : 1 }

        Image { anchors.fill: parent; anchors.margins: 1; source: "file://" + card.wall; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 400 }

        // a window, in the rice's frame and corners
        Rectangle {
            readonly property real pad: 14 * card.s
            x: (card.b.edge === "left" ? 22 : 10) * card.s + (card.b.kind === "rail" && card.b.edge === "left" ? 14 * card.s : 0)
            y: (card.b.edge === "top" || card.b.kind === "letterbox" ? 26 : 12) * card.s
            width: parent.width * 0.62
            height: parent.height * 0.52
            radius: Math.min(card.rice.hypr.rounding, 18) * card.s * 0.6
            color: card.c.surface
            border { color: "#" + card.rice.hypr.active[0].slice(0, 6); width: Math.max(1, card.rice.hypr.border * card.s * 0.6) }
            Column {
                x: 8 * card.s; y: 8 * card.s
                spacing: 4 * card.s
                Repeater { model: [0.7, 0.5, 0.6]; Rectangle { required property real modelData; width: 70 * card.s * modelData; height: 3 * card.s; radius: 1; color: card.c.muted; opacity: 0.6 } }
            }
        }

        // the bar, in the rice's place and shape
        Item {
            anchors.fill: parent
            readonly property real t: Math.max(6, card.b.size * card.s * 0.32)
            Rectangle {   // full-width strips (text, line, menubar, gnome, poster, taskbar, letterbox top)
                visible: ["text", "line", "menubar", "gnome", "poster", "taskbar", "letterbox"].includes(card.b.kind)
                width: parent.width; height: parent.t
                y: card.b.edge === "bottom" ? parent.height - height : 0
                color: card.b.kind === "gnome" || card.b.kind === "letterbox" ? "#000000" : card.b.kind === "line" ? card.c.ground : card.c.surface
                Rectangle { visible: card.b.kind === "poster"; width: parent.height; height: parent.height; x: parent.height; color: card.c.accent }
                Rectangle { visible: card.b.kind === "taskbar"; width: parent.height * 0.7; height: width; x: 3; anchors.verticalCenter: parent.verticalCenter; radius: 2; color: card.c.accent }
                Rectangle { visible: ["text", "gnome", "line", "menubar"].includes(card.b.kind); width: 16 * card.s; height: 3 * card.s; x: card.b.kind === "gnome" ? (parent.width - width) / 2 : parent.width - width - 6; anchors.verticalCenter: parent.verticalCenter; color: card.b.kind === "gnome" ? "#ffffff" : card.c.accent }
            }
            Rectangle {   // letterbox bottom band
                visible: card.b.kind === "letterbox"
                width: parent.width; height: parent.t; y: parent.height - height; color: "#000000"
            }
            Rectangle {   // side rail
                visible: card.b.kind === "rail"
                width: parent.t * 1.2; height: parent.height
                x: card.b.edge === "right" ? parent.width - width : 0
                color: card.c.text
                Column { anchors.horizontalCenter: parent.horizontalCenter; y: 20 * card.s; spacing: 3 * card.s
                    Repeater { model: 4; Rectangle { required property int index; width: 8 * card.s; height: width; color: index === 1 ? card.c.accent : "transparent"; border { color: card.c.ground; width: 1 } } } }
            }
            Row {   // pebble: three pills
                visible: card.b.kind === "pills"
                y: 4 * card.s; x: 4 * card.s
                width: parent.width - 8 * card.s
                spacing: (width - 3 * 34 * card.s) / 2
                Repeater { model: 3; Rectangle { width: 34 * card.s; height: 9 * card.s; radius: height / 2; color: card.c.surface; opacity: 0.92 } }
            }
            Rectangle {   // island, halo: one bottom capsule
                visible: card.b.kind === "island" || card.b.kind === "halo"
                width: (card.b.kind === "island" ? 110 : 54) * card.s; height: (card.b.kind === "island" ? 13 : 9) * card.s
                radius: height / 2
                x: (parent.width - width) / 2; y: parent.height - height - 4 * card.s
                color: card.b.kind === "island" ? card.c.accent2 : card.c.surface
            }
            Text {   // zen: the time in the corner
                visible: card.b.kind === "corner"
                anchors { right: parent.right; bottom: parent.bottom; margins: 6 * card.s }
                text: "17:42"; color: card.c.muted
                font { family: card.rice.font.ui; pixelSize: 9 * card.s }
            }
            Item {   // console: a readout line and corner brackets
                visible: card.b.kind === "readout"
                anchors.fill: parent
                Rectangle { width: 70 * card.s; height: 2 * card.s; x: (parent.width - width) / 2; y: 4 * card.s; color: card.c.accent }
                Repeater {
                    model: [[0, 0], [1, 0], [0, 1], [1, 1]]
                    Item {
                        required property var modelData
                        width: 12 * card.s; height: width
                        x: modelData[0] ? parent.width - width - 4 : 4; y: modelData[1] ? parent.height - height - 4 : 10 * card.s
                        Rectangle { width: parent.width; height: 1; color: card.c.accent; y: parent.modelData[1] ? parent.height - 1 : 0 }
                        Rectangle { width: 1; height: parent.height; color: card.c.accent; x: parent.modelData[0] ? parent.width - 1 : 0 }
                    }
                }
            }
        }

        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.picked() }
    }
    Text {
        id: name
        anchors { top: shot.bottom; topMargin: 6; left: parent.left }
        text: card.rice.name
        color: card.chosen ? Theme.accent : Theme.text
        font { family: card.rice.font.ui; pixelSize: Theme.fontSize; weight: card.chosen ? Font.DemiBold : Font.Medium }
    }
}
