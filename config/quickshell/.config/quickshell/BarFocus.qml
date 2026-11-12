pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// "Focus the bar": the bar of the focused screen takes the keyboard (Bar.qml), BarItem moves along it
// with arrows or Tab, Enter / Space activates, Escape leaves. From a shortcut: qs ipc call bar focus
Singleton {
    id: root
    property bool active: false
    property var screen: null     // the bar that has the keyboard

    function enter() {
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        active = true
    }
    function leave() { active = false }

    IpcHandler {
        target: "bar"
        function focus(): void { root.enter() }
    }
}
