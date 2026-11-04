import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

// The one popup framework: a floating panel that opens right beside the bar or dock item that was
// clicked (Anchor), or, from a keyboard shortcut, in its usual place on the monitor the pointer is
// on; always kept inside that monitor and clear of the bar and dock. It moves the theme's way
// (Theme.enter / exit / curve / travel / startScale) out of the trigger's side, and never blocks
// input: it takes clicks and keys from the first frame, and lets go of them the moment it closes. It takes the keyboard while
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
    // opened from a bar or dock item: that item, in the screen's logical pixels, and its edge
    property var anchorRect: null
    property string anchorEdge: barEdge
    readonly property string fromEdge: anchorRect ? anchorEdge : barEdge   // the side it moves out of
    // tallest a panel can be on its screen, between the bar and dock (callers cap boxHeight with it)
    readonly property int maxHeight: (targetScreen?.height ?? 1000) - Theme.reserveTop - Theme.reserveBottom - edge * 2
    // Where the box goes. "top" / "topLeft" / "topRight" mean "beside the bar": under a top bar,
    // above a bottom bar, next to a side rail (Left = its top end, Right = its bottom end).
    // Launcher placements: "strip" (across the top edge), "corner" (above the Start button),
    // "half" (the right half, full height), "column" (a full-height column on the left),
    // "island" (above the bottom island), "fullscreen", "center", "cursor".
    function place(w, h, W, H) {
        const p = placement, l = leftReserve, r = W - w - rightReserve, t = topReserve, b = H - h - bottomReserve
        const cx = (W - w) / 2
        const fit = (v, lo, hi) => Math.max(lo, Math.min(v, Math.max(lo, hi)))
        // beside the clicked item, centred on it along its edge (large launcher layouts keep their own place)
        if (anchorRect && !["strip", "half", "column", "fullscreen"].includes(p)) {
            const a = anchorRect, g = Theme.popupGap
            if (anchorEdge === "top") return [fit(a.x + a.width / 2 - w / 2, l, r), Math.max(a.y + a.height, Theme.reserveTop) + g]
            if (anchorEdge === "bottom") return [fit(a.x + a.width / 2 - w / 2, l, r), Math.min(a.y, H - Theme.reserveBottom) - g - h]
            if (anchorEdge === "left") return [Math.max(a.x + a.width, Theme.reserveLeft) + g, fit(a.y + a.height / 2 - h / 2, t, b)]
            return [Math.min(a.x, W - Theme.reserveRight) - g - w, fit(a.y + a.height / 2 - h / 2, t, b)]
        }
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

    function show() {
        if (Anchor.fresh && Anchor.screen) {   // clicked in the bar or dock: open there, now
            targetScreen = Anchor.screen
            anchorRect = Anchor.rect
            anchorEdge = Anchor.edge
            Anchor.at = 0
            open = true
            opened()
        } else {
            anchorRect = null
            locate.running = true
        }
    }
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

        // while closing, the window still shows the fade but takes no input at all
        mask: Region { item: popup.open ? catcher : null }
        MouseArea { id: catcher; anchors.fill: parent; enabled: popup.open; onClicked: popup.hide() }   // click outside
        Rectangle {   // optional dimmed screen behind the box
            anchors.fill: parent
            visible: popup.dim > 0
            color: "black"
            opacity: popup.open ? popup.dim * (Theme.light ? 0.6 : 1) : 0
            Behavior on opacity { NumberAnimation { duration: popup.open ? Theme.enter : Theme.exit } }
        }

        Item {
            id: box
            width: popup.boxWidth
            height: popup.boxHeight
            readonly property var at: popup.place(width, height, win.width, win.height)
            x: at[0]
            y: at[1]
            // out of the trigger's side: travel + start scale + fade on the theme's curve; out faster than in.
            // Only transform and opacity move, so it stays on the compositor's fast path at 120 Hz.
            property real t: popup.open ? 1 : 0
            // opened from a keyboard shortcut (no clicked item): no motion at all, it's used too often to wait for
            Behavior on t { NumberAnimation { duration: !popup.anchorRect ? 0 : popup.open ? Theme.enter : Theme.exit
                                              easing.type: popup.open ? Easing.BezierSpline : Easing.OutCubic
                                              easing.bezierCurve: Theme.curve } }
            opacity: Math.min(1, t * 1.6)
            readonly property real off: (1 - t) * Theme.travel
            readonly property real sc: Theme.startScale + (1 - Theme.startScale) * t
            transform: [
                Scale {
                    origin.x: popup.fromEdge === "left" ? 0 : popup.fromEdge === "right" ? box.width : box.width / 2
                    origin.y: popup.fromEdge === "top" ? 0 : popup.fromEdge === "bottom" ? box.height : box.height / 2
                    xScale: box.sc; yScale: box.sc
                },
                Translate {
                    x: popup.fromEdge === "left" ? -box.off : popup.fromEdge === "right" ? box.off : 0
                    y: popup.fromEdge === "top" ? -box.off : popup.fromEdge === "bottom" ? box.off : 0
                }
            ]

            MouseArea { anchors.fill: parent; z: -1 }   // clicks inside don't close
            // depth, the theme's way (Theme.depth): a soft shadow, a hard offset block, or the frame alone
            RectangularShadow {
                visible: Theme.depth === "soft"
                anchors.fill: parent
                z: -2
                offset.y: 10
                blur: 28
                spread: -4
                radius: Theme.radiusLarge
                color: Qt.rgba(0, 0, 0, Theme.light ? 0.18 : 0.42)
            }
            RectangularShadow {   // glow: a haze in the accent around the panel (Console's phosphor)
                visible: Theme.depth === "glow"
                anchors.fill: parent
                z: -2
                blur: 34
                spread: 2
                radius: Theme.radiusLarge
                color: Qt.alpha(Theme.accent, 0.22)
            }
            Repeater {   // brackets: accent corner marks over the panel's frame (Console)
                model: Theme.current.popup.decor === "brackets" ? [[0, 0], [1, 0], [0, 1], [1, 1]] : []
                Item {
                    id: mark
                    required property var modelData
                    z: 10
                    width: 14; height: 14
                    x: modelData[0] ? box.width - width + 2 : -2
                    y: modelData[1] ? box.height - height + 2 : -2
                    Rectangle { width: parent.width; height: 2; color: Theme.accent; y: mark.modelData[1] ? parent.height - 2 : 0 }
                    Rectangle { width: 2; height: parent.height; color: Theme.accent; x: mark.modelData[0] ? parent.width - 2 : 0 }
                }
            }
            Rectangle {
                visible: Theme.depth === "hard"
                anchors.fill: parent
                anchors { leftMargin: 7; topMargin: 7; rightMargin: -7; bottomMargin: -7 }
                z: -2
                color: Theme.stroke
            }
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
