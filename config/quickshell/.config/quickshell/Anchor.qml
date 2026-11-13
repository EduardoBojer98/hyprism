pragma Singleton
import Quickshell
import QtQuick

// Where the panel a bar or dock item opens should sit: right beside that item.
//   take()     a click: BarItem calls it just before its pressed signal; CursorPopup.show() uses it when fresh.
//   register() a bar item names the panel it opens (BarItem.opens), so a panel opened from a keyboard
//              shortcut still appears beside its own item on the pointer's monitor (CursorPopup: find()).
Singleton {
    id: root
    property var screen: null
    property rect rect: Qt.rect(0, 0, 0, 0)    // the clicked item, in the screen's logical pixels
    property string edge: "top"                // which screen edge the item sits on
    property real at: 0                        // when (ms since epoch)

    readonly property bool fresh: Date.now() - at < 500
    // an item's place on its screen. origin: where the item's window starts; a bar's window is anchored
    // to its edge, so by default it follows from the window's own size (the dock passes its own)
    function placeOf(item, edge, origin) {
        const win = item?.QsWindow?.window
        if (!win?.screen) return null
        const s = win.screen
        origin = origin ?? Qt.point(edge === "right" ? s.width - win.width : 0, edge === "bottom" ? s.height - win.height : 0)
        const p = item.mapToItem(null, 0, 0)
        return { screen: s, rect: Qt.rect(origin.x + p.x, origin.y + p.y, item.width, item.height), edge: edge }
    }
    function take(item, edge, origin) {
        const p = placeOf(item, edge, origin)
        if (!p) return
        screen = p.screen; rect = p.rect; this.edge = edge
        at = Date.now()
    }

    // which screen each open panel is on (CursorPopup keeps it), so only that screen's bar item lights up
    property var openOn: ({})
    function opened(name, screen) { const o = Object.assign({}, openOn); o[name] = screen; openOn = o }
    function closed(name) { if (openOn[name] === undefined) return; const o = Object.assign({}, openOn); delete o[name]; openOn = o }

    property var triggers: []                  // bar items that open a panel: { name, item }
    function register(name, item) { triggers = triggers.concat([{ name: name, item: item }]) }
    function unregister(item) { triggers = triggers.filter(t => t.item !== item) }
    // the item on this screen that opens panel `name` (shown, in a window that is up), as placeOf() gives it
    function find(name, screen) {
        for (const t of triggers) {
            if (t.name !== name || !t.item.visible || t.item.width <= 0) continue
            const p = placeOf(t.item, t.item.edge, t.item.origin)
            if (p && p.screen === screen && t.item.QsWindow.window.visible) return p
        }
        return null
    }
}
