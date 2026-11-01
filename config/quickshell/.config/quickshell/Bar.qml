import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Menu bar: monochrome items that light up on hover. Its look (Appearance > Menu Bar) is a set of separate
// options: shape (Config.bar.style), top or bottom, height, plain or chip items, and colour.
// Three zones (left, centre, right), each a list of the items below, arranged in Settings > Menu Bar.
// Desktops are numbers in a recessed pill; an accent pill slides to the current one.
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

    // Look (Settings > Appearance > Menu Bar): each option on its own, the designs there are sets of them
    readonly property string style: Config.bar.style      // strip, floating, islands, compact, tabs, clear
    readonly property bool bottom: Config.bar.position === "bottom"
    readonly property color surface: Theme.surface(Config.bar.tint)
    readonly property int inset: Theme.barInset     // gap between screen edge and glass
    readonly property int pad: ({ islands: 10, tabs: 14, compact: 12 })[style] ?? 0          // glass beyond the items
    readonly property int side: style === "floating" ? 20 : style === "islands" ? inset + 2 + pad
                              : style === "tabs" ? 8 + pad : Theme.spaceS + 4                 // screen side to the first item

    anchors { top: !bottom; bottom: bottom; left: true; right: true }
    implicitHeight: Theme.barHeight
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

    SystemClock { id: clock; precision: Config.bar.seconds ? SystemClock.Seconds : SystemClock.Minutes }
    // Settings > Menu Bar: "Fri 30 Oct  14:40", "30 Oct  2:40:05 PM", ...
    readonly property string clockFormat: ({ full: "ddd d MMM  ", short: "d MMM  ", none: "" })[Config.bar.date]
        + (Config.bar.clock24 ? "HH:mm" : "h:mm") + (Config.bar.seconds ? ":ss" : "") + (Config.bar.clock24 ? "" : " AP")

    // frosted strip: Hyprland blurs what's behind it (layer rule blur-shell), a hairline closes it off
    Rectangle {
        visible: bar.style === "strip"
        anchors.fill: parent
        color: Config.bar.tint === "glass" ? (Theme.light ? Qt.rgba(1, 1, 1, 0.55) : Theme.tinted(0.75, 0.40)) : bar.surface
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: bar.bottom ? undefined : parent.bottom; top: bar.bottom ? parent.top : undefined }
            height: 1
            color: Theme.light ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.06)
        }
    }

    Glass {
        visible: bar.style === "floating"
        anchors { fill: parent; topMargin: bar.bottom ? 0 : bar.inset; bottomMargin: bar.bottom ? bar.inset : 0; leftMargin: bar.inset + 2; rightMargin: bar.inset + 2 }
        radius: height / 2
        color: bar.surface
    }
    // clear: no surface, only a faint shade so light items stay readable on a bright wallpaper
    Rectangle {
        visible: bar.style === "clear"
        anchors { left: parent.left; right: parent.right; top: bar.bottom ? undefined : parent.top; bottom: bar.bottom ? parent.bottom : undefined }
        height: parent.height + 16
        gradient: Gradient {
            GradientStop { position: bar.bottom ? 1 : 0; color: Theme.light ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(0, 0, 0, 0.35) }
            GradientStop { position: bar.bottom ? 0 : 1; color: "transparent" }
        }
    }

    // Each zone shows its items in the order Settings > Menu Bar gives (Config.bar.left/center/right)
    readonly property var widgets: ({ logo: logoW, desktops: desktopsW, app: appW, weather: weatherW, clock: clockW,
        media: mediaW, tray: trayW, netspeed: netspeedW, cpu: cpuW, memory: memoryW, temperatures: temperaturesW,
        keyboard: keyboardW, status: statusW, notifications: notificationsW })

    Item {
        id: zones
        readonly property int gap: 12 + bar.pad * 2
        readonly property bool compact: bar.style === "compact"
        // compact: the three zones side by side in one centred pill
        readonly property real total: leftZone.width + centerZone.width + rightZone.width
            + (leftZone.width > 0 ? gap : 0) + (rightZone.width > 0 ? gap : 0)
        anchors { fill: parent; topMargin: bar.bottom ? 0 : bar.inset; bottomMargin: bar.bottom ? bar.inset : 0
                  leftMargin: bar.side; rightMargin: bar.side - (bar.style === "strip" || bar.style === "clear" ? 4 : 0) }
        Glass {
            visible: zones.compact
            x: leftZone.x - bar.pad
            width: zones.total + bar.pad * 2
            height: parent.height
            radius: height / 2
            color: bar.surface
        }
        ZonePill { zone: leftZone }
        ZonePill { zone: centerZone }
        ZonePill { zone: rightZone }
        Zone { id: leftZone; x: zones.compact ? (parent.width - zones.total) / 2 : 0; items: Config.bar.left }
        Zone { // centred, but moves aside rather than run into a crowded side
            id: centerZone
            items: Config.bar.center
            x: zones.compact ? leftZone.x + leftZone.width + (leftZone.width > 0 ? zones.gap : 0)
                : Math.max(leftZone.width + zones.gap, Math.min((parent.width - width) / 2, rightZone.x - width - zones.gap))
        }
        Zone { id: rightZone; x: zones.compact ? leftZone.x + zones.total - width : parent.width - width; items: Config.bar.right }
    }

    // islands and tabs: a surface behind one zone, gone when the zone shows nothing. Tabs hang from
    // the screen edge: square there, round away from it.
    component ZonePill: Rectangle {
        required property Item zone
        readonly property bool tab: bar.style === "tabs"
        visible: (bar.style === "islands" || tab) && zone.width > 0
        x: zone.x - bar.pad
        width: zone.width + bar.pad * 2
        height: parent.height
        radius: tab ? 0 : height / 2
        topLeftRadius: tab && !bar.bottom ? 0 : tab ? Theme.radius + 2 : radius
        topRightRadius: topLeftRadius
        bottomLeftRadius: tab && bar.bottom ? 0 : tab ? Theme.radius + 2 : radius
        bottomRightRadius: bottomLeftRadius
        color: bar.surface
        border { color: Theme.stroke; width: 1 }
    }

    component Zone: Row {
        property var items: []
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Repeater {
            model: parent.items
            Loader {
                required property string modelData
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: bar.widgets[modelData] ?? null
                visible: item?.shown ?? true   // a widget that has nothing to show takes no room
            }
        }
    }
    component BarText: Text {
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.text
        font { family: Theme.font; pixelSize: 13; weight: Font.Medium; features: { "tnum": 1 } }
    }

    Component {
        id: logoW
        BarItem { // this computer: about, tools and power, behind the system logo (like the Apple menu)
            active: UtilityMenu.open
            onPressed: UtilityMenu.toggle()
            StatusGlyph { glyph: "\u{F303}"; font.pixelSize: 15 }   // Arch logo; Nerd Fonts has no CachyOS one
        }
    }
    Component {
        id: desktopsW
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
    }
    Component {
        id: appW
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
            readonly property bool shown: appId !== ""
            visible: shown
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
                    visible: app.title !== "" && app.title !== app.name && Config.bar.windowTitle
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: 13 }
                }
            }
        }
    }
    Component {
        id: weatherW
        BarItem {   // weather: opens the forecast
            shown: Weather.ready
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
    }
    Component {
        id: clockW
        BarItem { // date and time: opens the calendar
            active: Calendar.open === true   // ours, not QtQuick.Controls.Calendar: Bar must not import Controls
            onPressed: Calendar.toggle()
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, bar.clockFormat)
                color: Theme.text
                font { family: Theme.font; pixelSize: 13; weight: Font.Medium; features: { "tnum": 1 } }
            }
        }
    }
    Component {
        id: mediaW
        BarItem { // what's playing: click to play or pause, scroll for next or previous
            id: media
            readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
            shown: player !== null
            spacing: 5
            onPressed: if (player?.canTogglePlaying) player.togglePlaying()
            onScrolled: d => { if (d < 0 && player?.canGoNext) player.next(); else if (d > 0 && player?.canGoPrevious) player.previous() }
            StatusGlyph { glyph: media.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}"; font.pixelSize: 14 }
            BarText {
                width: Math.min(implicitWidth, 220)
                elide: Text.ElideRight
                text: [media.player?.trackTitle, media.player?.trackArtist].filter(x => x).join(" · ")
            }
        }
    }
    Component {
        id: trayW
        Row { // tray
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Repeater { // tray
                model: SystemTray.items
                BarItem {
                    id: trayItem
                    required property SystemTrayItem modelData
                    // Passive = "nothing to show right now" (e.g. the update notifier when up to date)
                    visible: modelData.status !== Status.Passive
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
        }
    }
    Component {
        id: netspeedW
        BarItem { // network speed, down and up
            spacing: 4
            onPressed: ControlCenter.toggle()
            StatusGlyph { glyph: "\u{F01DA}"; tone: Theme.subtext; font.pixelSize: 13 }
            BarText { text: BarStats.speed(BarStats.down) }
            StatusGlyph { glyph: "\u{F0552}"; tone: Theme.subtext; font.pixelSize: 13 }
            BarText { text: BarStats.speed(BarStats.up) }
        }
    }
    Component {
        id: cpuW
        BarItem { // CPU use; click for the system dropdown
            spacing: 4
            active: Sensors.open
            onPressed: Sensors.toggle()
            StatusGlyph { glyph: "\u{F0EE0}"; tone: Theme.subtext; font.pixelSize: 14 }
            BarText { text: Math.round(BarStats.cpu * 100) + "%"; color: BarStats.cpu >= 0.9 ? Theme.yellow : Theme.text }
        }
    }
    Component {
        id: memoryW
        BarItem { // memory in use; click for the system dropdown
            spacing: 4
            active: Sensors.open
            onPressed: Sensors.toggle()
            StatusGlyph { glyph: "\u{F035B}"; tone: Theme.subtext; font.pixelSize: 14 }
            BarText { text: BarStats.memUsed.toFixed(1) + " GB"; color: BarStats.memUsed > BarStats.memTotal * 0.9 ? Theme.yellow : Theme.text }
        }
    }
    Component {
        id: temperaturesW
        BarItem { // temperatures (warm amber, hot red); click for the system dropdown
            active: Sensors.open
            onPressed: Sensors.toggle()
            spacing: Theme.spaceS
            Repeater {
                // chip, graphics card: the NVIDIA one ("Off" while it sleeps), else the built-in one
                model: [["\u{F4BC}", Sensors.cpu, ""],
                        Sensors.nvState === "" ? ["\u{F08AE}", Sensors.gpu, ""] : ["\u{F08AE}", Sensors.nv?.temp ?? NaN, Sensors.nvState === "active" ? "On" : "Off"]]
                Row { // quiet icon, the number carries the colour
                    required property var modelData
                    readonly property real v: modelData[1]
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !isNaN(v) || modelData[2] !== ""
                    spacing: 4
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData[0]
                        color: Theme.subtext
                        font { family: Theme.iconFont; pixelSize: 14 }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: isNaN(parent.v) ? parent.modelData[2] : Math.round(parent.v) + "°"
                        color: isNaN(parent.v) ? Theme.subtext : parent.v >= 90 ? Theme.red : parent.v >= 80 ? Theme.yellow : Theme.text
                        font { family: Theme.font; pixelSize: 13; weight: Font.Medium; features: { "tnum": 1 } }
                    }
                }
            }
        }
    }
    Component {
        id: keyboardW
        BarItem { // keyboard layout as a small keycap; click for the list of layouts
            shown: Keyboard.layouts.length > 1
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
    }
    Component {
        id: statusW
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
                    visible: Config.bar.batteryPercent
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
    }
    Component {
        id: notificationsW
        BarItem { // notifications: bell with the unread count, only while there are some; crossed out during Do Not Disturb
            shown: Notifications.history.length > 0
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
