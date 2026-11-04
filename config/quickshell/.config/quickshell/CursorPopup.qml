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
    property string placement: "cursor"        // see place() below
    property bool open: false
    property real dim: 0                       // 0..1: darken the rest of the screen while open
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
    // room the bar takes on each side (the theme decides the edge), plus a gap
    readonly property int topReserve: Theme.reserveTop + edge
    readonly property int bottomReserve: Theme.reserveBottom + edge
    readonly property int leftReserve: Theme.reserveLeft + edge
    readonly property int rightReserve: Theme.reserveRight + edge
    readonly property string barEdge: Theme.barEdge
    // Where the box goes. "top" / "topLeft" / "topRight" mean "beside the bar": under a top bar,
    // above a bottom bar, next to a side rail (Left = its top end, Right = its bottom end).
    // Launcher placements: "strip" (across the top edge), "corner" (above the Start button),
    // "half" (the right half, full height), "column" (a full-height column on the left),
    // "island" (above the bottom island), "fullscreen", "center", "cursor".
    function place(w, h, W, H) {
        const p = placement, l = leftReserve, r = W - w - rightReserve, t = topReserve, b = H - h - bottomReserve
        const cx = (W - w) / 2
        if (p === "center") return [cx, Math.max(t, H * 0.2)]
        if (p === "fullscreen") return [cx, Math.max(t, H * 0.1)]   // a large centred sheet over a dark screen
        if (p === "strip") return [0, Theme.reserveTop]
        if (p === "half") return [W - w - Theme.reserveRight, Theme.reserveTop]
        if (p === "column") return [Theme.reserveLeft, Theme.reserveTop]
        if (p === "corner") return [l, b]
        if (p === "island") return [cx, b]
        if (p === "top" || p === "topLeft" || p === "topRight") {
            if (barEdge === "left" || barEdge === "right") {
                const x = barEdge === "left" ? l : r
                return [x, p === "topLeft" ? t : p === "top" ? (H - h) / 2 : b]
            }
            const x = p === "top" ? cx : p === "topLeft" ? l : r
            return [x, barEdge === "bottom" ? b : t]
        }
        return [Math.max(l, Math.min(cursorX - w / 2, r)), Math.max(t, Math.min(cursorY - 28, b))]
    }

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
        Rectangle {   // optional dimmed screen behind the box
            anchors.fill: parent
            visible: popup.dim > 0
            color: "black"
            opacity: popup.open ? popup.dim : 0
            Behavior on opacity { NumberAnimation { duration: Theme.anim } }
        }

        Item {
            id: box
            width: popup.boxWidth
            height: popup.boxHeight
            readonly property var at: popup.place(width, height, win.width, win.height)
            x: at[0]
            y: at[1]
            // a plain drop-down: slides 8px out of the bar's side while it fades in (up from a bottom bar,
            // sideways from a rail); the same in every theme, no scaling, no bounce
            property real drop: popup.open ? 0 : 8
            opacity: popup.open ? 1 : 0
            transform: Translate {
                x: popup.barEdge === "left" ? -box.drop : popup.barEdge === "right" ? box.drop : 0
                y: popup.barEdge === "bottom" ? box.drop : popup.barEdge === "top" ? -box.drop : 0
            }
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on drop { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

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
