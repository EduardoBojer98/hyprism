pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Power menu (utility menu > Power…, the Control Center's power button, `qs ipc call power toggle`):
// a glass card centred on the focused screen over a dimmed backdrop. Tiles in 3, 2 or 1 columns,
// whatever fits the screen; on a narrow screen they become compact rows.
//   Click or arrows + Enter · Log out, Restart and Shut down ask for a second press · Esc or a
//   click outside closes.
Singleton {
    id: root

    property bool open: false
    property int selected: 0
    property string confirming: ""     // id of the action waiting for its second press
    property string host: ""
    property string uptime: ""

    readonly property var actions: allActions.filter(a => a.id !== "hibernate" || Machine.canHibernate)   // hibernate only where it works
    readonly property var allActions: [
        { id: "lock",      icon: "\u{F033E}", label: "Lock",      cmd: "loginctl lock-session" },
        { id: "suspend",   icon: "\u{F04B2}", label: "Sleep",     cmd: "systemctl suspend" },
        { id: "hibernate", icon: "\u{F0717}", label: "Hibernate", cmd: "systemctl hibernate" },
        { id: "logout",    icon: "\u{F0343}", label: "Log out",   cmd: "hyprshutdown", confirm: true },
        { id: "reboot",    icon: "\u{F0709}", label: "Restart",   cmd: "systemctl reboot", confirm: true },
        { id: "poweroff",  icon: "\u{F0425}", label: "Shut down", cmd: "systemctl poweroff", confirm: true, danger: true },
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
        cardWidth: 600
        cardHeight: content.implicitHeight + pad * 2
        onDismissed: root.hide()
        readonly property int pad: screenWidth - margin * 2 < 360 ? Theme.spaceL : Theme.spaceXl
        onKeyPressed: event => {
            const n = root.actions.length, cols = grid.columns
            if (event.key === Qt.Key_Escape) root.hide()
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.selected = (root.selected + 1) % n
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) root.selected = (root.selected - 1 + n) % n
            else if (event.key === Qt.Key_Down) root.selected = Math.min(n - 1, root.selected + cols)
            else if (event.key === Qt.Key_Up) root.selected = Math.max(0, root.selected - cols)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.activate(root.selected)
            else return
            if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space) root.confirming = ""
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
                        Text { text: "Power"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontHeading; weight: Font.Bold } }
                        Text {
                            Layout.fillWidth: true
                            text: root.host + (root.uptime ? " · up " + root.uptime : "")
                            elide: Text.ElideRight
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontLabel }
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
            }
        }
    }
}
