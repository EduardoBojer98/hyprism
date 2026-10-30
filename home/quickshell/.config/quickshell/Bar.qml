import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Floating glass top bar: workspaces | clock | tray · layout · status (opens Control Center) · power
PanelWindow {
    id: bar

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var battery: UPower.displayDevice

    anchors { top: true; left: true; right: true }
    implicitHeight: 44
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"

    PwObjectTracker { objects: [bar.sink] }

    Glass {
        anchors { fill: parent; topMargin: 6; leftMargin: 12; rightMargin: 12 }
        radius: height / 2

        // Workspaces on this screen: the active one is a wide pill
        Row {
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            spacing: 6

            Repeater {
                model: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === bar.monitor)

                Rectangle {
                    required property HyprlandWorkspace modelData
                    readonly property bool current: modelData.active && modelData.monitor === bar.monitor

                    width: current ? 26 : 8
                    height: 8
                    radius: 4
                    color: current ? Theme.accent
                         : modelData.urgent ? Theme.peach
                         : modelData.toplevels.values.length > 0 ? Theme.subtext : Theme.fillActive
                    Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: Theme.anim } }

                    MouseArea {
                        anchors { fill: parent; margins: -5 }
                        cursorShape: Qt.PointingHandCursor
                        onClicked: parent.modelData.activate()
                    }
                }
            }
        }

        SystemClock { id: clock; precision: SystemClock.Minutes }

        Text {
            anchors.centerIn: parent
            text: Qt.formatDateTime(clock.date, "ddd d MMM   HH:mm")
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
        }

        RowLayout {
            anchors { right: parent.right; rightMargin: 7; verticalCenter: parent.verticalCenter }
            spacing: 2

            // System tray: left click opens the app, right click its menu, middle click its secondary action
            Repeater {
                model: SystemTray.items

                MouseArea {
                    id: trayItem
                    required property SystemTrayItem modelData
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate()
                        else if (mouse.button === Qt.RightButton || modelData.onlyMenu) { if (modelData.hasMenu) trayMenu.open() }
                        else modelData.activate()
                    }
                    onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: trayItem.containsMouse ? Theme.fillHover : "transparent"
                    }
                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: trayItem.modelData.icon
                    }
                    QsMenuAnchor {
                        id: trayMenu
                        menu: trayItem.modelData.menu
                        anchor.item: trayItem
                        anchor.edges: Edges.Bottom
                        anchor.gravity: Edges.Bottom
                        anchor.margins.top: 8
                    }
                }
            }

            Rectangle { // divider between tray and the rest
                visible: SystemTray.items.values.length > 0
                Layout.preferredWidth: 1
                Layout.preferredHeight: 16
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                color: Theme.stroke
            }

            // Keyboard layout, updated from Hyprland's activelayout event
            Chip {
                id: layoutChip
                label: "US"
                onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
                Connections {
                    target: Hyprland
                    function onRawEvent(event) {
                        if (event.name === "activelayout")
                            layoutChip.label = event.data.includes("Serbian") ? "SR" : "US"
                    }
                }
                Process { // starting value: the main keyboard's current layout
                    running: true
                    command: ["hyprctl", "-j", "devices"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            const main = JSON.parse(text).keyboards.find(k => k.main)
                            if (main) layoutChip.label = main.active_keymap.includes("Serbian") ? "SR" : "US"
                        }
                    }
                }
            }

            // Status pill: Wi-Fi, Bluetooth, volume, battery in one. Opens the Control Center.
            Chip {
                id: statusChip
                readonly property int vol: Math.round((bar.sink?.audio?.volume ?? 0) * 100)
                readonly property int pct: Math.round((bar.battery?.percentage ?? 0) * 100)
                readonly property bool charging: bar.battery?.state === UPowerDeviceState.Charging || !UPower.onBattery
                active: controlCenter.visible
                icon: [
                    bar.wired ? "\u{F0200}" : bar.network ? "\u{F05A9}" : "\u{F05AA}",
                    bar.adapter?.enabled ? "\u{F00AF}" : "",
                    bar.sink?.audio?.muted ? "\u{F075F}" : "\u{F057E}",
                    charging ? "\u{F0084}" : pct >= 95 ? "\u{F0079}" : String.fromCodePoint(0xF007A + Math.max(0, Math.floor(pct / 10) - 1)),
                ].filter(i => i).join("  ")
                iconColor: pct <= 15 && !charging ? Theme.red : Theme.text
                label: (bar.battery?.isPresent ?? false) ? pct + "%" : ""
                onClicked: controlCenter.visible = !controlCenter.visible
                onScrolled: d => { const a = bar.sink?.audio; if (a) a.volume = Math.max(0, Math.min(1, a.volume + d * 0.05)) }
            }

            Chip {
                id: powerChip
                icon: "\u{F0425}"
                active: powerMenu.visible
                onClicked: powerMenu.visible = !powerMenu.visible
            }
        }
    }

    ControlCenter {
        id: controlCenter
        anchorItem: statusChip
    }

    // Power menu under the power button; closes on a choice or a click elsewhere
    PopupWindow {
        id: powerMenu
        anchor.item: powerChip
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.top: 12
        grabFocus: true
        implicitWidth: 200
        implicitHeight: menuColumn.implicitHeight + 14
        color: "transparent"

        Glass {
            anchors.fill: parent
            strong: true

            Column {
                id: menuColumn
                anchors { fill: parent; margins: 7 }

                Repeater {
                    model: [
                        { icon: "\u{F033E}", label: "Lock",      cmd: ["loginctl", "lock-session"] },
                        { icon: "\u{F04B2}", label: "Suspend",   cmd: ["systemctl", "suspend"] },
                        { icon: "\u{F0717}", label: "Hibernate", cmd: ["systemctl", "hibernate"] },
                        { icon: "\u{F0343}", label: "Log out",   cmd: ["hyprshutdown"] },
                        { icon: "\u{F0709}", label: "Restart",   cmd: ["systemctl", "reboot"] },
                        { icon: "\u{F0425}", label: "Shut down", cmd: ["systemctl", "poweroff"], danger: true },
                    ]

                    Rectangle {
                        required property var modelData
                        width: menuColumn.width
                        height: 36
                        radius: 10
                        color: item.containsMouse ? Theme.fillHover : "transparent"

                        Row {
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            spacing: 12
                            Text {
                                text: modelData.icon
                                color: modelData.danger ? Theme.red : Theme.text
                                font { family: Theme.iconFont; pixelSize: 15 }
                            }
                            Text {
                                text: modelData.label
                                color: Theme.text
                                font { family: Theme.font; pixelSize: Theme.fontSize }
                            }
                        }

                        MouseArea {
                            id: item
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                powerMenu.visible = false
                                Quickshell.execDetached(modelData.cmd)
                            }
                        }
                    }
                }
            }
        }
    }
}
