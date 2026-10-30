import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

// Dock: pinned apps (Config.dock.pinned) then other running apps. With auto-hide it slides up when
// the pointer touches the bottom edge and stays visible on an empty workspace. Right-click an icon
// to pin, minimise (to Hyprland's special:minimized workspace), restore or quit.
PanelWindow {
    id: dock

    readonly property int iconSize: Config.dock.iconSize
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property bool emptyWorkspace: (monitor?.activeWorkspace?.toplevels.values.length ?? 0) === 0
    readonly property bool shown: !Config.dock.autoHide || hover.hovered || hideTimer.running || emptyWorkspace || menu.entry !== null

    function entryFor(appId) { return DesktopEntries.heuristicLookup(appId) }
    // Hyprland's view of the windows (address + workspace), linked to the Wayland toplevel for activate()
    function windowsOf(entry) {
        return entry ? Hyprland.toplevels.values.filter(t => t.wayland && entryFor(t.wayland.appId)?.id === entry.id) : []
    }
    function isMinimised(t) { return t.workspace?.name === "special:minimized" }
    function address(t) { return "0x" + String(t.address).replace(/^0x/, "") }
    function dispatch(lua) { Quickshell.execDetached(["hyprctl", "dispatch", lua]) }
    function minimise(t) { dispatch(`hl.dsp.window.move({ workspace = "special:minimized", follow = false, window = "address:${address(t)}" })`) }
    function restore(t) { dispatch(`hl.dsp.window.move({ workspace = "${monitor?.activeWorkspace?.id ?? 1}", window = "address:${address(t)}" })`) }
    function close(t) { dispatch(`hl.dsp.window.close({ window = "address:${address(t)}" })`) }
    function setPinned(entry, pin) {
        const list = Config.dock.pinned.filter(id => id !== entry.id)
        if (pin) list.push(entry.id)
        Config.set("dock", "pinned", list)
    }

    readonly property var apps: {
        const list = Config.dock.pinned.map(id => DesktopEntries.byId(id)).filter(e => e)
        if (Config.dock.showRunning)
            for (const t of ToplevelManager.toplevels.values) {
                const e = entryFor(t.appId)
                if (e && !list.some(x => x.id === e.id)) list.push(e)
            }
        return list
    }

    anchors.bottom: true
    implicitWidth: island.width + 40
    implicitHeight: menu.entry ? 340 : 120 // island + room above it for tooltips / the app menu
    exclusiveZone: Config.dock.autoHide ? 0 : island.height + 10
    color: "transparent"
    WlrLayershell.namespace: "qs-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Only the visible island (or a thin strip at the bottom edge when hidden) takes input
    mask: Region { item: dock.shown ? island : edge; Region { item: menu.entry ? menu : null } }

    Item {
        id: edge
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
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
        y: dock.shown ? parent.height - height - 10 : parent.height + 4
        Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

        width: row.width + 20
        height: dock.iconSize + 22
        radius: Theme.radiusLarge

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            // App menu / Spotlight-style launcher
            Item {
                width: dock.iconSize + 4
                height: dock.iconSize + 8

                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                    width: dock.iconSize
                    height: dock.iconSize
                    radius: 12
                    color: launcherArea.containsMouse || Launcher.open ? Theme.accent : Theme.fill
                    scale: launcherArea.containsMouse ? 1.18 : 1
                    transformOrigin: Item.Bottom
                    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.anim } }

                    Text {
                        anchors.centerIn: parent
                        text: "\u{F003B}"
                        color: launcherArea.containsMouse || Launcher.open ? Theme.accentText : Theme.text
                        font { family: Theme.iconFont; pixelSize: dock.iconSize / 2 }
                    }
                }

                MouseArea {
                    id: launcherArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Launcher.toggle()
                }

                ToolTip { visible: launcherArea.containsMouse; text: "Apps & search" }
            }

            Rectangle { // divider
                width: 1
                height: 36
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.fill
            }

            Repeater {
                model: dock.apps

                Item {
                    id: app
                    required property DesktopEntry modelData
                    readonly property var windows: dock.windowsOf(modelData)
                    readonly property var visibleWindows: windows.filter(t => !dock.isMinimised(t))

                    width: dock.iconSize + 4
                    height: dock.iconSize + 8

                    IconImage {
                        id: icon
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                        implicitSize: dock.iconSize
                        source: Quickshell.iconPath(app.modelData?.icon ?? "", "application-x-executable")
                        scale: area.containsMouse ? 1.18 : 1
                        transformOrigin: Item.Bottom
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }

                    // Running indicator
                    Rectangle {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        width: app.windows.some(w => w.activated) ? 14 : 5
                        opacity: app.visibleWindows.length ? 1 : 0.4
                        height: 4
                        radius: 2
                        color: Theme.accent
                        visible: app.windows.length > 0
                        Behavior on width { NumberAnimation { duration: Theme.anim } }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        // Left: focus the app (cycling through its windows), bring back minimised ones, or start it.
                        // Middle: always a new window. Right: pin / minimise / quit menu.
                        onClicked: mouse => {
                            if (!app.modelData) return   // delegate is being replaced
                            if (mouse.button === Qt.RightButton) { menu.openFor(app); return }
                            const w = app.visibleWindows
                            if (mouse.button === Qt.MiddleButton || app.windows.length === 0) { app.modelData.execute(); return }
                            if (w.length === 0) { for (const t of app.windows) dock.restore(t); return }
                            const i = w.findIndex(t => t.activated)
                            w[(i + 1) % w.length].wayland.activate()
                        }
                    }

                    ToolTip {
                        visible: area.containsMouse && menu.entry === null
                        text: app.modelData?.name ?? ""
                    }
                }
            }
        }
    }

    // Right-click menu for one dock icon
    Glass {
        id: menu
        property var entry: null      // DesktopEntry
        property var item: null       // the dock icon it belongs to
        readonly property var windows: item?.windows ?? []
        readonly property bool pinned: entry ? Config.dock.pinned.includes(entry.id) : false
        function openFor(icon) { item = icon; entry = icon.modelData }
        function done() { entry = null; item = null }

        visible: entry !== null
        strong: true
        radius: Theme.radius
        width: 200
        height: actions.implicitHeight + Theme.spaceS * 2
        x: item ? Math.max(8, Math.min(dock.width - width - 8, item.mapToItem(dock.contentItem, item.width / 2, 0).x - width / 2)) : 0
        y: island.y - height - Theme.spaceS

        HoverHandler { onHoveredChanged: if (!hovered) closeTimer.restart(); else closeTimer.stop() }
        Timer { id: closeTimer; interval: 900; onTriggered: menu.done() }

        Column {
            id: actions
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
            Text {
                width: parent.width; leftPadding: Theme.spaceS; bottomPadding: Theme.spaceXs
                text: menu.entry?.name ?? ""; elide: Text.ElideRight
                color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
            }
            Repeater {
                model: [
                    { label: "New window", show: true, run: () => menu.entry.execute() },
                    { label: "Minimise", show: menu.windows.some(t => !dock.isMinimised(t)), run: () => menu.windows.forEach(dock.minimise) },
                    { label: "Restore", show: menu.windows.some(dock.isMinimised), run: () => menu.windows.filter(dock.isMinimised).forEach(dock.restore) },
                    { label: menu.pinned ? "Unpin from dock" : "Pin to dock", show: true, run: () => dock.setPinned(menu.entry, !menu.pinned) },
                    { label: menu.windows.length > 1 ? `Quit (${menu.windows.length} windows)` : "Quit", show: menu.windows.length > 0, run: () => menu.windows.forEach(dock.close) }
                ].filter(a => a.show)
                Rectangle {
                    required property var modelData
                    width: actions.width; height: Theme.controlHeight
                    radius: Theme.radiusSmall
                    color: rowArea.containsMouse ? Theme.fillHover : "transparent"
                    Text {
                        anchors { left: parent.left; leftMargin: Theme.spaceS; verticalCenter: parent.verticalCenter }
                        text: parent.modelData.label; color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontSize }
                    }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { parent.modelData.run(); menu.done() }
                    }
                }
            }
        }
    }

    component ToolTip: Rectangle {
        property string text
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: 14 }
        width: label.implicitWidth + 16
        height: 24
        radius: 6
        color: Theme.glassStrong
        Text {
            id: label
            anchors.centerIn: parent
            text: parent.text
            color: Theme.text
            font { family: Theme.font; pixelSize: 12 }
        }
    }
}
