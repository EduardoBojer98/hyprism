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
import QtQuick.Controls

// Top bar as a row of floating glass complications:
//   workspaces · focused app · weather        clock        temperatures · tray · status · power
// Blue marks only the active workspace and an open panel; amber/red appear only when a value
// leaves its normal range. The status capsule opens the Control Center.
PanelWindow {
    id: bar

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var battery: UPower.displayDevice
    property string appClass: ""   // focused window, from Hyprland's activewindow event
    property string appTitle: ""
    property string layout: "US"

    anchors { top: true; left: true; right: true }
    implicitHeight: 64
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"

    PwObjectTracker { objects: [bar.sink] }

    // Keyboard layout: starting value from hyprctl, then Hyprland's activelayout events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") bar.layout = event.data.includes("Serbian") ? "SR" : "US"
            else if (event.name === "activewindow") {
                const comma = event.data.indexOf(",")
                bar.appClass = event.data.slice(0, comma)
                bar.appTitle = event.data.slice(comma + 1)
            }
        }
    }
    Process {
        running: true
        command: ["hyprctl", "-j", "activewindow"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { const w = JSON.parse(text); bar.appClass = w.class ?? ""; bar.appTitle = w.title ?? "" } catch (e) {}
            }
        }
    }
    Process {
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const main = JSON.parse(text).keyboards.find(k => k.main)
                if (main) bar.layout = main.active_keymap.includes("Serbian") ? "SR" : "US"
            }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Item {
        anchors { fill: parent; topMargin: 10; leftMargin: 12; rightMargin: 12; bottomMargin: 14 }

        // ---- left ----------------------------------------------------------------------------
        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: 8

            Capsule { // workspaces on this screen
                Repeater {
                    model: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === bar.monitor)
                    Rectangle {
                        required property HyprlandWorkspace modelData
                        readonly property bool current: modelData.active
                        readonly property bool busy: modelData.toplevels.values.length > 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: current ? 34 : 24
                        height: 24
                        radius: 12
                        color: current ? Theme.accent : wsArea.containsMouse ? Theme.fillHover : modelData.urgent ? Qt.rgba(0.96, 0.66, 0.5, 0.3) : Theme.fill
                        Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Theme.anim } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.id
                            color: parent.current ? Theme.accentText : parent.busy ? Theme.text : Theme.muted
                            font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold; features: { "tnum": 1 } }
                        }
                        MouseArea { id: wsArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.activate() }
                    }
                }
            }

            Capsule { // focused app, on the screen that holds it
                id: appCapsule
                // Focused screen: the focused window. Other screen: the window on its visible workspace, dimmed.
                readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === bar.monitor?.name
                readonly property var other: focusedScreen ? null : (bar.monitor?.activeWorkspace?.toplevels.values[0] ?? null)
                readonly property string appId: focusedScreen ? bar.appClass : (other?.wayland?.appId ?? "")
                readonly property string title: focusedScreen ? bar.appTitle : (other?.title ?? "")
                readonly property var entry: appId ? DesktopEntries.heuristicLookup(appId) : null
                visible: appId !== ""
                opacity: focusedScreen ? 1 : 0.7
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 18
                    source: Quickshell.iconPath(appCapsule.entry?.icon ?? "", "application-x-executable")
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: appCapsule.entry?.name ?? appCapsule.appId
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 300)
                    elide: Text.ElideRight
                    text: appCapsule.title
                    visible: appCapsule.title !== "" && appCapsule.title !== (appCapsule.entry?.name ?? appCapsule.appId)
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: 12 }
                }
            }

            Capsule { // weather
                visible: Weather.ready
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.glyph
                    color: Theme.text
                    font { family: Theme.iconFont; pixelSize: 18 }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: Math.round(Weather.temperature) + "°"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold; features: { "tnum": 1 } }
                    }
                    Text {
                        text: Weather.city + " · " + Weather.condition
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: 11 }
                    }
                }
            }
        }

        // ---- centre: the clock leads ---------------------------------------------------------
        Capsule {
            id: clockCapsule
            anchors.centerIn: parent
            horizontalPadding: 22
            interactive: true
            active: NotificationCenter.open
            onClicked: NotificationCenter.toggle()
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.text
                    lineHeight: 0.95
                    lineHeightMode: Text.ProportionalHeight
                    font { family: Theme.font; pixelSize: 20; weight: Font.Bold; features: { "tnum": 1 } }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd d MMMM")
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: 11 }
                }
            }
            // Do Not Disturb, or how many notifications came in since the centre was opened
            Row {
                anchors.verticalCenter: parent.verticalCenter
                visible: Notifications.dnd || Notifications.unread > 0
                spacing: 3
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifications.dnd ? "\u{F009B}" : "\u{F009A}"
                    color: Notifications.dnd ? Theme.subtext : Theme.accent
                    font { family: Theme.iconFont; pixelSize: 15 }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Notifications.unread > 0
                    text: Notifications.unread
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold; features: { "tnum": 1 } }
                }
            }
        }

        // ---- right ---------------------------------------------------------------------------
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 8

            Capsule { // temperatures
                spacing: 8
                Ring { anchors.verticalCenter: parent.verticalCenter; value: Sensors.cpu }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "CPU"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold } }
                Item { width: 2; height: 1 }
                Ring { anchors.verticalCenter: parent.verticalCenter; value: Sensors.gpu }
                Text { anchors.verticalCenter: parent.verticalCenter; text: "GPU"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold } }
            }

            Capsule { // tray
                visible: SystemTray.items.values.length > 0
                spacing: 4
                Repeater {
                    model: SystemTray.items
                    MouseArea {
                        id: trayItem
                        required property SystemTrayItem modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate()
                            else if (mouse.button === Qt.RightButton || modelData.onlyMenu) { if (modelData.hasMenu) trayMenu.open() }
                            else modelData.activate()
                        }
                        onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)
                        Rectangle { anchors.fill: parent; radius: 14; color: trayItem.containsMouse ? Theme.fillHover : "transparent" }
                        IconImage { anchors.centerIn: parent; implicitSize: 16; source: trayItem.modelData.icon }
                        QsMenuAnchor {
                            id: trayMenu
                            menu: trayItem.modelData.menu
                            anchor.item: trayItem
                            anchor.edges: Edges.Bottom
                            anchor.gravity: Edges.Bottom
                            anchor.margins.top: 12
                        }
                    }
                }
            }

            Capsule { // status: layout, network, bluetooth, volume, battery → Control Center
                id: statusCapsule
                readonly property int pct: Math.round((bar.battery?.percentage ?? 0) * 100)
                readonly property bool charging: bar.battery?.state === UPowerDeviceState.Charging || !UPower.onBattery
                readonly property bool low: pct <= 15 && !charging
                interactive: true
                active: ControlCenter.open
                spacing: 12
                onClicked: ControlCenter.toggle()
                onScrolled: d => { const a = bar.sink?.audio; if (a) a.volume = Math.max(0, Math.min(1, a.volume + d * 0.05)) }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bar.layout
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: 11; weight: Font.DemiBold }
                }
                StatusGlyph {
                    glyph: bar.wired ? "\u{F0200}" : bar.network ? "\u{F05A9}" : "\u{F05AA}"
                    tone: bar.wired || bar.network ? Theme.text : Theme.red
                }
                StatusGlyph {
                    visible: bar.adapter?.enabled ?? false
                    glyph: (bar.adapter?.devices.values.some(d => d.connected) ?? false) ? "\u{F00B1}" : "\u{F00AF}"
                    tone: Theme.text
                }
                StatusGlyph {
                    glyph: bar.sink?.audio?.muted ? "\u{F075F}" : "\u{F057E}"
                    tone: bar.sink?.audio?.muted ? Theme.muted : Theme.text
                }
                Row {
                    visible: bar.battery?.isPresent ?? false
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: statusCapsule.charging ? "\u{F0084}" : statusCapsule.pct >= 95 ? "\u{F0079}" : String.fromCodePoint(0xF007A + Math.max(0, Math.floor(statusCapsule.pct / 10) - 1))
                        color: statusCapsule.low ? Theme.red : Theme.text
                        font { family: Theme.iconFont; pixelSize: 16 }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: statusCapsule.pct + "%"
                        color: statusCapsule.low ? Theme.red : Theme.text
                        font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold; features: { "tnum": 1 } }
                    }
                }
            }

            Capsule { // power
                id: powerCapsule
                horizontalPadding: 12
                interactive: true
                active: UtilityMenu.open
                onClicked: UtilityMenu.toggle()
                StatusGlyph { glyph: "\u{F0425}"; tone: Theme.text }
            }
        }
    }
}
