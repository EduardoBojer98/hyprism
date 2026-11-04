import Quickshell
import Quickshell.Widgets
import QtQuick

// A tray app's menu drawn in the shell's own style instead of the toolkit's. Submenus open in place
// with a "‹ Back" row. Closes on a click outside or after picking an item.
//   TrayMenu { id: m; anchorItem: someBarItem; menu: trayItem.menu }   m.open = true
PopupWindow {
    id: root

    property Item anchorItem
    property var menu
    property bool open: false
    property var stack: []          // submenu entries opened so far, innermost last

    anchor.item: anchorItem
    // open away from the bar: below a top bar, above a bottom one, beside a rail
    readonly property int away: ({ top: Edges.Bottom, bottom: Edges.Top, left: Edges.Right, right: Edges.Left })[Theme.barEdge] ?? Edges.Bottom
    anchor.edges: away
    anchor.gravity: away
    anchor.margins.top: Theme.barEdge === "top" ? 6 : 0
    grabFocus: true
    visible: open || box.opacity > 0   // stays up while it fades out
    implicitWidth: 236
    implicitHeight: Math.min(col.implicitHeight + 10, 560)
    color: "transparent"
    onVisibleChanged: if (!visible) { open = false; stack = [] }

    QsMenuOpener { id: opener; menu: root.stack.length ? root.stack[root.stack.length - 1] : root.menu }

    Rectangle {
        id: box
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.menu
        opacity: root.open ? 1 : 0
        // out of the bar's side, the theme's way (CursorPopup has the same motion)
        property real off: root.open ? 0 : Theme.travel
        transform: Translate {
            x: Theme.barEdge === "left" ? -box.off : Theme.barEdge === "right" ? box.off : 0
            y: Theme.barEdge === "top" ? -box.off : Theme.barEdge === "bottom" ? box.off : 0
        }
        Behavior on off { NumberAnimation { duration: root.open ? Theme.enter : Theme.exit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
        Behavior on opacity { NumberAnimation { duration: root.open ? Theme.enter : Theme.exit; easing.type: Easing.OutCubic } }
        border { color: Theme.stroke; width: Theme.line }

        Flickable {
            anchors { fill: parent; margins: 5 }
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col
                width: parent.width

                Row_ {
                    visible: root.stack.length > 0
                    label: "Back"
                    glyph: "\u{F0141}"
                    onClicked: root.stack = root.stack.slice(0, -1)
                }
                Repeater {
                    model: opener.children
                    Loader {
                        required property QsMenuEntry modelData
                        width: col.width
                        sourceComponent: modelData.isSeparator ? separator : entry
                        Component {
                            id: separator
                            Item { height: 9; Rectangle { anchors.centerIn: parent; width: parent.width - 16; height: 1; color: Theme.stroke } }
                        }
                        Component {
                            id: entry
                            Row_ {
                                readonly property QsMenuEntry e: modelData
                                label: e.text.replace(/_(?=\w)/, "")   // drop GTK mnemonic underscores
                                icon: e.icon
                                enabled: e.enabled
                                checked: e.buttonType !== QsMenuButtonType.None && e.checkState === Qt.Checked
                                more: e.hasChildren
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

    // Menu row: check or icon, label, a chevron for submenus; accent highlight under the pointer
    component Row_: Rectangle {
        id: row
        property string label
        property string icon
        property string glyph
        property bool checked: false
        property bool more: false
        signal clicked()
        width: parent ? parent.width : 0
        height: Theme.controlHeight - 2
        radius: Theme.radiusSmall - 2
        opacity: enabled ? 1 : 0.4
        readonly property bool lit: area.containsMouse && enabled
        color: lit ? Theme.accent : "transparent"

        Text {
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            visible: row.checked || row.glyph !== ""
            text: row.checked ? "✓" : row.glyph
            color: row.lit ? Theme.accentText : Theme.text
            font { family: row.checked ? Theme.font : Theme.iconFont; pixelSize: 12; weight: Font.DemiBold }
        }
        IconImage {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            visible: !row.checked && row.glyph === "" && row.icon !== ""
            implicitSize: 14
            source: row.icon
        }
        Text {
            anchors { left: parent.left; leftMargin: 26; right: parent.right; rightMargin: 22; verticalCenter: parent.verticalCenter }
            text: row.label
            elide: Text.ElideRight
            color: row.lit ? Theme.accentText : Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize }
        }
        Text {
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            visible: row.more
            text: "\u{F0142}"
            color: row.lit ? Theme.accentText : Theme.subtext
            font { family: Theme.iconFont; pixelSize: 13 }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (row.enabled) row.clicked() }
    }
}
