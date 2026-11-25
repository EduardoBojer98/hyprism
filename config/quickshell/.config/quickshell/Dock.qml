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
    readonly property string markSide: ds.markSide ?? "edge"   // edge | inner | left
    readonly property string hoverStyle: ds.hover     // lift | grow | plate
    readonly property int lift: Theme.dockLift
    readonly property string look: Config.dock.look         // theme | clear | frosted | none (Settings > Dock > Look)
    readonly property real tint: Config.dock.tint / 100
    readonly property color tintBase: ds.fill === "ink" ? Theme.text : Theme.surfaceColor        // gap to the screen edge
    readonly property string edge: Theme.dockEdge
    readonly property bool vertical: Theme.dockVertical
    readonly property int sign: edge === "bottom" || edge === "right" ? 1 : -1   // towards the edge
    readonly property color ink: ds.fill === "ink" ? Theme.base : Theme.text
    readonly property int slot: iconSize + 4          // one icon's cell, along the dock
    readonly property int cellCross: iconSize + 8     // and across it (room for the mark)

    // hover "magnify": icons swell toward the pointer on a smooth falloff and push their neighbours
    // aside, the island widening with them. Distances use the row's own layout (transforms don't move
    // it), so the swell never feeds back into where the pointer seems to be.
    readonly property bool magnify: hoverStyle === "magnify" && Theme.moves
    readonly property real growth: 0.55 * magOn                // extra size of the icon under the pointer
    readonly property real reach: slot * 2.8                   // how far along the row the swell spreads
    property real magOn: magnify && hover.hovered && dragId === "" && runDrag === "" && !menu.entry ? 1 : 0
    Behavior on magOn { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    property real pointer: 0   // along the row, in row coordinates; kept on leave so the swell eases out in place
    readonly property real rowStart: vertical ? (height - row.height) / 2 : (width - row.width) / 2
    readonly property real pointerNow: (vertical ? hover.point.position.y : hover.point.position.x) - rowStart
    onPointerNowChanged: if (magnify && hover.hovered) pointer = pointerNow
    function bump(d) { return d >= reach ? 0 : (1 + Math.cos(Math.PI * d / reach)) / 2 }          // 1 at the pointer, 0 at reach
    function bumpArea(a) { return a >= reach ? reach / 2 : a / 2 + reach / (2 * Math.PI) * Math.sin(Math.PI * a / reach) }
    function centreOf(item) { return vertical ? item.y + item.height / 2 : item.x + item.width / 2 }
    function swell(item) { return 1 + growth * bump(Math.abs(centreOf(item) - pointer)) }
    // how far a part slides away from the pointer: the growth of everything between them
    function push(item) { const d = centreOf(item) - pointer; return Math.sign(d) * growth * iconSize / (slot + row.spacing) * bumpArea(Math.abs(d)) }
    readonly property real growBefore: growth * iconSize / (slot + row.spacing) * bumpArea(Math.max(0, pointer))
    readonly property real growAfter: growth * iconSize / (slot + row.spacing) * bumpArea(Math.max(0, (vertical ? row.height : row.width) - pointer))
    // by name, re-read when monitors change: after a display switch Hyprland makes new monitor objects and monitorFor() stays stale
    readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screen?.name) ?? null
    readonly property bool emptyWorkspace: (monitor?.activeWorkspace?.toplevels.values.length ?? 0) === 0
    // the keyboard is here (DockFocus, or its menu is open): the dock shows itself and takes the keys
    readonly property bool hasKeys: DockFocus.active && DockFocus.screen?.name === screen?.name || menu.entry !== null
    onHasKeysChanged: if (hasKeys && !menu.entry) takeFocus.restart()
    Timer { id: takeFocus; interval: 80; onTriggered: if (root.hasKeys && !menu.entry) (launcherPart.visible ? launcherPart : launcherPart.nextItemInFocusChain(true)).forceActiveFocus() }   // the compositor hands over the keys a moment after
    readonly property bool shown: !Config.dock.autoHide || hover.hovered || hideTimer.running || emptyWorkspace
                                  || hasKeys || dragId !== "" || runDrag !== ""
    // keys on an icon: Left / Right (Up / Down on a vertical dock) or Tab move, Enter / Space does what a click does,
    // Menu or Shift+F10 opens its menu, Escape leaves
    function key(e, item, activate, openMenu) {
        const next = vertical ? Qt.Key_Down : Qt.Key_Right, prev = vertical ? Qt.Key_Up : Qt.Key_Left
        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) { activate(); DockFocus.leave() }
        else if (e.key === Qt.Key_Menu || (e.key === Qt.Key_F10 && (e.modifiers & Qt.ShiftModifier))) openMenu()
        else if (e.key === Qt.Key_Escape) DockFocus.leave()
        else if (e.key === next) item.nextItemInFocusChain(true).forceActiveFocus()
        else if (e.key === prev) item.nextItemInFocusChain(false).forceActiveFocus()
        else return
        e.accepted = true
    }

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
        return DockOrder.sort(out, "apps", e => e.id, e => out.indexOf(e))   // openWindows is by workspace already
    }
    readonly property var widgetIds: Config.dock.widgets.filter((id, i, a) => Theme.dockWidgets[id] !== undefined && a.indexOf(id) === i)
    readonly property var appEntries: pinnedEntries.concat(runningEntries)
    function dragTo(x) {
        dragX = x
        const first = Config.dock.launcher ? root.slot + row.spacing * 2 + 1 : 0   // launcher + divider
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
    readonly property var openWindows: Config.dock.showRunning ? DockOrder.sort(Hyprland.toplevels.values.filter(t => {
        if (!t.wayland) return false
        if (!isMinimised(t)) { if (t.monitor) homes[t.address] = t.monitor.name; return !!monitor && t.monitor?.name === monitor.name }
        return (homes[t.address] ?? t.monitor?.name) === monitor?.name
    }), "windows", address, DockOrder.ws) : []
    // an open app or window dragged along its own group takes its place at once (DockOrder, by workspace until then)
    property string runDrag: ""
    function dragRunning(item, pos) {   // pos: the pointer along the dock, in window coordinates
        const group = item.orderGroup, key = item.orderKey
        runDrag = key
        const tiles = Array.from(row.children).filter(c => c.visible && c.orderGroup === group && c.orderKey)
        tiles.sort((a, b) => middleOf(a) - middleOf(b))
        const before = tiles.find(c => c.orderKey !== key && middleOf(c) > pos)
        DockOrder.move(group, tiles.map(c => c.orderKey), key, before ? before.orderKey : "")
    }
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
    WlrLayershell.keyboardFocus: hasKeys ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
        flat: root.look === "none"   // no glass sheen or rim: only the icons
        // along the dock: centred; across: at the edge, or just past it while hidden. The hide is a
        // translate (no layout), out of the way towards the edge, faster out than in.
        readonly property real across: root.vertical ? width : height
        readonly property real restAt: root.sign > 0 ? (root.vertical ? parent.width : parent.height) - across - root.lift : root.lift
        x: root.vertical ? restAt : (parent.width - width) / 2 + (root.growAfter - root.growBefore) / 2
        y: root.vertical ? (parent.height - height) / 2 + (root.growAfter - root.growBefore) / 2 : restAt
        property real hide: root.shown ? 0 : (across + root.lift + 4) * root.sign
        transform: Translate { x: root.vertical ? island.hide : 0; y: root.vertical ? 0 : island.hide }
        opacity: root.shown ? 1 : 0
        Behavior on hide { NumberAnimation { duration: root.shown ? Theme.enter : Theme.exit; easing.type: Theme.easing } }
        Behavior on opacity { NumberAnimation { duration: root.shown ? Theme.anim : Theme.exit } }

        readonly property int pad: Theme.dockPad
        readonly property real grown: root.growBefore + root.growAfter
        width: root.vertical ? Theme.dockThickness : row.implicitWidth + pad * 2 + (root.shape === "pill" ? 8 : 0) + grown
        height: root.vertical ? row.implicitHeight + pad * 2 + (root.shape === "pill" ? 8 : 0) + grown : Theme.dockThickness
        radius: root.shape === "pill" ? across / 2 : root.shape === "tile" ? Theme.radiusPanel : Theme.radius
        color: root.look === "theme" ? (({ glass: Theme.glass, surface: Theme.surfaceColor, ink: Theme.text })[root.ds.fill] ?? Theme.glass)
             : root.look === "clear" ? Qt.alpha(root.tintBase, root.tint) : "transparent"   // frosted: the overlay is on the blur layer
        border { width: root.look === "none" ? 0 : Theme.line
                 color: root.look === "frosted" ? Qt.alpha(Theme.light ? "#ffffff" : Theme.text, Theme.light ? 0.55 : 0.14)   // palette: a glass rim
                      : root.ds.fill === "ink" ? Theme.text : Theme.stroke }

        // the theme's depth: a soft shadow (glass themes) or a hard offset block (Poster), under the island
        RectangularShadow {
            visible: ((Theme.depth === "soft" || Theme.depth === "glow") && root.look === "theme") || root.look === "frosted"
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
            visible: Theme.depth === "hard" && root.look === "theme"
            z: -1
            x: 6; y: 6; width: parent.width; height: parent.height
            color: Theme.stroke
        }

        Grid {
            id: row
            anchors.centerIn: parent
            // magnify: the row stays put on screen while the island grows unevenly around it
            anchors.horizontalCenterOffset: root.vertical ? 0 : (root.growBefore - root.growAfter) / 2
            anchors.verticalCenterOffset: root.vertical ? (root.growBefore - root.growAfter) / 2 : 0
            // one row or one column: only `columns` is set (setting rows too adds spacing for empty rows)
            columns: root.vertical ? 1 : Math.max(1, visibleChildren.filter(c => c.width > 0).length)
            spacing: 6
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            // App menu / Spotlight-style launcher
            DockLauncher { id: launcherPart; dock: root; visible: Config.dock.launcher }   // Settings > Dock: Launcher button

            DockSeparator { dock: root; visible: Config.dock.launcher }

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

    // Settings > Dock > Look "frosted": the overlay on a full-screen layer of its own just under the dock, which
    // Hyprland blurs at any strength (rules.lua: qs-dockblur, ignore_alpha 0), kept on the island's place
    PanelWindow {
        screen: root.screen
        WlrLayershell.namespace: "qs-dockblur"
        // over windows (a window behind the dock is blurred too) and under the dock: mapped for as long as
        // the shell runs and fully clear unless frosted, so the dock, which maps after it, stays on top
        WlrLayershell.layer: WlrLayer.Top
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        mask: Region {}
        Rectangle {
            readonly property point at: root.origin()
            x: at.x + island.x + (root.vertical ? island.hide : 0)
            y: at.y + island.y + (root.vertical ? 0 : island.hide)
            width: island.width; height: island.height
            radius: island.radius
            // a trace of colour even at 0%, or Hyprland has nothing to blur behind
            visible: root.look === "frosted"
            color: Qt.alpha(root.tintBase, Math.max(0.01, root.tint))
            opacity: island.opacity
        }
    }

    // the tooltip, beside the island at the hovered icon; hover-to-hover it moves without waiting
    DockTip { dock: root }

    // Window previews for one app (combined mode), beside the island
    DockPreview { id: preview; dock: root }

    DockMenu { id: menu; dock: root }
}
