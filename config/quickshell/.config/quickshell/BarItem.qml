import QtQuick

// One clickable bar item in any rice: its content in a row (or a column on a vertical rail), a
// hover highlight in the rice's corner radius, brighter while its panel is open.
Rectangle {
    id: item
    default property alias content: grid.data
    property alias spacing: grid.spacing
    property bool vertical: false
    property bool active: false
    property bool interactive: true
    property bool shown: true          // false: nothing to show, the bar leaves no gap
    property int pad: vertical ? 6 : 8
    property color hover: Theme.fillHover
    property color pressedColor: Theme.fillActive
    property alias acceptedButtons: area.acceptedButtons
    signal pressed(int button)
    signal scrolled(int delta)

    visible: shown
    implicitWidth: vertical ? Math.max(grid.implicitWidth + pad * 2, 28) : grid.implicitWidth + pad * 2
    implicitHeight: vertical ? grid.implicitHeight + pad * 2 : Math.max(grid.implicitHeight + 6, 24)
    radius: Theme.radiusSmall
    color: active ? pressedColor : interactive && area.containsMouse ? hover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Grid {
        id: grid
        anchors.centerIn: parent
        rows: item.vertical ? -1 : 1
        columns: item.vertical ? 1 : -1
        spacing: 6
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
    }
    MouseArea {
        id: area
        anchors.fill: parent
        z: -1
        enabled: item.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: mouse => item.pressed(mouse.button)
        onWheel: wheel => item.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
