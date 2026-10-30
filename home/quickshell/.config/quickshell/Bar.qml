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
//   layout · Wi-Fi/Bluetooth/volume/battery (Control Center) · notifications bell · power
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
    property string layout: "US"

    anchors { top: true; left: true; right: true }
    implicitHeight: 30
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"

    PwObjectTracker { objects: [bar.sink] }

    // Keyboard layout: starting value from hyprctl, then Hyprland's activelayout events
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout") kbRead.running = true
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
        id: kbRead
        running: true
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                const main = JSON.parse(text).keyboards.find(k => k.main)
                // "us,rs" + index 1 -> "RS"
                if (main) bar.layout = (main.layout.split(",")[main.active_layout_index] ?? main.layout).toUpperCase()
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
                    model: [["CPU", Sensors.cpu], ["GPU", Sensors.gpu]]
                    Text {
                        required property var modelData
                        readonly property real v: modelData[1]
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !isNaN(v)
                        text: `<span style="font-size:10px;font-weight:700">${modelData[0]}</span> ${Math.round(v)}°`
                        textFormat: Text.StyledText
                        color: v >= 90 ? Theme.red : v >= 80 ? Theme.yellow : Theme.text
                        font { family: Theme.font; pixelSize: 13; weight: Font.Medium; features: { "tnum": 1 } }
                    }
                }
            }

            BarItem { // status → Control Center; scroll for volume
                id: status
                readonly property int pct: Math.round((bar.battery?.percentage ?? 0) * 100)
                readonly property bool charging: bar.battery?.state === UPowerDeviceState.Charging || !UPower.onBattery
                readonly property bool low: pct <= 15 && !charging
                spacing: Theme.spaceM
                active: ControlCenter.open
                onPressed: ControlCenter.toggle()
                onScrolled: d => { const a = bar.sink?.audio; if (a) a.volume = Math.max(0, Math.min(1, a.volume + d * 0.05)) }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bar.layout
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 11; weight: Font.Bold }
                }
                StatusGlyph {
                    glyph: bar.wired ? "\u{F0200}" : bar.network ? "\u{F05A9}" : "\u{F05AA}"
                    tone: bar.wired || bar.network ? Theme.text : Theme.red
                }
                StatusGlyph {
                    visible: bar.adapter?.enabled ?? false
                    glyph: (bar.adapter?.devices.values.some(d => d.connected) ?? false) ? "\u{F00B1}" : "\u{F00AF}"
                }
                StatusGlyph { glyph: bar.sink?.audio?.muted ? "\u{F075F}" : "\u{F057E}" }
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
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: status.charging ? "\u{F0084}" : status.pct >= 95 ? "\u{F0079}" : String.fromCodePoint(0xF007A + Math.max(0, Math.floor(status.pct / 10) - 1))
                        color: status.low ? Theme.red : Theme.text
                        font { family: Theme.iconFont; pixelSize: 17 }
                    }
                }
            }

            BarItem { // notifications: bell with the unread count; crossed out during Do Not Disturb
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

            BarItem { // power and tools
                active: UtilityMenu.open
                onPressed: UtilityMenu.toggle()
                StatusGlyph { glyph: "\u{F0425}"; font.pixelSize: 15 }
            }
        }
    }
}
