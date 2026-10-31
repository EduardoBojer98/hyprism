pragma Singleton
import Quickshell
import QtQuick

// What a hot corner can do (HotCorners.qml runs them, Settings > Hot Corners lists them).
Singleton {
    readonly property var list: [
        { id: "", name: "Nothing" },
        { id: "mission", name: "Mission Control" },
        { id: "launcher", name: "Spotlight" },
        { id: "controlcenter", name: "Control Center" },
        { id: "notifications", name: "Notifications" },
        { id: "lock", name: "Lock screen" }
    ]
    function name(id) { return list.find(a => a.id === id)?.name ?? "Nothing" }
    function run(id) {
        switch (id) {
        case "mission": MissionControl.toggle(); break
        case "launcher": Launcher.toggle(); break
        case "controlcenter": ControlCenter.toggle(); break
        case "notifications": NotificationCenter.toggle(); break
        case "lock": Quickshell.execDetached(["loginctl", "lock-session"]); break
        }
    }
}
