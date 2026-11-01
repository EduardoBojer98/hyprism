import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

// Dock: the all-apps button, pinned apps (Config.dock.pinned, drag to reorder), a divider, then
// every window on this dock's monitor as its own live thumbnail with the app's icon on it. With auto-hide it slides up
// when the pointer touches the bottom edge and stays visible on an empty workspace.
// Right-click an icon or a window for windows and pin / minimise / restore / quit.
// Its look (Appearance > Dock) is a set of separate options: shape (Config.dock.style), colour (tint),
// the open-app mark (indicator) and what hovering an icon does (hover).
PanelWindow {
    id: dock

    readonly property int iconSize: Config.dock.iconSize
    readonly property string style: Config.dock.style
    readonly property int lift: style === "panel" ? 0 : 10     // gap under the island
    readonly property bool bare: style === "clear" || style === "shelf"   // no surface around the icons
    readonly property string indicator: Config.dock.indicator
    readonly property string hoverStyle: Config.dock.hover
    readonly property int slot: iconSize + 4          // one icon's cell
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
    property real dragX: 0            // pointer, in row coordinates
    readonly property var pinnedIds: dragOrder ?? Config.dock.pinned
    readonly property var pinnedEntries: appCount ? pinnedIds.map(id => DesktopEntries.byId(id)).filter(e => e) : []
    function dragTo(x) {
        dragX = x
        const first = launcher.width + row.spacing * 2 + 1          // launcher + divider
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

    // A fixed full-width strip: the surface never resizes when apps open or the menu shows (resizing
    // a layer surface made the dock jump and flicker); the input mask limits it to the island.
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 340   // island + room above it for tooltips / the app menu
    exclusiveZone: Config.dock.autoHide ? 0 : island.height + dock.lift
    color: "transparent"
    WlrLayershell.namespace: "qs-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Only the visible island (or a thin strip at the bottom edge when hidden) takes input
    mask: Region { item: dock.shown ? island : edge; Region { item: menu.entry ? menu : null } }

    Item {
        id: edge
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
        width: island.width
        height: 4
    }

    HoverHandler {
        id: hover
        onHoveredChanged: if (!hovered) hideTimer.restart()
    }
    Timer { id: hideTimer; interval: 500 }

    Glass {
        id: island
        anchors.horizontalCenter: parent.horizontalCenter
        y: dock.shown ? parent.height - height - dock.lift : parent.height + 4
        opacity: dock.shown ? 1 : 0
        Behavior on y { NumberAnimation { duration: Theme.animate ? 260 : 0; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
        Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

        width: dock.style === "panel" ? parent.width : row.implicitWidth + (dock.style === "pill" ? 24 : 16)
        height: dock.iconSize + 16
        radius: dock.style === "panel" ? 0 : dock.style === "pill" ? height / 2 : Theme.radiusLarge + 4
        flat: dock.bare
        color: dock.bare ? "transparent" : dock.style === "panel" && Config.dock.tint === "glass" ? Theme.glassStrong : Theme.surface(Config.dock.tint)
        border.width: dock.bare ? 0 : 1

        Rectangle {   // shelf: the icons stand on a glass slab
            visible: dock.style === "shelf"
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Math.round(parent.height * 0.42)
            radius: Theme.radiusSmall
            color: Theme.surface(Config.dock.tint === "glass" ? "solid" : Config.dock.tint)
            border { color: Theme.strokeStrong; width: 1 }
        }

        Row {
            id: row
            anchors { left: dock.style === "panel" ? undefined : parent.left; leftMargin: dock.style === "pill" ? 12 : 8
                      horizontalCenter: dock.style === "panel" ? parent.horizontalCenter : undefined
                      verticalCenter: parent.verticalCenter }
            spacing: 6

            // App menu / Spotlight-style launcher
            Item {
                id: launcher
                width: dock.slot
                height: dock.iconSize + 8

                // a frosted tile with a 2 x 2 grid; on hover the grid turns a quarter and one square
                // becomes an accent dot
                Rectangle {
                    id: launcherTile
                    readonly property bool lit: Launcher.open || launcherArea.containsMouse
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                    width: dock.iconSize
                    height: dock.iconSize
                    radius: Math.round(dock.iconSize * 0.27)
                    color: launcherTile.lit ? Theme.fillActive : Theme.fill
                    border { color: launcherTile.lit ? Theme.strokeStrong : Theme.stroke; width: 1 }
                    scale: launcherArea.pressed ? 0.92 : 1
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.anim } }

                    Rectangle {   // top sheen, like light on glass
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
                        rotation: launcherTile.lit ? 45 : 0
                        Behavior on rotation { NumberAnimation { duration: Theme.anim * 1.5; easing.type: Easing.OutBack } }
                        Repeater {
                            model: 4
                            Rectangle {
                                required property int index
                                readonly property bool dot: index === 1 && launcherTile.lit
                                width: dots.cell; height: dots.cell
                                radius: dot ? dots.cell / 2 : dots.cell * 0.3
                                color: index === 1 ? Theme.accent : Theme.text
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
                    onClicked: Launcher.toggle()
                }
            }

            Rectangle { // divider
                width: 1
                height: dock.iconSize * 0.7
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.stroke
            }

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

                    width: dock.slot
                    height: dock.iconSize + 8
                    z: dragged ? 1 : 0
                    // neighbours glide aside while an icon is dragged past them
                    Behavior on x { enabled: dock.dragId !== ""; NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

                    Item {
                        id: cell
                        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                        width: dock.slot
                        // the dragged icon follows the pointer
                        transform: Translate {
                            x: app.dragged ? dock.dragX - (app.x + app.width - cell.width / 2) : 0
                            y: app.dragged ? -4 : 0
                        }

                        // hover plate: a soft tile behind the icon (hover "plate"; always while dragged or in a menu)
                        Rectangle {
                            anchors { fill: parent; topMargin: -2 }
                            radius: Theme.radius
                            color: area.pressed || app.dragged ? Theme.fillActive : Theme.fillHover
                            opacity: area.containsMouse && dock.hoverStyle === "plate" || app.dragged || menu.item === app ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        }

                        IconImage {
                            id: icon
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top
                                      topMargin: dock.hoverStyle === "lift" && area.containsMouse && !app.dragged ? -8 : 0 }
                            Behavior on anchors.topMargin { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
                            implicitSize: dock.iconSize
                            source: Quickshell.iconPath(app.modelData?.icon ?? "", "application-x-executable")
                            transformOrigin: Item.Bottom
                            scale: area.pressed && !app.dragged ? 0.9 : dock.hoverStyle === "grow" && area.containsMouse && !app.dragged ? 1.22 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }

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
                        onPressed: mouse => { pressX = mouse.x; moved = false }
                        // drag a pinned icon sideways to reorder
                        onPositionChanged: mouse => {
                            if (!pressed || pressedButtons !== Qt.LeftButton || !app.pinned) return
                            if (!app.dragged && Math.abs(mouse.x - pressX) < 8) return
                            if (!app.dragged) { moved = true; dock.dragId = app.modelData.id }
                            dock.dragTo(mapToItem(row, mouse.x, 0).x)
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

            Rectangle { // divider before the open windows
                visible: dock.openWindows.length > 0
                width: 1
                height: dock.iconSize * 0.7
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.stroke
            }

            // ---- open windows: a live picture of each, its app's icon in the corner ---------------
            Repeater {
                model: ScriptModel { values: dock.openWindows }

                Item {
                    id: win
                    required property var modelData           // HyprlandToplevel
                    readonly property var entry: dock.entryFor(modelData.wayland?.appId ?? "")
                    readonly property bool minimised: dock.isMinimised(modelData)
                    readonly property bool focused: modelData.activated
                    readonly property real mid: width / 2   // tooltip / menu centre
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

                    width: dock.thumbWidth
                    height: dock.iconSize + 8

                    Rectangle {   // hover plate
                        anchors { fill: parent; topMargin: -2 }
                        radius: Theme.radius
                        color: winArea.pressed ? Theme.fillActive : Theme.fillHover
                        opacity: winArea.containsMouse && dock.hoverStyle === "plate" || menu.item === win ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }

                    Rectangle {
                        id: frame
                        readonly property real boxH: dock.iconSize - 4
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top
                                  topMargin: dock.hoverStyle === "lift" && winArea.containsMouse ? -6 : 2 }
                        Behavior on anchors.topMargin { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
                        height: Math.min(boxH, (win.width - 6) / win.aspect)
                        width: height * win.aspect
                        radius: Theme.radiusSmall - 2
                        color: Theme.fill
                        border { color: win.focused ? Theme.accent : Theme.stroke; width: win.focused ? 2 : 1 }
                        opacity: win.minimised ? 0.55 : 1
                        transformOrigin: Item.Bottom
                        scale: winArea.pressed ? 0.94 : dock.hoverStyle === "grow" && winArea.containsMouse ? 1.15 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack } }
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

    // the tooltip, above the island over the hovered icon
    Rectangle {
        readonly property bool on: dock.tipReady && dock.tipItem !== null && menu.entry === null && dock.dragId === ""
        x: dock.tipItem ? Math.max(8, Math.min(dock.width - width - 8,
               island.x + row.x + dock.tipItem.x + (dock.tipItem.mid ?? dock.tipItem.width - dock.slot / 2) - width / 2)) : 0
        y: island.y - height - 8 + (on ? 0 : 3)
        width: tipLabel.implicitWidth + 16
        height: 24
        radius: 7
        color: Theme.menu
        border { color: Theme.stroke; width: 1 }
        opacity: on ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        Behavior on y { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Text {
            id: tipLabel
            anchors.centerIn: parent
            text: dock.tipText
            color: Theme.text
            font { family: Theme.font; pixelSize: 12 }
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
        x: item ? Math.max(8, Math.min(dock.width - width - 8, item.mapToItem(dock.contentItem, item.mid ?? item.width - dock.slot / 2, 0).x - width / 2)) : 0
        y: island.y - height - Theme.spaceS

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

    // the open-app mark under an icon (Config.dock.indicator): a dot or a short line; brighter when focused
    component Mark: Rectangle {
        property bool on: false
        property bool urgent: false
        visible: dock.indicator !== "none" || urgent
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
        width: dock.indicator === "line" ? (on ? 16 : 8) : 4
        height: dock.indicator === "line" ? 3 : 4
        radius: height / 2
        color: urgent ? Theme.warning : on ? Theme.accent : Theme.text
        Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
    }
}
