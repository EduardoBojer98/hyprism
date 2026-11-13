pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Small utility menu behind the system logo at the left end of the bar (also
// `qs ipc call utilitymenu toggle`): this computer, quick tools, then Power… which opens the
// power menu (PowerMenu.qml).
Singleton {
    id: root

    readonly property bool open: popup.open
    property string host: ""
    property string uptime: ""

    function toggle() { popup.toggle() }
    function run(cmd, delayed) {
        popup.hide()
        Quickshell.execDetached(delayed ? ["sh", "-c", "sleep 0.3; " + cmd] : ["sh", "-c", cmd])
    }

    readonly property var tools: [
        { icon: "\u{F02FD}", label: "About this computer",  act: () => { popup.hide(); SettingsApp.show("about") } },
        { icon: "\u{F0493}", label: "Settings",             act: () => { popup.hide(); SettingsApp.show("") } },
        { icon: "\u{F0313}", label: "Keyboard shortcuts",   act: () => { popup.hide(); SettingsApp.show("keybinds") } },
        { icon: "\u{F0100}", label: "Screenshot an area",   act: () => root.run("screenshot", true) },
        { icon: "\u{F0A3B}", label: "Copy text from screen", act: () => root.run("screentext", true) },
        { icon: "\u{F0485}", label: "Colour picker",        act: () => root.run("hyprpicker -a", true) },
        { icon: "\u{F014C}", label: "Clipboard history",    act: () => { popup.hide(); Clipboard.toggle() } },
        { icon: "\u{F0785}", label: "Emoji",                act: () => root.run("emojipick", true) },
    ]
    IpcHandler {
        target: "utilitymenu"
        function toggle(): void { root.toggle() }
    }

    Process {
        id: info
        command: ["sh", "-c", "uname -n; uptime -p | sed 's/^up //'"]
        stdout: StdioCollector { onStreamFinished: { const l = text.trim().split("\n"); root.host = l[0] ?? ""; root.uptime = l[1] ?? "" } }
    }

    CursorPopup {
        id: popup
        name: "utilitymenu"
        placement: "topLeft"
        boxWidth: 236
        boxHeight: menu.implicitHeight + Theme.spaceS * 2
        onOpened: info.running = true

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge

            ColumnLayout {
                id: menu
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
                spacing: 0

                Column {
                    Layout.fillWidth: true
                    Layout.margins: Theme.spaceS
                    Layout.bottomMargin: Theme.spaceXs
                    Text { text: root.host; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold } }
                    Text { text: root.uptime ? "Up " + root.uptime : ""; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                }
                Divider {}
                Repeater {
                    model: root.tools
                    Row_ { required property var modelData; icon: modelData.icon; label: modelData.label; onClicked: modelData.act() }
                }
                Divider {}
                Row_ { icon: "\u{F0425}"; label: "Power…"; onClicked: { popup.hide(); PowerMenu.show() } }
            }
        }
    }

    component Divider: Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        Layout.topMargin: Theme.spaceXs
        Layout.bottomMargin: Theme.spaceXs
        color: Theme.stroke
    }

    component Row_: Rectangle {
        id: row
        property string icon
        property string label
        property bool danger: false
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.controlHeight
        radius: Theme.radiusSmall - 2
        color: area.containsMouse ? (row.danger ? Theme.error : Theme.accent) : "transparent"
        RowLayout {
            anchors { fill: parent; leftMargin: Theme.spaceS + 2; rightMargin: Theme.spaceS + 2 }
            spacing: Theme.spaceS + 2
            Text { text: row.icon; color: area.containsMouse ? Theme.accentText : row.danger ? Theme.error : Theme.subtext; font { family: Theme.iconFont; pixelSize: 14 } }
            Text { Layout.fillWidth: true; text: row.label; elide: Text.ElideRight; color: area.containsMouse ? Theme.accentText : row.danger ? Theme.error : Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize } }
        }
        MouseArea { id: area; Accessible.role: Accessible.Button; Accessible.name: row.label; Accessible.onPressAction: row.clicked(); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: row.clicked() }
    }
}
