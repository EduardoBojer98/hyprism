pragma Singleton
import Quickshell
import QtQuick

// Notification history now lives in the Control Center, under its controls (the bell in the bar,
// Super+N, `qs ipc call notifications toggle` open it scrolled to the notifications). This keeps
// the folding state and the old entry points.
Singleton {
    id: root

    readonly property bool open: ControlCenter.open
    property var unfolded: ({})            // app name -> true

    function toggle() { ControlCenter.toggleNotifications() }
    function fold(app, on) { const u = Object.assign({}, unfolded); if (on) delete u[app]; else u[app] = true; unfolded = u }
}
