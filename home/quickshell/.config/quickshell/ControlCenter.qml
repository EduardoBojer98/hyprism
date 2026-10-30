pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Control Center at the top right of the screen under the pointer (status pill, Super+C,
// `qs ipc call controlcenter toggle`), laid out like macOS Tahoe: separate glass modules
// floating on the wallpaper on a 4-column grid.
//   Wi-Fi pill · media (or battery) square · Bluetooth / Night Light rounds · Do Not Disturb pill ·
//   Caffeine / Acer rounds · Power card · Display, Sound and Microphone cards · shortcut rounds.
// Click a module to toggle it; right-click Bluetooth or Caffeine (or click the Wi-Fi name, the
// device buttons) to open its list underneath.
Singleton {
    id: cc

    readonly property bool open: popup.open
    property string expanded: ""     // "", "wifi", "bt", "caffeine", "out", "in"
    property var passwordFor: null   // Wi-Fi network waiting for a password
    property real brightness: 0
    property int kbdLight: 0           // 0-3
    property date now: new Date()

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var battery: UPower.displayDevice
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property int pct: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property string batteryText: {
        const secs = charging ? (battery?.timeToFull ?? 0) : (battery?.timeToEmpty ?? 0)
        const hm = Math.floor(secs / 3600) + " h " + Math.round(secs % 3600 / 60) + " min"
        return !UPower.onBattery && !charging ? "Plugged in" : secs > 0 ? (charging ? "Full in " + hm : hm + " left") : charging ? "Charging" : "On battery"
    }

    readonly property int unit: 72        // one grid cell
    readonly property int gap: 12


    PwObjectTracker { objects: [cc.sink, cc.source] }

    function toggle() { popup.toggle() }
    function hide() { popup.hide() }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { cc.toggle() }
    }

    Connections {
        target: popup
        function onOpenChanged() { cc.opened(popup.open) }
    }
    function opened(visible) {
        if (wifi) wifi.scannerEnabled = visible
        if (visible) { brightnessRead.running = true; kbdRead.running = Machine.kbdDevice !== ""; now = new Date() }
        else { expanded = ""; passwordFor = null }
    }

    Process {
        id: brightnessRead
        command: ["brightnessctl", "-m"]   // amdgpu_bl1,backlight,123,48%,255
        stdout: StdioCollector { onStreamFinished: cc.brightness = parseInt(text.split(",")[3]) / 100 }
    }
    Process {
        id: kbdRead
        command: ["brightnessctl", "-m", "-d", Machine.kbdDevice]   // asus::kbd_backlight,leds,1,33%,3
        stdout: StdioCollector { onStreamFinished: cc.kbdLight = parseInt(text.split(",")[2]) || 0 }
    }
    Timer { interval: 30000; repeat: true; running: popup.open; onTriggered: cc.now = new Date() }

    function nodeName(n) { return n?.description || n?.nickname || n?.name || "" }
    function toggleExpanded(name) { expanded = expanded === name ? "" : name; passwordFor = null }
    function setKbd(level) {
        kbdLight = level
        Quickshell.execDetached(["brightnessctl", "-q", "-d", Machine.kbdDevice, "set", String(level)])
    }

    CursorPopup {
    id: popup
    name: "controlcenter"
    placement: "topRight"
    boxWidth: cc.unit * 4 + cc.gap * 3
    boxHeight: content.implicitHeight

    ColumnLayout {
        id: content
        width: parent.width
        spacing: cc.gap

        // ---- toggles + media ----------------------------------------------------------------
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: cc.gap
            rowSpacing: cc.gap

            Pill {
                glyph: Networking.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
                title: "Wi-Fi"
                subtitle: !Networking.wifiEnabled ? "Off" : (cc.wifi?.networks.values.find(n => n.connected)?.name ?? "Not connected")
                active: Networking.wifiEnabled
                isExpanded: cc.expanded === "wifi"
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                onExpand: cc.toggleExpanded("wifi")
            }

            // Media when something plays, otherwise the battery
            Glass {
                Layout.columnSpan: 2
                Layout.rowSpan: 2
                Layout.preferredWidth: cc.unit * 2 + cc.gap
                Layout.preferredHeight: cc.unit * 2 + cc.gap
                radius: Theme.radiusLarge

                Item {
                    anchors { fill: parent; margins: 16 }
                    visible: Config.controlCenter.showMedia && cc.player !== null

                    Rectangle {
                        id: artBox
                        width: 52; height: 52; radius: 12
                        color: Theme.fill
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: cc.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize { width: 104; height: 104 }
                            visible: status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !(cc.player?.trackArtUrl)
                            text: "\u{F075A}"
                            color: Theme.subtext
                            font { family: Theme.iconFont; pixelSize: 24 }
                        }
                    }
                    Column {
                        anchors { left: parent.left; right: parent.right; top: artBox.bottom; topMargin: 10 }
                        Text { width: parent.width; text: cc.player?.trackTitle || cc.player?.identity || ""; color: Theme.text; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontSize + 1; weight: Font.DemiBold } }
                        Text { width: parent.width; text: cc.player?.trackArtist || cc.player?.identity || ""; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontLabel } }
                    }
                    Row {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -4 }
                        spacing: 14
                        Repeater {
                            model: [
                                ["\u{F04AE}", () => cc.player.previous(), cc.player?.canGoPrevious ?? false, 22],
                                [cc.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}", () => cc.player.togglePlaying(), cc.player?.canTogglePlaying ?? false, 28],
                                ["\u{F04AD}", () => cc.player.next(), cc.player?.canGoNext ?? false, 22],
                            ]
                            Text {
                                required property var modelData
                                width: 30; height: 30
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                text: modelData[0]
                                opacity: modelData[2] ? 1 : 0.35
                                color: Theme.text
                                font { family: Theme.iconFont; pixelSize: modelData[3] }
                                MouseArea { anchors.fill: parent; enabled: parent.modelData[2]; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData[1]() }
                            }
                        }
                    }
                }

                Item {
                    anchors { fill: parent; margins: 16 }
                    visible: !(Config.controlCenter.showMedia && cc.player !== null)
                    Text {
                        text: cc.charging ? "\u{F0084}" : "\u{F0079}"
                        color: cc.charging ? Theme.success : Theme.text
                        font { family: Theme.iconFont; pixelSize: 28 }
                    }
                    Column {
                        anchors { left: parent.left; bottom: parent.bottom }
                        Text { text: cc.pct + "%"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontDisplay; weight: Font.DemiBold; features: { "tnum": 1 } } }
                        Text { text: cc.batteryText; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontLabel } }
                    }
                }
            }

            Round {
                glyph: cc.adapter?.enabled ? "\u{F00AF}" : "\u{F00B2}"
                hint: !cc.adapter ? "No Bluetooth" : (cc.adapter.devices.values.filter(d => d.connected).map(d => d.name).join(", ") || "Bluetooth") + " · right-click for devices"
                active: cc.adapter?.enabled ?? false
                isExpanded: cc.expanded === "bt"
                onToggled: if (cc.adapter) cc.adapter.enabled = !cc.adapter.enabled
                onExpand: cc.toggleExpanded("bt")
            }
            Round {
                glyph: "\u{F0599}"
                hint: "Night Light · " + ({ off: "off", on: "on", sun: "sunset to sunrise", schedule: `${Config.nightLight.from}–${Config.nightLight.to}` })[Config.nightLight.mode]
                active: NightLight.active
                onToggled: NightLight.toggle()
            }

            Pill {
                glyph: "\u{F0594}"
                title: "Focus"
                subtitle: Config.notifications.dnd ? "Do Not Disturb on" : "Do Not Disturb off"
                active: Config.notifications.dnd
                onToggled: Config.set("notifications", "dnd", !Config.notifications.dnd)
            }
            Round {
                glyph: "\u{F0176}"
                hint: "Caffeine · " + Caffeine.remaining(cc.now.getTime()) + " · right-click for durations"
                active: Caffeine.active
                isExpanded: cc.expanded === "caffeine"
                onToggled: Caffeine.toggle()
                onExpand: cc.toggleExpanded("caffeine")
            }
            Round { // shared monitor (monswitch), only when ~/.config/monswitch.conf exists
                visible: Machine.monitorSwitch
                readonly property bool ours: Hyprland.monitors.values.some(m => m.name === Machine.switchOutput)
                glyph: "\u{F0379}"
                hint: "Shared monitor · " + (ours ? "on this computer" : "on the other computer")
                active: ours
                onToggled: Quickshell.execDetached(["monswitch", "toggle"])
            }
        }

        // ---- lists that open under the toggles -----------------------------------------------
        Module {
            visible: cc.expanded === "wifi"
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: cc.wifi ? [...cc.wifi.networks.values].sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength).slice(0, 8) : []
                    ListRow {
                        required property var modelData
                        glyph: modelData.signalStrength > 0.66 ? "\u{F0928}" : modelData.signalStrength > 0.33 ? "\u{F0925}" : "\u{F091F}"
                        title: modelData.name
                        trailing: modelData.connected ? "\u{F012C}" : (modelData.security !== WifiSecurityType.Open && !modelData.known) ? "\u{F033E}" : ""
                        selected: modelData.connected
                        onClicked: {
                            if (modelData.connected) modelData.disconnect()
                            else if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect()
                            else cc.passwordFor = modelData
                        }
                    }
                }
                Rectangle {
                    visible: cc.passwordFor !== null
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    Layout.topMargin: 6
                    radius: Theme.radiusSmall
                    color: Theme.fill
                    border { color: psk.activeFocus ? Theme.accent : Theme.stroke; width: 1 }
                    TextInput {
                        id: psk
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontSize }
                        focus: parent.visible
                        onAccepted: { cc.passwordFor.connectWithPsk(text); text = ""; cc.passwordFor = null }
                        Keys.onEscapePressed: cc.passwordFor = null
                        Text {
                            visible: !psk.text
                            text: "Password for " + (cc.passwordFor?.name ?? "") + " — Enter to join"
                            color: Theme.muted
                            font: psk.font
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                Empty { shown: !cc.wifi || cc.wifi.networks.values.length === 0; text: Networking.wifiEnabled ? "Looking for networks…" : "Wi-Fi is off" }
            }
        }

        Module {
            visible: cc.expanded === "bt"
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: (cc.adapter?.devices.values ?? []).filter(d => d.paired || d.connected).sort((a, b) => b.connected - a.connected)
                    ListRow {
                        required property var modelData
                        glyph: "\u{F00AF}"
                        title: modelData.name + (modelData.batteryAvailable ? "  ·  " + Math.round(modelData.battery * 100) + "%" : "")
                        trailing: modelData.connected ? "\u{F012C}" : ""
                        selected: modelData.connected
                        onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                    }
                }
                Empty {
                    shown: (cc.adapter?.devices.values ?? []).filter(d => d.paired || d.connected).length === 0
                    text: "No paired devices. Pair new ones in Settings > Bluetooth."
                }
            }
        }

        Module {
            visible: cc.expanded === "caffeine"
            Flow {
                Layout.fillWidth: true
                spacing: Theme.spaceS
                Repeater {
                    model: Caffeine.choices
                    Chip {
                        required property int modelData
                        label: Caffeine.label(modelData)
                        active: Caffeine.active && Caffeine.minutes === modelData
                        onClicked: { Caffeine.start(modelData); cc.now = new Date() }
                    }
                }
                Chip { label: "Turn off"; visible: Caffeine.active; onClicked: Caffeine.stop() }
            }
        }

        // ---- power -----------------------------------------------------------------------------
        Module {
            title: "Power"
            detail: (Config.controlCenter.showMedia && cc.player !== null ? cc.pct + "% · " + cc.batteryText : "")
                    + (Config.controlCenter.showHardware ? (cc.player !== null && Config.controlCenter.showMedia ? "  ·  " : "") + `CPU ${Math.round(Sensors.cpu)}°` : "")
            onDetailClicked: { cc.hide(); SettingsApp.show(Machine.asus ? "asus" : "power") }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: Theme.radiusSmall + 2
                color: Theme.fill

                Rectangle {
                    width: (parent.width - 6) / 3
                    height: parent.height - 6
                    y: 3
                    x: 3 + PowerProfiles.profile * width
                    radius: Theme.radiusSmall
                    color: "#f2f4fa"
                    Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                }
                Row {
                    anchors { fill: parent; margins: 3 }
                    Repeater {
                        model: [["\u{F032A}", "Quiet"], ["\u{F05D1}", "Balanced"], ["\u{F04C5}", "Performance"]]
                        Item {
                            required property var modelData
                            required property int index
                            readonly property bool on: PowerProfiles.profile === index
                            width: parent.width / 3
                            height: parent.height
                            Row {
                                anchors.centerIn: parent
                                spacing: 5
                                Text { text: modelData[0]; color: parent.parent.on ? Theme.accent : Theme.subtext; font { family: Theme.iconFont; pixelSize: 14 } }
                                Text { text: modelData[1]; color: parent.parent.on ? "#1e2030" : Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: PowerProfiles.profile = index }
                        }
                    }
                }
            }
        }

        // ---- display and sound -----------------------------------------------------------------
        Module {
            title: "Display"
            Bar {
                lowIcon: "\u{F00DE}"; highIcon: "\u{F00E0}"
                value: cc.brightness
                onMoved: v => {
                    cc.brightness = Math.max(0.05, v)
                    Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(cc.brightness * 100) + "%"])
                }
            }
        }

        Module {
            title: "Sound"
            Bar {
                lowIcon: cc.sink?.audio?.muted ? "\u{F075F}" : "\u{F057F}"; highIcon: "\u{F057E}"
                value: cc.sink?.audio?.muted ? 0 : (cc.sink?.audio?.volume ?? 0)
                device: true
                deviceOpen: cc.expanded === "out"
                onMoved: v => { if (cc.sink?.audio) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                onLowClicked: if (cc.sink?.audio) cc.sink.audio.muted = !cc.sink.audio.muted
                onDeviceClicked: cc.toggleExpanded("out")
            }
            ColumnLayout {
                visible: cc.expanded === "out"
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
                    ListRow {
                        required property var modelData
                        glyph: "\u{F04C3}"
                        title: cc.nodeName(modelData)
                        selected: modelData === cc.sink
                        trailing: selected ? "\u{F012C}" : ""
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }
            }
        }

        Module {
            title: "Microphone"
            Bar {
                lowIcon: cc.source?.audio?.muted ? "\u{F036D}" : "\u{F036C}"; highIcon: ""
                value: cc.source?.audio?.muted ? 0 : (cc.source?.audio?.volume ?? 0)
                device: true
                deviceOpen: cc.expanded === "in"
                onMoved: v => { if (cc.source?.audio) { cc.source.audio.muted = false; cc.source.audio.volume = v } }
                onLowClicked: if (cc.source?.audio) cc.source.audio.muted = !cc.source.audio.muted
                onDeviceClicked: cc.toggleExpanded("in")
            }
            ColumnLayout {
                visible: cc.expanded === "in"
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
                    ListRow {
                        required property var modelData
                        glyph: "\u{F036C}"
                        title: cc.nodeName(modelData)
                        selected: modelData === cc.source
                        trailing: selected ? "\u{F012C}" : ""
                        onClicked: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }
            }
        }

        // ---- shortcuts -------------------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: cc.gap
            Round {
                glyph: "\u{F030C}"
                hint: "On-screen keyboard"
                active: Osk.visible
                onToggled: Osk.toggle()
            }
            Round {
                visible: Machine.kbdDevice !== ""
                glyph: cc.kbdLight > 0 ? "\u{F0E5B}" : "\u{F0E5A}"
                hint: "Keyboard light · " + ["off", "low", "medium", "high"][cc.kbdLight]
                active: cc.kbdLight > 0
                onToggled: cc.setKbd((cc.kbdLight + 1) % 4)
            }
            Round {
                glyph: "\u{F0100}"
                hint: "Screenshot an area"
                onToggled: { cc.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; grim -g \"$(slurp)\" - | satty --filename -"]) }
            }
            Round {
                glyph: "\u{F0493}"
                hint: "Settings"
                onToggled: { cc.hide(); SettingsApp.show("") }
            }
        }
    }

    }

    // ---- building blocks -----------------------------------------------------------------------

    // Two cells wide: a round icon that toggles, then the name; clicking the name opens a list
    component Pill: Glass {
        id: pill
        property string glyph
        property string title
        property string subtitle
        property bool active: false
        property bool isExpanded: false
        signal toggled()
        signal expand()

        Layout.columnSpan: 2
        Layout.preferredWidth: cc.unit * 2 + cc.gap
        Layout.preferredHeight: cc.unit
        radius: Theme.radiusLarge
        border.color: isExpanded ? Theme.accent : Theme.stroke

        Bubble {
            id: bubble
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            size: 46
            glyph: pill.glyph
            active: pill.active
            onClicked: pill.toggled()
        }
        Column {
            anchors { left: bubble.right; leftMargin: 10; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            Text { width: parent.width; text: pill.title; color: Theme.text; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontSize + 1; weight: Font.DemiBold } }
            Text { width: parent.width; text: pill.subtitle; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontLabel } }
        }
        MouseArea {
            anchors { fill: parent; leftMargin: bubble.width + 12 }
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.expand()
        }
    }

    // One cell: a big round toggle. Right-click opens its list, if it has one.
    component Round: Item {
        id: round
        property string glyph
        property string hint
        property bool active: false
        property bool isExpanded: false
        signal toggled()
        signal expand()

        Layout.preferredWidth: cc.unit
        Layout.preferredHeight: cc.unit

        Bubble {
            anchors.fill: parent
            size: cc.unit
            glyph: round.glyph
            iconSize: 24
            active: round.active
            outlined: round.isExpanded
            onClicked: round.toggled()
            onRightClicked: round.expand()
            ToolTipText { shown: parent.hovered && round.hint !== ""; text: round.hint; z: 10 }
        }
    }

    // White when on (icon in the accent), glass when off, like Tahoe's toggles
    component Bubble: Rectangle {
        id: b
        property string glyph
        property int size: 46
        property int iconSize: 20
        property bool active: false
        property bool outlined: false
        readonly property bool hovered: area.containsMouse
        signal clicked()
        signal rightClicked()

        width: size; height: size; radius: size / 2
        color: active ? "#f2f4fa" : area.containsMouse ? Theme.fillHover : Theme.glass
        border { color: outlined ? Theme.accent : active ? "transparent" : Theme.stroke; width: outlined ? 2 : 1 }
        scale: area.pressed ? 0.94 : 1
        Behavior on color { ColorAnimation { duration: Theme.anim } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

        Text {
            anchors.centerIn: parent
            text: b.glyph
            color: b.active ? Theme.accent : Theme.text
            font { family: Theme.iconFont; pixelSize: b.iconSize }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => mouse.button === Qt.RightButton ? b.rightClicked() : b.clicked()
        }
    }

    // A full-width glass card with an optional title (and a clickable detail on the right)
    component Module: Glass {
        id: mod
        property string title
        property string detail
        default property alias body: inner.data
        signal detailClicked()

        Layout.fillWidth: true
        Layout.preferredHeight: inner.implicitHeight + 28
        radius: Theme.radiusLarge

        ColumnLayout {
            id: inner
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14; leftMargin: 18; rightMargin: 18 }
            spacing: 8
            Item {
                visible: mod.title !== ""
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: mod.title
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontSize + 1; weight: Font.DemiBold }
                }
                Text {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    text: mod.detail
                    color: Sensors.cpu >= 90 ? Theme.warning : Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: mod.detailClicked() }
                }
            }
        }
    }

    // Thin Tahoe slider: icon, track, icon, and optionally a round device button at the end
    component Bar: RowLayout {
        id: bar
        property real value: 0
        property string lowIcon
        property string highIcon
        property bool device: false
        property bool deviceOpen: false
        signal moved(real value)
        signal lowClicked()
        signal deviceClicked()

        Layout.fillWidth: true
        spacing: 10

        Text {
            text: bar.lowIcon
            color: Theme.text
            font { family: Theme.iconFont; pixelSize: 16 }
            MouseArea { anchors { fill: parent; margins: -6 } cursorShape: Qt.PointingHandCursor; onClicked: bar.lowClicked() }
        }
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            Rectangle {
                id: track
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 8
                radius: 4
                color: Theme.fill
                Rectangle {
                    width: Math.max(track.height, track.width * Math.max(0, Math.min(1, bar.value)))
                    height: parent.height
                    radius: parent.radius
                    color: "#f2f4fa"
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function set(x) { bar.moved(Math.max(0, Math.min(1, x / width))) }
                onPressed: mouse => set(mouse.x)
                onPositionChanged: mouse => { if (pressed) set(mouse.x) }
                onWheel: wheel => bar.moved(Math.max(0, Math.min(1, bar.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
            }
        }
        Text {
            visible: bar.highIcon !== ""
            text: bar.highIcon
            color: Theme.text
            font { family: Theme.iconFont; pixelSize: 18 }
        }
        Bubble {
            visible: bar.device
            size: 30
            iconSize: 15
            glyph: "\u{F04C3}"
            active: bar.deviceOpen
            onClicked: bar.deviceClicked()
        }
    }

    component ListRow: Rectangle {
        id: row
        property string glyph
        property string title
        property string trailing
        property bool selected: false
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 12
        color: rowArea.containsMouse ? Theme.fillHover : "transparent"
        Text {
            id: rowGlyph
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            text: row.glyph
            color: row.selected ? Theme.accent : Theme.subtext
            font { family: Theme.iconFont; pixelSize: 15 }
        }
        Text {
            anchors { left: rowGlyph.right; leftMargin: 10; right: trailingText.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: row.title
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize; weight: row.selected ? Font.DemiBold : Font.Normal }
        }
        Text {
            id: trailingText
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            text: row.trailing
            color: row.selected ? Theme.accent : Theme.muted
            font { family: Theme.iconFont; pixelSize: 14 }
        }
        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }

    component Empty: Text {
        property bool shown: false
        visible: shown
        Layout.fillWidth: true
        padding: 8
        wrapMode: Text.Wrap
        color: Theme.muted
        font { family: Theme.font; pixelSize: Theme.fontLabel }
    }
}
