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
    id: dock

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
    function dragTo(x) {
        dragX = x
        const first = dock.slot + row.spacing * 2 + 1          // launcher + divider
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
    Timer { running: true; interval: 3000; onTriggered: dock.captureReady = true }
    // live pictures make Hyprland copy every window each frame: only while the pointer is on the dock,
    // otherwise a fresh still every dock.thumbRefresh seconds (and right away when the pointer leaves)
    readonly property bool liveShots: shown && hover.hovered
    signal snapshot()
    Timer {
        running: dock.shown && Config.dock.thumbnails && !dock.liveShots
        interval: Config.dock.thumbRefresh * 1000; repeat: true; triggeredOnStart: true
        onTriggered: dock.snapshot()
    }

    // Shared tooltip: appears after a short pause, then follows the pointer between icons at once
    property Item tipItem: null
    property string tipText: ""
    property bool tipReady: false
    function hovering(item, text, on) {
        if (on) { tipItem = item; tipText = text; tipGrace.stop(); if (!tipReady) tipDelay.restart() }
        else if (tipItem === item) { tipItem = null; tipGrace.restart() }
    }
    Timer { id: tipDelay; interval: 350; onTriggered: dock.tipReady = dock.tipItem !== null }
    Timer { id: tipGrace; interval: 200; onTriggered: { dock.tipReady = false; tipDelay.stop() } }

    // A fixed full-length strip along its edge: the surface never resizes when apps open or the menu
    // shows (resizing a layer surface made the dock jump and flicker); the input mask limits it to the
    // island. Created after the bar, so Hyprland places it beside the bar when they share an edge.
    anchors { bottom: edge !== "top"; top: edge !== "bottom"; left: edge !== "right"; right: edge !== "left" }
    implicitHeight: vertical ? 0 : 340   // island + room beside it for tooltips / the app menu
    implicitWidth: vertical ? 340 : 0
    exclusiveZone: Config.dock.autoHide ? 0 : Theme.dockThickness + dock.lift
    color: "transparent"
    WlrLayershell.namespace: "qs-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Only the visible island (or a thin strip at the bottom edge when hidden) takes input
    mask: Region { item: dock.shown ? island : edgeStrip; Region { item: menu.entry ? menu : null } }

    Item {   // the hidden dock's trigger: a thin strip along its edge
        id: edgeStrip
        x: dock.vertical ? (dock.edge === "left" ? 0 : parent.width - width) : island.x
        y: dock.vertical ? island.y : (dock.edge === "top" ? 0 : parent.height - height)
        width: dock.vertical ? 4 : island.width
        height: dock.vertical ? island.height : 4
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
        readonly property real across: dock.vertical ? width : height
        readonly property real restAt: dock.sign > 0 ? (dock.vertical ? parent.width : parent.height) - across - dock.lift : dock.lift
        x: dock.vertical ? restAt : (parent.width - width) / 2
        y: dock.vertical ? (parent.height - height) / 2 : restAt
        property real hide: dock.shown ? 0 : (across + dock.lift + 4) * dock.sign
        transform: Translate { x: dock.vertical ? island.hide : 0; y: dock.vertical ? 0 : island.hide }
        opacity: dock.shown ? 1 : 0
        Behavior on hide { NumberAnimation { duration: dock.shown ? Theme.enter : Theme.exit; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: dock.shown ? Theme.anim : Theme.exit } }

        readonly property int pad: Theme.dockPad
        width: dock.vertical ? Theme.dockThickness : row.implicitWidth + pad * 2 + (dock.shape === "pill" ? 8 : 0)
        height: dock.vertical ? row.implicitHeight + pad * 2 + (dock.shape === "pill" ? 8 : 0) : Theme.dockThickness
        radius: dock.shape === "pill" ? across / 2 : dock.shape === "tile" ? Theme.radiusLarge + 4 : Theme.radius
        color: ({ glass: Theme.glass, surface: Theme.surfaceColor, ink: Theme.text })[dock.ds.fill] ?? Theme.glass
        border { width: Theme.line; color: dock.ds.fill === "ink" ? Theme.text : Theme.stroke }

        // the theme's depth: a soft shadow (glass themes) or a hard offset block (Poster), under the island
        RectangularShadow {
            visible: Theme.depth === "soft" || Theme.depth === "glow"
            z: -1
            anchors.fill: parent
            offset.y: Theme.depth === "glow" ? 0 : 6
            blur: Theme.depth === "glow" ? 26 : 22
            spread: -2
            radius: parent.radius
            color: Theme.depth === "glow" ? Qt.alpha(Theme.accent, 0.2) : Qt.rgba(0, 0, 0, Theme.light ? 0.18 : 0.4)
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
            columns: dock.vertical ? 1 : Math.max(1, visibleChildren.length)
            spacing: 6
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            // App menu / Spotlight-style launcher
            Item {
                id: launcher
                readonly property real mid: (dock.vertical ? height : width) / 2
                width: dock.vertical ? dock.cellCross : dock.slot
                height: dock.vertical ? dock.slot : dock.cellCross

                // a frosted tile with a 2 x 2 grid; on hover the grid turns a quarter and one square
                // becomes an accent dot
                Rectangle {
                    id: launcherTile
                    readonly property bool lit: Launcher.open || launcherArea.containsMouse
                    anchors.centerIn: parent
                    width: dock.iconSize
                    height: dock.iconSize
                    radius: dock.shape === "block" ? 0 : Math.round(dock.iconSize * 0.27)
                    color: launcherTile.lit ? Qt.alpha(dock.ink, 0.17) : Qt.alpha(dock.ink, 0.07)
                    border { color: Qt.alpha(dock.ink, launcherTile.lit ? 0.3 : 0.15); width: 1 }
                    scale: launcherArea.pressed ? Theme.pressScale : 1
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.anim } }

                    Rectangle {   // top sheen, like light on glass
                        visible: Theme.glassy
                        anchors { fill: parent; margins: 1 }
                        radius: parent.radius - 1
                        gradient: Gradient {
                            GradientStop { position: 0; color: Theme.highlight }
                            GradientStop { position: 0.5; color: "transparent" }
                        }
                    }

                    Grid {
                        id: dots
                        readonly property real cell: dock.iconSize * 0.2
                        anchors.centerIn: parent
                        columns: 2
                        spacing: dock.iconSize * 0.09
                        rotation: launcherTile.lit && Theme.moves ? 45 : 0
                        Behavior on rotation { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                readonly property bool dot: index === 1 && launcherTile.lit
                                width: dots.cell; height: dots.cell
                                radius: dot ? dots.cell / 2 : dots.cell * 0.3
                                color: index === 1 ? Theme.accent : dock.ink
                                opacity: index === 1 ? 1 : 0.88
                                Behavior on radius { NumberAnimation { duration: Theme.anim } }
                            }
                        }
                    }
                }

                MouseArea {
                    id: launcherArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: dock.hovering(launcher, "Apps & search", containsMouse)
                    onClicked: { Anchor.take(launcher, dock.edge, dock.origin()); Launcher.toggle() }
                }
            }

            Separator {}

            Repeater {
                // ScriptModel keeps existing icons when the list changes (and moves them on reorder)
                model: ScriptModel { values: dock.pinnedEntries }

                Item {
                    id: app
                    required property DesktopEntry modelData
                    required property int index
                    readonly property bool pinned: true
                    readonly property bool dragged: dock.dragId !== "" && dock.dragId === modelData?.id
                    readonly property var windows: dock.windowsOf(modelData)
                    readonly property var visibleWindows: windows.filter(t => !dock.isMinimised(t))
                    property bool launching: false
                    onWindowsChanged: if (windows.length) launching = false

                    width: dock.vertical ? dock.cellCross : dock.slot
                    height: dock.vertical ? dock.slot : dock.cellCross
                    readonly property real along: dock.vertical ? y : x
                    readonly property real mid: (dock.vertical ? height : width) / 2   // tooltip / menu centre
                    z: dragged ? 1 : 0
                    // neighbours glide aside while an icon is dragged past them
                    Behavior on x { enabled: dock.dragId !== "" && !dock.vertical; NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                    Behavior on y { enabled: dock.dragId !== "" && dock.vertical; NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

                    Item {
                        id: cell
                        anchors.fill: parent
                        // the dragged icon follows the pointer, a little off the edge
                        readonly property real follow: app.dragged ? dock.dragX - (app.along + app.mid) : 0
                        transform: Translate {
                            x: dock.vertical ? (app.dragged ? -4 * dock.sign : 0) : cell.follow
                            y: dock.vertical ? cell.follow : (app.dragged ? -4 * dock.sign : 0)
                        }

                        // hover plate: a soft tile behind the icon (hover "plate"; always while dragged or in a menu)
                        Rectangle {
                            anchors { fill: parent; margins: -1 }
                            radius: Theme.radius
                            color: Qt.alpha(dock.ink, area.pressed || app.dragged ? 0.17 : 0.11)
                            opacity: area.containsMouse && dock.hoverStyle === "plate" || app.dragged || menu.item === app ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        }

                        IconImage {
                            id: icon
                            anchors.centerIn: parent
                            // a little away from the edge, so the open-app mark has room on the edge side
                            anchors.horizontalCenterOffset: dock.vertical ? -3 * dock.sign : 0
                            anchors.verticalCenterOffset: dock.vertical ? 0 : -3 * dock.sign
                            implicitSize: dock.iconSize
                            source: Quickshell.iconPath(app.modelData?.icon ?? "", "application-x-executable")
                            transformOrigin: dock.edgeOrigin
                            // hover: lift (moves off the edge) or grow (from the edge); press: a small give
                            property real raise: dock.hoverStyle === "lift" && area.containsMouse && !app.dragged && Theme.moves ? -6 * dock.sign : 0
                            transform: Translate { x: dock.vertical ? icon.raise : 0; y: dock.vertical ? 0 : icon.raise }
                            Behavior on raise { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                            scale: area.pressed && !app.dragged ? Theme.pressScale : dock.hoverStyle === "grow" && area.containsMouse && !app.dragged && Theme.moves ? 1.14 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

                            // launching: a slow breath until the first window shows up
                            SequentialAnimation on opacity {
                                running: app.launching && Theme.animate
                                loops: Animation.Infinite
                                onRunningChanged: if (!running) icon.opacity = 1
                                NumberAnimation { to: 0.45; duration: 520; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1; duration: 520; easing.type: Easing.InOutSine }
                            }
                        }
                        Timer { running: app.launching; interval: 10000; onTriggered: app.launching = false }
                        Mark { visible: app.windows.length > 0; on: app.windows.some(t => t.activated) }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: app.dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        property real pressX: 0
                        property bool moved: false
                        onContainsMouseChanged: dock.hovering(app, app.modelData?.name ?? "", containsMouse)
                        onPressed: mouse => { pressX = dock.vertical ? mouse.y : mouse.x; moved = false }
                        // drag a pinned icon along the dock to reorder
                        onPositionChanged: mouse => {
                            if (!pressed || pressedButtons !== Qt.LeftButton || !app.pinned) return
                            const at = dock.vertical ? mouse.y : mouse.x
                            if (!app.dragged && Math.abs(at - pressX) < 8) return
                            if (!app.dragged) { moved = true; dock.dragId = app.modelData.id }
                            const p = mapToItem(row, mouse.x, mouse.y)
                            dock.dragTo(dock.vertical ? p.y : p.x)
                        }
                        onReleased: if (app.dragged) dock.endDrag()
                        onCanceled: if (app.dragged) dock.endDrag()
                        // Left: focus the app (cycling through its windows), bring back minimised ones, or start it.
                        // Middle: always a new window. Right: windows and pin / minimise / quit menu.
                        onClicked: mouse => {
                            if (!app.modelData || moved) return   // delegate is being replaced / was a drag
                            if (mouse.button === Qt.RightButton) { menu.openFor(app); return }
                            const w = app.visibleWindows
                            if (mouse.button === Qt.MiddleButton || app.windows.length === 0) {
                                app.launching = app.windows.length === 0
                                app.modelData.execute()
                                return
                            }
                            if (w.length === 0) { for (const t of app.windows) dock.restore(t); return }
                            const i = w.findIndex(t => t.activated)
                            w[(i + 1) % w.length].wayland.activate()
                        }
                    }
                }
            }

            Separator { visible: dock.openWindows.length > 0 }   // before the open windows

            // ---- open windows: a live picture of each, its app's icon in the corner ---------------
            Repeater {
                model: ScriptModel { values: dock.openWindows }

                Item {
                    id: win
                    required property var modelData           // HyprlandToplevel
                    readonly property var entry: dock.entryFor(modelData.wayland?.appId ?? "")
                    readonly property bool minimised: dock.isMinimised(modelData)
                    readonly property bool focused: modelData.activated
                    readonly property real mid: (dock.vertical ? height : width) / 2   // tooltip / menu centre
                    readonly property var windows: [modelData]
                    // the window's shape (from its picture once there is one), fitted into the tile
                    readonly property real aspect: shot.hasContent && shot.sourceSize.height > 0
                        ? Math.max(0.5, Math.min(2.4, shot.sourceSize.width / shot.sourceSize.height)) : 1.6
                    property bool retrying: false
                    // the capture breaks when the window changes workspace: start it again once it's back
                    onMinimisedChanged: if (!minimised) { retrying = true; retry.restart() }
                    // a failed capture (window resized or just opened) is dropped without `stopped`: start it again
                    Connections {
                        target: dock
                        function onSnapshot() {
                            if (win.minimised) return
                            if (shot.hasContent) shot.captureFrame(); else { win.retrying = true; retry.restart() }
                        }
                    }

                    width: dock.vertical ? dock.cellCross : dock.thumbWidth
                    height: dock.vertical ? Math.round(dock.iconSize * 0.9) : dock.cellCross

                    Rectangle {   // hover plate
                        anchors { fill: parent; margins: -1 }
                        radius: Theme.radius
                        color: Qt.alpha(dock.ink, winArea.pressed ? 0.17 : 0.11)
                        opacity: winArea.containsMouse && dock.hoverStyle === "plate" || menu.item === win ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }

                    Rectangle {
                        id: frame
                        readonly property real boxH: dock.iconSize - 4
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: dock.vertical ? -3 * dock.sign : 0
                        anchors.verticalCenterOffset: dock.vertical ? 0 : -3 * dock.sign
                        property real raise: dock.hoverStyle === "lift" && winArea.containsMouse && Theme.moves ? -5 * dock.sign : 0
                        transform: Translate { x: dock.vertical ? frame.raise : 0; y: dock.vertical ? 0 : frame.raise }
                        Behavior on raise { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                        height: dock.vertical ? Math.min(win.height - 6, (dock.iconSize - 4) / win.aspect) : Math.min(boxH, (win.width - 6) / win.aspect)
                        width: height * win.aspect
                        radius: Theme.radiusSmall - 2
                        color: Qt.alpha(dock.ink, 0.07)
                        border { color: win.focused ? Theme.accent : Qt.alpha(dock.ink, 0.2); width: win.focused ? 2 : 1 }
                        opacity: win.minimised ? 0.55 : 1
                        transformOrigin: dock.edgeOrigin
                        scale: winArea.pressed ? Theme.pressScale : dock.hoverStyle === "grow" && winArea.containsMouse && Theme.moves ? 1.1 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                        clip: true

                        ScreencopyView {
                            id: shot
                            anchors { fill: parent; margins: frame.border.width }
                            // only while the dock can be seen: each live picture costs a little GPU
                            captureSource: dock.shown && Config.dock.thumbnails && dock.captureReady && !win.retrying ? win.modelData.wayland : null
                            live: dock.liveShots && !win.minimised   // a minimised window keeps its last picture
                            // a capture can fail (e.g. right at login); start it again a moment later
                            onStopped: { win.retrying = true; retry.restart() }
                            // Quickshell 0.3.2 never sends `stopped`: a lost picture (window resized) is the sign
                            onHasContentChanged: if (!hasContent && captureSource) { win.retrying = true; retry.restart() }
                        }
                        Timer { id: retry; interval: 600; onTriggered: win.retrying = false }
                        IconImage {   // no picture (yet): the app's icon fills in
                            anchors.centerIn: parent
                            visible: !shot.hasContent
                            implicitSize: Math.round(frame.height * 0.72)
                            source: Quickshell.iconPath(win.entry?.icon ?? "", "application-x-executable")
                        }
                    }
                    IconImage {   // whose window it is
                        visible: shot.hasContent
                        anchors { right: frame.right; bottom: frame.bottom; rightMargin: -4; bottomMargin: -5 }
                        implicitSize: Math.round(dock.iconSize * 0.42)
                        source: Quickshell.iconPath(win.entry?.icon ?? "", "application-x-executable")
                    }
                    Mark {   // focused / asking for attention
                        on: true
                        urgent: win.modelData.urgent
                        opacity: win.modelData.urgent || win.focused ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
                    }

                    MouseArea {
                        id: winArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onContainsMouseChanged: dock.hovering(win, (win.modelData.title || win.entry?.name || "") + (win.minimised ? "  (minimised)" : ""), containsMouse)
                        // Left: bring it up (or minimise it when it already is the front window).
                        // Middle: close. Right: menu.
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) menu.openFor(win, win.entry)
                            else if (mouse.button === Qt.MiddleButton) dock.close(win.modelData)
                            else if (win.focused && !win.minimised) dock.minimise(win.modelData)
                            else dock.focus(win.modelData)
                        }
                    }
                }
            }
        }
    }

    // where an icon's middle is, along the dock, in window coordinates
    function middleOf(item) {
        const p = item.mapToItem(dock.contentItem, 0, 0)
        return (vertical ? p.y : p.x) + (item.mid ?? (vertical ? item.height : item.width) / 2)
    }
    // a box of size w x h beside the island, on the desktop side, centred on `at` along the dock
    function beside(w, h, at, gap) {
        const along = Math.max(8, Math.min((vertical ? dock.height - h : dock.width - w) - 8, at - (vertical ? h : w) / 2))
        const across = sign > 0 ? (vertical ? island.x - w : island.y - h) - gap : (vertical ? island.x + island.width : island.y + island.height) + gap
        return vertical ? Qt.point(across, along) : Qt.point(along, across)
    }
    // the screen side the icons grow and lift from (Item.TransformOrigin)
    readonly property int edgeOrigin: ({ bottom: Item.Bottom, top: Item.Top, left: Item.Left, right: Item.Right })[edge]
    // this window's top-left on the screen (Anchor: panels opened from the dock appear beside it)
    function origin() {   // Hyprland puts this window inside the bar's room on the edges they share
        const s = dock.screen, bh = Theme.barShownOn(s) ? Theme.barHeight : 0, be = Theme.barEdge
        return Qt.point(edge === "right" ? s.width - dock.width - (be === "right" ? bh : 0) : (be === "left" ? bh : 0),
                        edge === "bottom" ? s.height - dock.height - (be === "bottom" ? bh : 0) : (be === "top" ? bh : 0))
    }

    // the tooltip, beside the island at the hovered icon; hover-to-hover it moves without waiting
    Rectangle {
        id: tip
        readonly property bool on: dock.tipReady && dock.tipItem !== null && menu.entry === null && dock.dragId === ""
        readonly property point at: dock.tipItem ? dock.beside(width, height, dock.middleOf(dock.tipItem), 8) : Qt.point(0, 0)
        x: at.x; y: at.y
        width: tipLabel.implicitWidth + 16
        height: 24
        radius: Theme.radiusSmall
        color: Theme.menu
        border { color: Theme.stroke; width: Theme.line }
        opacity: on ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Text {
            id: tipLabel
            anchors.centerIn: parent
            text: dock.tipText
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
    }

    // Right-click menu for one dock icon: its windows, then actions
    Glass {
        id: menu
        property var entry: null      // DesktopEntry
        property var item: null       // the dock icon it belongs to
        readonly property var windows: item?.windows ?? []   // a window tile has just its own window
        readonly property bool pinned: entry ? Config.dock.pinned.includes(entry.id) : false
        function openFor(icon, appEntry) { item = icon; entry = appEntry ?? icon.modelData; closeTimer.restart() }
        function done() { entry = null; item = null }

        visible: entry !== null
        strong: true
        radius: Theme.radius
        width: 220
        height: actions.implicitHeight + Theme.spaceS * 2
        readonly property point at: item ? dock.beside(width, height, dock.middleOf(item), Theme.spaceS) : Qt.point(0, 0)
        x: at.x; y: at.y

        // closes a moment after the pointer leaves it (or never enters it)
        HoverHandler { onHoveredChanged: if (!hovered) closeTimer.restart(); else closeTimer.stop() }
        Timer { id: closeTimer; interval: 1500; onTriggered: menu.done() }

        Column {
            id: actions
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
            Text {
                width: parent.width; leftPadding: Theme.spaceS; bottomPadding: Theme.spaceXs
                text: menu.entry?.name ?? ""; elide: Text.ElideRight
                color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
            }
            Repeater {
                model: menu.windows.slice(0, 8).map(t => ({
                    label: t.title || menu.entry?.name || "", window: t, run: () => dock.focus(t)
                })).concat([
                    { label: "New window", show: menu.entry !== null, run: () => menu.entry.execute() },
                    { label: "Minimise", show: menu.windows.some(t => !dock.isMinimised(t)), run: () => menu.windows.forEach(dock.minimise) },
                    { label: "Restore", show: menu.windows.some(dock.isMinimised), run: () => menu.windows.filter(dock.isMinimised).forEach(dock.restore) },
                    { label: menu.pinned ? "Unpin from dock" : "Pin to dock", show: menu.entry !== null, run: () => dock.setPinned(menu.entry, !menu.pinned) },
                    { label: menu.item?.mid !== undefined ? "Close window" : menu.windows.length > 1 ? `Quit (${menu.windows.length} windows)` : "Quit", show: menu.windows.length > 0, run: () => menu.windows.forEach(dock.close) }
                ].filter(a => a.show).map((a, i) => Object.assign(a, { sep: i === 0 && menu.windows.length > 0 })))
                Item {
                    id: menuRow
                    required property var modelData
                    width: actions.width
                    height: Theme.controlHeight - 2 + (modelData.sep ? 9 : 0)
                    Rectangle {   // between the windows and the actions
                        visible: !!menuRow.modelData.sep
                        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 4; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS }
                        height: 1
                        color: Theme.stroke
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: Theme.controlHeight - 2
                        radius: Theme.radiusSmall - 2
                        color: rowArea.containsMouse ? Theme.accent : "transparent"
                        Row {
                            anchors { left: parent.left; right: parent.right; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS; verticalCenter: parent.verticalCenter }
                            spacing: 6
                            Rectangle {   // window rows: focused / minimised marker
                                visible: !!menuRow.modelData.window
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6; height: 6; radius: 3
                                color: rowArea.containsMouse ? Theme.accentText : Theme.text
                                opacity: menuRow.modelData.window?.activated ? 1 : dock.isMinimised(menuRow.modelData.window ?? {}) ? 0.25 : 0.55
                            }
                            Text {
                                width: parent.width - (menuRow.modelData.window ? 12 : 0)
                                text: menuRow.modelData.label; elide: Text.ElideRight
                                color: rowArea.containsMouse ? Theme.accentText : Theme.text
                                font { family: Theme.font; pixelSize: Theme.fontSize }
                            }
                        }
                        MouseArea {
                            id: rowArea
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { menuRow.modelData.run(); menu.done() }
                        }
                    }
                }
            }
        }
    }

    // the open-app mark on the edge side of an icon (theme dock.mark): a dot, a short line, or a
    // square bar; longer and in the accent when focused
    component Mark: Rectangle {
        property bool on: false
        property bool urgent: false
        readonly property real len: dock.indicator === "line" ? (on ? 16 : 8) : dock.indicator === "bar" ? (on ? 22 : 10) : 4
        readonly property real thick: dock.indicator === "dot" ? 4 : 3
        x: dock.vertical ? (dock.sign > 0 ? parent.width - thick - 1 : 1) : (parent.width - width) / 2
        y: dock.vertical ? (parent.height - height) / 2 : (dock.sign > 0 ? parent.height - thick - 1 : 1)
        width: dock.vertical ? thick : len
        height: dock.vertical ? len : thick
        radius: dock.indicator === "bar" ? 0 : thick / 2
        color: urgent ? Theme.warning : on ? Theme.accent : dock.ink
        Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    }
    component Separator: Rectangle {
        width: dock.vertical ? dock.iconSize * 0.7 : 1
        height: dock.vertical ? 1 : dock.iconSize * 0.7
        color: Qt.alpha(dock.ink, 0.2)
    }
}
