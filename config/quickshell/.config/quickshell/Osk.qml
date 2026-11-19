pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// On-screen keyboard (squeekboard). Never pops up by itself; only the bar button shows/hides it.
// Shared by the bars on both screens.
Singleton {
    id: root
    property bool visible: false
    property bool installed: false   // squeekboard on the PATH: the tile is offered only then

    function toggle() {
        set.command = ["busctl", "--user", "call", "sm.puri.OSK0", "/sm/puri/OSK0", "sm.puri.OSK0", "SetVisible", "b", visible ? "false" : "true"]
        set.running = true
    }
    // what squeekboard says, after every change: a failed call leaves the tile as it was
    Process { id: set; onExited: read.running = true }
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
}
