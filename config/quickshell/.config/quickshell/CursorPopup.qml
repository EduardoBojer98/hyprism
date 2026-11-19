import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// The one popup framework: a floating panel that opens right beside the bar or dock item that was
// clicked (Anchor), or, from a keyboard shortcut, in its usual place on the monitor the pointer is
// on; always kept inside that monitor and clear of the bar and dock. It moves the theme's way
// (Theme.enter / exit / curve / travel / startScale) out of the trigger's side, and never blocks
// input: it takes clicks and keys from the first frame, and lets go of them the moment it closes. It takes the keyboard while
// open; Esc or a click outside closes it, on any monitor. Used by the launcher, clipboard, and other quick panels.
//
//   CursorPopup { id: p; name: "launcher"; boxWidth: 640; boxHeight: content.implicitHeight   (its natural height)
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
    property bool darkScrim: false             // keep the dim full strength in light themes too (Launchpad)
    readonly property bool visible: open || box.opacity > 0
    property var targetScreen: Quickshell.screens[0]
    property real cursorX: 0                   // pointer, in the target monitor's logical pixels
    property real cursorY: 0
    property Item focusItem                    // gets keyboard focus on open
    default property alias content: scroll.flickableData
    readonly property alias box: box
    readonly property alias overlay: overlay

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
    // tallest a panel can be on its screen, between the bar and dock. Callers needn't cap boxHeight with it:
    // a taller panel scrolls inside its frame (scroll bar, a fade at the cut edge, the focused control kept in view)
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

    // [x, y, height]: place() for a height capped to the room between bar and dock, kept on the screen
    function frame(w, h, W, H) {
        const flush = ["strip", "half", "column", "fullscreen"].includes(placement)   // edge-to-edge layouts
        // opened from a bottom bar it sits popupGap above the bar, not edge: the cap must leave it that room
        const below = flush ? 0 : anchorRect && anchorEdge === "bottom" ? Theme.popupGap : edge
        const lo = Theme.reserveTop, hi = H - Theme.reserveBottom - below
        h = Math.min(h, hi - lo - (flush ? 0 : edge))
        const at = place(w, h, W, H), y = Math.max(lo, at[1])
        return [Math.max(0, Math.min(at[0], W - w)), y, Math.max(0, Math.min(h, hi - y))]
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
            locating = true
            locate.running = true
        }
    }
    // a close while Hyprland is still being asked where the pointer is cancels the open
    property bool locating: false
    function hide() { locating = false; if (open) { open = false; closed() } }
    onOpenChanged: {
        if (open) Anchor.opened(name, targetScreen); else Anchor.closed(name)
        if (open) { scroll.contentY = 0; takeFocus() }
    }
    function takeFocus() { (focusItem ?? box).forceActiveFocus() }
    onTargetScreenChanged: if (open) Anchor.opened(name, targetScreen)
    function toggle() { if (open || locating) hide(); else show() }

    // Pointer position and monitor layout from Hyprland, in one call
    Process {
        id: locate
        command: ["sh", "-c", "printf '{\"cursor\":%s,\"monitors\":%s}' \"$(hyprctl -j cursorpos)\" \"$(hyprctl -j monitors)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!popup.locating) return
                popup.locating = false
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
                // from a shortcut: beside this panel's own bar item on that monitor, as if it were clicked
                const own = Anchor.find(popup.name, popup.targetScreen)
                if (own) { popup.anchorRect = own.rect; popup.anchorEdge = own.edge }
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
        MouseArea { id: catcher; Accessible.ignored: true; anchors.fill: parent; enabled: popup.open; onClicked: popup.hide() }   // click outside
        Rectangle {   // optional dimmed screen behind the box
            anchors.fill: parent
            visible: popup.dim > 0
            color: "black"
            opacity: popup.open ? popup.dim * (Theme.light && !popup.darkScrim ? 0.6 : 1) : 0
            Behavior on opacity { NumberAnimation { duration: popup.open ? Theme.enter : Theme.exit } }
        }

        Item {
            id: box
            width: popup.boxWidth
            readonly property var at: popup.frame(width, popup.boxHeight, win.width, win.height)
            x: at[0]
            y: at[1]
            height: at[2]
            // taller than the room: the content scrolls inside the panel's frame, with a fade at the cut edge
            readonly property bool overflow: popup.boxHeight > height + 1
            // the panel surface's own corner (its first child, usually a Glass)
            readonly property real radius: scroll.contentItem.children[0]?.radius ?? Theme.radiusPanel
            // out of the trigger's side: travel + start scale + fade on the theme's curve; out faster than in.
            // Only transform and opacity move, so it stays on the compositor's fast path at 120 Hz.
            property real t: popup.open ? 1 : 0
            // opened from a keyboard shortcut (no clicked item): it's used too often to wait for, so only a quick
            // fade and a slight grow in place, no travel; motion off still means none
            readonly property bool keyed: !popup.anchorRect
            Behavior on t { NumberAnimation { duration: box.keyed ? (popup.open ? Math.min(Theme.enter, 150) : Math.min(Theme.exit, 110))
                                                        : popup.open ? Theme.enter : Theme.exit
                                              easing.type: popup.open ? Easing.BezierSpline : Easing.OutCubic
                                              easing.bezierCurve: Theme.curve } }
            opacity: Math.min(1, t * 1.6)
            readonly property real off: keyed ? 0 : (1 - t) * Theme.travel
            readonly property real sc: keyed ? (Theme.moves ? 0.97 + 0.03 * t : 1) : Theme.startScale + (1 - Theme.startScale) * t
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

            MouseArea { anchors.fill: parent; z: -2 }   // clicks inside don't close
            PopupDepth { anchors.fill: parent; z: -1; radius: box.radius }

            Item {
                anchors.fill: parent
                // cut to the panel's rounded shape while it scrolls (a plain clip would square the corners)
                layer.enabled: box.overflow && box.radius > 0
                layer.effect: MultiEffect { maskEnabled: true; maskSource: shape; maskThresholdMin: 0.5; maskSpreadAtMin: 1 }

                Flickable {
                    id: scroll
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: popup.boxHeight
                    clip: box.overflow
                    interactive: box.overflow
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: GlassScrollBar {}
                }
                MoreBelow { flick: scroll; anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: Theme.spaceXl }
                MoreBelow {   // and "more above", the same fade turned over
                    flick: scroll
                    visible: scroll.contentY > 1
                    rotation: 180
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: Theme.spaceXl
                }
            }
            Rectangle { id: shape; anchors.fill: parent; radius: box.radius; visible: false; layer.enabled: box.overflow }
            Rectangle {   // the frame's edge where the content is cut off
                visible: box.overflow
                anchors.fill: parent
                z: 5
                radius: box.radius
                color: "transparent"
                border { color: Theme.stroke; width: Theme.line }
            }
            PopupDepth { anchors.fill: parent; z: 10; over: true }

            // keep the keyboard's place in view: Tab or the arrows into a row below the cut scroll to it
            readonly property Item focused: Window.activeFocusItem
            onFocusedChanged: {
                let p = focused
                while (p && p !== box) p = p.parent
                // the focused row was rebuilt or removed (a list changed): back to the panel, so Escape still works
                if (!p) { if (popup.open) Qt.callLater(popup.takeFocus); return }
                if (!overflow) return
                const y = focused.mapToItem(scroll.contentItem, 0, 0).y, pad = Theme.spaceXl
                if (y < scroll.contentY + pad) scroll.contentY = Math.max(0, y - pad)
                else if (y + focused.height > scroll.contentY + height - pad)
                    scroll.contentY = Math.min(scroll.contentHeight - height, y + focused.height - height + pad)
            }
            Keys.onEscapePressed: popup.hide()
        }

        // over everything, the whole screen: a caller's own layer (the launcher's Quick Look) via `parent: popup.overlay`
        Item { id: overlay; anchors.fill: parent; z: 50 }
        // the keyboard goes into the panel on open, so Escape always reaches the box
        onVisibleChanged: if (visible) popup.takeFocus()
    }

    // the catcher above only covers this monitor; Hyprland reports clicks on the others
    HyprlandFocusGrab {
        windows: [win]
        active: popup.open
        onCleared: popup.hide()
    }

}
