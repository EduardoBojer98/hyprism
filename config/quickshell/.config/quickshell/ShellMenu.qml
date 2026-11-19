import Quickshell
import QtQuick
import QtQuick.Layouts

// A menu of the shell's own, in TrayMenu's look: rows of { label, glyph, run, sep (a line above), danger }.
// Opens away from the bar beside `anchorItem`, or at `at` (a point in anchorItem) for a right-click on empty space.
// Keyboard: Up / Down, Enter picks, Escape closes; a click outside closes it.
//   ShellMenu { id: m; anchorItem: someItem; rows: [...] }   m.open = true
PopupWindow {
    id: root

    property Item anchorItem
    property var rows: []
    property var at: null           // { x, y } in anchorItem, or null: the whole item
    property bool open: false

    readonly property int room: depthUnder.room
    readonly property int gap: 6
    anchor.item: anchorItem
    readonly property int away: ({ top: Edges.Bottom, bottom: Edges.Top, left: Edges.Right, right: Edges.Left })[Theme.barEdge] ?? Edges.Bottom
    readonly property bool across: away === Edges.Bottom || away === Edges.Top
    anchor.edges: away
    anchor.gravity: away
    anchor.rect.width: at && across ? 1 : anchorItem?.width ?? 0
    anchor.rect.height: at && !across ? 1 : anchorItem?.height ?? 0
    anchor.rect.x: away === Edges.Right ? gap - room : away === Edges.Left ? room - gap : at ? at.x : 0
    anchor.rect.y: away === Edges.Bottom ? gap - room : away === Edges.Top ? room - gap : at ? at.y : 0
    grabFocus: true
    visible: open || box.opacity > 0
    implicitWidth: 236 + room * 2
    implicitHeight: Math.min(list.implicitHeight + Theme.spaceXs * 2, 560) + room * 2
    color: "transparent"
    onVisibleChanged: if (!visible) open = false
    onOpenChanged: if (open) list.forceActiveFocus()

    Rectangle {
        id: box
        anchors { fill: parent; margins: root.room }
        radius: Theme.radius
        color: Theme.menu
        border { color: Theme.stroke; width: Theme.line }
        opacity: root.open ? 1 : 0
        property real off: root.open ? 0 : Theme.travel
        transform: Translate {
            x: Theme.barEdge === "left" ? -box.off : Theme.barEdge === "right" ? box.off : 0
            y: Theme.barEdge === "top" ? -box.off : Theme.barEdge === "bottom" ? box.off : 0
        }
        Behavior on off { NumberAnimation { duration: root.open ? Theme.enter : Theme.exit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
        Behavior on opacity { NumberAnimation { duration: root.open ? Theme.enter : Theme.exit; easing.type: Theme.easing } }

        PopupDepth { id: depthUnder; anchors.fill: parent; z: -1; radius: box.radius }
        PopupDepth { anchors.fill: parent; z: 10; over: true }

        Flickable {
            anchors { fill: parent; margins: Theme.spaceXs }
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            MenuList {
                id: list
                width: parent.width
                Keys.onEscapePressed: root.open = false
                Repeater {
                    model: root.rows
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 0
                        readonly property Item item: row   // MenuList finds the row through this, for the keys
                        Item {
                            visible: modelData.sep === true
                            Layout.fillWidth: true
                            implicitHeight: Theme.spaceS + 1
                            Rectangle { anchors.centerIn: parent; width: parent.width - Theme.spaceL; height: 1; color: Theme.stroke }
                        }
                        MenuRow {
                            id: row
                            Layout.fillWidth: true
                            label: modelData.label
                            glyph: modelData.glyph ?? ""
                            iconSource: modelData.icon ?? ""
                            checked: modelData.checked === true
                            danger: modelData.danger === true
                            onClicked: { root.open = false; modelData.run() }
                        }
                    }
                }
            }
        }
    }
}
