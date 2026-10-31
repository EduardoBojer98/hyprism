pragma Singleton
import Quickshell
import QtQuick

// On-screen keyboard (squeekboard). Never pops up by itself; only the bar button shows/hides it.
// Shared by the bars on both screens.
Singleton {
    property bool visible: false

    function toggle() {
        visible = !visible
        Quickshell.execDetached(["busctl", "--user", "call", "sm.puri.OSK0", "/sm/puri/OSK0",
                                 "sm.puri.OSK0", "SetVisible", "b", visible ? "true" : "false"])
    }
}
