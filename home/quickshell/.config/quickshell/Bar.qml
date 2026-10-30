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

// Top bar: one thin frosted strip across the screen, monochrome items that light up on hover.
// Desktops are numbers in a recessed pill; an accent pill slides to the current one.
//   desktops · app name and title      weather · date and time (calendar)      tray · temperatures ·
//   keyboard layout (its own dropdown) · Wi-Fi/Bluetooth/volume/battery (Control Center) · notifications bell
// Amber/red appear only when a value leaves its normal range.
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

    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"

    PwObjectTracker { objects: [bar.sink] }

    // Focused app from Hyprland's activewindow events (the keyboard layout lives in Keyboard.qml)
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activewindow") {
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

    SystemClock { id: clock; precision: SystemClock.Minutes }

    // frosted strip: Hyprland blurs what's behind it (layer rule blur-shell), a hairline closes it off
    Rectangle {
        anchors.fill: parent
        color: Theme.light ? Qt.rgba(1, 1, 1, 0.55) : Theme.tinted(0.75, 0.40)
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 1
            color: Theme.light ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.06)
        }
    }

    Item {
        id: content
        anchors { fill: parent; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS }

        // ---- left ----------------------------------------------------------------------------
        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: 2

            Item { width: Theme.spaceXs; height: 1 }
            BarItem { // this computer: about, tools and power, behind the system logo (like the Apple menu)
                active: UtilityMenu.open
                onPressed: UtilityMenu.toggle()
                StatusGlyph { glyph: "\u{F303}"; font.pixelSize: 15 }   // Arch logo; Nerd Fonts has no CachyOS one
            }
            Item { width: Theme.spaceXs; height: 1 }
            Rectangle { // desktops on this screen: numbers in a recessed pill, an accent pill slides to the current one
                id: desks
                readonly property var list: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === bar.monitor).sort((a, b) => a.id - b.id)
                readonly property int current: list.findIndex(w => w.active)
                readonly property int slot: 22
                // scroll on it to step through this screen's desktops
                function step(dy) { const next = list[current + (dy < 0 ? 1 : -1)]; if (next) next.activate() }
                anchors.verticalCenter: parent.verticalCenter
                width: list.length * slot + 4
                height: 22
                radius: height / 2
                color: Theme.fill
                border { color: Theme.stroke; width: 1 }
                Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }

                Rectangle {
                    visible: desks.current >= 0
                    x: 2 + Math.max(0, desks.current) * desks.slot
                    y: 2
                    width: desks.slot; height: desks.height - 4
                    radius: height / 2
                    color: Theme.accent
                    Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                }

                Row {
                    x: 2; y: 2
                    Repeater {
                        model: desks.list
                        Item {
                            id: ws
                            required property HyprlandWorkspace modelData
                            required property int index
                            readonly property bool current: index === desks.current
                            readonly property bool busy: modelData.toplevels.values.length > 0
                            width: desks.slot; height: desks.height - 4
                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Theme.fillHover
                                opacity: wsArea.containsMouse && !ws.current ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: ws.modelData.id
                                color: ws.current ? Theme.accentText : ws.modelData.urgent ? Theme.warning
                                     : ws.busy || wsArea.containsMouse ? Theme.text : Theme.muted
                                font { family: Theme.font; pixelSize: 11; weight: ws.current || ws.busy ? Font.DemiBold : Font.Medium; features: { "tnum": 1 } }
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                            MouseArea { id: wsArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ws.modelData.activate(); onWheel: w => desks.step(w.angleDelta.y) }
                        }
                    }
                }
            }
            Item { width: Theme.spaceS; height: 1 }

            Item { // focused app, on the screen that holds it: bold name, then the window title
                id: app
                // Focused screen: the focused window. Other screen: the window on its visible workspace, dimmed.
                readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === bar.monitor?.name
                readonly property var other: focusedScreen ? null : (bar.monitor?.activeWorkspace?.toplevels.values[0] ?? null)
                readonly property string appId: focusedScreen ? bar.appClass : (other?.wayland?.appId ?? "")
                readonly property string title: focusedScreen ? bar.appTitle : (other?.title ?? "")
                readonly property var entry: appId && DesktopEntries.applications.values.length ? DesktopEntries.heuristicLookup(appId) : null
                // no desktop entry: "com.anthropic.Claude" -> "Claude"
                readonly property string name: entry?.name ?? (appId.split(".").pop().replace(/^./, c => c.toUpperCase()))
                anchors.verticalCenter: parent.verticalCenter
                visible: appId !== ""
                opacity: focusedScreen ? 1 : 0.6
                width: appRow.implicitWidth; height: 26
                Row {
                    id: appRow
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spaceM
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: app.name
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, bar.width * 0.3)
                        elide: Text.ElideRight
                        text: app.title
                        visible: app.title !== "" && app.title !== app.name
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: 13 }
                    }
                }
            }
        }

        // ---- centre: weather, then date and time ("Fri 30 Oct  14:40"), which opens the calendar ----
        Row {
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
            spacing: 2

            BarItem {   // weather: opens the forecast
                visible: Weather.ready
                active: Weather.open
                onPressed: Weather.toggle()
                spacing: 5
                Text { anchors.verticalCenter: parent.verticalCenter; text: Weather.glyph; color: Theme.text; font { family: Theme.iconFont; pixelSize: 15 } }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Weather.temperature) + "°"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 13; weight: Font.Medium; features: { "tnum": 1 } }
                }
            }
            BarItem {
                active: Calendar.open === true   // ours, not QtQuick.Controls.Calendar: Bar must not import Controls
                onPressed: Calendar.toggle()
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 13; weight: Font.Medium; features: { "tnum": 1 } }
                }
            }
        }

        // ---- right ---------------------------------------------------------------------------
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 2

            Repeater { // tray
                model: SystemTray.items
                BarItem {
                    id: trayItem
                    required property SystemTrayItem modelData
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onPressed: button => {
                        if (button === Qt.MiddleButton) modelData.secondaryActivate()
                        else if (button === Qt.RightButton || modelData.onlyMenu) { if (modelData.hasMenu) trayMenu.open = !trayMenu.open }
                        else modelData.activate()
                    }
                    onScrolled: d => modelData.scroll(d * 120, false)
                    IconImage { anchors.verticalCenter: parent.verticalCenter; implicitSize: 16; source: trayItem.modelData.icon }
                    TrayMenu {
                        id: trayMenu
                        anchorItem: trayItem
                        menu: trayItem.modelData.menu
                    }
                }
            }

            BarItem { // temperatures (warm amber, hot red); click for the system dropdown
                active: Sensors.open
                onPressed: Sensors.toggle()
                spacing: Theme.spaceS
                Repeater {
                    model: [["\u{F4BC}", Sensors.cpu], ["\u{F08AE}", Sensors.gpu]]   // chip, graphics card
                    Row { // quiet icon, the number carries the colour
                        required property var modelData
                        readonly property real v: modelData[1]
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !isNaN(v)
                        spacing: 4
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.modelData[0]
                            color: Theme.subtext
                            font { family: Theme.iconFont; pixelSize: 14 }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(parent.v) + "°"
                            color: parent.v >= 90 ? Theme.red : parent.v >= 80 ? Theme.yellow : Theme.text
                            font { family: Theme.font; pixelSize: 13; weight: Font.Medium; features: { "tnum": 1 } }
                        }
                    }
                }
            }

            BarItem { // keyboard layout as a small keycap; click for the list of layouts
                visible: Keyboard.layouts.length > 1
                active: Keyboard.open
                onPressed: Keyboard.toggle()
                onScrolled: d => Keyboard.use((Keyboard.active + (d > 0 ? 1 : Keyboard.layouts.length - 1)) % Keyboard.layouts.length)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(22, layoutText.implicitWidth + 8); height: 15
                    radius: 4
                    color: "transparent"
                    border { color: Qt.alpha(Theme.text, 0.45); width: 1 }
                    Text {
                        id: layoutText
                        anchors.centerIn: parent
                        text: Keyboard.short
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 9; weight: Font.Bold; letterSpacing: 0.3 }
                    }
                }
            }

            BarItem { // status → Control Center; scroll for volume
                id: status
                readonly property int pct: Math.round((bar.battery?.percentage ?? 0) * 100)
                readonly property bool plugged: !UPower.onBattery
                readonly property bool charging: bar.battery?.state === UPowerDeviceState.Charging
                readonly property bool low: pct <= 15 && !plugged
                spacing: Theme.spaceM
                active: ControlCenter.open
                onPressed: ControlCenter.toggle()
                onScrolled: d => { const a = bar.sink?.audio; if (a) a.volume = Math.max(0, Math.min(1, a.volume + d * 0.05)) }

                StatusGlyph {
                    visible: bar.wired || !Networking.wifiEnabled
                    glyph: bar.wired ? "\u{F0200}" : "\u{F05AA}"
                    tone: bar.wired ? Theme.text : Theme.muted
                    font.pixelSize: 15
                }
                WifiGlyph {   // signal strength; all dim while not connected
                    visible: !bar.wired && Networking.wifiEnabled
                    strength: bar.network ? bar.network.signalStrength : -1
                }
                StatusGlyph { // bluetooth: dim until something is connected
                    readonly property bool linked: bar.adapter?.devices.values.some(d => d.connected) ?? false
                    visible: bar.adapter?.enabled ?? false
                    glyph: linked ? "\u{F00B1}" : "\u{F00AF}"
                    tone: linked ? Theme.text : Theme.subtext
                    font.pixelSize: 15
                }
                StatusGlyph { // volume: muted / low / medium / high
                    readonly property real vol: bar.sink?.audio?.volume ?? 0
                    glyph: bar.sink?.audio?.muted || vol === 0 ? "\u{F075F}" : vol < 0.34 ? "\u{F057F}" : vol < 0.67 ? "\u{F0580}" : "\u{F057E}"
                    tone: bar.sink?.audio?.muted ? Theme.subtext : Theme.text
                    font.pixelSize: 15
                }
                Row {
                    visible: bar.battery?.isPresent ?? false
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: status.pct + "%"
                        color: status.low ? Theme.red : Theme.text
                        font { family: Theme.font; pixelSize: 12; weight: Font.Medium; features: { "tnum": 1 } }
                    }
                    Item { // drawn battery: hairline body, fill to the charge, nub; green while charging, red when low
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property color tone: status.low ? Theme.red : status.charging ? Theme.success : Theme.text
                        width: 25; height: 12
                        Rectangle {
                            id: batteryBody
                            width: 22; height: 12; radius: 3.5
                            color: "transparent"
                            border { color: Qt.alpha(Theme.text, 0.45); width: 1 }
                            Rectangle {
                                x: 2; y: 2
                                width: Math.max(2, (parent.width - 4) * Math.min(1, status.pct / 100))
                                height: parent.height - 4
                                radius: 2
                                color: parent.parent.tone
                                Behavior on width { NumberAnimation { duration: Theme.anim } }
                            }
                        }
                        Rectangle { // nub
                            anchors { left: batteryBody.right; leftMargin: 1; verticalCenter: batteryBody.verticalCenter }
                            width: 2; height: 4; radius: 1
                            color: Qt.alpha(Theme.text, 0.45)
                        }
                    }
                    Text { // bolt while charging, plug while plugged in and held (charge limit)
                        visible: status.plugged || status.charging
                        anchors.verticalCenter: parent.verticalCenter
                        text: status.charging ? "\u{F0241}" : "\u{F06A5}"
                        color: Theme.text
                        font { family: Theme.iconFont; pixelSize: 12 }
                    }
                }
            }

            BarItem { // notifications: bell with the unread count, only while there are some; crossed out during Do Not Disturb
                visible: Notifications.history.length > 0
                active: NotificationCenter.open
                onPressed: NotificationCenter.toggle()   // the Control Center, scrolled to notifications
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16; height: 18
                    Text {
                        anchors.centerIn: parent
                        text: Notifications.dnd ? "\u{F009B}" : "\u{F009C}"
                        color: Theme.text
                        font { family: Theme.iconFont; pixelSize: 16 }
                    }
                    Rectangle {
                        visible: Notifications.unread > 0 && !Notifications.dnd
                        x: parent.width - 7; y: -3
                        width: Math.max(14, badge.implicitWidth + 6); height: 14; radius: 7
                        color: Theme.red
                        Text {
                            id: badge
                            anchors.centerIn: parent
                            text: Notifications.unread > 9 ? "9+" : Notifications.unread
                            color: "white"
                            font { family: Theme.font; pixelSize: 9; weight: Font.Bold; features: { "tnum": 1 } }
                        }
                    }
                }
            }

        }
    }
}
