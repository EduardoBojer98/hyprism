import QtQuick

// One clickable bar item in any theme: its content in a row (or a column on a vertical bar), a
// hover highlight in the theme's corner radius, brighter while its panel is open, a small press.
// A click records where it happened (Anchor), so the panel it opens appears beside it.
Rectangle {
    id: item
    default property alias content: grid.data
    property alias spacing: grid.spacing
    property bool vertical: false
    property bool active: false
    property bool interactive: true
    property bool shown: true          // false: nothing to show, the bar leaves no gap
    readonly property bool hovered: area.containsMouse
    property int pad: vertical ? 6 : 8
    property color hover: Qt.alpha(Theme.barInk, Theme.light ? 0.10 : 0.11)
    property color pressedColor: Qt.alpha(Theme.barInk, Theme.light ? 0.16 : 0.17)
    property alias acceptedButtons: area.acceptedButtons
    property string edge: Theme.barEdge     // the screen edge this item sits on (the dock sets its own)
    property var origin: undefined          // its window's top-left on the screen, when not at the edge (Anchor)
    signal pressed(int button)
    signal scrolled(int delta)

    visible: shown
    implicitWidth: vertical ? Math.max(grid.implicitWidth + pad * 2, 28) : grid.implicitWidth + pad * 2
    property real minHeight: 0          // e.g. a block that fills the bar's height
    implicitHeight: vertical ? grid.implicitHeight + pad * 2 : Math.max(grid.implicitHeight + 6, 24, minHeight)
    radius: Theme.radiusSmall
    color: active ? pressedColor : interactive && area.containsMouse ? hover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    scale: area.pressed ? Theme.pressScale : 1
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

    Grid {
        id: grid
        anchors.centerIn: parent
        // one row or one column: only `columns` is set (setting rows too adds spacing for empty rows)
        columns: item.vertical ? 1 : Math.max(1, visibleChildren.length)
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
        onClicked: mouse => { Anchor.take(item, item.edge, item.origin); item.pressed(mouse.button) }
        onWheel: wheel => item.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
