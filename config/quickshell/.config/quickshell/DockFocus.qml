pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

// "Focus the dock": the dock of the focused screen takes the keyboard (Dock.qml), arrows or Tab move along its
// icons, Enter / Space opens one, Menu or Shift+F10 opens its menu, Escape leaves.
// From a shortcut: qs ipc call dock focus
Singleton {
    id: root
    property bool active: false
    property var screen: null     // the dock that has the keyboard

    function enter() {
        screen = Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        active = true
    }
    function leave() { active = false }

    IpcHandler {
        target: "dock"
        function focus(): void { root.enter() }
    }
}
