pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Opens bar popups from IPC/keybinds on the focused screen's bar (each bar listens).
//   qs ipc call controlcenter toggle
Singleton {
    signal toggleControlCenter()

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { toggleControlCenter() }
    }
}
