import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import qs

// The dock inside the bar: pinned apps, then other running ones; a mark under each open app,
// the accent under the focused one. Click: bring it up (again: its next window) or start it;
// middle-click: a new window. Drag a pinned app to reorder it.
Item {
    id: apps
    required property var bar
    readonly property int count: DesktopEntries.applications.values.length   // lookups re-run once apps have loaded
    function entryFor(appId) { return count ? DesktopEntries.heuristicLookup(appId) : null }
    readonly property var running: Hyprland.toplevels.values.filter(t => t.wayland && t.workspace?.monitor === bar.monitor)
    // like the floating dock: launchers, then (unless Settings > Dock > Combine) each open window after a rule
    readonly property bool combine: Config.dock.combine
    readonly property var pinned: count ? Array.from(Config.dock.pinned).map(id => DesktopEntries.byId(id)).filter(e => e) : []
    readonly property var cells: {
        const out = pinned.map(e => ({ entry: e, win: null }))
        if (combine) {
            for (const t of running) { const e = entryFor(t.wayland.appId); if (e && !out.some(x => x.entry.id === e.id)) out.push({ entry: e, win: null }) }
        } else if (Config.dock.showRunning && running.length) {
            out.push({ rule: true })
            for (const t of running) out.push({ entry: entryFor(t.wayland.appId), win: t })
        }
        return out
    }
    // a window minimised from the dock (parked on special:minimized) comes back to this screen's workspace first
    function bring(t) {
        if (t.workspace?.name !== "special:minimized") { t.wayland.activate(); return }
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.window.move({ workspace = "${bar.monitor?.activeWorkspace?.id ?? 1}", window = "address:0x${String(t.address).replace(/^0x/, "")}" })`])
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
            model: apps.cells
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
                opacity: apps.dragId !== "" && apps.dragId === entry?.id && isPinned ? 0.45 : 1
                vertical: apps.bar.vertical
                // a window with its name is a tab: room for the mark on its left and air around the name
                readonly property bool tab: label !== "" && !asText
                pad: rule ? 5 : tab ? 10 : 4
                spacing: tab ? 8 : 6
                interactive: !rule
                active: marked && wins.some(t => t.activated)
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onPressed: button => {
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
                MouseArea {   // left button on a pinned app: a click as usual, or a drag to reorder
                    parent: app
                    anchors.fill: parent
                    enabled: app.isPinned
                    acceptedButtons: Qt.LeftButton
                    cursorShape: apps.dragId !== "" ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    property real pressAt: 0
                    property bool moved: false
                    onPressed: mouse => { pressAt = apps.bar.vertical ? mouse.y : mouse.x; moved = false }
                    onPositionChanged: mouse => {
                        if (!moved && Math.abs((apps.bar.vertical ? mouse.y : mouse.x) - pressAt) < 8) return
                        moved = true
                        apps.dragId = app.entry.id
                        apps.dropAt = apps.dropIndex(mapToItem(grid, mouse.x, mouse.y))
                    }
                    onReleased: apps.endDrag()
                    onCanceled: { apps.dragId = ""; apps.dropAt = -1 }
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
