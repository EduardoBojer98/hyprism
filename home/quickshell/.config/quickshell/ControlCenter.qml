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
import QtQuick.Controls
import QtQuick.Layouts

// Control Center at the top right of the screen under the pointer (status pill, Super+C,
// `qs ipc call controlcenter toggle`): one glass panel holding grouped tiles.
//   Wi-Fi / Bluetooth / Focus rows · media (or battery) tile
//   quick toggles: Night Light, Caffeine, shared monitor, keyboard light, on-screen keyboard
//   Display, Sound and Microphone sliders · Power mode · footer: battery, screenshot, settings, power
// The round icon in a row toggles it; the rest of the row (or a chevron) opens its list underneath.
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

    readonly property int gap: 8          // between tiles
    readonly property int pad: 10         // panel padding


    PwObjectTracker { objects: [cc.sink, cc.source] }

    function toggle() { popup.toggle() }
    // the bell / Super+N: open (or close) scrolled down to the notifications
    property bool toNotes: false
    function toggleNotifications() { if (popup.open) popup.hide(); else { toNotes = true; popup.show() } }

    // One tooltip for the whole panel, drawn above the scroll area so it is never clipped
    property Item hintItem: null
    property string hintText: ""
    function hint(item, text) { hintText = text; hintItem = item }
    function unhint(item) { if (hintItem === item) hintItem = null }
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
        if (visible) {
            scroller.contentY = 0; brightnessRead.running = true; kbdRead.running = Machine.kbdDevice !== ""; now = new Date()
            Notifications.unread = 0; Notifications.now = new Date(); NotificationCenter.unfolded = ({})
            if (toNotes) scrollToNotes.restart()
        }
        else { expanded = ""; passwordFor = null; hintItem = null; toNotes = false }
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
    Timer {   // after layout settles
        id: scrollToNotes
        interval: 30
        onTriggered: { scroller.contentY = Math.max(0, Math.min(notesHeader.y - 4, scroller.contentHeight - scroller.height)); cc.toNotes = false }
    }

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
    boxWidth: 330
    // capped to the screen; the content scrolls when lists make it taller
    boxHeight: Math.min(content.implicitHeight + cc.pad * 2, (popup.targetScreen?.height ?? 1000) - popup.topReserve - popup.edge * 2)

    Glass {   // the backdrop every tile sits on
        anchors.fill: parent
        strong: true
        radius: Theme.radiusLarge + 4

    Flickable {
        id: scroller
        anchors { fill: parent; margins: cc.pad }
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: GlassScrollBar {}

    ColumnLayout {
        id: content
        width: scroller.width
        spacing: cc.gap

        // ---- connections + media ------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: cc.gap

            Tile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: conns.implicitHeight + 8
                Column {
                    id: conns
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 4 }
                    ConnRow {
                        glyph: Networking.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
                        title: "Wi-Fi"
                        subtitle: !Networking.wifiEnabled ? "Off" : (cc.wifi?.networks.values.find(n => n.connected)?.name ?? "Not connected")
                        active: Networking.wifiEnabled
                        isExpanded: cc.expanded === "wifi"
                        onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                        onExpand: cc.toggleExpanded("wifi")
                    }
                    ConnRow {
                        glyph: cc.adapter?.enabled ? "\u{F00AF}" : "\u{F00B2}"
                        title: "Bluetooth"
                        subtitle: !cc.adapter ? "Unavailable" : !cc.adapter.enabled ? "Off"
                                : (cc.adapter.devices.values.filter(d => d.connected).map(d => d.name).join(", ") || "On")
                        active: cc.adapter?.enabled ?? false
                        isExpanded: cc.expanded === "bt"
                        onToggled: if (cc.adapter) cc.adapter.enabled = !cc.adapter.enabled
                        onExpand: cc.toggleExpanded("bt")
                    }
                    ConnRow {
                        glyph: "\u{F0594}"
                        title: "Focus"
                        subtitle: Config.notifications.dnd ? "Do Not Disturb" : "Off"
                        active: Config.notifications.dnd
                        expandable: false
                        onToggled: Config.set("notifications", "dnd", !Config.notifications.dnd)
                    }
                }
            }

            // Media when something plays, otherwise the battery
            Tile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.fillHeight: true

                Item {
                    anchors { fill: parent; margins: 12 }
                    visible: Config.controlCenter.showMedia && cc.player !== null

                    Rectangle {
                        id: artBox
                        width: 40; height: 40; radius: 8
                        color: Theme.fill
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: cc.player?.trackArtUrl ?? ""
                            fillMode: Image.PreserveAspectCrop
                            sourceSize { width: 80; height: 80 }
                            visible: status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: !(cc.player?.trackArtUrl)
                            text: "\u{F075A}"
                            color: Theme.subtext
                            font { family: Theme.iconFont; pixelSize: 20 }
                        }
                    }
                    Column {
                        anchors { left: parent.left; right: parent.right; top: artBox.bottom; topMargin: 8 }
                        Text { width: parent.width; text: cc.player?.trackTitle || cc.player?.identity || ""; color: Theme.text; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold } }
                        Text { width: parent.width; text: cc.player?.trackArtist || cc.player?.identity || ""; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                    }
                    Row {
                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: -6 }
                        spacing: 10
                        Repeater {
                            model: [
                                ["\u{F04AE}", () => cc.player.previous(), cc.player?.canGoPrevious ?? false, 20],
                                [cc.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}", () => cc.player.togglePlaying(), cc.player?.canTogglePlaying ?? false, 26],
                                ["\u{F04AD}", () => cc.player.next(), cc.player?.canGoNext ?? false, 20],
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
                    anchors { fill: parent; margins: 12 }
                    visible: !(Config.controlCenter.showMedia && cc.player !== null)
                    Text {
                        text: cc.charging ? "\u{F0084}" : "\u{F0079}"
                        color: cc.charging ? Theme.success : Theme.text
                        font { family: Theme.iconFont; pixelSize: 24 }
                    }
                    Column {
                        anchors { left: parent.left; bottom: parent.bottom }
                        Text { text: cc.pct + "%"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontDisplay; weight: Font.DemiBold; features: { "tnum": 1 } } }
                        Text { text: cc.batteryText; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                    }
                }
            }
        }

        // ---- quick toggles ------------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: cc.gap
            QuickToggle {
                glyph: "\u{F0599}"
                label: "Night"
                hint: ({ off: "Off", on: "On", sun: "Sunset to sunrise", schedule: `${Config.nightLight.from}–${Config.nightLight.to}` })[Config.nightLight.mode]
                active: NightLight.active
                onToggled: NightLight.toggle()
            }
            QuickToggle {
                glyph: "\u{F0176}"
                label: Caffeine.active ? Caffeine.remaining(cc.now.getTime()) : "Caffeine"
                hint: "Keep awake · choose how long"
                active: Caffeine.active
                expandable: true
                isExpanded: cc.expanded === "caffeine"
                onToggled: Caffeine.toggle()
                onExpand: cc.toggleExpanded("caffeine")
            }
            QuickToggle { // shared monitor (monswitch), only when ~/.config/monswitch.conf exists
                visible: Machine.monitorSwitch
                readonly property bool ours: Hyprland.monitors.values.some(m => m.name === Machine.switchOutput)
                glyph: "\u{F0379}"
                label: "Monitor"
                hint: ours ? "On this computer" : "On the other computer"
                active: ours
                onToggled: Quickshell.execDetached(["monswitch", "toggle"])
            }
            QuickToggle {
                visible: Machine.kbdDevice !== ""
                glyph: cc.kbdLight > 0 ? "\u{F0E5B}" : "\u{F0E5A}"
                label: "Key light"
                hint: ["Off", "Low", "Medium", "High"][cc.kbdLight] + " · click for next level"
                active: cc.kbdLight > 0
                onToggled: cc.setKbd((cc.kbdLight + 1) % 4)
            }
            QuickToggle {
                glyph: "\u{F030C}"
                label: "Keyboard"
                hint: "On-screen keyboard"
                active: Osk.visible
                onToggled: Osk.toggle()
            }
        }

        // ---- lists that open under the toggles -----------------------------------------------
        Module {
            visible: cc.expanded === "wifi"
            title: "Wi-Fi networks"
            expandable: true; isExpanded: true
            onDetailClicked: cc.toggleExpanded("wifi")
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
                    Layout.preferredHeight: 34
                    Layout.topMargin: 6
                    radius: Theme.radiusSmall
                    color: Theme.fill
                    border { color: psk.activeFocus ? Theme.accent : Theme.stroke; width: 1 }
                    TextInput {
                        id: psk
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontSize }
                        focus: parent.visible
                        onAccepted: { cc.passwordFor.connectWithPsk(text); text = ""; cc.passwordFor = null }
                        Keys.onEscapePressed: cc.passwordFor = null
                        Text {
                            visible: !psk.text
                            width: parent.width
                            elide: Text.ElideRight
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
            title: "Bluetooth devices"
            expandable: true; isExpanded: true
            onDetailClicked: cc.toggleExpanded("bt")
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
            title: "Keep awake for"
            expandable: true; isExpanded: true
            onDetailClicked: cc.toggleExpanded("caffeine")
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

        // ---- display and sound: one tile, three sliders ---------------------------------------
        Tile {
            Layout.fillWidth: true
            Layout.preferredHeight: sliders.implicitHeight + 22
            ColumnLayout {
                id: sliders
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11; leftMargin: 12; rightMargin: 12 }
                spacing: 10

                SliderHead { title: "Display" }
                Bar {
                    lowIcon: "\u{F00DE}"; highIcon: "\u{F00E0}"
                    value: cc.brightness
                    onMoved: v => {
                        cc.brightness = Math.max(0.05, v)
                        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(cc.brightness * 100) + "%"])
                    }
                }

                SliderHead {
                    title: "Sound"
                    detail: cc.nodeName(cc.sink) || "No output"
                    isExpanded: cc.expanded === "out"
                    onClicked: cc.toggleExpanded("out")
                }
                Bar {
                    lowIcon: cc.sink?.audio?.muted ? "\u{F075F}" : "\u{F057F}"; highIcon: "\u{F057E}"
                    value: cc.sink?.audio?.muted ? 0 : (cc.sink?.audio?.volume ?? 0)
                    onMoved: v => { if (cc.sink?.audio) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                    onLowClicked: if (cc.sink?.audio) cc.sink.audio.muted = !cc.sink.audio.muted
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

                SliderHead {
                    title: "Microphone"
                    detail: cc.nodeName(cc.source) || "No input"
                    isExpanded: cc.expanded === "in"
                    onClicked: cc.toggleExpanded("in")
                }
                Bar {
                    lowIcon: cc.source?.audio?.muted ? "\u{F036D}" : "\u{F036C}"; highIcon: ""
                    value: cc.source?.audio?.muted ? 0 : (cc.source?.audio?.volume ?? 0)
                    onMoved: v => { if (cc.source?.audio) { cc.source.audio.muted = false; cc.source.audio.volume = v } }
                    onLowClicked: if (cc.source?.audio) cc.source.audio.muted = !cc.source.audio.muted
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
        }

        // ---- power mode ---------------------------------------------------------------------
        Module {
            title: "Power mode"
            detail: Config.controlCenter.showHardware ? `CPU ${Math.round(Sensors.cpu)}°` : ""
            warn: Sensors.cpu >= 90
            onDetailClicked: { cc.hide(); SettingsApp.show(Machine.asus ? "asus" : "power") }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.controlHeight
                radius: Theme.radiusSmall + 1
                color: Theme.fill

                Rectangle {
                    width: (parent.width - 6) / 3
                    height: parent.height - 6
                    y: 3
                    x: 3 + PowerProfiles.profile * width
                    radius: Theme.radiusSmall - 1
                    color: Theme.thumb
                    Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                }
                Row {
                    anchors { fill: parent; margins: 3 }
                    Repeater {
                        model: ["Quiet", "Balanced", "Performance"]
                        Item {
                            required property string modelData
                            required property int index
                            readonly property bool on: PowerProfiles.profile === index
                            width: parent.width / 3
                            height: parent.height
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: parent.on ? Theme.thumbText : Theme.subtext
                                font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: PowerProfiles.profile = index }
                        }
                    }
                }
            }
        }

        // ---- footer: battery, then shortcuts --------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 2
            Text {
                Layout.fillWidth: true
                visible: cc.battery?.isPresent ?? false
                text: (cc.charging ? "\u{F0084} " : "\u{F0079} ") + cc.pct + "%  ·  " + cc.batteryText
                elide: Text.ElideRight
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
            }
            Item { Layout.fillWidth: true; visible: !(cc.battery?.isPresent ?? false) }
            IconButton { glyph: "\u{F0100}"; hint: "Screenshot an area"; onClicked: { cc.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; screenshot"]) } }
            IconButton { glyph: "\u{F0493}"; hint: "Settings"; onClicked: { cc.hide(); SettingsApp.show("") } }
            IconButton { glyph: "\u{F0425}"; hint: "Lock, sleep, restart…"; onClicked: { cc.hide(); UtilityMenu.toggle() } }
        }

        // ---- notifications: the history, grouped by app; a group folds into its newest card ----
        RowLayout {
            id: notesHeader
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.leftMargin: 4
            spacing: 4
            Text {
                Layout.fillWidth: true
                text: Notifications.history.length ? "Notifications" : "No notifications"
                color: Notifications.history.length ? Theme.text : Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
            }
            Chip {
                icon: Notifications.dnd ? "\u{F009B}" : "\u{F009A}"
                label: Notifications.dnd ? "Do Not Disturb" : ""
                active: Notifications.dnd
                onClicked: Notifications.toggleDnd()
            }
            Chip { visible: Notifications.history.length > 0; label: "Clear all"; onClicked: Notifications.clearAll() }
        }
        Repeater {
            model: Notifications.groups
            ColumnLayout {
                id: group
                required property var modelData
                readonly property bool unfolded: modelData.items.length === 1 || NotificationCenter.unfolded[modelData.app] === true
                Layout.fillWidth: true
                Layout.bottomMargin: unfolded ? 0 : 12        // room for the folded stack
                spacing: 6

                RowLayout {
                    visible: group.modelData.items.length > 1 && group.unfolded
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Text {
                        Layout.fillWidth: true
                        text: group.modelData.app
                        color: Theme.subtext
                        elide: Text.ElideRight
                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                    }
                    Chip { label: "Show less"; onClicked: NotificationCenter.fold(group.modelData.app, true) }
                    Chip { icon: "\u{F0156}"; onClicked: Notifications.clearApp(group.modelData.app) }
                }
                Repeater {
                    model: group.unfolded ? group.modelData.items : group.modelData.items.slice(0, 1)
                    NotificationCard {
                        required property var modelData
                        Layout.fillWidth: true
                        flat: true
                        notification: modelData
                        stacked: group.unfolded ? 0 : group.modelData.items.length - 1
                        onExpandRequested: NotificationCenter.fold(group.modelData.app, false)
                    }
                }
            }
        }
    }
    }
    }

    Rectangle {   // the shared tooltip (cc.hint), kept inside the panel's edges
        id: hintBox
        readonly property var at: cc.hintItem ? cc.hintItem.mapToItem(popup.box, 0, 0) : Qt.point(0, 0)
        readonly property bool fitsBelow: at.y + (cc.hintItem?.height ?? 0) + 6 + height <= popup.box.height - 4
        z: 100
        opacity: cc.hintItem ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        width: Math.min(hintLabel.implicitWidth + Theme.spaceM * 2, popup.box.width - 8)
        height: hintLabel.implicitHeight + Theme.spaceS
        x: Math.max(4, Math.min(at.x + (cc.hintItem?.width ?? 0) / 2 - width / 2, popup.box.width - width - 4))
        y: fitsBelow ? at.y + (cc.hintItem?.height ?? 0) + 6 : at.y - height - 6
        radius: Theme.radiusSmall - 2
        color: Theme.menu
        border { color: Theme.stroke; width: 1 }
        Text {
            id: hintLabel
            anchors.centerIn: parent
            width: Math.min(implicitWidth, popup.box.width - 8 - Theme.spaceM * 2)
            text: cc.hintText
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
    }
    }

    // ---- building blocks -----------------------------------------------------------------------

    // A grouping tile on the panel: a slightly lighter rounded area, no border
    component Tile: Rectangle {
        radius: Theme.radius
        color: Theme.fill
    }

    // Connection row: round icon that toggles, then name and status that open its list
    component ConnRow: Item {
        id: conn
        property string glyph
        property string title
        property string subtitle
        property bool active: false
        property bool expandable: true
        property bool isExpanded: false
        signal toggled()
        signal expand()

        width: parent ? parent.width : 0
        height: 44

        Rectangle {   // hover / open highlight for the list part
            anchors { fill: parent; margins: 1 }
            radius: Theme.radiusSmall + 2
            color: conn.isExpanded ? Theme.fillHover : rowHover.containsMouse && conn.expandable ? Theme.fill : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
        MouseArea {
            id: rowHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: conn.expandable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: conn.expandable ? conn.expand() : conn.toggled()
        }
        Rectangle {   // round toggle (inline: components declared in this file can't nest)
            id: disc
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            width: 30; height: 30; radius: 15
            color: conn.active ? Theme.selected : discArea.containsMouse ? Theme.fillActive : Theme.fillHover
            scale: discArea.pressed ? 0.92 : 1
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
            Text {
                anchors.centerIn: parent
                text: conn.glyph
                color: conn.active ? Theme.onSelected : Theme.text
                font { family: Theme.iconFont; pixelSize: 15 }
            }
            MouseArea { id: discArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: conn.toggled() }
        }
        Column {
            anchors { left: disc.right; leftMargin: 8; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            Text { width: parent.width; text: conn.title; color: Theme.text; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
            Text { width: parent.width; text: conn.subtitle; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontCaption } }
        }
    }

    // A square tile in the quick-toggle row: icon over a short label; accent when on.
    // With a list, a small chevron in the corner opens it (right-click works too).
    component QuickToggle: Rectangle {
        id: qt
        property string glyph
        property string label
        property string hint
        property bool active: false
        property bool expandable: false
        property bool isExpanded: false
        signal toggled()
        signal expand()

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: 58
        radius: Theme.radius
        color: active ? Theme.selected : qtArea.containsMouse ? Theme.fillHover : Theme.fill
        border { color: isExpanded ? Theme.accent : "transparent"; width: 1 }
        scale: qtArea.pressed ? 0.96 : 1
        Behavior on color { ColorAnimation { duration: Theme.anim } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

        Column {
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 3
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qt.glyph
                color: qt.active ? Theme.onSelected : Theme.text
                font { family: Theme.iconFont; pixelSize: 18 }
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: qt.label
                elide: Text.ElideRight
                color: qt.active ? Theme.onSelected : Theme.subtext
                font { family: Theme.font; pixelSize: 10; weight: Font.Medium }
            }
        }
        MouseArea {
            id: qtArea
            anchors.fill: parent
            hoverEnabled: true
            onContainsMouseChanged: containsMouse && qt.hint !== "" ? cc.hint(qt, qt.hint) : cc.unhint(qt)
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => mouse.button === Qt.RightButton && qt.expandable ? qt.expand() : qt.toggled()
        }
        Rectangle {
            visible: qt.expandable
            anchors { right: parent.right; top: parent.top; margins: 3 }
            width: 18; height: 18; radius: 9
            color: chevArea.containsMouse ? Theme.fillActive : "transparent"
            Chevron { anchors.centerIn: parent; open: qt.isExpanded; size: 12 }
            MouseArea { id: chevArea; anchors { fill: parent; margins: -3 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: qt.expand() }
        }

    }

    // Small round icon button for the footer
    component IconButton: Rectangle {
        id: ib
        property string glyph
        property string hint
        signal clicked()
        Layout.preferredWidth: 30
        Layout.preferredHeight: 30
        radius: 15
        color: ibArea.containsMouse ? Theme.fillHover : "transparent"
        Text { anchors.centerIn: parent; text: ib.glyph; color: Theme.text; font { family: Theme.iconFont; pixelSize: 15 } }
        MouseArea {
            id: ibArea
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: ib.clicked()
            onContainsMouseChanged: containsMouse ? cc.hint(ib, ib.hint) : cc.unhint(ib)
        }
    }

    // Label over a slider; with a detail (device name) it is a button that opens the device list
    component SliderHead: Item {
        id: sh
        property string title
        property string detail
        property bool isExpanded: false
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredHeight: 16
        Layout.bottomMargin: -4
        Text {
            id: shTitle
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: sh.title
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
        }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            visible: sh.detail !== ""
            spacing: 2
            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, sh.width - shTitle.implicitWidth - 30)
                text: sh.detail
                elide: Text.ElideRight
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
            Chevron { open: sh.isExpanded; size: 13; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea {
            anchors.fill: parent
            enabled: sh.detail !== ""
            cursorShape: Qt.PointingHandCursor
            onClicked: sh.clicked()
        }
    }

    // A tile with a title row (and a clickable detail on the right)
    component Module: Rectangle {   // same look as Tile
        id: mod
        radius: Theme.radius
        color: Theme.fill
        property string title
        property string detail
        property bool warn: false          // detail in the warning colour
        property bool expandable: false    // header shows a chevron and opens/closes a list
        property bool isExpanded: false
        default property alias body: inner.data
        signal detailClicked()

        Layout.fillWidth: true
        Layout.preferredHeight: inner.implicitHeight + 22

        ColumnLayout {
            id: inner
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11; leftMargin: 12; rightMargin: 12 }
            spacing: 6
            Item {
                id: header
                visible: mod.title !== ""
                Layout.fillWidth: true
                Layout.preferredHeight: 16
                Text {
                    id: headerTitle
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: mod.title
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                }
                Row {
                    id: headerDetail
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 4
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, header.width - headerTitle.implicitWidth - 40)
                        text: mod.detail
                        elide: Text.ElideRight
                        color: mod.warn ? Theme.warning : Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
                    }
                    Chevron { visible: mod.expandable; open: mod.isExpanded; size: 13; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    anchors.fill: mod.expandable ? header : headerDetail
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mod.detailClicked()
                }
            }
        }
    }

    // Thin slider: icon, track, icon
    component Bar: RowLayout {
        id: bar
        property real value: 0
        property string lowIcon
        property string highIcon
        signal moved(real value)
        signal lowClicked()

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
            Layout.preferredHeight: 20
            Rectangle {
                id: track
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 6
                radius: 3
                color: Theme.fill
                Rectangle {
                    width: Math.max(track.height, track.width * Math.max(0, Math.min(1, bar.value)))
                    height: parent.height
                    radius: parent.radius
                    color: Theme.selected
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
    }

    component ListRow: Rectangle {
        id: row
        property string glyph
        property string title
        property string trailing
        property bool selected: false
        signal clicked()
        Layout.fillWidth: true
        implicitHeight: Theme.controlHeight + 4
        radius: Theme.radiusSmall
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
