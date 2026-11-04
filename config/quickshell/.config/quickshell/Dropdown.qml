import Quickshell
import QtQuick

// Button that shows the current value and opens a list of options below it.
Item {
    id: dd

    property var options: []
    property string current
    signal picked(string value)

    implicitWidth: 200
    implicitHeight: 28
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
        Chevron {
            id: chevron
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            open: dd.open
            size: 14
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dd.open = !dd.open }
    }

    // A popup so the list floats above the rows below instead of being covered by them
    PopupWindow {
        visible: dd.open || box.opacity > 0   // stays up while it fades out
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
            id: box
            anchors.fill: parent
            radius: Theme.radius
            color: Theme.menu
            opacity: dd.open ? 1 : 0
            // a plain drop: slides 6px down into place while it fades in
            transform: Translate { y: dd.open ? 0 : -6; Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
            border { color: Theme.stroke; width: 1 }

            ListView {
                id: list
                anchors { fill: parent; margins: 4 }
                clip: true
                model: dd.options
                delegate: Rectangle {
                    required property string modelData
                    width: list.width
                    height: 26
                    radius: 6
                    color: optArea.containsMouse ? Theme.accent : "transparent"
                    Text {   // checkmark beside the current value
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        visible: modelData === dd.current
                        text: "\u2713"
                        color: optArea.containsMouse ? Theme.accentText : Theme.text
                        font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold }
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 24; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: modelData
                        elide: Text.ElideRight
                        color: optArea.containsMouse ? Theme.accentText : Theme.text
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
