import Quickshell.Hyprland
import QtQuick

// Workspaces of one monitor, drawn in the rice's own way (Rices.qml bar.ws):
//   dots     small dots; the current one stretches into an accent pill (Pebble, Canvas, Zen, Halo)
//   filled   numbers, the current one on an accent block (Monolith)
//   text     one readout label, "WS 02" (Console)
//   numbers  numbers in a recessed pill with an accent pill sliding to the current (Glass)
//   blocks   huge numbers filling the bar height, the current one a solid accent block (Poster)
//   squares  outlined squares, the current one filled (Atlas)
//   roman    lowercase roman numerals, the current one in the accent (Noir)
//   ticks    short lines, the current one long and dark (Mist)
//   tiles    rounded tiles with numbers, the current one in the accent (Garden)
//   small    small numbers for a taskbar (Workstation)
// Click goes there, scroll steps through them.
Item {
    id: ws
    required property var monitor
    property string style: Theme.bar.ws
    property bool vertical: false
    property int thickness: Theme.bar.size              // the bar's height (or width when vertical)
    readonly property var list: Sys.workspacesOf(monitor)
    readonly property int current: list.findIndex(w => w.active)
    function step(d) { const next = list[current + (d < 0 ? 1 : -1)]; if (next) next.activate() }
    function label(w) { return style === "roman" ? Sys.roman(w.id) : String(w.id) }

    visible: style !== "none"
    implicitWidth: style === "text" ? textLabel.implicitWidth : flow.implicitWidth
    implicitHeight: style === "text" ? textLabel.implicitHeight : flow.implicitHeight

    Text {   // text: one label for the whole set
        id: textLabel
        visible: ws.style === "text"
        anchors.centerIn: parent
        text: "WS " + String(ws.list[ws.current]?.id ?? 0).padStart(2, "0")
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
        rows: ws.vertical ? -1 : 1
        columns: ws.vertical ? 1 : -1
        spacing: ({ dots: 6, ticks: 6, blocks: 0, squares: 6, tiles: 6, filled: 2, roman: 14, numbers: 0, small: 2 })[ws.style] ?? 4
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

                implicitWidth: s === "dots" ? (on ? 20 : 8) : s === "ticks" ? (on ? 22 : 10) : s === "blocks" ? ws.thickness * 0.95
                    : s === "squares" ? 34 : s === "tiles" ? 30 : s === "numbers" ? 22 : s === "small" ? 22 : Math.max(label.implicitWidth + 12, 20)
                implicitHeight: s === "dots" ? 8 : s === "ticks" ? 2 : s === "blocks" ? ws.thickness : s === "squares" ? 34 : s === "tiles" ? 30
                    : s === "numbers" ? 20 : s === "small" ? 22 : 20
                Behavior on implicitWidth { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }

                Rectangle {
                    anchors.fill: parent
                    radius: cell.s === "dots" || cell.s === "numbers" ? height / 2 : cell.s === "tiles" ? Theme.radiusSmall : cell.s === "small" ? 4 : 0
                    color: cell.on ? (cell.s === "ticks" ? Theme.text : Theme.accent)
                         : cell.s === "dots" ? (cell.busy ? Theme.subtext : Theme.muted)
                         : cell.s === "ticks" ? (cell.busy ? Theme.subtext : Theme.stroke)
                         : cell.s === "tiles" ? Theme.fill
                         : area.containsMouse && cell.s !== "roman" ? Theme.fillHover : "transparent"
                    border { color: cell.s === "squares" && !cell.on ? Theme.text : "transparent"; width: cell.s === "squares" ? 2 : 0 }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
                Text {
                    id: label
                    visible: !["dots", "ticks"].includes(cell.s)
                    anchors.centerIn: parent
                    text: ws.label(cell.modelData)
                    color: cell.on ? (cell.s === "roman" ? Theme.accent : Theme.accentText)
                         : cell.modelData.urgent ? Theme.warning : cell.busy || area.containsMouse ? Theme.text : Theme.subtext
                    font {
                        family: cell.s === "blocks" || cell.s === "roman" ? Theme.displayFont : cell.s === "filled" ? Theme.monoFont : Theme.font
                        pixelSize: cell.s === "blocks" ? ws.thickness * 0.72 : cell.s === "roman" ? Theme.fontTitle + 2 : cell.s === "squares" ? Theme.fontTitle : Theme.fontLabel
                        weight: cell.s === "blocks" ? Theme.displayWeight : cell.s === "squares" ? Font.ExtraBold : cell.on || cell.busy ? Font.DemiBold : Font.Normal
                        features: { "tnum": 1 }
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.margins: cell.s === "ticks" || cell.s === "dots" ? -6 : 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cell.modelData.activate()
                    onWheel: w => ws.step(w.angleDelta.y)
                }
            }
        }
    }
}
