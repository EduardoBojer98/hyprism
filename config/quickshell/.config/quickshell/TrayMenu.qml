import Quickshell
import QtQuick
import QtQuick.Layouts

// A tray app's menu drawn in the shell's own style instead of the toolkit's: the theme's surface, depth,
// decor and motion, like every panel. Submenus open in place with a "Back" row. Keyboard: Up / Down /
// Home / End, Enter picks, Right opens a submenu, Left or Escape goes back, Escape at the top closes.
// Closes on a click outside or after picking an item.
//   TrayMenu { id: m; anchorItem: someBarItem; menu: trayItem.menu }   m.open = true
PopupWindow {
    id: root

    property Item anchorItem
    property var menu
    property bool open: false
    property var stack: []          // submenu entries opened so far, innermost last

    readonly property int room: depthUnder.room   // around the box, so the theme's shadow isn't cut off
    readonly property int gap: 6
    anchor.item: anchorItem
    // open away from the bar: below a top bar, above a bottom one, beside a rail (the box sits `gap` off the item)
    readonly property int away: ({ top: Edges.Bottom, bottom: Edges.Top, left: Edges.Right, right: Edges.Left })[Theme.barEdge] ?? Edges.Bottom
    anchor.edges: away
    anchor.gravity: away
    anchor.rect.width: anchorItem?.width ?? 0
    anchor.rect.height: anchorItem?.height ?? 0
    anchor.rect.x: away === Edges.Right ? gap - room : away === Edges.Left ? room - gap : 0
    anchor.rect.y: away === Edges.Bottom ? gap - room : away === Edges.Top ? room - gap : 0
    grabFocus: true
    visible: open || box.opacity > 0   // stays up while it fades out
    implicitWidth: 236 + room * 2
    implicitHeight: Math.min(list.implicitHeight + Theme.spaceXs * 2, 560) + room * 2
    color: "transparent"
    onVisibleChanged: if (!visible) { open = false; stack = [] }
    onOpenChanged: if (open) list.forceActiveFocus()
    onStackChanged: if (open) list.forceActiveFocus()

    QsMenuOpener { id: opener; menu: root.stack.length ? root.stack[root.stack.length - 1] : root.menu }

    function back() { if (stack.length) stack = stack.slice(0, -1); else open = false }

    Rectangle {
        id: box
        anchors { fill: parent; margins: root.room }
        radius: Theme.radius
        color: Theme.menu
        border { color: Theme.stroke; width: Theme.line }
        opacity: root.open ? 1 : 0
        // out of the bar's side, the theme's way (CursorPopup has the same motion)
        property real off: root.open ? 0 : Theme.travel
        transform: Translate {
            x: Theme.barEdge === "left" ? -box.off : Theme.barEdge === "right" ? box.off : 0
            y: Theme.barEdge === "top" ? -box.off : Theme.barEdge === "bottom" ? box.off : 0
        }
        Behavior on off { NumberAnimation { duration: root.open ? Theme.enter : Theme.exit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
        Behavior on opacity { NumberAnimation { duration: root.open ? Theme.enter : Theme.exit; easing.type: Easing.OutCubic } }

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
                Keys.onEscapePressed: root.back()
                Keys.onLeftPressed: if (root.stack.length) root.back()

                MenuRow {
                    visible: root.stack.length > 0
                    label: "Back"
                    glyph: "\u{F0141}"
                    onClicked: root.back()
                }
                Repeater {
                    model: opener.children
                    Loader {
                        required property QsMenuEntry modelData
                        Layout.fillWidth: true
                        sourceComponent: modelData.isSeparator ? separator : entry
                        Component {
                            id: separator
                            Item { implicitHeight: Theme.spaceS + 1; Rectangle { anchors.centerIn: parent; width: parent.width - Theme.spaceL; height: 1; color: Theme.stroke } }
                        }
                        Component {
                            id: entry
                            MenuRow {
                                readonly property QsMenuEntry e: modelData
                                label: e.text.replace(/_(?=\w)/, "")   // drop GTK mnemonic underscores
                                iconSource: e.icon
                                enabled: e.enabled
                                checked: e.buttonType !== QsMenuButtonType.None && e.checkState === Qt.Checked
                                more: e.hasChildren
                                Keys.onRightPressed: if (more) clicked()
                                onClicked: {
                                    if (e.hasChildren) { root.stack = root.stack.concat([e]); return }
                                    e.triggered()
                                    root.open = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
