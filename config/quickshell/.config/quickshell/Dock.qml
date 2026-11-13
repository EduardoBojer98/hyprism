import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock: the all-apps button, pinned apps (Config.dock.pinned, drag to reorder), a divider, then
// every window on this dock's monitor as its own live thumbnail with the app's icon on it.
// It sits on any edge (Settings > Dock; beside the bar when they share one). With auto-hide it slides
// in when the pointer touches its edge and stays visible on an empty workspace.
// Right-click an icon or a window for windows and pin / minimise / restore / quit.
// Its look follows the theme (Themes.qml dock: shape, hover, mark, fill).
PanelWindow {
    id: root

    readonly property int iconSize: Config.dock.iconSize
    readonly property var ds: Theme.dockStyle
    readonly property string shape: ds.shape          // pill | tile | block
    readonly property string indicator: ds.mark       // line | dot | bar
    readonly property string hoverStyle: ds.hover     // lift | grow | plate
    readonly property int lift: Theme.dockLift        // gap to the screen edge
    readonly property string edge: Theme.dockEdge
    readonly property bool vertical: Theme.dockVertical
    readonly property int sign: edge === "bottom" || edge === "right" ? 1 : -1   // towards the edge
    readonly property color ink: ds.fill === "ink" ? Theme.base : Theme.text
    readonly property int slot: iconSize + 4          // one icon's cell, along the dock
    readonly property int cellCross: iconSize + 8     // and across it (room for the mark)
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property bool emptyWorkspace: (monitor?.activeWorkspace?.toplevels.values.length ?? 0) === 0
    readonly property bool shown: !Config.dock.autoHide || hover.hovered || hideTimer.running || emptyWorkspace
                                  || menu.entry !== null || dragId !== ""

    // app list size: lookups below re-run once it has loaded (it is empty for a moment at login)
    readonly property int appCount: DesktopEntries.applications.values.length
    function entryFor(appId) { return appCount ? DesktopEntries.heuristicLookup(appId) : null }
    // Hyprland's view of the windows (address + workspace), linked to the Wayland toplevel for activate()
    function windowsOf(entry) {
        return entry ? Hyprland.toplevels.values.filter(t => t.wayland && entryFor(t.wayland.appId)?.id === entry.id) : []
    }
    function isMinimised(t) { return t.workspace?.name === "special:minimized" }
    function address(t) { return "0x" + String(t.address).replace(/^0x/, "") }
    function dispatch(lua) { Quickshell.execDetached(["hyprctl", "dispatch", lua]) }
    function minimise(t) { dispatch(`hl.dsp.window.move({ workspace = "special:minimized", follow = false, window = "address:${address(t)}" })`) }
    function restore(t) { dispatch(`hl.dsp.window.move({ workspace = "${monitor?.activeWorkspace?.id ?? 1}", window = "address:${address(t)}" })`) }
    function focus(t) { if (isMinimised(t)) restore(t); else t.wayland.activate() }
    function close(t) { dispatch(`hl.dsp.window.close({ window = "address:${address(t)}" })`) }
    function setPinned(entry, pin) {
        const list = Config.dock.pinned.filter(id => id !== entry.id)
        if (pin) list.push(entry.id)
        Config.set("dock", "pinned", list)
    }

    // Reordering: while an icon is dragged the order lives here and is saved on release
    property var dragOrder: null
    property string dragId: ""
    property real dragX: 0            // pointer along the dock, in row coordinates
    readonly property var pinnedIds: dragOrder ?? Config.dock.pinned
    readonly property var pinnedEntries: appCount ? pinnedIds.map(id => DesktopEntries.byId(id)).filter(e => e) : []
    // Two ways to show what's open, like the Windows taskbar (Settings > Dock > Combine):
    //   separate  pinned apps are launchers; every open window is its own tile after them (default)
    //   combined  an open app shares its pinned icon (others join after the pinned ones); hovering an
    //             app with windows shows a preview of each, click one to bring it up
    readonly property bool combine: Config.dock.combine
    readonly property var runningEntries: {
        if (!combine || !Config.dock.showRunning) return []
        const out = []
        for (const t of openWindows) { const e = entryFor(t.wayland?.appId ?? ""); if (e && !pinnedIds.includes(e.id) && !out.some(x => x.id === e.id)) out.push(e) }
        return out
    }
    readonly property var widgetIds: Config.dock.widgets.filter((id, i, a) => Theme.dockWidgets[id] !== undefined && a.indexOf(id) === i)
    readonly property var appEntries: pinnedEntries.concat(runningEntries)
    function dragTo(x) {
        dragX = x
        const first = root.slot + row.spacing * 2 + 1          // launcher + divider
        const i = Math.max(0, Math.min(pinnedEntries.length - 1, Math.floor((x - first) / (slot + row.spacing))))
        const ids = pinnedEntries.map(e => e.id)
        if (ids[i] === dragId) return
        ids.splice(ids.indexOf(dragId), 1)
        ids.splice(i, 0, dragId)
        dragOrder = ids
    }
    function endDrag() {
        if (dragOrder) Config.set("dock", "pinned", dragOrder)
        dragOrder = null
        dragId = ""
    }

    // this monitor's open windows, one tile each (minimised ones too), in the order they opened.
    // A minimised window stays on the dock of the monitor it was on (homes: address -> monitor name).
    // shortcut: after a shell restart a minimised window's home is unknown, it goes by Hyprland's monitor until restored.
    property var homes: ({})
    readonly property var openWindows: Config.dock.showRunning ? Hyprland.toplevels.values.filter(t => {
        if (!t.wayland) return false
        if (!isMinimised(t)) { if (t.monitor) homes[t.address] = t.monitor.name; return t.monitor === monitor }
        return (homes[t.address] ?? t.monitor?.name) === monitor?.name
    }) : []
    readonly property int thumbWidth: Math.round(iconSize * 1.6)
    // window pictures started while the shell is still starting fail for good; start them a bit later
    property bool captureReady: false
    Timer { running: true; interval: 3000; onTriggered: root.captureReady = true }
    // live pictures make Hyprland copy every window each frame: only while the pointer is on the dock,
    // otherwise a fresh still every root.thumbRefresh seconds (and right away when the pointer leaves)
    readonly property bool liveShots: shown && hover.hovered
    signal snapshot()
    Timer {
        running: root.shown && Config.dock.thumbnails && !root.liveShots
        interval: Config.dock.thumbRefresh * 1000; repeat: true; triggeredOnStart: true
        onTriggered: root.snapshot()
    }

    // Shared tooltip: appears after a short pause, then follows the pointer between icons at once
    property Item tipItem: null
    property string tipText: ""
    property bool tipReady: false
    function hovering(item, text, on) {
        if (on) { tipItem = item; tipText = text; tipGrace.stop(); if (!tipReady) tipDelay.restart() }
        else if (tipItem === item) { tipItem = null; tipGrace.restart() }
        // combined: an app with windows shows their previews instead of a tooltip
        if (on && combine && Config.dock.previews && (item.windows?.length ?? 0) > 0) { previewFor = item; previewGrace.stop(); previewDelay.restart() }
        else if (!on && previewFor === item) previewGrace.restart()
    }
    property Item previewFor: null
    property bool previewOn: false
    Timer { id: previewDelay; interval: 300; onTriggered: root.previewOn = root.previewFor !== null }
    Timer { id: previewGrace; interval: 350; onTriggered: { if (!preview.pointerOn) { root.previewOn = false; root.previewFor = null } } }
    Timer { id: tipDelay; interval: 350; onTriggered: root.tipReady = root.tipItem !== null }
    Timer { id: tipGrace; interval: 200; onTriggered: { root.tipReady = false; tipDelay.stop() } }

    // A fixed full-length strip along its edge: the surface never resizes when apps open or the menu
    // shows (resizing a layer surface made the dock jump and flicker); the input mask limits it to the
    // island. Created after the bar, so Hyprland places it beside the bar when they share an edge.
    anchors { bottom: edge !== "top"; top: edge !== "bottom"; left: edge !== "right"; right: edge !== "left" }
    implicitHeight: vertical ? 0 : 340   // island + room beside it for tooltips / the app menu
    implicitWidth: vertical ? 340 : 0
    exclusiveZone: Config.dock.autoHide ? 0 : Theme.dockThickness + root.lift
    color: "transparent"
    WlrLayershell.namespace: "qs-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Only the visible island (or a thin strip at the bottom edge when hidden) takes input
    mask: Region { item: root.shown ? island : edgeStrip; Region { item: menu.entry ? menu : null } Region { item: preview.visible ? preview : null } }

    Item {   // the hidden dock's trigger: a thin strip along its edge
        id: edgeStrip
        x: root.vertical ? (root.edge === "left" ? 0 : parent.width - width) : island.x
        y: root.vertical ? island.y : (root.edge === "top" ? 0 : parent.height - height)
        width: root.vertical ? 4 : island.width
        height: root.vertical ? island.height : 4
    }

    HoverHandler {
        id: hover
        onHoveredChanged: if (!hovered) hideTimer.restart()
    }
    Timer { id: hideTimer; interval: 500 }


    Glass {
        id: island
        // along the dock: centred; across: at the edge, or just past it while hidden. The hide is a
        // translate (no layout), out of the way towards the edge, faster out than in.
        readonly property real across: root.vertical ? width : height
        readonly property real restAt: root.sign > 0 ? (root.vertical ? parent.width : parent.height) - across - root.lift : root.lift
        x: root.vertical ? restAt : (parent.width - width) / 2
        y: root.vertical ? (parent.height - height) / 2 : restAt
        property real hide: root.shown ? 0 : (across + root.lift + 4) * root.sign
        transform: Translate { x: root.vertical ? island.hide : 0; y: root.vertical ? 0 : island.hide }
        opacity: root.shown ? 1 : 0
        Behavior on hide { NumberAnimation { duration: root.shown ? Theme.enter : Theme.exit; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: root.shown ? Theme.anim : Theme.exit } }

        readonly property int pad: Theme.dockPad
        width: root.vertical ? Theme.dockThickness : row.implicitWidth + pad * 2 + (root.shape === "pill" ? 8 : 0)
        height: root.vertical ? row.implicitHeight + pad * 2 + (root.shape === "pill" ? 8 : 0) : Theme.dockThickness
        radius: root.shape === "pill" ? across / 2 : root.shape === "tile" ? Theme.radiusPanel : Theme.radius
        color: ({ glass: Theme.glass, surface: Theme.surfaceColor, ink: Theme.text })[root.ds.fill] ?? Theme.glass
        border { width: Theme.line; color: root.ds.fill === "ink" ? Theme.text : Theme.stroke }

        // the theme's depth: a soft shadow (glass themes) or a hard offset block (Poster), under the island
        RectangularShadow {
            visible: Theme.depth === "soft" || Theme.depth === "glow"
            z: -1
            anchors.fill: parent
            offset.y: Theme.depth === "glow" ? 0 : 6
            blur: Theme.depth === "glow" ? 26 : 22
            spread: -2
            radius: parent.radius
            color: Theme.depth === "glow" ? Qt.alpha(Theme.accent, 0.2) : Theme.shadow
        }
        // Poster's hard offset shadow: a block of the line colour drawn under the island (z < 0)
        Rectangle {
            visible: Theme.depth === "hard"
            z: -1
            x: 6; y: 6; width: parent.width; height: parent.height
            color: Theme.stroke
        }

        Grid {
            id: row
            anchors.centerIn: parent
            // one row or one column: only `columns` is set (setting rows too adds spacing for empty rows)
            columns: root.vertical ? 1 : Math.max(1, visibleChildren.filter(c => c.width > 0).length)
            spacing: 6
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            // App menu / Spotlight-style launcher
            DockLauncher { dock: root }

            DockSeparator { dock: root }

            Repeater {
                // ScriptModel keeps existing icons when the list changes (and moves them on reorder)
                model: ScriptModel { values: root.appEntries }

                DockApp { dock: root }
            }

            DockSeparator { dock: root; visible: !root.combine && root.openWindows.length > 0 }   // before the open windows

            // ---- open windows: a live picture of each, its app's icon in the corner ---------------
            Repeater {
                model: ScriptModel { values: root.combine ? [] : root.openWindows }

                DockWindow { dock: root }
            }

            DockSeparator { dock: root; visible: widgetIds.length > 0 }   // before the widgets (Settings > Dock > Widgets)

            Repeater {
                model: ScriptModel { values: root.widgetIds }

                DockWidget { dock: root }
            }
        }
    }

    readonly property var menuBox: menu       // the parts reach these through `dock`
    readonly property var rowItem: row
    function previewLeave(hovered) { if (!hovered) previewGrace.restart(); else previewGrace.stop() }
    // where an icon's middle is, along the dock, in window coordinates
    function middleOf(item) {
        const p = item.mapToItem(root.contentItem, 0, 0)
        return (vertical ? p.y : p.x) + (item.mid ?? (vertical ? item.height : item.width) / 2)
    }
    // a box of size w x h beside the island, on the desktop side, centred on `at` along the dock
    function beside(w, h, at, gap) {
        const along = Math.max(8, Math.min((vertical ? root.height - h : root.width - w) - 8, at - (vertical ? h : w) / 2))
        const across = sign > 0 ? (vertical ? island.x - w : island.y - h) - gap : (vertical ? island.x + island.width : island.y + island.height) + gap
        return vertical ? Qt.point(across, along) : Qt.point(along, across)
    }
    // the screen side the icons grow and lift from (Item.TransformOrigin)
    readonly property int edgeOrigin: ({ bottom: Item.Bottom, top: Item.Top, left: Item.Left, right: Item.Right })[edge] ?? Item.Bottom   // before the edge is known
    // this window's top-left on the screen (Anchor: panels opened from the dock appear beside it)
    function origin() {   // Hyprland puts this window inside the bar's room on the edges they share
        const s = root.screen, bh = Theme.barShownOn(s) ? Theme.barHeight : 0, be = Theme.barEdge
        return Qt.point(edge === "right" ? s.width - root.width - (be === "right" ? bh : 0) : (be === "left" ? bh : 0),
                        edge === "bottom" ? s.height - root.height - (be === "bottom" ? bh : 0) : (be === "top" ? bh : 0))
    }

    // the tooltip, beside the island at the hovered icon; hover-to-hover it moves without waiting
    DockTip { dock: root }

    // Window previews for one app (combined mode), beside the island
    DockPreview { id: preview; dock: root }

    DockMenu { id: menu; dock: root }
}
