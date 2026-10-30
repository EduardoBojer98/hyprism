import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

// Auto-hiding dock: slides up when the pointer touches the bottom edge, and stays
// visible on an empty workspace. Pinned apps first, then other running apps.
PanelWindow {
    id: dock

    // Desktop file IDs (ls /usr/share/applications)
    readonly property var pinned: ["firefox", "google-chrome", "com.microsoft.VSCode", "com.mitchellh.ghostty", "org.kde.dolphin", "com.anthropic.Claude", "org.opengamingcollective.rog-control-center"]

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property bool emptyWorkspace: (monitor?.activeWorkspace?.toplevels.values.length ?? 0) === 0
    readonly property bool shown: hover.hovered || hideTimer.running || emptyWorkspace

    function entryFor(appId) { return DesktopEntries.heuristicLookup(appId) }
    function windowsOf(entry) {
        return entry ? ToplevelManager.toplevels.values.filter(t => entryFor(t.appId)?.id === entry.id) : []
    }

    readonly property var apps: {
        const list = pinned.map(id => DesktopEntries.byId(id)).filter(e => e)
        for (const t of ToplevelManager.toplevels.values) {
            const e = entryFor(t.appId)
            if (e && !list.some(x => x.id === e.id)) list.push(e)
        }
        return list
    }

    anchors.bottom: true
    implicitWidth: island.width + 40
    implicitHeight: 120 // island + room above it for tooltips
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "qs-dock"
    WlrLayershell.layer: WlrLayer.Top

    // Only the visible island (or a thin strip at the bottom edge when hidden) takes input
    mask: Region { item: dock.shown ? island : edge }

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
        height: 66
        radius: Theme.radiusLarge

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            // App menu / Spotlight-style launcher
            Item {
                width: 48
                height: 52

                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                    width: 44
                    height: 44
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
                        font { family: Theme.iconFont; pixelSize: 22 }
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

                    width: 48
                    height: 52

                    IconImage {
                        id: icon
                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top }
                        implicitSize: 44
                        source: Quickshell.iconPath(app.modelData?.icon ?? "", "application-x-executable")
                        scale: area.containsMouse ? 1.18 : 1
                        transformOrigin: Item.Bottom
                        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    }

                    // Running indicator
                    Rectangle {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                        width: app.windows.some(w => w.activated) ? 14 : 5
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
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        // Left: focus the app (cycling through its windows) or start it. Middle: always a new window.
                        onClicked: mouse => {
                            const w = app.windows
                            if (mouse.button === Qt.MiddleButton || w.length === 0) { app.modelData.execute(); return }
                            const i = w.findIndex(t => t.activated)
                            w[(i + 1) % w.length].activate()
                        }
                    }

                    ToolTip {
                        visible: area.containsMouse
                        text: app.modelData?.name ?? ""
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
