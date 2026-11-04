import Quickshell.Hyprland
import QtQuick

// Workspaces of one monitor, drawn in the theme's own way (Themes.qml bar.ws), across a horizontal
// bar or down a vertical one:
//   dots     small dots; the current one stretches into an accent pill (Pebble)
//   filled   numbers, the current one on an accent block (Monolith)
//   text     one readout label, "WS 02" (Console)
//   numbers  numbers in a recessed pill with the current one filled (Glass)
//   blocks   huge numbers filling the bar, the current one a solid accent block (Poster)
//   squares  outlined squares, the current one filled (Atlas)
// Click goes there, scroll steps through them.
Item {
    id: ws
    required property var monitor
    property string style: Theme.barStyle.ws
    property bool vertical: false
    property int thickness: Theme.barSize               // the bar's height (or width when vertical)
    property color tone: Theme.text                     // ink on this bar's ground (Atlas's rail)
    property color dim: Theme.subtext
    readonly property var list: Sys.workspacesOf(monitor)
    readonly property int current: list.findIndex(w => w.active)
    function step(d) { const next = list[current + (d < 0 ? 1 : -1)]; if (next) next.activate() }
    function label(w) { return String(w.id) }

    visible: style !== "none"
    implicitWidth: style === "text" ? textLabel.implicitWidth : flow.implicitWidth
    implicitHeight: style === "text" ? textLabel.implicitHeight : flow.implicitHeight

    Text {   // text: one label for the whole set
        id: textLabel
        visible: ws.style === "text"
        anchors.centerIn: parent
        text: (ws.vertical ? "" : "WS ") + String(ws.list[ws.current]?.id ?? 0).padStart(2, "0")
        color: Theme.accent
        font { family: Theme.monoFont; pixelSize: Theme.fontLabel; letterSpacing: 1 }
        MouseArea { anchors.fill: parent; onWheel: w => ws.step(w.angleDelta.y) }
    }

    Rectangle {   // numbers: the recessed pill behind the set
        visible: ws.style === "numbers"
        anchors.fill: flow
        anchors.margins: -2
        radius: height / 2
        color: Theme.fill
    }

    Grid {
        id: flow
        visible: ws.style !== "text"
        anchors.centerIn: parent
        rows: ws.vertical ? 99 : 1
        columns: ws.vertical ? 1 : 99
        spacing: ({ dots: 6, blocks: 0, squares: 6, filled: 2, numbers: 0 })[ws.style] ?? 4
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        Repeater {
            model: ws.list
            Item {
                id: cell
                required property HyprlandWorkspace modelData
                required property int index
                readonly property bool on: index === ws.current
                readonly property bool busy: modelData.toplevels.values.length > 0
                readonly property string s: ws.style

                // along the bar (main) and across it (cross); a dot stretches along the bar when current
                readonly property real main: s === "dots" ? (on ? 20 : 8) : s === "blocks" ? ws.thickness * 0.95
                    : s === "squares" ? 34 : s === "numbers" ? 22 : Math.max(label.implicitWidth + 12, 20)
                readonly property real cross: s === "dots" ? 8 : s === "blocks" ? ws.thickness : s === "squares" ? 34 : s === "numbers" ? 20 : 20
                implicitWidth: ws.vertical ? cross : main
                implicitHeight: ws.vertical ? main : cross
                Behavior on implicitWidth { enabled: !ws.vertical; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                Behavior on implicitHeight { enabled: ws.vertical; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }

                Rectangle {
                    anchors.fill: parent
                    radius: cell.s === "dots" || cell.s === "numbers" ? Math.min(width, height) / 2 : 0
                    color: cell.on ? Theme.accent
                         : cell.s === "dots" ? (cell.busy ? ws.dim : Qt.alpha(ws.dim, 0.45))
                         : area.containsMouse ? Qt.alpha(ws.tone, 0.11) : "transparent"
                    border { color: cell.s === "squares" && !cell.on ? ws.tone : "transparent"; width: cell.s === "squares" ? 2 : 0 }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
                Text {
                    id: label
                    visible: cell.s !== "dots"
                    anchors.centerIn: parent
                    text: ws.label(cell.modelData)
                    color: cell.on ? Theme.accentText
                         : cell.modelData.urgent ? Theme.warning : cell.busy || area.containsMouse ? ws.tone : ws.dim
                    font {
                        family: cell.s === "blocks" ? Theme.displayFont : cell.s === "filled" ? Theme.monoFont : Theme.font
                        pixelSize: cell.s === "blocks" ? Math.min(ws.thickness * 0.72, 40) : cell.s === "squares" ? Theme.fontTitle : Theme.fontLabel
                        weight: cell.s === "blocks" ? Theme.displayWeight : cell.s === "squares" ? Font.ExtraBold : cell.on || cell.busy ? Font.DemiBold : Font.Normal
                        features: { "tnum": 1 }
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.margins: cell.s === "dots" ? -6 : 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cell.modelData.activate()
                    onWheel: w => ws.step(w.angleDelta.y)
                }
            }
        }
    }
}
