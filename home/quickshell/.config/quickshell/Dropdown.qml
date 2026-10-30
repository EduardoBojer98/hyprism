import Quickshell
import QtQuick

// Button that shows the current value and opens a list of options below it.
Item {
    id: dd

    property var options: []
    property string current
    signal picked(string value)

    implicitWidth: 200
    implicitHeight: 30
    property bool open: false

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: area.containsMouse ? Theme.fillHover : Theme.fill
        border { color: dd.open ? Theme.accent : Theme.stroke; width: 1 }
        Text {
            anchors { left: parent.left; leftMargin: 12; right: chevron.left; verticalCenter: parent.verticalCenter }
            text: dd.current
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: 12 }
        }
        Text {
            id: chevron
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: dd.open ? "\u{F0143}" : "\u{F0140}"
            color: Theme.subtext
            font { family: Theme.iconFont; pixelSize: 14 }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dd.open = !dd.open }
    }

    // A popup so the list floats above the rows below instead of being covered by them
    PopupWindow {
        visible: dd.open
        anchor.item: dd
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 4
        grabFocus: true
        implicitWidth: dd.width
        implicitHeight: Math.min(list.contentHeight + 8, 260)
        color: "transparent"
        onVisibleChanged: if (!visible) dd.open = false

        Rectangle {
            anchors.fill: parent
            radius: Theme.radius
            color: Qt.rgba(0.06, 0.06, 0.09, 0.96)
            border { color: Theme.stroke; width: 1 }

            ListView {
                id: list
                anchors { fill: parent; margins: 4 }
                clip: true
                model: dd.options
                delegate: Rectangle {
                    required property string modelData
                    width: list.width
                    height: 30
                    radius: 8
                    color: optArea.containsMouse ? Theme.fillHover : modelData === dd.current ? Theme.fill : "transparent"
                    Text {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        text: modelData
                        color: modelData === dd.current ? Theme.accent : Theme.text
                        font { family: Theme.font; pixelSize: 12 }
                    }
                    MouseArea {
                        id: optArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { dd.open = false; dd.picked(modelData) }
                    }
                }
            }
        }
    }
}
