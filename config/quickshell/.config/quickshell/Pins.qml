pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Screenshots pinned on top of everything (`screenshot pin`). Each pin is a small window on the Overlay layer.
//   qs ipc call pins add <file> <x> <y> <w> <h>   x, y, w, h: where the picture was taken, in layout coordinates
//   qs ipc call pins clear | count
// Pins: drag with the left button, scroll to zoom (25-300 %), middle or double click closes, right click copies.
// The file lives in $XDG_RUNTIME_DIR/hyprism-pins/ and is deleted when its pin closes.
Singleton {
    id: root

    readonly property string folder: (Quickshell.env("XDG_RUNTIME_DIR") ?? "") + "/hyprism-pins/"
    readonly property int maxPins: 12
    property var pins: []   // oldest first: { path, x, y, w, h }

    // paths come over IPC, so they are data: only plain names inside the pins folder
    function allowed(path: string): bool {
        return root.folder !== "/hyprism-pins/" && path.startsWith(root.folder) && /^[A-Za-z0-9_.\/-]+$/.test(path) && path.indexOf("..") < 0
    }
    function remove(pin) {
        root.pins = root.pins.filter(p => p !== pin)
        if (root.allowed(pin.path)) Quickshell.execDetached(["rm", "-f", "--", pin.path])
    }
    function add(path: string, x: real, y: real, w: real, h: real): string {
        if (!root.allowed(path)) return "refused: the file must be inside " + root.folder
        if (!(w > 0 && h > 0)) return "refused: empty size"
        const list = root.pins.slice()
        while (list.length >= root.maxPins) {
            const old = list.shift()
            Quickshell.execDetached(["rm", "-f", "--", old.path])
        }
        list.push({ path: path, x: x, y: y, w: w, h: h })
        root.pins = list
        return "ok"
    }
    function clear() { for (const p of root.pins.slice()) root.remove(p) }

    IpcHandler {
        target: "pins"
        function add(path: string, x: real, y: real, w: real, h: real): string { return root.add(path, x, y, w, h) }
        function clear(): void { root.clear() }
        function count(): int { return root.pins.length }
    }

    Variants {
        model: root.pins

        PanelWindow {
            id: pin
            required property var modelData
            property real zoom: 1
            // stays on the screen it was taken on (shortcut: dragging across screens is not followed)
            screen: Quickshell.screens.find(s => modelData.x >= s.x && modelData.x < s.x + s.width && modelData.y >= s.y && modelData.y < s.y + s.height) ?? Quickshell.screens[0]
            property real left: modelData.x - (screen?.x ?? 0)
            property real top: modelData.y - (screen?.y ?? 0)

            anchors { left: true; top: true }
            margins { left: Math.round(pin.left); top: Math.round(pin.top) }
            implicitWidth: Math.max(1, Math.round(modelData.w * zoom))
            implicitHeight: Math.max(1, Math.round(modelData.h * zoom))
            exclusionMode: ExclusionMode.Ignore   // so x, y are the screen's own, not shifted by the bar
            color: "transparent"
            WlrLayershell.namespace: "qs-pin"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Item {
                anchors.fill: parent
                Accessible.role: Accessible.Graphic
                Accessible.name: "Pinned screenshot"

                Image {
                    anchors.fill: parent
                    source: "file://" + pin.modelData.path
                    cache: false
                    smooth: true
                }
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border { width: 1; color: Theme.accent }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    property real sx: 0
                    property real sy: 0
                    onPressed: mouse => { sx = mouse.x; sy = mouse.y }
                    onPositionChanged: mouse => {
                        if (!(pressedButtons & Qt.LeftButton)) return
                        pin.left += mouse.x - sx
                        pin.top += mouse.y - sy
                    }
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) root.remove(pin.modelData)
                        else if (mouse.button === Qt.RightButton) Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", pin.modelData.path])
                    }
                    onDoubleClicked: root.remove(pin.modelData)
                    onWheel: wheel => pin.zoom = Math.max(0.25, Math.min(3, pin.zoom * (wheel.angleDelta.y > 0 ? 1.1 : 1 / 1.1)))
                }
            }
        }
    }
}
