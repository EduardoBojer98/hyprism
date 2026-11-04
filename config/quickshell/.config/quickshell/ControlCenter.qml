pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center at the top right of the screen under the pointer (status pill, Super+C,
// `qs ipc call controlcenter toggle`): one glass panel holding grouped tiles.
//   Wi-Fi / Bluetooth / Focus / Night Light tiles · Caffeine, shared monitor, key light, on-screen keyboard
//   media (while something plays) · Display, Sound and Microphone sliders · Power mode
//   shortcuts (screenshot, settings, lock, power) · notifications
// A tile's round icon toggles it; the rest of the tile (or a chevron) opens its list underneath.
// The battery lives in the bar, so it isn't repeated here.
Singleton {
    id: cc

    readonly property bool open: popup.open
    // ---- layout (Settings > Control Center): order of sections and tiles, and what's hidden ----
    readonly property var defaults: ({
        sections: ["connections", "toggles", "media", "sliders", "power", "shortcuts", "notifications"],
        tiles: ["wifi", "bt", "focus", "nightlight"],
        toggles: ["caffeine", "monitor", "keylight", "keyboard", "touchpad", "touchscreen", "record"],
        shortcuts: ["screenshot", "settings", "lock", "power", "colorpicker", "mission"]
    })
    // the saved order, plus anything newer than the saved list at the end
    function order(group) {
        const saved = (Config.controlCenter[group] ?? []).filter(id => defaults[group].includes(id))
        return saved.concat(defaults[group].filter(id => !saved.includes(id)))
    }
    function available(id) {
        switch (id) {
        case "monitor": return Machine.monitorSwitch
        case "keylight": return Machine.kbdDevice !== ""
        case "media": return player !== null
        default: return true
        }
    }
    function shown(group) { return order(group).filter(id => !Config.controlCenter.hidden.includes(id) && available(id)) }
    readonly property var shownSections: shown("sections")
    readonly property var shownTiles: shown("tiles")
    readonly property var shownToggles: shown("toggles")
    readonly property var shownShortcuts: shown("shortcuts")

    // names and icons of everything the layout editor (Settings > Control Center) can move or hide
    readonly property var itemInfo: ({
        connections: { label: "Connections", glyph: "\u{F05A9}", group: "tiles" },
        toggles: { label: "Quick toggles", glyph: "\u{F0176}", group: "toggles" },
        media: { label: "Media (while playing)", glyph: "\u{F075A}" },
        sliders: { label: "Display and sound", glyph: "\u{F00DF}" },
        power: { label: "Power mode", glyph: "\u{F0079}" },
        shortcuts: { label: "Shortcuts", glyph: "\u{F0100}", group: "shortcuts" },
        notifications: { label: "Notifications", glyph: "\u{F009A}" },
        wifi: { label: "Wi-Fi", glyph: "\u{F05A9}" },
        bt: { label: "Bluetooth", glyph: "\u{F00AF}" },
        focus: { label: "Focus", glyph: "\u{F0594}" },
        nightlight: { label: "Night Light", glyph: "\u{F0599}" },
        caffeine: { label: "Caffeine", glyph: "\u{F0176}" },
        monitor: { label: "Shared monitor", glyph: "\u{F0379}" },
        keylight: { label: "Key light", glyph: "\u{F0E5B}" },
        keyboard: { label: "On-screen keyboard", glyph: "\u{F030C}" },
        touchpad: { label: "Touchpad", glyph: "\u{F0E40}" },
        touchscreen: { label: "Touchscreen", glyph: "\u{F0741}" },
        record: { label: "Record screen", glyph: "\u{F044A}" }
    })
    // shortcut buttons: what each one shows and does (the Settings editor lists them too)
    readonly property var shortcutInfo: ({
        screenshot: { glyph: "\u{F0100}", label: "Screenshot", run: () => Quickshell.execDetached(["sh", "-c", "sleep 0.3; screenshot"]) },
        settings: { glyph: "\u{F0493}", label: "Settings", run: () => SettingsApp.show("") },
        lock: { glyph: "\u{F033E}", label: "Lock", run: () => Quickshell.execDetached(["loginctl", "lock-session"]) },
        power: { glyph: "\u{F0425}", label: "Power", run: () => PowerMenu.show() },
        colorpicker: { glyph: "\u{F020A}", label: "Colour", run: () => Quickshell.execDetached(["sh", "-c", "sleep 0.3; hyprpicker -a"]) },
        mission: { glyph: "\u{F0570}", label: "Windows", run: () => MissionControl.toggle() }
    })

    property string expanded: ""     // "", "wifi", "bt", "caffeine", "out", "in"
    property var passwordFor: null   // Wi-Fi network waiting for a password
    property string wifiFailed: ""   // name of the network that just failed to connect
    property real brightness: 0
    property int kbdLight: 0           // 0-3
    property date now: new Date()

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    readonly property string style: Config.controlCenter.style || "panel"
    readonly property int customWidth: Config.controlCenter.width || 330
    readonly property int gap: style === "compact" ? 4 : 8          // between tiles
    readonly property int pad: style === "compact" ? 6 : 10         // panel padding


    readonly property var streams: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioOutStream)   // apps playing
    PwObjectTracker { objects: [cc.sink, cc.source].concat(cc.streams) }

    // icon and kind for an audio device / a Bluetooth device's icon name
    function audioGlyph(n) {
        const d = n?.description ?? ""
        if (/HDMI|DisplayPort|\bDP\b/.test(d)) return "\u{F0379}"
        if (n?.name?.startsWith("bluez") || /Headphone|Headset/i.test(d)) return "\u{F02CB}"
        return "\u{F04C3}"
    }
    function audioKind(n) {
        const d = n?.description ?? "", name = n?.name ?? ""
        return name.startsWith("bluez") ? "Bluetooth" : /HDMI|DisplayPort|\bDP\b/.test(d) ? "Screen (HDMI / DisplayPort)"
             : name.includes("usb") ? "USB" : /Analog/.test(d) ? "Built-in" : ""
    }
    function btGlyph(icon) {
        return ({ "audio-headset": "\u{F02CE}", "audio-headphones": "\u{F02CB}", "audio-card": "\u{F04C3}", "input-mouse": "\u{F037D}",
                  "input-keyboard": "\u{F030C}", "input-gaming": "\u{F0297}", "phone": "\u{F011C}", "computer": "\u{F0322}" })[icon] ?? "\u{F00AF}"
    }

    function toggle() { popup.toggle() }
    function showSection(name) { if (!popup.open) popup.show(); cc.expanded = name }   // a bar item opens its own part
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
        // open with a dropdown showing: wifi, bt, caffeine, out (sound), in (microphone)
        function expand(name: string): void { if (!popup.open) popup.show(); cc.expanded = name }
    }

    Connections {
        target: popup
        function onOpenChanged() { cc.opened(popup.open) }
    }
    function opened(visible) {
        if (wifi) wifi.scannerEnabled = visible
        if (visible) {
            scroller.contentY = 0; brightnessRead.running = true; Hyprland.refreshMonitors(); kbdRead.running = Machine.kbdDevice !== ""; now = new Date()
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
        onTriggered: { scroller.contentY = Math.max(0, Math.min(notesSection.y + notesHeader.y - 4, scroller.contentHeight - scroller.height)); cc.toNotes = false }
    }

    // short device names: the monitor's own name for HDMI/DP audio, "Built-in …" for the laptop's codec
    function nodeName(n) {
        const d = n?.description ?? "", nick = n?.nickname ?? ""
        if (/HDMI|DisplayPort|\bDP\b/.test(d) && nick) return nick
        if (/Analog/.test(d) && /Controller/.test(d)) return n.type === PwNodeType.AudioSink ? "Built-in speakers" : "Built-in microphone"
        return d || nick || n?.name || ""
    }
    function toggleExpanded(name) { expanded = expanded === name ? "" : name; passwordFor = null; wifiFailed = "" }
    function setKbd(level) {
        kbdLight = level
        Quickshell.execDetached(["brightnessctl", "-q", "-d", Machine.kbdDevice, "set", String(level)])
    }

    CursorPopup {
    id: popup
    name: "controlcenter"
    placement: "topRight"
    boxWidth: cc.customWidth
    // capped to the screen; the content scrolls when lists make it taller
    boxHeight: Math.min(content.implicitHeight + cc.pad * 2, (popup.targetScreen?.height ?? 1000) - popup.topReserve - popup.edge * 2)

    Glass {   // the backdrop every tile sits on
        anchors.fill: parent
        strong: true
        radius: cc.style === "compact" ? Theme.radiusLarge : cc.style === "borderless" ? Theme.radius : Theme.radiusLarge + 4
        border.width: cc.style === "borderless" ? 0 : 1

    Flickable {
        id: scroller
        anchors { fill: parent; margins: cc.pad }
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: GlassScrollBar {}

    GridLayout {   // one column; each section takes the row of its place in cc.shownSections
        id: content
        width: scroller.width
        columns: 1
        rowSpacing: cc.gap

        ColumnLayout {
            Layout.fillWidth: true
            Layout.row: Math.max(0, cc.shownSections.indexOf("connections"))
            visible: cc.shownSections.includes("connections")
            spacing: cc.gap

            // ---- connections: Wi-Fi, Bluetooth, Focus, Night Light --------------------------------
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: cc.gap
                rowSpacing: cc.gap
                ConnTile {
                    visible: cc.shownTiles.includes("wifi")
                    Layout.row: Math.floor(Math.max(0, cc.shownTiles.indexOf("wifi")) / 2); Layout.column: Math.max(0, cc.shownTiles.indexOf("wifi")) % 2
                    glyph: Networking.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
                    title: "Wi-Fi"
                    subtitle: !Networking.wifiEnabled ? "Off" : (cc.wifi?.networks.values.find(n => n.connected)?.name ?? "Not connected")
                    active: Networking.wifiEnabled
                    isExpanded: cc.expanded === "wifi"
                    onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                    onExpand: cc.toggleExpanded("wifi")
                }
                ConnTile {
                    visible: cc.shownTiles.includes("bt")
                    Layout.row: Math.floor(Math.max(0, cc.shownTiles.indexOf("bt")) / 2); Layout.column: Math.max(0, cc.shownTiles.indexOf("bt")) % 2
                    glyph: cc.adapter?.enabled ? "\u{F00AF}" : "\u{F00B2}"
                    title: "Bluetooth"
                    subtitle: !cc.adapter ? "Unavailable" : !cc.adapter.enabled ? "Off"
                            : (cc.adapter.devices.values.filter(d => d.connected).map(d => d.name).join(", ") || "On")
                    active: cc.adapter?.enabled ?? false
                    isExpanded: cc.expanded === "bt"
                    onToggled: if (cc.adapter) cc.adapter.enabled = !cc.adapter.enabled
                    onExpand: cc.toggleExpanded("bt")
                }
                ConnTile {
                    visible: cc.shownTiles.includes("focus")
                    Layout.row: Math.floor(Math.max(0, cc.shownTiles.indexOf("focus")) / 2); Layout.column: Math.max(0, cc.shownTiles.indexOf("focus")) % 2
                    glyph: "\u{F0594}"
                    title: "Focus"
                    subtitle: Config.notifications.dnd ? "Do Not Disturb" : "Off"
                    active: Config.notifications.dnd
                    expandable: false
                    onToggled: Config.set("notifications", "dnd", !Config.notifications.dnd)
                }
                ConnTile {
                    visible: cc.shownTiles.includes("nightlight")
                    Layout.row: Math.floor(Math.max(0, cc.shownTiles.indexOf("nightlight")) / 2); Layout.column: Math.max(0, cc.shownTiles.indexOf("nightlight")) % 2
                    glyph: "\u{F0599}"
                    title: "Night Light"
                    subtitle: ({ off: "Off", on: "On", sun: "Sunset to sunrise", schedule: `${Config.nightLight.from}–${Config.nightLight.to}` })[Config.nightLight.mode]
                    active: NightLight.active
                    expandable: false
                    onToggled: NightLight.toggle()
                }
            }

            // ---- Wi-Fi and Bluetooth dropdowns, under their tiles ----------------------------------
            Drop {
                id: wifiDrop
                open: cc.expanded === "wifi"
                title: "Wi-Fi"
                switchOn: Networking.wifiEnabled
                onSwitched: Networking.wifiEnabled = !Networking.wifiEnabled
                settingsLabel: "Network Settings…"
                settingsPage: "network"

                // one row per name (the strongest access point), known networks first
                readonly property var nets: {
                    const best = {}
                    for (const n of cc.wifi?.networks.values ?? []) if (n.name && (!best[n.name] || n.connected || n.signalStrength > best[n.name].signalStrength)) best[n.name] = n
                    return Object.values(best).sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength)
                }
                readonly property var known: nets.filter(n => n.known || n.connected)
                readonly property var others: nets.filter(n => !n.known && !n.connected).slice(0, 6)

                SectionLabel { visible: wifiDrop.known.length > 0 && Networking.wifiEnabled; text: "Known networks" }
                Repeater { model: Networking.wifiEnabled ? wifiDrop.known : []; WifiRow {} }
                SectionLabel { visible: wifiDrop.others.length > 0 && Networking.wifiEnabled; text: "Other networks" }
                Repeater { model: Networking.wifiEnabled ? wifiDrop.others : []; WifiRow {} }
                Empty {
                    shown: !Networking.wifiEnabled || wifiDrop.nets.length === 0
                    text: !Networking.wifiEnabled ? "Wi-Fi is off." : "Looking for networks…"
                }
            }

            Drop {
                id: btDrop
                open: cc.expanded === "bt"
                title: "Bluetooth"
                switchOn: cc.adapter?.enabled ?? false
                onSwitched: if (cc.adapter) cc.adapter.enabled = !cc.adapter.enabled
                settingsLabel: "Bluetooth Settings…"
                settingsPage: "bluetooth"

                readonly property var devices: (cc.adapter?.devices.values ?? []).filter(d => d.paired || d.connected)
                    .sort((a, b) => b.connected - a.connected || a.name.localeCompare(b.name))

                SectionLabel { visible: btDrop.devices.length > 0 && (cc.adapter?.enabled ?? false); text: "My devices" }
                Repeater {
                    model: cc.adapter?.enabled ? btDrop.devices : []
                    DeviceRow {
                        required property var modelData
                        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                        glyph: cc.btGlyph(modelData.icon)
                        title: modelData.name
                        subtitle: modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                                : modelData.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                                : modelData.connected ? "Connected" + (modelData.batteryAvailable ? `  ·  ${Math.round(modelData.battery * 100)}% battery` : "")
                                : "Not connected"
                        selected: modelData.connected
                        action: busy ? "" : modelData.connected ? "Disconnect" : "Connect"
                        onClicked: if (!busy) modelData.connected ? modelData.disconnect() : modelData.connect()
                    }
                }
                Empty {
                    shown: !(cc.adapter?.enabled ?? false) || btDrop.devices.length === 0
                    text: !cc.adapter ? "No Bluetooth adapter." : !cc.adapter.enabled ? "Bluetooth is off." : "No paired devices yet. Pair one in Bluetooth Settings."
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.row: Math.max(0, cc.shownSections.indexOf("toggles"))
            visible: cc.shownSections.includes("toggles")
            spacing: cc.gap

            // ---- quick toggles: name, then what it's doing ---------------------------------------
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: cc.gap
                rowSpacing: cc.gap
                QuickToggle {
                    visible: cc.shownToggles.includes("caffeine")
                    Layout.row: Math.floor(Math.max(0, cc.shownToggles.indexOf("caffeine")) / 4); Layout.column: Math.max(0, cc.shownToggles.indexOf("caffeine")) % 4
                    glyph: "\u{F0176}"
                    label: "Caffeine"
                    status: Caffeine.active ? Caffeine.remaining(cc.now.getTime()) : "Off"
                    hint: "Keep awake · chevron to choose how long"
                    active: Caffeine.active
                    expandable: true
                    isExpanded: cc.expanded === "caffeine"
                    onToggled: Caffeine.toggle()
                    onExpand: cc.toggleExpanded("caffeine")
                }
                QuickToggle { // shared monitor (monswitch), only when ~/.config/monswitch.conf exists
                    visible: cc.shownToggles.includes("monitor")
                    Layout.row: Math.floor(Math.max(0, cc.shownToggles.indexOf("monitor")) / 4); Layout.column: Math.max(0, cc.shownToggles.indexOf("monitor")) % 4
                    readonly property bool ours: Hyprland.monitors.values.some(m => m.name === Machine.switchOutput)
                    glyph: "\u{F0379}"
                    label: "Monitor"
                    status: ours ? "Here" : "Other PC"
                    hint: ours ? "Shared monitor shows this computer · click to hand it over" : "Shared monitor shows the other computer · click to take it back"
                    active: ours
                    onToggled: Quickshell.execDetached(["monswitch", "toggle"])
                }
                QuickToggle {
                    visible: cc.shownToggles.includes("keylight")
                    Layout.row: Math.floor(Math.max(0, cc.shownToggles.indexOf("keylight")) / 4); Layout.column: Math.max(0, cc.shownToggles.indexOf("keylight")) % 4
                    glyph: cc.kbdLight > 0 ? "\u{F0E5B}" : "\u{F0E5A}"
                    label: "Key light"
                    status: ["Off", "Low", "Medium", "High"][cc.kbdLight]
                    hint: "Keyboard backlight · click for the next level"
                    active: cc.kbdLight > 0
                    onToggled: cc.setKbd((cc.kbdLight + 1) % 4)
                }
                QuickToggle {
                    visible: cc.shownToggles.includes("keyboard")
                    Layout.row: Math.floor(Math.max(0, cc.shownToggles.indexOf("keyboard")) / 4); Layout.column: Math.max(0, cc.shownToggles.indexOf("keyboard")) % 4
                    glyph: "\u{F030C}"
                    label: "Keyboard"
                    status: Osk.visible ? "Shown" : "Hidden"
                    hint: "On-screen keyboard"
                    active: Osk.visible
                    onToggled: Osk.toggle()
                }
                QuickToggle {
                    visible: cc.shownToggles.includes("touchpad") && Inputs.touchpadName !== ""
                    Layout.row: Math.floor(Math.max(0, cc.shownToggles.indexOf("touchpad")) / 4); Layout.column: Math.max(0, cc.shownToggles.indexOf("touchpad")) % 4
                    glyph: Inputs.touchpad ? "\u{F0E40}" : "\u{F0E41}"
                    label: "Touchpad"
                    status: Inputs.touchpad ? "On" : "Off"
                    hint: "Turn it off while typing on an external keyboard; back on at the next login"
                    active: Inputs.touchpad
                    onToggled: Inputs.setTouchpad(!Inputs.touchpad)
                }
                QuickToggle {
                    visible: cc.shownToggles.includes("touchscreen")
                    Layout.row: Math.floor(Math.max(0, cc.shownToggles.indexOf("touchscreen")) / 4); Layout.column: Math.max(0, cc.shownToggles.indexOf("touchscreen")) % 4
                    glyph: "\u{F0741}"
                    label: "Touch"
                    status: Inputs.touchscreen ? "On" : "Off"
                    hint: "Touchscreen and pen; back on at the next login"
                    active: Inputs.touchscreen
                    onToggled: Inputs.setTouchscreen(!Inputs.touchscreen)
                }
                QuickToggle {
                    visible: cc.shownToggles.includes("record")
                    Layout.row: Math.floor(Math.max(0, cc.shownToggles.indexOf("record")) / 4); Layout.column: Math.max(0, cc.shownToggles.indexOf("record")) % 4
                    glyph: "\u{F044A}"
                    label: "Record"
                    status: Sys.recording ? "Recording" : "Off"
                    hint: "Record the screen under the mouse (Super+Alt+R) · Super+Alt+Shift+R for an area"
                    active: Sys.recording
                    onToggled: { if (!Sys.recording) cc.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; record " + (Sys.recording ? "stop" : "screen")]) }
                }
            }

            Drop {
                open: cc.expanded === "caffeine"
                title: "Caffeine"
                switchOn: Caffeine.active
                onSwitched: Caffeine.toggle()
                settingsLabel: "Lock & Sleep Settings…"
                settingsPage: "idle"

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    Layout.bottomMargin: 2
                    wrapMode: Text.Wrap
                    text: !Caffeine.active ? "Keeps the screen on and stops sleep. Stays on after a restart until you turn it off."
                        : Caffeine.endsAt === 0 ? "Keeping the screen on until you turn it off."
                        : "Keeping the screen on until " + Qt.formatTime(new Date(Caffeine.endsAt), "HH:mm") + "  ·  " + Caffeine.remaining(cc.now.getTime())
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                }
                SectionLabel { text: Caffeine.active ? "Change to" : "Turn on for" }
                Segmented {
                    options: Caffeine.choices.map(m => m === 0 ? "Always" : Caffeine.label(m))
                    current: Caffeine.active ? Caffeine.choices.indexOf(Caffeine.minutes) : -1
                    onPicked: i => { Caffeine.start(Caffeine.choices[i]); cc.now = new Date() }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.row: Math.max(0, cc.shownSections.indexOf("media"))
            visible: cc.shownSections.includes("media")
            spacing: cc.gap

            // ---- media, while a player is around ----------------------------------------------------
            Tile {
                visible: cc.player !== null
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                Rectangle {
                    id: artBox
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    width: 44; height: 44; radius: Theme.radiusSmall
                    color: Theme.fill
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: cc.player?.trackArtUrl ?? ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize { width: 88; height: 88 }
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
                    anchors { left: artBox.right; leftMargin: 10; right: controls.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    Text { width: parent.width; text: cc.player?.trackTitle || cc.player?.identity || ""; color: Theme.text; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold } }
                    Text { width: parent.width; text: cc.player?.trackArtist || cc.player?.identity || ""; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                }
                Row {
                    id: controls
                    anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    Repeater {
                        model: [
                            ["\u{F04AE}", () => cc.player.previous(), cc.player?.canGoPrevious ?? false, 18],
                            [cc.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}", () => cc.player.togglePlaying(), cc.player?.canTogglePlaying ?? false, 24],
                            ["\u{F04AD}", () => cc.player.next(), cc.player?.canGoNext ?? false, 18],
                        ]
                        Rectangle {
                            required property var modelData
                            width: 32; height: 32; radius: 16
                            color: mediaArea.containsMouse && modelData[2] ? Theme.fillHover : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData[0]
                                opacity: parent.modelData[2] ? 1 : 0.35
                                color: Theme.text
                                font { family: Theme.iconFont; pixelSize: parent.modelData[3] }
                            }
                            MouseArea { id: mediaArea; anchors.fill: parent; hoverEnabled: true; enabled: parent.modelData[2]; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData[1]() }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.row: Math.max(0, cc.shownSections.indexOf("sliders"))
            visible: cc.shownSections.includes("sliders")
            spacing: cc.gap

            // ---- display and sound: one tile, three sliders ---------------------------------------
            Tile {
                Layout.fillWidth: true
                Layout.preferredHeight: sliders.implicitHeight + 22
                ColumnLayout {
                    id: sliders
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11; leftMargin: 12; rightMargin: 12 }
                    spacing: 10
                    // the section's title; click it to fold the section down to this one line
                    SliderHead {
                        title: "Display and sound"
                        detail: Config.controlCenter.slidersOpen ? "Hide"
                            : `Screen ${Math.round(cc.brightness * 100)}% · Sound ${cc.sink?.audio?.muted ? "muted" : Math.round((cc.sink?.audio?.volume ?? 0) * 100) + "%"}`
                        isExpanded: Config.controlCenter.slidersOpen
                        onClicked: Config.set("controlCenter", "slidersOpen", !Config.controlCenter.slidersOpen)
                    }
                    Reveal {
                        open: Config.controlCenter.slidersOpen
                        spacing: 10

                        SliderHead { title: "Display" }
                        Text { // names only once there's more than one screen to tell apart
                            visible: externals.count > 0
                            Layout.bottomMargin: -6
                            text: "Built-in"
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                        }
                        Bar {
                            icon: "\u{F00DF}"
                            value: cc.brightness
                            onMoved: v => {
                                cc.brightness = Math.max(0.05, v)
                                Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(cc.brightness * 100) + "%"])
                            }
                        }
                        // external monitors over DDC/CI (VCP 0x10); read each time the panel opens, hidden when
                        // a monitor doesn't answer (DDC/CI off in its menu)
                        Repeater {
                            id: externals
                            model: popup.open ? Hyprland.monitors.values.filter(m => !m.name.startsWith("eDP")) : []
                            ColumnLayout {
                                id: ext
                                required property var modelData
                                property string bus: ""
                                property int max: 100
                                property real value: -1
                                visible: value >= 0
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: ext.modelData.lastIpcObject?.model || ext.modelData.name
                                    color: Theme.subtext
                                    font { family: Theme.font; pixelSize: Theme.fontCaption }
                                }
                                Bar {
                                    icon: "\u{F0379}"
                                    value: Math.max(0, ext.value)
                                    onMoved: v => { ext.value = Math.max(0.01, v); ddcSet.restart() }
                                }
                                Process {
                                    running: true
                                    command: ["sh", "-c", "b=$(readlink -f /sys/class/drm/card*-\"$1\"/ddc | sed 's/.*i2c-//'); [ -n \"$b\" ] || exit 1; echo \"$b\"; ddcutil --bus \"$b\" getvcp 10 --terse", "sh", ext.modelData.name]
                                    stdout: StdioCollector {
                                        onStreamFinished: {
                                            const l = text.trim().split("\n")   // "6", "VCP 10 C 80 100"
                                            const v = (l[1] ?? "").split(" ")
                                            if (v[0] !== "VCP" || !(parseInt(v[4]) > 0)) return
                                            ext.bus = l[0]; ext.max = parseInt(v[4]); ext.value = parseInt(v[3]) / ext.max
                                        }
                                    }
                                }
                                Timer {   // DDC is slow: send once dragging pauses
                                    id: ddcSet
                                    interval: 150
                                    onTriggered: Quickshell.execDetached(["ddcutil", "--bus", ext.bus, "--noverify", "setvcp", "10", String(Math.round(ext.value * ext.max))])
                                }
                            }
                        }

                        SliderHead {
                            title: "Sound"
                            detail: cc.nodeName(cc.sink) || "No output"
                            isExpanded: cc.expanded === "out"
                            onClicked: cc.toggleExpanded("out")
                        }
                        Bar {
                            icon: cc.sink?.audio?.muted ? "\u{F075F}" : "\u{F057E}"
                            hint: cc.sink?.audio?.muted ? "Unmute" : "Mute"
                            value: cc.sink?.audio?.muted ? 0 : (cc.sink?.audio?.volume ?? 0)
                            onMoved: v => { if (cc.sink?.audio) { cc.sink.audio.muted = false; cc.sink.audio.volume = v } }
                            onIconClicked: if (cc.sink?.audio) cc.sink.audio.muted = !cc.sink.audio.muted
                        }
                        Reveal {
                            open: cc.expanded === "out"
                            SectionLabel { text: "Play sound through" }
                            Repeater {
                                model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSink)
                                DeviceRow {
                                    required property var modelData
                                    glyph: cc.audioGlyph(modelData)
                                    title: cc.nodeName(modelData)
                                    subtitle: cc.audioKind(modelData)
                                    selected: modelData === cc.sink
                                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                                }
                            }
                            SectionLabel { visible: cc.streams.length > 0; text: "Apps" }
                            Repeater {
                                model: cc.streams
                                ColumnLayout {
                                    id: app
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 6
                                    Layout.rightMargin: 6
                                    Layout.bottomMargin: 4
                                    spacing: 4
                                    Text {
                                        Layout.fillWidth: true
                                        text: app.modelData.properties["application.name"] || app.modelData.description || app.modelData.name
                                        elide: Text.ElideRight
                                        color: Theme.subtext
                                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                                    }
                                    Bar {
                                        icon: app.modelData.audio?.muted ? "\u{F075F}" : "\u{F057E}"
                                        hint: app.modelData.audio?.muted ? "Unmute" : "Mute"
                                        value: app.modelData.audio?.muted ? 0 : (app.modelData.audio?.volume ?? 0)
                                        onMoved: v => { if (app.modelData.audio) { app.modelData.audio.muted = false; app.modelData.audio.volume = v } }
                                        onIconClicked: if (app.modelData.audio) app.modelData.audio.muted = !app.modelData.audio.muted
                                    }
                                }
                            }
                            SettingsLink { label: "Sound Settings…"; page: "sound" }
                        }

                        SliderHead {
                            title: "Microphone"
                            detail: cc.nodeName(cc.source) || "No input"
                            isExpanded: cc.expanded === "in"
                            onClicked: cc.toggleExpanded("in")
                        }
                        Bar {
                            icon: cc.source?.audio?.muted ? "\u{F036D}" : "\u{F036C}"
                            hint: cc.source?.audio?.muted ? "Unmute" : "Mute"
                            value: cc.source?.audio?.muted ? 0 : (cc.source?.audio?.volume ?? 0)
                            onMoved: v => { if (cc.source?.audio) { cc.source.audio.muted = false; cc.source.audio.volume = v } }
                            onIconClicked: if (cc.source?.audio) cc.source.audio.muted = !cc.source.audio.muted
                        }
                        Reveal {
                            open: cc.expanded === "in"
                            SectionLabel { text: "Record from" }
                            Repeater {
                                model: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
                                DeviceRow {
                                    required property var modelData
                                    glyph: modelData.name.startsWith("bluez") ? "\u{F02CE}" : "\u{F036C}"
                                    title: cc.nodeName(modelData)
                                    subtitle: cc.audioKind(modelData)
                                    selected: modelData === cc.source
                                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                                }
                            }
                            SettingsLink { label: "Sound Settings…"; page: "sound" }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.row: Math.max(0, cc.shownSections.indexOf("power"))
            visible: cc.shownSections.includes("power")
            spacing: cc.gap

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
                        x: 3 + PowerMode.profile * width
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
                                readonly property bool on: PowerMode.profile === index
                                width: parent.width / 3
                                height: parent.height
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: parent.on ? Theme.thumbText : Theme.subtext
                                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: PowerMode.set(index) }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.row: Math.max(0, cc.shownSections.indexOf("shortcuts"))
            visible: cc.shownSections.includes("shortcuts")
            spacing: cc.gap

            // ---- shortcuts ------------------------------------------------------------------------
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: cc.gap
                rowSpacing: cc.gap
                Repeater {
                    model: cc.shownShortcuts
                    IconButton {
                        required property string modelData
                        readonly property var sc: cc.shortcutInfo[modelData]
                        glyph: sc.glyph
                        label: sc.label
                        onClicked: { cc.hide(); sc.run() }
                    }
                }
            }
        }

        ColumnLayout {
            id: notesSection
            Layout.fillWidth: true
            Layout.row: Math.max(0, cc.shownSections.indexOf("notifications"))
            visible: cc.shownSections.includes("notifications")
            spacing: cc.gap

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
                Text {
                    visible: Notifications.dnd
                    text: "\u{F009B}  Silenced"
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption }
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

    // A dropdown under its tile: title with an on/off switch, the content, then a link to Settings
    component Drop: Rectangle {
        id: drop
        property string title
        property bool switchOn: false
        property bool hasSwitch: true
        property string settingsLabel
        property string settingsPage
        property bool open: false
        default property alias body: dropBody.data
        signal switched()

        // slides open and shut: the height follows the content, so it also grows as networks appear
        property real shown: open ? dropCol.implicitHeight + 16 : 0
        Behavior on shown { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        Layout.fillWidth: true
        Layout.preferredHeight: shown
        visible: shown > 0
        clip: true
        opacity: open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        radius: Theme.radius
        color: Theme.fill
        border { color: Theme.stroke; width: 1 }

        ColumnLayout {
            id: dropCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                Text {
                    Layout.fillWidth: true
                    text: drop.title
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
                }
                Toggle { visible: drop.hasSwitch; checked: drop.switchOn; onToggled: drop.switched() }
            }
            ColumnLayout { id: dropBody; Layout.fillWidth: true; spacing: 2 }
            SettingsLink { visible: drop.settingsLabel !== ""; label: drop.settingsLabel; page: drop.settingsPage }
        }
    }

    // A column that slides open and shut (the sound and microphone device lists)
    component Reveal: Item {
        id: rv
        property bool open: false
        property alias spacing: rvCol.spacing
        default property alias content: rvCol.data
        property real shown: open ? rvCol.implicitHeight : 0
        Behavior on shown { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        Layout.fillWidth: true
        Layout.preferredHeight: shown
        visible: shown > 0
        clip: true
        opacity: open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        ColumnLayout {
            id: rvCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 2
        }
    }

    // Small heading inside a dropdown ("Known networks", "Apps")
    component SectionLabel: Text {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.topMargin: 6
        Layout.bottomMargin: 2
        color: Theme.muted
        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
    }

    // A hairline, then "X Settings…" that opens that Settings page
    component SettingsLink: ColumnLayout {
        id: link
        property string label
        property string page
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 4
        Rectangle { Layout.fillWidth: true; Layout.leftMargin: 6; Layout.rightMargin: 6; implicitHeight: 1; color: Theme.stroke }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: Theme.radiusSmall
            color: linkArea.containsMouse ? Theme.fillHover : "transparent"
            Text {
                anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
                text: link.label
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontLabel }
            }
            MouseArea { id: linkArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { cc.hide(); SettingsApp.show(link.page) } }
        }
    }

    // A device or network: round icon (accent when in use), name, status line, and on hover what a
    // click does ("Connect", "Disconnect"); a check mark marks the one in use
    component DeviceRow: Rectangle {
        id: dr
        property string glyph
        property string title
        property string subtitle
        property string trailingGlyph       // e.g. a lock on secured networks
        property string action              // shown on hover
        property bool selected: false
        property bool warn: false
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: subtitle !== "" ? 44 : 36
        radius: Theme.radiusSmall
        color: drArea.containsMouse ? Theme.fillHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Rectangle {
            id: badge
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            width: 28; height: 28; radius: 14
            color: dr.selected ? Theme.accent : Theme.fillHover
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            Text {
                anchors.centerIn: parent
                text: dr.glyph
                color: dr.selected ? Theme.accentText : Theme.text
                font { family: Theme.iconFont; pixelSize: 14 }
            }
        }
        Column {
            anchors { left: badge.right; leftMargin: 10; right: tail.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 1
            Text {
                width: parent.width
                text: dr.title
                elide: Text.ElideRight
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontSize; weight: dr.selected ? Font.DemiBold : Font.Normal }
            }
            Text {
                visible: dr.subtitle !== ""
                width: parent.width
                text: dr.subtitle
                elide: Text.ElideRight
                color: dr.warn ? Theme.warning : Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
        }
        Item {
            id: tail
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            width: Math.max(actionPill.visible ? actionPill.width : 0, tailGlyph.visible ? tailGlyph.implicitWidth : 0)
            height: 22
            Rectangle {
                id: actionPill
                visible: drArea.containsMouse && dr.action !== ""
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                width: actionText.implicitWidth + 16; height: 22; radius: 11
                color: Theme.fillActive
                Text { id: actionText; anchors.centerIn: parent; text: dr.action; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
            }
            Text {
                id: tailGlyph
                visible: !actionPill.visible && text !== ""
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: dr.selected ? "\u{F012C}" : dr.trailingGlyph
                color: dr.selected ? Theme.accent : Theme.muted
                font { family: Theme.iconFont; pixelSize: 14 }
            }
        }
        MouseArea { id: drArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dr.clicked() }
    }

    // A Wi-Fi network row; a secured network you haven't joined asks for its password right under it
    component WifiRow: ColumnLayout {
        id: wr
        required property var modelData
        readonly property bool secured: modelData.security !== WifiSecurityType.Open
        readonly property bool failed: cc.wifiFailed === modelData.name
        Layout.fillWidth: true
        spacing: 2

        DeviceRow {
            glyph: wr.modelData.signalStrength > 0.66 ? "\u{F0928}" : wr.modelData.signalStrength > 0.33 ? "\u{F0925}" : "\u{F091F}"
            title: wr.modelData.name
            subtitle: wr.modelData.stateChanging ? (wr.modelData.connected ? "Disconnecting…" : "Connecting…")
                    : wr.modelData.connected ? "Connected"
                    : wr.failed ? "Couldn't connect" + (wr.secured ? ". Check the password." : "")
                    : wr.modelData.known ? "Saved" : wr.secured ? "Secured" : "Open"
            warn: wr.failed && !wr.modelData.connected
            trailingGlyph: wr.secured ? "\u{F033E}" : ""
            selected: wr.modelData.connected
            action: wr.modelData.connected ? "Disconnect" : "Join"
            onClicked: {
                cc.wifiFailed = ""
                if (wr.modelData.connected) wr.modelData.disconnect()
                else if (wr.modelData.known || !wr.secured) wr.modelData.connect()
                else cc.passwordFor = wr.modelData
            }
        }
        Connections {
            target: wr.modelData
            function onConnectionFailed() { cc.wifiFailed = wr.modelData.name; if (wr.secured) cc.passwordFor = wr.modelData }
        }
        RowLayout {   // password, under the network it's for
            visible: cc.passwordFor === wr.modelData
            Layout.fillWidth: true
            Layout.leftMargin: 44
            Layout.rightMargin: 6
            Layout.bottomMargin: 6
            spacing: 6
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: Theme.radiusSmall
                color: Theme.fill
                border { color: psk.activeFocus ? Theme.accent : Theme.stroke; width: 1 }
                TextInput {
                    id: psk
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontSize }
                    focus: parent.parent.visible
                    onAccepted: join()
                    Keys.onEscapePressed: cc.passwordFor = null
                    function join() { if (!text) return; cc.wifiFailed = ""; wr.modelData.connectWithPsk(text); text = ""; cc.passwordFor = null }
                    Text { visible: !psk.text; anchors.verticalCenter: parent.verticalCenter; text: "Password"; color: Theme.muted; font: psk.font }
                }
            }
            Chip { label: "Join"; active: psk.text !== ""; onClicked: psk.join() }
        }
    }

    // Segmented choice (current -1 = none picked)
    component Segmented: Rectangle {
        id: seg
        property var options: []
        property int current: -1
        signal picked(int index)
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        implicitHeight: Theme.controlHeight + 2
        radius: Theme.radiusSmall + 1
        color: Theme.fill
        Rectangle {
            visible: seg.current >= 0
            width: (parent.width - 6) / Math.max(1, seg.options.length)
            height: parent.height - 6
            y: 3
            x: 3 + Math.max(0, seg.current) * width
            radius: Theme.radiusSmall - 1
            color: Theme.thumb
            Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        }
        Row {
            anchors { fill: parent; margins: 3 }
            Repeater {
                model: seg.options
                Item {
                    required property string modelData
                    required property int index
                    width: parent.width / seg.options.length
                    height: parent.height
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: seg.current === index ? Theme.thumbText : Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: seg.picked(index) }
                }
            }
        }
    }

    // A grouping tile on the panel: a slightly lighter rounded area, no border
    component Tile: Rectangle {
        radius: cc.style === "borderless" ? Theme.radiusSmall : Theme.radius
        color: cc.style === "borderless" ? "transparent" : Theme.fill
        border { color: cc.style === "borderless" ? Theme.stroke : "transparent"; width: cc.style === "borderless" ? 0 : 0 }
    }

    // Connection tile: round icon that toggles, then name and status that open its list (chevron)
    component ConnTile: Rectangle {
        id: conn
        property string glyph
        property string title
        property string subtitle
        property bool active: false
        property bool expandable: true
        property bool isExpanded: false
        signal toggled()
        signal expand()

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: cc.style === "compact" ? 44 : 52
        radius: cc.style === "borderless" ? Theme.radiusSmall : Theme.radius
        color: conn.isExpanded || rowHover.containsMouse ? Theme.fillHover
             : cc.style === "borderless" ? "transparent" : Theme.fill
        border { color: conn.isExpanded ? Theme.strokeStrong : cc.style === "borderless" ? Theme.stroke : "transparent"; width: 1 }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        MouseArea {
            id: rowHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: conn.expandable ? conn.expand() : conn.toggled()
        }
        Rectangle {   // round toggle (inline: components declared in this file can't nest)
            id: disc
            anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
            width: 32; height: 32; radius: 16
            color: conn.active ? Theme.selected : discArea.containsMouse ? Theme.fillActive : Theme.fillHover
            scale: discArea.pressed ? 0.92 : 1
            Behavior on color { ColorAnimation { duration: Theme.anim } }
            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
            Text {
                anchors.centerIn: parent
                text: conn.glyph
                color: conn.active ? Theme.onSelected : Theme.text
                font { family: Theme.iconFont; pixelSize: 16 }
            }
            MouseArea { id: discArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: conn.toggled() }
        }
        Column {
            anchors { left: disc.right; leftMargin: 9; right: chev.visible ? chev.left : parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            Text { width: parent.width; text: conn.title; color: Theme.text; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
            Text { width: parent.width; text: conn.subtitle; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontCaption } }
        }
        Chevron { id: chev; visible: conn.expandable; open: conn.isExpanded; size: 12; anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } }
    }

    // A square tile in the quick-toggle row: icon, name, and what it's doing; white when on.
    // With a list, a small chevron in the corner opens it (right-click works too).
    component QuickToggle: Rectangle {
        id: qt
        property string glyph
        property string label
        property string status
        property string hint
        property bool active: false
        property bool expandable: false
        property bool isExpanded: false
        signal toggled()
        signal expand()

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: cc.style === "compact" ? 54 : 66
        radius: cc.style === "borderless" ? Theme.radiusSmall : Theme.radius
        color: active ? Theme.selected
             : qtArea.containsMouse ? Theme.fillHover
             : cc.style === "borderless" ? "transparent" : Theme.fill
        border { color: isExpanded ? Theme.accent : cc.style === "borderless" ? Theme.stroke : "transparent"; width: 1 }
        scale: qtArea.pressed ? 0.96 : 1
        Behavior on color { ColorAnimation { duration: Theme.anim } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

        Column {
            anchors.centerIn: parent
            width: parent.width - 8
            spacing: 1
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
                color: qt.active ? Theme.onSelected : Theme.text
                font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
            }
            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: qt.status
                elide: Text.ElideRight
                opacity: 0.75
                color: qt.active ? Theme.onSelected : Theme.subtext
                font { family: Theme.font; pixelSize: 10; features: { "tnum": 1 } }
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
        Rectangle {   // dropdown button: a small round badge that reads on both the light (on) and dark (off) tile
            visible: qt.expandable
            anchors { right: parent.right; top: parent.top; margins: 5 }
            width: 20; height: 20; radius: 10
            color: qt.active ? Qt.rgba(0, 0, 0, chevArea.containsMouse || qt.isExpanded ? 0.16 : 0.09)
                             : chevArea.containsMouse || qt.isExpanded ? Theme.fillActive : Theme.fillHover
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            Chevron {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: qt.isExpanded ? -1 : 1
                open: qt.isExpanded
                size: 13
                color: qt.active ? Theme.onSelected : Theme.text
            }
            MouseArea { id: chevArea; anchors { fill: parent; margins: -4 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: qt.expand() }
        }

    }

    // Shortcut in the bottom row: icon over a small label, on a quiet tile
    component IconButton: Rectangle {
        id: ib
        property string glyph
        property string label
        signal clicked()
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.preferredHeight: 50
        radius: Theme.radius
        color: ibArea.containsMouse ? Theme.fillHover : Theme.fill
        scale: ibArea.pressed ? 0.96 : 1
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
        Column {
            anchors.centerIn: parent
            spacing: 2
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: ib.glyph; color: Theme.text; font { family: Theme.iconFont; pixelSize: 16 } }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: ib.label; color: Theme.subtext; font { family: Theme.font; pixelSize: 10; weight: Font.Medium } }
        }
        MouseArea { id: ibArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
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

    // Pill slider: the fill carries the icon (click it to mute), the value sits at the right end
    component Bar: Item {
        id: bar
        property real value: 0
        property string icon
        property string hint
        signal moved(real value)
        signal iconClicked()
        readonly property real v: Math.max(0, Math.min(1, value))

        Layout.fillWidth: true
        Layout.preferredHeight: 26

        Rectangle {
            id: track
            anchors.fill: parent
            radius: height / 2
            color: Theme.fill
            Rectangle {
                width: Math.max(track.height, track.width * bar.v)
                height: parent.height
                radius: parent.radius
                color: Theme.selected
            }
        }
        Text {
            id: barIcon
            anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
            text: bar.icon
            color: Theme.onSelected
            font { family: Theme.iconFont; pixelSize: 14 }
        }
        Text {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            text: Math.round(bar.v * 100) + "%"
            // over the fill near the top, on the track otherwise
            color: track.width * bar.v >= track.width - anchors.rightMargin - width - 2 ? Theme.onSelected : Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold; features: { "tnum": 1 } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            property bool onIcon: false
            function set(x) { bar.moved(Math.max(0, Math.min(1, x / width))) }
            onPressed: mouse => { onIcon = bar.hint !== "" && mouse.x < track.height; if (!onIcon) set(mouse.x) }
            onPositionChanged: mouse => { if (pressed && !onIcon) set(mouse.x) }
            onReleased: mouse => { if (onIcon && mouse.x < track.height) bar.iconClicked() }
            onWheel: wheel => bar.moved(Math.max(0, Math.min(1, bar.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
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
