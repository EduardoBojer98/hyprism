import Quickshell
import QtQuick

// Small glass tooltip under its parent while `shown`. It is its own popup window, so nothing else
// on the page can draw over it, and it never takes the mouse (so it can't steal the hover).
Item {
    id: host

    property bool shown: false
    property alias text: label.text
    property int gap: Theme.spaceXs + 2   // space under the parent; negative overlaps it

    anchors.fill: parent

    PopupWindow {
        anchor.item: host
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: host.gap
        implicitWidth: box.width
        implicitHeight: box.height
        visible: box.opacity > 0
        color: "transparent"
        mask: Region {}

        Rectangle {
            id: box
            width: label.implicitWidth + Theme.spaceM * 2
            height: label.implicitHeight + Theme.spaceS
            radius: Theme.radiusSmall / 1.5
            color: Theme.menu   // solid, so it reads over whatever is under it
            border { color: Theme.stroke; width: 1 }
            opacity: host.shown && host.text !== "" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

            Text {
                id: label
                anchors.centerIn: parent
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
        }
    }
}
