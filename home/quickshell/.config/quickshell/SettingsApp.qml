pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// The Settings app: one glass window with a sidebar of sections, like macOS System Settings.
// Open with Super+I, the Control Center's gear, the launcher ("Settings"), or
// `qs ipc call settings open [section]`.
Singleton {
    id: root

    property bool open: false
    property string section: "appearance"

    readonly property var sections: [
        { id: "appearance",    name: "Appearance & Themes", glyph: "\u{F03D8}" },
        { id: "icons",         name: "Icons",               glyph: "\u{F0BC1}" },
        { id: "dock",          name: "Desktop & Dock",      glyph: "\u{F0379}" },
        { id: "launcher",      name: "Search & Launcher",   glyph: "\u{F0349}" },
        { id: "clipboard",     name: "Clipboard",           glyph: "\u{F014C}" },
        { id: "controlcenter", name: "Control Center",      glyph: "\u{F0493}" },
        { id: "notifications", name: "Notifications",       glyph: "\u{F009A}" },
        { id: "displays",      name: "Displays",            glyph: "\u{F0379}" },
        { id: "sound",         name: "Sound",               glyph: "\u{F057E}" },
        { id: "network",       name: "Wi-Fi & Network",     glyph: "\u{F05A9}" },
        { id: "bluetooth",     name: "Bluetooth",           glyph: "\u{F00AF}" },
        { id: "input",         name: "Keyboard & Touchpad", glyph: "\u{F030C}" },
        { id: "keybinds",      name: "Keyboard Shortcuts",  glyph: "\u{F0313}" },
        { id: "power",         name: "Battery & Power",     glyph: "\u{F0079}" },
        { id: "asus",          name: "ASUS Hardware",       glyph: "\u{F061A}" },
        { id: "wallpaper",     name: "Wallpaper",           glyph: "\u{F02E9}" },
        { id: "idle",          name: "Lock & Sleep",        glyph: "\u{F033E}" },
        { id: "apps",          name: "Default Applications", glyph: "\u{F003B}" },
        { id: "about",         name: "About",               glyph: "\u{F02FD}" },
    ]

    function show(s) { if (s && sections.some(x => x.id === s)) section = s; open = true }

    IpcHandler {
        target: "settings"
        function open(section: string): void { root.show(section) }
        function toggle(): void { root.open = !root.open }
    }

    // Lua table literal from a plain JS object (strings, numbers, booleans, nested objects)
    function lua(value, indent) {
        indent = indent || ""
        if (typeof value === "string") return JSON.stringify(value)
        if (typeof value === "number" || typeof value === "boolean") return String(value)
        const inner = indent + "    "
        return "{\n" + Object.keys(value).map(k =>
            inner + "[" + JSON.stringify(k) + "] = " + lua(value[k], inner) + ",").join("\n") + "\n" + indent + "}"
    }

    // Write a text file in the Hyprland config (the repo, through the stow link)
    function writeHyprFile(rel, text) {
        // mkdir: settings/ isn't in git (your own choices), so a fresh install has to create it
        Quickshell.execDetached(["sh", "-c", "f=\"$HOME/.config/hypr/" + rel + "\"; mkdir -p \"$(dirname \"$f\")\"; cat > \"$f\" <<'QS_EOF'\n" + text + "\nQS_EOF"])
    }

    FloatingWindow {
        id: win
        visible: root.open
        title: "Settings"
        color: "transparent"
        implicitWidth: 1020
        implicitHeight: 700
        minimumSize: Qt.size(860, 560)
        onVisibleChanged: if (!visible) root.open = false

        Glass {
            anchors.fill: parent
            strong: true
            radius: 0
            border.width: 0

            // ---- sidebar ---------------------------------------------------------------------
            Rectangle {
                id: sidebar
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                width: 240
                color: Qt.rgba(0, 0, 0, 0.18)

                Column {
                    anchors { fill: parent; margins: 12; topMargin: 18 }
                    spacing: 2

                    Text {
                        text: "Settings"
                        leftPadding: 10
                        bottomPadding: 12
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 20; weight: Font.Bold }
                    }

                    Repeater {
                        model: root.sections
                        Rectangle {
                            required property var modelData
                            readonly property bool current: root.section === modelData.id
                            width: parent.width
                            height: 34
                            radius: Theme.radiusSmall
                            color: current ? Theme.fillActive : navArea.containsMouse ? Theme.fillHover : "transparent"
                            border { color: current ? Theme.stroke : "transparent"; width: 1 }
                            Row {
                                anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                spacing: 10
                                Rectangle {
                                    width: 24; height: 24; radius: 7
                                    color: current ? Theme.accent : Theme.fill
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.glyph
                                        color: current ? Theme.accentText : Theme.text
                                        font { family: Theme.iconFont; pixelSize: 14 }
                                    }
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name
                                    color: Theme.text
                                    font { family: Theme.font; pixelSize: 13; weight: current ? Font.DemiBold : Font.Normal }
                                }
                            }
                            MouseArea { id: navArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.section = modelData.id }
                        }
                    }
                }
            }

            Rectangle { // divider
                anchors { left: sidebar.right; top: parent.top; bottom: parent.bottom }
                width: 1
                color: Theme.stroke
            }

            // ---- page ------------------------------------------------------------------------
            Flickable {
                id: page
                anchors { left: sidebar.right; leftMargin: 1; right: parent.right; top: parent.top; bottom: parent.bottom }
                contentHeight: pageColumn.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: pageColumn
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 }
                    spacing: 20

                    Text {
                        text: root.sections.find(s => s.id === root.section)?.name ?? ""
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 22; weight: Font.Bold }
                    }

                    Loader {
                        Layout.fillWidth: true
                        active: root.open
                        source: "SettingsPage" + root.section.charAt(0).toUpperCase() + root.section.slice(1) + ".qml"
                    }
                }
            }
        }
    }
}
