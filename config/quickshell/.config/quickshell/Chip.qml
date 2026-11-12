import QtQuick

// A clickable item in the bar: Nerd Font icon plus optional label.
Rectangle {
    id: chip

    property string icon
    property string label
    property color iconColor: Theme.text
    property bool active: false
    readonly property alias hovered: mouse.containsMouse
    signal clicked()
    signal scrolled(int delta)

    activeFocusOnTab: true
    Keys.onSpacePressed: chip.clicked()
    Keys.onReturnPressed: chip.clicked()
    FocusRing {}

    property string accessibleName: ""
    Accessible.role: Accessible.Button
    Accessible.name: chip.accessibleName !== "" ? chip.accessibleName : chip.label
    Accessible.focusable: true
    Accessible.onPressAction: chip.clicked()

    implicitWidth: row.implicitWidth + 18
    implicitHeight: Math.max(26, Theme.hit)
    radius: height / 2
    color: active ? Theme.fillActive : mouse.containsMouse ? Theme.fillHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.spaceXs + 2

        Text {
            visible: chip.icon !== ""
            text: chip.icon
            color: chip.iconColor
            font { family: Theme.iconFont; pixelSize: Theme.iconSmall - 1 }
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: chip.label !== ""
            text: chip.label
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
        onWheel: wheel => chip.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
