pragma Singleton
import Quickshell
import QtQuick

// Where the last bar or dock click happened, so the panel it opens can sit right beside it.
// BarItem calls take() just before its pressed signal; CursorPopup.show() uses it when it is fresh
// (opened from a keyboard shortcut instead, a panel falls back to its usual place).
Singleton {
    property var screen: null
    property rect rect: Qt.rect(0, 0, 0, 0)    // the clicked item, in the screen's logical pixels
    property string edge: "top"                // which screen edge the item sits on
    property real at: 0                        // when (ms since epoch)

    readonly property bool fresh: Date.now() - at < 500
    // origin: where the item's window starts on the screen; a bar's window is anchored to its edge, so
    // by default it follows from the window's own size (the dock passes its own, it sits beside the bar)
    function take(item, edge, origin) {
        const win = item?.QsWindow?.window
        if (!win?.screen) return
        const s = win.screen
        origin = origin ?? Qt.point(edge === "right" ? s.width - win.width : 0, edge === "bottom" ? s.height - win.height : 0)
        const p = item.mapToItem(null, 0, 0)
        screen = s
        rect = Qt.rect(origin.x + p.x, origin.y + p.y, item.width, item.height)
        this.edge = edge
        at = Date.now()
    }
}
