pragma Singleton
import Quickshell
import QtQuick

// The order of open apps and windows on the dock, the floating one and the one in the bar alike: by workspace,
// then as they opened. Dragging one sets an order of its own, kept for this session; ones opened later join after.
// shortcut: the dragged order is not saved, a shell restart goes back to by-workspace; save it if that annoys.
Singleton {
    id: root
    property var manual: ({ windows: [], apps: [] })   // window addresses / app ids, in the order the user left them

    function ws(t) { const id = t?.workspace?.id ?? 0; return id > 0 ? id : 1e6 }   // minimised and special last
    // list sorted for `group`: dragged ones first in their order, the rest by workspace, then as given
    function sort(list, group, key, wsOf) {
        const m = manual[group] ?? []
        return list.map((x, i) => ({ x: x, i: i, m: m.indexOf(key(x)), w: wsOf(x) }))
            .sort((a, b) => (a.m < 0) - (b.m < 0) || (a.m >= 0 ? a.m - b.m : a.w - b.w || a.i - b.i))
            .map(o => o.x)
    }
    // `key` dragged to just before `before` ("" = the end); `shown`: the group's keys as they are now
    function move(group, shown, key, before) {
        const ids = shown.filter(k => k !== key)
        const at = before ? ids.indexOf(before) : -1
        ids.splice(at < 0 ? ids.length : at, 0, key)
        if (JSON.stringify(ids) === JSON.stringify(manual[group] ?? [])) return
        const next = Object.assign({}, manual)
        next[group] = ids
        manual = next
    }
}
