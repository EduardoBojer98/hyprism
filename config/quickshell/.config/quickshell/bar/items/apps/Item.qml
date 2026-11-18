import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import qs

// The dock inside the bar: pinned apps, then other running ones; a mark under each open app,
// the accent under the focused one. Click: bring it up (again: its next window) or start it;
// middle-click: a new window; right-click: its windows and actions. Drag any app to reorder it: pinned ones are
// saved, open ones keep the order for this session (DockOrder: by workspace until then).
Item {
    id: apps
    required property var bar
    readonly property int count: DesktopEntries.applications.values.length   // lookups re-run once apps have loaded
    function entryFor(appId) { return count ? DesktopEntries.heuristicLookup(appId) : null }
    function addr(t) { return "0x" + String(t.address).replace(/^0x/, "") }
    readonly property var running: DockOrder.sort(Hyprland.toplevels.values.filter(t => t.wayland && t.workspace?.monitor === bar.monitor),
                                                  "windows", addr, DockOrder.ws)
    // like the floating dock: launchers, then (unless Settings > Dock > Combine) each open window after a rule
    readonly property bool combine: Config.dock.combine
    readonly property var pinned: count ? Array.from(Config.dock.pinned).map(id => DesktopEntries.byId(id)).filter(e => e) : []
    readonly property var cells: {
        const out = pinned.map(e => ({ key: "p:" + e.id, entry: e, win: null }))
        if (combine) {
            const open = []
            for (const t of running) { const e = entryFor(t.wayland.appId); if (e && !out.some(x => x.entry.id === e.id) && !open.some(x => x.entry.id === e.id)) open.push({ key: "a:" + e.id, entry: e, win: null, w: DockOrder.ws(t) }) }
            return out.concat(DockOrder.sort(open, "apps", x => x.entry.id, x => x.w))
        } else if (Config.dock.showRunning && running.length) {
            out.push({ key: "rule", rule: true })
            for (const t of running) out.push({ key: "w:" + addr(t), entry: entryFor(t.wayland.appId), win: t })
        }
        return out
    }
    // a window minimised from the dock (parked on special:minimized) comes back to this screen's workspace first
    function bring(t) {
        if (t.workspace?.name !== "special:minimized") { t.wayland.activate(); return }
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.window.move({ workspace = "${bar.monitor?.activeWorkspace?.id ?? 1}", window = "address:0x${String(t.address).replace(/^0x/, "")}" })`])
    }
    function minimise(t) { Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.window.move({ workspace = "special:minimized", follow = false, window = "address:${addr(t)}" })`]) }
    function setPinned(e, pin) {
        const list = Config.dock.pinned.filter(id => id !== e.id)
        if (pin) list.push(e.id)
        Config.set("dock", "pinned", list)
    }
    // right-click: the app's windows, then what can be done with it (the floating dock's DockMenu, in the bar's look)
    function menuFor(cell) {
        const e = cell.entry, wins = cell.wins, pinned = !!e && Config.dock.pinned.includes(e.id)
        const min = t => t.workspace?.name === "special:minimized"
        const list = cell.win ? [] : wins.slice(0, 8).map(t => ({ label: (t.title || e?.name || "Window") + (min(t) ? "  (minimised)" : ""),
            icon: Quickshell.iconPath(e?.icon ?? "", "application-x-executable"), run: () => apps.bring(t) }))
        const acts = [
            e ? { label: "New window", glyph: "\u{F0415}", run: () => e.execute() } : null,
            wins.some(t => !min(t)) ? { label: "Minimise", glyph: "\u{F05B0}", run: () => wins.filter(t => !min(t)).forEach(apps.minimise) } : null,
            wins.some(min) ? { label: "Restore", glyph: "\u{F05B2}", run: () => wins.filter(min).forEach(apps.bring) } : null,
            e ? { label: pinned ? "Unpin from dock" : "Pin to dock", glyph: pinned ? "\u{F0931}" : "\u{F0403}", run: () => apps.setPinned(e, !pinned) } : null,
            wins.length ? { label: cell.win ? "Close window" : wins.length > 1 ? `Quit (${wins.length} windows)` : "Quit", glyph: "\u{F0156}",
                            danger: true, run: () => wins.forEach(t => t.wayland?.close()) } : null
        ].filter(x => x)
        if (list.length && acts.length) acts[0].sep = true
        menu.rows = list.concat(acts)
        menu.anchorItem = cell
        menu.open = true
    }
    ShellMenu { id: menu }

    // an open app or window dragged along its own group takes its place at once (DockOrder)
    property string runDrag: ""
    function cellKey(c) { return c.win ? addr(c.win) : c.entry?.id ?? "" }
    function dragRunning(cell, p) {
        const group = cell.win ? "windows" : "apps", key = cellKey(cell)
        runDrag = key
        const mid = c => bar.vertical ? c.y + c.height / 2 : c.x + c.width / 2
        const cells = []
        for (let i = 0; i < cellRepeater.count; i++) {
            const c = cellRepeater.itemAt(i)
            if (c && !c.rule && !c.isPinned && (c.win !== null) === (group === "windows")) cells.push(c)
        }
        cells.sort((a, b) => mid(a) - mid(b))
        const before = cells.find(c => cellKey(c) !== key && mid(c) > (bar.vertical ? p.y : p.x))
        DockOrder.move(group, cells.map(cellKey), key, before ? cellKey(before) : "")
    }
    readonly property int icon: Math.max(16, Math.min(Math.round(bar.thickness * 0.62), 30))

    // Drag a pinned app along the bar to reorder it (the same list as the floating dock); an accent line shows
    // where it lands, and the order is saved on release
    property string dragId: ""
    property int dropAt: -1           // insert before pinned[dropAt]; pinned.length = after the last
    function dropIndex(p) {
        for (let i = 0; i < pinned.length; i++) {
            const c = cellRepeater.itemAt(i)
            if (c && (bar.vertical ? p.y < c.y + c.height / 2 : p.x < c.x + c.width / 2)) return i
        }
        return pinned.length
    }
    function endDrag() {
        const before = pinned[dropAt]?.id ?? null
        if (dragId !== "" && dropAt >= 0 && before !== dragId) {
            // the whole saved list, so pins whose app isn't installed right now keep their place
            const ids = Config.dock.pinned.filter(id => id !== dragId)
            const at = before ? ids.indexOf(before) : ids.indexOf(pinned[pinned.length - 1].id) + 1
            ids.splice(at, 0, dragId)
            Config.set("dock", "pinned", ids)
        }
        dragId = ""
        dropAt = -1
    }
    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight
    Grid {
        id: grid
        columns: bar.vertical ? 1 : Math.max(1, visibleChildren.filter(c => c.width > 0).length)
        spacing: 4
        // cells differ in height (the divider's is short): centre them on one line
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter
        Repeater {
            id: cellRepeater
            model: ScriptModel { values: apps.cells; objectProp: "key" }   // icons are kept (and moved) while the list changes
            BarItem {
                id: app
                required property var modelData
                required property int index
                readonly property bool rule: modelData.rule === true
                readonly property var entry: modelData.entry ?? null
                readonly property var win: modelData.win ?? null
                // a launcher's own windows (it focuses them); a window cell is just its window
                readonly property var wins: win ? [win] : apps.running.filter(t => entry && apps.entryFor(t.wayland.appId)?.id === entry.id)
                readonly property bool marked: win !== null || (apps.combine && wins.length > 0)
                readonly property bool isPinned: !rule && win === null && index < apps.pinned.length
                opacity: apps.dragId !== "" && apps.dragId === entry?.id && isPinned || apps.runDrag !== "" && apps.runDrag === apps.cellKey(app) ? 0.45 : 1
                vertical: apps.bar.vertical
                // a window with its name is a tab: room for the mark on its left and air around the name
                readonly property bool tab: label !== "" && !asText
                pad: rule ? 5 : tab ? 10 : 4
                spacing: tab ? 8 : 6
                interactive: !rule
                active: marked && wins.some(t => t.activated)
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onPressed: button => {
                    if (button === Qt.RightButton) { apps.menuFor(app); return }
                    if (win) { if (button === Qt.MiddleButton) win.wayland.close(); else apps.bring(win); return }
                    if (button === Qt.MiddleButton || wins.length === 0) { entry?.execute(); return }
                    const i = wins.findIndex(t => t.activated)
                    apps.bring(wins[(i + 1) % wins.length])
                }
                // words voices (terminal themes) name the apps instead, like tmux's window list
                readonly property bool asText: apps.bar.words && !apps.bar.vertical
                readonly property bool nameOnly: win !== null && Config.dock.nameOnly   // Settings > Dock > Open windows as names
                color: asText && active ? Theme.accent : active ? pressedColor : hovered ? hover : "transparent"
                radius: asText ? 0 : Theme.radiusSmall
                Rectangle {   // the rule between launchers and open windows
                    visible: app.rule
                    width: apps.bar.vertical ? Math.round(apps.icon * 0.7) : 1
                    height: apps.bar.vertical ? 1 : Math.round(apps.icon * 0.7)
                    color: Qt.alpha(apps.bar.tone, 0.22)
                }
                IconImage { visible: !app.rule && !app.asText && !app.nameOnly; implicitSize: app.tab ? Math.round(apps.icon * 0.8) : apps.icon; source: Quickshell.iconPath(app.entry?.icon ?? "", "application-x-executable") }
                // an open window can say what it is (Settings > Dock > Open windows in the bar): its app or its title
                readonly property string label: !win || apps.bar.vertical ? "" : app.nameOnly || Config.dock.barLabels === "name" ? (entry?.name ?? win.wayland?.appId ?? "")
                                              : Config.dock.barLabels === "title" ? (win.title || entry?.name || "") : ""
                Text {
                    visible: !app.rule && !app.asText && app.label !== ""
                    width: Math.min(implicitWidth, 180)
                    elide: Text.ElideRight
                    text: app.label
                    color: app.active ? apps.bar.tone : apps.bar.dim
                    font { family: apps.bar.family; pixelSize: Theme.fontLabel; weight: app.active ? Font.DemiBold : Font.Normal }
                }
                Text {
                    visible: !app.rule && app.asText
                    text: apps.bar.say((app.win ? "" : (app.index + 1) + " ") + (app.label !== "" ? app.label.slice(0, 28) : (app.entry?.name ?? app.win?.wayland?.appId ?? "").toLowerCase().split(/[ .]/)[0])
                                + (apps.combine && app.wins.length > 1 ? "·" + app.wins.length : ""))
                    color: app.active ? Theme.accentText : app.marked ? apps.bar.tone : apps.bar.dim
                    font { family: apps.bar.family; pixelSize: Theme.fontLabel; weight: app.active ? Font.Bold : Font.Normal }
                }
                MouseArea {   // left button on an app: a click as usual, or a drag to reorder
                    parent: app
                    anchors.fill: parent
                    enabled: !app.rule
                    acceptedButtons: Qt.LeftButton
                    cursorShape: apps.dragId !== "" || apps.runDrag !== "" ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    property real pressAt: 0
                    property bool moved: false
                    onPressed: mouse => { pressAt = apps.bar.vertical ? mouse.y : mouse.x; moved = false }
                    onPositionChanged: mouse => {
                        if (!moved && Math.abs((apps.bar.vertical ? mouse.y : mouse.x) - pressAt) < 8) return
                        moved = true
                        if (!app.isPinned) { apps.dragRunning(app, mapToItem(grid, mouse.x, mouse.y)); return }
                        apps.dragId = app.entry.id
                        apps.dropAt = apps.dropIndex(mapToItem(grid, mouse.x, mouse.y))
                    }
                    onReleased: { apps.runDrag = ""; apps.endDrag() }
                    onCanceled: { apps.runDrag = ""; apps.dragId = ""; apps.dropAt = -1 }
                    onClicked: if (!moved) app.activate(Qt.LeftButton)
                }
                DockMark {   // open / focused mark, on the screen-edge side (icons only; same look as the floating dock)
                    parent: app
                    visible: app.marked && !app.asText && (!app.tab || app.active)   // every tab is open: only the focused one is marked
                    vertical: apps.bar.vertical
                    sign: Theme.barEdge === "bottom" || Theme.barEdge === "right" ? 1 : -1
                    ink: Qt.alpha(apps.bar.tone, 0.6)
                    style: Theme.dockStyle.mark
                    side: Theme.dockStyle.markSide ?? "edge"
                    on: app.active
                }
            }
        }
    }
    Rectangle {   // where the dragged app lands
        readonly property bool after: apps.dropAt >= apps.pinned.length
        readonly property Item cell: apps.dropAt < 0 ? null : cellRepeater.itemAt(after ? apps.pinned.length - 1 : apps.dropAt)
        visible: apps.dragId !== "" && cell !== null
        color: Theme.accent
        radius: 1
        width: apps.bar.vertical ? (cell?.width ?? 0) : 2
        height: apps.bar.vertical ? 2 : (cell?.height ?? 0)
        x: !cell ? 0 : apps.bar.vertical ? cell.x : after ? cell.x + cell.width + 1 : cell.x - 3
        y: !cell ? 0 : !apps.bar.vertical ? cell.y : after ? cell.y + cell.height + 1 : cell.y - 3
    }
}
