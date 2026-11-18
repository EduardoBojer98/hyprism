pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Quick Look: a large preview of a file (QuickLookView). In the launcher: select a file or folder result with ↑↓, then
// Space (or Ctrl+Y at any time); it opens over the launcher and follows the selection. Anywhere else, e.g. a file
// manager's custom action:   qs ipc call quicklook open /path/to/file
// Space, Esc or a click beside it closes it; Enter opens the file in its app. Off in Settings > Search & Launcher.
Singleton {
    id: root

    property string path: ""
    property bool inLauncher: false          // drawn over the launcher (Launcher.qml), not in its own popup
    readonly property bool shown: path !== "" && (inLauncher || popup.open)

    function open(p, fromLauncher) {
        if (!Config.launcher.quickLook || !p) return
        path = p
        inLauncher = fromLauncher === true
        if (!inLauncher && !popup.open) popup.show()
    }
    function close() { inLauncher = false; popup.hide(); if (!popup.open) path = "" }
    function launch() { const p = path; close(); Launcher.close(); Quickshell.execDetached(["xdg-open", p]) }

    IpcHandler {
        target: "quicklook"
        function open(path: string): void { root.open(path.replace(/^file:\/\//, ""), false) }
        function close(): void { root.close() }
    }

    CursorPopup {
        id: popup
        name: "quicklook"
        placement: "fullscreen"
        dim: 0.4
        readonly property real sw: targetScreen?.width ?? 1600
        readonly property real sh: targetScreen?.height ?? 1000
        boxWidth: Math.min(1100, sw * 0.72)
        boxHeight: Math.min(820, sh - bottomReserve - Math.max(topReserve, sh * 0.1))   // fits under where "fullscreen" puts the top
        focusItem: sheet
        onClosed: if (!root.inLauncher) root.path = ""

        QuickLookView {
            id: sheet
            width: popup.boxWidth
            height: popup.boxHeight
            path: root.inLauncher ? "" : root.path
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Space || event.key === Qt.Key_Escape) root.close()
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.launch()
                else if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) sheet.scroll(event.key === Qt.Key_Down ? 60 : 400)
                else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) sheet.scroll(event.key === Qt.Key_Up ? -60 : -400)
                else return
                event.accepted = true
            }
        }
    }
}
