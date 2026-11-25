import Quickshell
import Quickshell.Hyprland
import QtQuick

// Workspaces of one monitor, drawn in the theme's own way (Themes.qml bar.ws), across a horizontal
// bar or down a vertical one:
//   dots     small dots; the current one stretches into an accent pill (Lumen)
//   filled   numbers, the current one on an accent block (Monolith)
//   text     one readout label, "WS 02" (Console)
//   numbers  numbers in a recessed pill with the current one filled (Glass)
//   blocks   huge numbers filling the bar, the current one a solid accent block (Poster)
//   squares  outlined squares, the current one filled (Atlas)
//   tabs     tmux's window list: number and app ("2 firefox"), the current one an accent block the bar's height
//   reticle  mono numbers; HUD corner marks lock onto the current one over a faint accent wash (Monolith)
// Click goes there, scroll steps through them. A + at the end (Settings > Workspaces > New workspace button,
// dynamic workspaces only) opens the lowest free workspace on this screen and goes there.
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
    readonly property bool adds: Config.workspaces.newButton && Config.workspaces.mode !== "fixed"
    // the pointer is on this bar, so this screen has focus: the next empty workspace after this one opens here
    function addOne() { Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.focus({ workspace = "emptyn" })']) }
    function step(d) { const next = list[current + (d < 0 ? 1 : -1)]; if (next) next.activate() }
    function label(w) { return String(w.id) + (style === "tabs" && !vertical && app(w) !== "" ? " " + app(w) : "") }
    // tabs: the workspace's app, short like tmux's process name ("com.mitchellh.ghostty" -> "ghostty")
    function app(w) {
        const t = w.toplevels.values, top = t.find(x => x.activated) ?? t[t.length - 1]
        return String(top?.wayland?.appId ?? top?.lastIpcObject?.class ?? "").split(".").pop().toLowerCase().slice(0, 12)
    }

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
        MouseArea { anchors.fill: parent; onWheel: w => ws.step(w.angleDelta.y); Accessible.ignored: true }
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
        // one row or one column: only `columns` is set (setting rows too adds spacing for empty rows)
        columns: ws.vertical ? 1 : Math.max(1, visibleChildren.filter(c => c.width > 0).length)
        spacing: ({ dots: 6, blocks: 0, squares: 6, filled: 2, numbers: 0, tabs: 0, reticle: 2 })[ws.style] ?? 4
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
                    : s === "squares" ? 34 : s === "numbers" ? 22 : s === "reticle" ? Math.max(label.implicitWidth + 14, 22)
                    : Math.max(label.implicitWidth + (s === "tabs" ? 20 : 12), 20)
                readonly property real cross: s === "dots" ? 8 : s === "blocks" ? ws.thickness - (Theme.barFloating ? 2 * Theme.line : 1) : s === "squares" ? 34 : s === "numbers" ? 20
                    : s === "tabs" ? ws.thickness - 1 : s === "reticle" ? Math.min(ws.thickness - 6, 22) : 20
                implicitWidth: ws.vertical ? cross : main
                implicitHeight: ws.vertical ? main : cross
                Behavior on implicitWidth { enabled: !ws.vertical; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                Behavior on implicitHeight { enabled: ws.vertical; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }

                Rectangle {
                    anchors.fill: parent
                    radius: cell.s === "dots" || cell.s === "numbers" ? Math.min(width, height) / 2 : 0
                    color: cell.on ? (cell.s === "reticle" ? Qt.alpha(Theme.accent, 0.14) : Theme.accent)
                         : cell.s === "dots" ? (cell.busy ? ws.dim : Qt.alpha(ws.dim, 0.45))
                         : area.containsMouse ? Qt.alpha(ws.tone, 0.11) : "transparent"
                    border { color: cell.s === "squares" && !cell.on ? ws.tone : "transparent"; width: cell.s === "squares" ? 2 : 0 }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
                Item {   // reticle: four corner marks, closing in from a little outside when this one becomes current
                    id: marks
                    visible: cell.s === "reticle"
                    anchors.fill: parent
                    anchors.margins: cell.on ? 0 : -4
                    opacity: cell.on ? 1 : 0
                    Behavior on anchors.margins { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    Repeater {
                        model: 4
                        Item {
                            id: corner
                            required property int index
                            readonly property bool atRight: index % 2 === 1
                            readonly property bool atLow: index > 1
                            x: atRight ? marks.width - width : 0
                            y: atLow ? marks.height - height : 0
                            width: 5; height: 5
                            Rectangle { width: 5; height: 1; y: corner.atLow ? 4 : 0; color: Theme.accent }
                            Rectangle { width: 1; height: 5; x: corner.atRight ? 4 : 0; color: Theme.accent }
                        }
                    }
                }
                Text {
                    id: label
                    visible: cell.s !== "dots"
                    anchors.centerIn: parent
                    // tabs: the number dimmed before the app's name, except on the current tab's block
                    textFormat: cell.s === "tabs" ? Text.StyledText : Text.PlainText
                    text: cell.s === "tabs" && !cell.on && ws.app(cell.modelData) !== "" && !ws.vertical
                          ? `<font color="${ws.dim}">${cell.modelData.id}</font> ${ws.app(cell.modelData)}` : ws.label(cell.modelData)
                    color: cell.on ? (cell.s === "reticle" ? Theme.accent : Theme.accentText)
                         : cell.modelData.urgent ? Theme.warning : cell.busy || area.containsMouse ? ws.tone : ws.dim
                    font {
                        family: cell.s === "blocks" ? Theme.displayFont : cell.s === "filled" || cell.s === "tabs" || cell.s === "reticle" ? Theme.monoFont : Theme.font
                        pixelSize: cell.s === "blocks" ? Math.min(ws.thickness * 0.72, 40) : cell.s === "squares" ? Theme.fontTitle : Theme.fontLabel
                        weight: cell.s === "blocks" ? Theme.displayWeight : cell.s === "squares" ? Font.ExtraBold : cell.on || cell.busy ? Font.DemiBold : Font.Normal
                        features: { "tnum": 1 }
                    }
                }
                MouseArea {
                    id: area
                    Accessible.role: Accessible.Button
                    Accessible.name: "Workspace " + ws.label(cell.modelData)
                    Accessible.onPressAction: cell.modelData.activate()
                    anchors.fill: parent
                    anchors.margins: cell.s === "dots" ? -6 : 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cell.modelData.activate()
                    onWheel: w => ws.step(w.angleDelta.y)
                }
            }
        }

        Item {   // new workspace
            visible: ws.adds
            readonly property real size: ws.style === "dots" ? 14 : ws.style === "blocks" ? ws.thickness * 0.7 : Math.min(ws.thickness - 6, 22)
            implicitWidth: size; implicitHeight: size
            Rectangle {
                anchors.fill: parent
                radius: ws.style === "dots" || ws.style === "numbers" ? width / 2 : Theme.radius === 0 ? 0 : Math.min(Theme.radiusSmall, width / 3)
                color: addArea.pressed ? Qt.alpha(ws.tone, 0.18) : addArea.containsMouse ? Qt.alpha(ws.tone, 0.11) : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
            Text {
                anchors.centerIn: parent
                text: "\u{F0415}"
                color: addArea.containsMouse ? ws.tone : ws.dim
                font { family: Theme.iconFont; pixelSize: ws.style === "dots" ? Theme.glyphXs : Theme.glyphS }
            }
            MouseArea {
                id: addArea
                Accessible.role: Accessible.Button
                Accessible.name: "New workspace"
                Accessible.onPressAction: ws.addOne()
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ws.addOne()
            }
        }
    }
}
