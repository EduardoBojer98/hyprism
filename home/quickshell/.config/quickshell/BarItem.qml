import QtQuick

// One top-bar item: a rounded highlight on hover, brighter while its panel is open.
Rectangle {
    id: pill
    default property alias content: row.data
    property alias spacing: row.spacing
    property bool active: false
    property bool interactive: true
    property alias acceptedButtons: area.acceptedButtons
    signal pressed(int button)
    signal scrolled(int delta)

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 18
    implicitHeight: 26
    radius: 13
    color: active ? Theme.fillActive : interactive && area.containsMouse ? Theme.fillHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Row {
        id: row
        anchors.centerIn: parent
        height: parent.height
        spacing: 6
    }
    MouseArea {
        id: area
        anchors.fill: parent
        z: -1
        enabled: pill.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => pill.pressed(mouse.button)
        onWheel: wheel => pill.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
