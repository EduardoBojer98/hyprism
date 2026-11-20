pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Power menu (utility menu > Power…, the Control Center's power button, `qs ipc call power toggle`):
// a glass card centred on the focused screen over a dimmed backdrop. Tiles in 3, 2 or 1 columns,
// whatever fits the screen; on a narrow screen they become compact rows.
//   Click or arrows + Enter, or an action's key (L S H O R P) or number (1-6) · Log out, Restart and
//   Shut down ask for a second press · Esc or a click outside closes.
// theme.json power.style: tiles (icon tiles) | blocks (giant display-type blocks with their key, hard
// shadows) | list (a numbered mono list: 1) lock  2) sleep ...)
Singleton {
    id: root

    property bool open: false
    property int selected: 0
    property string confirming: ""     // id of the action waiting for its second press
    property string host: ""
    property string uptime: ""
    readonly property string style: Theme.current.power?.style ?? "tiles"

    readonly property var actions: allActions.filter(a => a.id !== "hibernate" || Machine.canHibernate)   // hibernate only where it works
    readonly property var allActions: [
        { id: "lock", key: "L",      icon: "\u{F033E}", label: "Lock",      cmd: "loginctl lock-session" },
        { id: "suspend", key: "S",   icon: "\u{F04B2}", label: "Sleep",     cmd: "systemctl suspend" },
        { id: "hibernate", key: "H", icon: "\u{F0717}", label: "Hibernate", cmd: "systemctl hibernate" },
        { id: "logout", key: "O",    icon: "\u{F0343}", label: "Log out",   cmd: "hyprshutdown", confirm: true },
        { id: "reboot", key: "R",    icon: "\u{F0709}", label: "Restart",   cmd: "systemctl reboot", confirm: true },
        { id: "poweroff", key: "P",  icon: "\u{F0425}", label: "Shut down", cmd: "systemctl poweroff", confirm: true, danger: true },
    ]

    function show() { selected = 0; confirming = ""; info.running = true; open = true }
    function hide() { open = false; confirming = "" }
    function toggle() { if (open) hide(); else show() }
    function activate(i) {
        const a = actions[i]
        selected = i
        if (a.confirm && confirming !== a.id) { confirming = a.id; confirmReset.restart(); return }
        hide()
        // after the fade, so the lock screen or logout doesn't capture the menu
        Quickshell.execDetached(["sh", "-c", "sleep 0.25; " + a.cmd])
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.toggle() }
    }

    Process {
        id: info
        command: ["sh", "-c", "uname -n; uptime -p | sed 's/^up //'"]
        stdout: StdioCollector { onStreamFinished: { const l = text.trim().split("\n"); root.host = l[0] ?? ""; root.uptime = l[1] ?? "" } }
    }
    Timer { id: confirmReset; interval: 4000; onTriggered: root.confirming = "" }

    Overlay {
        id: card
        name: "power"
        open: root.open
        cardWidth: root.style === "blocks" ? 720 : root.style === "list" ? 480 : 600
        cardHeight: content.implicitHeight + pad * 2
        onDismissed: root.hide()
        readonly property int pad: screenWidth - margin * 2 < 360 ? Theme.spaceL : Theme.spaceXl
        onKeyPressed: event => {
            const n = root.actions.length, cols = root.style === "list" ? 1 : root.style === "blocks" ? blockGrid.columns : grid.columns
            const t = event.text.toUpperCase(), byKey = root.actions.findIndex(a => a.key === t)
            if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
            if (event.key === Qt.Key_Escape) root.hide()
            else if (byKey >= 0) root.activate(byKey)
            else if (t >= "1" && t <= "9" && Number(t) <= n) root.activate(Number(t) - 1)
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.selected = (root.selected + 1) % n
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) root.selected = (root.selected - 1 + n) % n
            else if (event.key === Qt.Key_Down) root.selected = Math.min(n - 1, root.selected + cols)
            else if (event.key === Qt.Key_Up) root.selected = Math.max(0, root.selected - cols)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.activate(root.selected)
            else return
            if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space && byKey < 0 && !(t >= "1" && t <= "9")) root.confirming = ""
            event.accepted = true
        }

        Flickable {   // scrolls only on very short screens
            anchors { fill: parent; margins: card.pad }
            contentHeight: content.implicitHeight
            clip: contentHeight > height
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: content
                width: parent.width
                spacing: Theme.spaceL

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceM
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: root.style === "blocks" ? "POWER" : root.style === "list" ? "$ power" : "Power"
                            color: root.style === "list" ? Theme.accent : Theme.text
                            font {
                                family: root.style === "blocks" ? Theme.displayFont : root.style === "list" ? Theme.monoFont : Theme.font
                                pixelSize: root.style === "blocks" ? Theme.fontDisplay : root.style === "list" ? Theme.fontTitle : Theme.fontHeading
                                weight: root.style === "blocks" ? Math.max(Theme.displayWeight, Font.Bold) : Font.Bold
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.style === "list" ? "// " + root.host + (root.uptime ? "  up " + root.uptime : "")
                                                        : root.host + (root.uptime ? " · up " + root.uptime : "")
                            elide: Text.ElideRight
                            color: Theme.subtext
                            font { family: root.style === "list" ? Theme.monoFont : Theme.font; pixelSize: Theme.fontLabel }
                        }
                    }
                    Rectangle {   // close
                        Layout.alignment: Qt.AlignTop
                        width: 28; height: 28; radius: 14
                        color: closeArea.containsMouse ? Theme.fillHover : Theme.fill
                        Text { anchors.centerIn: parent; text: "\u{F0156}"; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
                        MouseArea { id: closeArea; Accessible.role: Accessible.Button; Accessible.name: "Close"; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.hide() }
                    }
                }

                GridLayout {
                    id: grid
                    visible: root.style === "tiles"
                    Layout.fillWidth: true
                    // tiles need ~150 px each; below two of those, compact rows
                    readonly property bool rows: width < 300
                    columns: rows ? 1 : width >= 3 * 150 + 2 * columnSpacing ? 3 : 2
                    columnSpacing: Theme.spaceM
                    rowSpacing: Theme.spaceM

                    Repeater {
                        model: root.actions
                        Rectangle {
                            id: tile
                            required property var modelData
                            required property int index
                            readonly property bool asking: root.confirming === modelData.id
                            readonly property bool lit: tileArea.containsMouse || root.selected === index
                            readonly property color tone: asking || modelData.danger ? Theme.error : Theme.accentLikeError ? Theme.text : Theme.accent

                            Layout.fillWidth: true
                            Layout.preferredHeight: grid.rows ? 52 : 112
                            radius: Theme.radius
                            color: asking ? Qt.rgba(tone.r, tone.g, tone.b, 0.22) : lit ? Theme.fillHover : Theme.fill
                            border { color: asking ? tone : root.selected === index ? Theme.strokeStrong : "transparent"; width: 1 }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            GridLayout {
                                anchors { fill: parent; margins: Theme.spaceM }
                                columns: grid.rows ? 2 : 1
                                rowSpacing: Theme.spaceS
                                columnSpacing: Theme.spaceM

                                Rectangle {
                                    Layout.alignment: grid.rows ? Qt.AlignVCenter : Qt.AlignHCenter
                                    width: grid.rows ? 30 : 46; height: width; radius: width / 2
                                    color: tile.lit || tile.asking ? tile.tone : Theme.fillActive
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: tile.modelData.icon
                                        color: tile.lit || tile.asking ? (tile.tone === Theme.text ? Theme.base : Theme.accentText) : tile.modelData.danger ? Theme.error : Theme.text
                                        font { family: Theme.iconFont; pixelSize: grid.rows ? 15 : 22 }
                                    }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: grid.rows ? Qt.AlignVCenter : Qt.AlignHCenter
                                    spacing: 1
                                    Text {
                                        Layout.fillWidth: true
                                        horizontalAlignment: grid.rows ? Text.AlignLeft : Text.AlignHCenter
                                        text: tile.modelData.label
                                        elide: Text.ElideRight
                                        color: tile.asking ? tile.tone : Theme.text
                                        font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        visible: tile.asking
                                        horizontalAlignment: grid.rows ? Text.AlignLeft : Text.AlignHCenter
                                        text: "Press again to confirm"
                                        elide: Text.ElideRight
                                        color: Theme.subtext
                                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                                    }
                                }
                            }
                            MouseArea {
                                id: tileArea
                                Accessible.role: Accessible.Button
                                Accessible.name: tile.modelData.label
                                Accessible.onPressAction: root.activate(tile.index)
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selected = tile.index
                                onClicked: root.activate(tile.index)
                            }
                        }
                    }
                                }

                // blocks: giant display-type blocks with their key, a hard shadow; the chosen one an accent block
                GridLayout {
                    id: blockGrid
                    visible: root.style === "blocks"
                    Layout.fillWidth: true
                    columns: width >= 3 * 170 + 2 * columnSpacing ? 3 : width >= 2 * 140 + columnSpacing ? 2 : 1
                    columnSpacing: Theme.spaceL
                    rowSpacing: Theme.spaceL

                    Repeater {
                        model: root.actions
                        Item {
                            id: blk
                            required property var modelData
                            required property int index
                            readonly property bool asking: root.confirming === modelData.id
                            readonly property bool lit: blkArea.containsMouse || root.selected === index
                            readonly property color fill: asking || lit && modelData.danger ? Theme.error : lit ? Theme.accent : Theme.surfaceColor
                            readonly property color ink: asking || lit ? Theme.accentText : Theme.text
                            readonly property int drop: blkArea.pressed ? 0 : Theme.spaceS   // the shadow collapses on press
                            Layout.fillWidth: true
                            Layout.preferredHeight: blockGrid.columns === 1 ? 72 : 132

                            Rectangle {   // the hard shadow
                                x: Theme.spaceS; y: Theme.spaceS; width: parent.width; height: parent.height
                                color: Theme.text
                            }
                            Rectangle {
                                x: Theme.spaceS - blk.drop; y: Theme.spaceS - blk.drop; width: parent.width; height: parent.height
                                color: blk.fill
                                border { width: Math.max(2, Theme.line); color: Theme.text }
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                Rectangle {   // the key
                                    anchors { top: parent.top; right: parent.right; margins: Theme.spaceM }
                                    width: keyText.implicitHeight + Theme.spaceXs; height: width
                                    color: "transparent"
                                    border { width: Math.max(2, Theme.line); color: blk.ink }
                                    Text {
                                        id: keyText
                                        anchors.centerIn: parent
                                        text: blk.modelData.key
                                        color: blk.ink
                                        font { family: Theme.displayFont; pixelSize: Theme.fontTitle; weight: Font.Bold }
                                    }
                                }
                                Column {
                                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.spaceM }
                                    Text {
                                        width: parent.width
                                        visible: blk.asking
                                        text: "AGAIN TO CONFIRM"
                                        elide: Text.ElideRight
                                        color: blk.ink
                                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Bold; letterSpacing: 1 }
                                    }
                                    Text {
                                        width: parent.width
                                        text: blk.modelData.label.toUpperCase()
                                        elide: Text.ElideRight
                                        color: blk.ink
                                        font { family: Theme.displayFont; pixelSize: Theme.fontDisplay; weight: Math.max(Theme.displayWeight, Font.Bold) }
                                    }
                                }
                            }
                            MouseArea {
                                id: blkArea
                                Accessible.role: Accessible.Button
                                Accessible.name: blk.modelData.label + ", key " + blk.modelData.key
                                Accessible.onPressAction: root.activate(blk.index)
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selected = blk.index
                                onClicked: root.activate(blk.index)
                            }
                        }
                    }
                }

                // list: numbered mono lines, a > on the chosen one
                Column {
                    visible: root.style === "list"
                    Layout.fillWidth: true
                    spacing: 0
                    Repeater {
                        model: root.actions
                        Rectangle {
                            id: line
                            required property var modelData
                            required property int index
                            readonly property bool asking: root.confirming === modelData.id
                            readonly property bool lit: lineArea.containsMouse || root.selected === index
                            width: parent.width
                            height: lineText.implicitHeight + Theme.spaceS * 2
                            color: lit ? Theme.fill : "transparent"
                            Text {
                                id: lineText
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.spaceS }
                                textFormat: Text.PlainText
                                text: (line.lit ? "> " : "  ") + (line.index + 1) + ") " + line.modelData.label.toLowerCase()
                                      + (line.asking ? "   press " + (line.index + 1) + " again to confirm" : "")
                                elide: Text.ElideRight
                                color: line.asking || line.modelData.danger && line.lit ? Theme.error : line.lit ? Theme.accent : Theme.text
                                font { family: Theme.monoFont; pixelSize: Theme.fontSize }
                            }
                            MouseArea {
                                id: lineArea
                                Accessible.role: Accessible.Button
                                Accessible.name: (line.index + 1) + ", " + line.modelData.label
                                Accessible.onPressAction: root.activate(line.index)
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selected = line.index
                                onClicked: root.activate(line.index)
                            }
                        }
                    }
                }
                Text {
                    visible: root.style === "list"
                    Layout.fillWidth: true
                    text: "[1-" + root.actions.length + "] pick  [enter] run  [esc] close"
                    elide: Text.ElideRight
                    color: Theme.subtext
                    font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
                }
            }
        }
    }
}
