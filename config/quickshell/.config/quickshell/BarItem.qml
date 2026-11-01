import QtQuick

// One top-bar item: a soft rounded-rect highlight on hover, brighter while its panel is open.
Rectangle {
    id: pill
    default property alias content: row.data
    property alias spacing: row.spacing
    property bool active: false
    property bool interactive: true
    property bool shown: true     // false: nothing to show, the bar leaves no gap
    visible: shown
    property alias acceptedButtons: area.acceptedButtons
    signal pressed(int button)
    signal scrolled(int delta)

    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: row.implicitWidth + 16
    implicitHeight: Config.bar.size - 8
    radius: 7
    // "chips" (Settings > Appearance > Menu Bar): every item sits on its own glass tile
    readonly property bool chip: Config.bar.items === "chips"
    readonly property color base: chip ? Theme.surface(Config.bar.tint) : "transparent"
    color: active ? (chip ? Qt.tint(base, Theme.fillActive) : Theme.fillActive)
         : interactive && area.containsMouse ? (chip ? Qt.tint(base, Theme.fillHover) : Theme.fillHover) : base
    border { color: Theme.stroke; width: chip ? 1 : 0 }
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
