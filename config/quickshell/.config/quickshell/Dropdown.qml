import Quickshell
import QtQuick

// Button that shows the current value and opens a list of options below it.
Item {
    id: dd

    property var options: []
    property string current
    // opt-in: a current value outside options is listed too, labelled "(custom)"
    property bool showCustom: false
    readonly property bool isCustom: showCustom && current !== "" && options.indexOf(current) < 0
    signal picked(string value)

    implicitWidth: 200
    implicitHeight: Math.max(28, Theme.hit)
    property bool open: false

    // keyboard: Tab to it, Up / Down picks the one before or after, Space or Enter opens the list
    activeFocusOnTab: true
    function step(d) { const i = options.indexOf(current) + d; if (i >= 0 && i < options.length) picked(options[i]) }
    Keys.onUpPressed: step(-1)
    Keys.onDownPressed: step(1)
    Keys.onSpacePressed: dd.open = !dd.open
    Keys.onReturnPressed: dd.open = !dd.open
    FocusRing { radius: Theme.radiusSmall + 3 }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: area.containsMouse ? Theme.fillHover : Theme.fill
        border { color: dd.open ? Theme.accent : Theme.stroke; width: 1 }
        Text {
            anchors { left: parent.left; leftMargin: 12; right: chevron.left; verticalCenter: parent.verticalCenter }
            text: dd.isCustom ? dd.current + " (custom)" : dd.current
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel }
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
            // drops out of the field, the theme's way, never more than a few px
            transform: Translate { y: dd.open ? 0 : -Math.min(6, Theme.travel); Behavior on y { NumberAnimation { duration: dd.open ? Theme.enter : Theme.exit; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: dd.open ? Theme.enter : Theme.exit; easing.type: Easing.OutCubic } }
            border { color: Theme.stroke; width: Theme.line }

            ListView {
                id: list
                anchors { fill: parent; margins: 4 }
                clip: true
                model: dd.isCustom ? [dd.current].concat(dd.options) : dd.options
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: list.width
                    height: Math.max(26, Theme.fontLabel + 14)   // grows with Settings > Text size
                    radius: Theme.radiusSmall
                    color: optArea.containsMouse ? Theme.accent : "transparent"
                    Text {   // checkmark beside the current value
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        visible: modelData === dd.current
                        text: "\u{F012C}"
                        color: optArea.containsMouse ? Theme.accentText : Theme.text
                        font { family: Theme.iconFont; pixelSize: Theme.fontLabel }
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 8 + Theme.fontLabel + 4; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: dd.isCustom && index === 0 ? modelData + " (custom)" : modelData
                        elide: Text.ElideRight
                        color: optArea.containsMouse ? Theme.accentText : Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontLabel }
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
