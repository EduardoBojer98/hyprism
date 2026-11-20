pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// On-screen keyboard (squeekboard). Shown from the bar button or the Control Center; Settings > Touch & Tablet can
// make it pop up on a tapped text field, or in tablet mode (~/.local/bin/panel).
// Shared by the bars on both screens.
Singleton {
    id: root
    property bool visible: false
    property bool installed: false   // squeekboard on the PATH: the tile is offered only then

    // flips at once (two quick taps send show, then hide), then squeekboard's own answer wins
    function toggle() {
        visible = !visible
        Quickshell.execDetached(["busctl", "--user", "call", "sm.puri.OSK0", "/sm/puri/OSK0", "sm.puri.OSK0", "SetVisible", "b", String(visible)])
        readLater.restart()
    }
    Timer { id: readLater; interval: 400; onTriggered: read.running = true }   // a failed call puts the tile back
    Process {
        id: read
        command: ["busctl", "--user", "get-property", "sm.puri.OSK0", "/sm/puri/OSK0", "sm.puri.OSK0", "Visible"]
        stdout: StdioCollector { onStreamFinished: root.visible = text.trim() === "b true" }
    }
    Process {
        running: true
        command: ["sh", "-c", "command -v squeekboard"]
        onExited: code => root.installed = code === 0
    }

    // Settings > Touch & Tablet, told to squeekboard through the GNOME settings it reads: pop up on a tapped text
    // field, and your keyboard layouts as its languages ("rs" with variant "latin" -> ('xkb', 'rs+latin'))
    readonly property string sources: "[" + Array.from(Config.input.layouts).map(l => `('xkb', '${l.code}${l.variant ? "+" + l.variant : ""}')`).join(", ") + "]"
    readonly property var apply: ["sh", "-c", 'gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled "$1"; [ "$2" = true ] && gsettings set org.gnome.desktop.input-sources sources "$3"; true',
                                  "sh", String(Config.touch.oskAuto), String(Config.touch.oskLayouts), sources]
    onApplyChanged: if (installed) Quickshell.execDetached(apply)
    onInstalledChanged: if (installed) Quickshell.execDetached(apply)
}
