import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

// The one popup framework: a floating glass box that opens at the mouse cursor, on the monitor
// the cursor is on, pushed back inside that monitor near its edges. It takes the keyboard while
// open; Esc or a click outside closes it, on any monitor. Used by the launcher, clipboard, and other quick panels.
//
//   CursorPopup { id: p; name: "launcher"; boxWidth: 640; boxHeight: content.implicitHeight
//                 SomeContent { id: content; anchors.fill: parent } }
//   p.show() / p.hide() / p.toggle()
Scope {
    id: popup

    property string name: "popup"              // layer namespace: qs-<name> (blurred by Hyprland)
    property int boxWidth: 600
    property int boxHeight: 400
    property string placement: "cursor"        // "cursor": under the pointer; "center"; "top" / "topLeft" / "topRight" (under the bar)
    property bool open: false
    readonly property bool visible: open || box.opacity > 0
    property var targetScreen: Quickshell.screens[0]
    property real cursorX: 0                   // pointer, in the target monitor's logical pixels
    property real cursorY: 0
    property Item focusItem                    // gets keyboard focus on open
    default property alias content: box.data
    readonly property alias box: box

    signal opened()
    signal closed()

    readonly property int edge: Theme.spaceM
    readonly property int topReserve: 38        // keep clear of the bar (30) with a small gap

    function show() { locate.running = true }
    function hide() { if (open) { open = false; closed() } }
    function toggle() { if (open) hide(); else show() }

    // Pointer position and monitor layout from Hyprland, in one call
    Process {
        id: locate
        command: ["sh", "-c", "printf '{\"cursor\":%s,\"monitors\":%s}' \"$(hyprctl -j cursorpos)\" \"$(hyprctl -j monitors)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let target = null, x = 0, y = 0
                try {
                    const d = JSON.parse(text)
                    for (const m of d.monitors) {
                        const rotated = m.transform % 2 === 1
                        const w = (rotated ? m.height : m.width) / m.scale
                        const h = (rotated ? m.width : m.height) / m.scale
                        if (d.cursor.x >= m.x && d.cursor.x < m.x + w && d.cursor.y >= m.y && d.cursor.y < m.y + h) {
                            target = Quickshell.screens.find(s => s.name === m.name) ?? null
                            x = d.cursor.x - m.x
                            y = d.cursor.y - m.y
                        }
                    }
                } catch (e) {}
                popup.targetScreen = target ?? Quickshell.screens[0]
                popup.cursorX = target ? x : popup.targetScreen.width / 2
                popup.cursorY = target ? y : popup.targetScreen.height / 3
                popup.open = true
                popup.opened()
            }
        }
    }

    PanelWindow {
        id: win
        screen: popup.targetScreen
        visible: popup.visible
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-" + popup.name
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: popup.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        MouseArea { anchors.fill: parent; onClicked: popup.hide() }   // click outside

        Item {
            id: box
            width: popup.boxWidth
            height: popup.boxHeight
            x: popup.placement === "center" || popup.placement === "top" ? (win.width - width) / 2
               : popup.placement === "topRight" ? win.width - width - popup.edge
               : popup.placement === "topLeft" ? popup.edge
               : Math.max(popup.edge, Math.min(popup.cursorX - width / 2, win.width - width - popup.edge))
            y: popup.placement === "center" ? win.height * 0.22
               : popup.placement === "topRight" || popup.placement === "topLeft" || popup.placement === "top" ? popup.topReserve
               : Math.max(popup.topReserve, Math.min(popup.cursorY - 28, win.height - height - popup.edge))

            opacity: popup.open ? 1 : 0
            scale: popup.open ? 1 : 0.96
            transformOrigin: Item.Top
            Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

            MouseArea { anchors.fill: parent; z: -1 }   // clicks inside don't close
            Keys.onEscapePressed: popup.hide()
        }

        onVisibleChanged: if (visible && popup.focusItem) popup.focusItem.forceActiveFocus()
    }

    // the catcher above only covers this monitor; Hyprland reports clicks on the others
    HyprlandFocusGrab {
        windows: [win]
        active: popup.open
        onCleared: popup.hide()
    }

    onOpenChanged: if (open && focusItem) focusItem.forceActiveFocus()
}
