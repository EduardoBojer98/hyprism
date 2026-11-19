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
}
