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

// Control Center, opened beside its bar item (the quick-settings item, Super+C,
// `qs ipc call controlcenter toggle`): one panel holding grouped tiles.
//   Wi-Fi / Bluetooth / Focus / Night Light tiles · Caffeine, shared monitor, key light, on-screen keyboard
//   media (while something plays) · Display, Sound and Microphone sliders · Power mode
//   shortcuts (screenshot, settings, lock, power). Notifications have their own panel (NotificationCenter.qml).
// A tile's round icon toggles it; the rest of the tile (or a chevron) opens its list underneath.
// The battery lives in the bar, so it isn't repeated here.
// This file holds the state, the header and the tooltip. Each section is a ControlCenter<Section>.qml
// (Connections, Toggles, Media, Sliders, Power, Shortcuts); the tiles and rows they use are ControlCenter<Block>.qml.
// The parts read the panel's state (expanded, adapter, sink ...) from this singleton by name.
Singleton {
    id: cc

    readonly property bool open: popup.open
    // ---- layout (Settings > Control Center): order of sections and tiles, and what's hidden ----
    readonly property var defaults: ({
        sections: ["connections", "toggles", "media", "sliders", "power", "shortcuts"],
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
    // Settings, Lock and Power sit in the header; the shortcuts row keeps the rest
    readonly property var shownShortcuts: shown("shortcuts").filter(id => !["settings", "lock", "power"].includes(id))

    // names and icons of everything the layout editor (Settings > Control Center) can move or hide
    readonly property var itemInfo: ({
        connections: { label: "Connections", glyph: "\u{F05A9}", group: "tiles" },
        toggles: { label: "Quick toggles", glyph: "\u{F0176}", group: "toggles" },
        media: { label: "Media (while playing)", glyph: "\u{F075A}" },
        sliders: { label: "Display and sound", glyph: "\u{F00DF}" },
        power: { label: "Power mode", glyph: "\u{F0079}" },
        shortcuts: { label: "Shortcuts", glyph: "\u{F0100}", group: "shortcuts" },
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
    function toggleNotifications() { NotificationCenter.toggle() }   // old entry point; notifications have their own panel

    // One tooltip for the whole panel, drawn above the scroll area so it is never clipped
    property Item hintItem: null
    property string hintText: ""
    function hint(item, text) { hintText = text; hintItem = item }
    function unhint(item) { if (hintItem === item) hintItem = null }
    function hide() { popup.hide() }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { cc.toggle() }
        function close(): void { popup.hide() }
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
            Notifications.now = new Date()
        }
        else { expanded = ""; passwordFor = null; hintItem = null }
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
    boxHeight: Math.min(header.height + cc.gap + content.implicitHeight + cc.pad * 2, popup.maxHeight)

    Glass {   // the backdrop every tile sits on
        anchors.fill: parent
        strong: true
        radius: cc.style === "compact" ? Theme.radiusLarge : cc.style === "borderless" ? Theme.radius : Theme.radiusPanel
        border.width: cc.style === "borderless" ? 0 : 1

    // ---- header: the time large in the theme's display face, the date, then battery and the three
    // things you reach for (Settings, Lock, Power) as round buttons ----
    RowLayout {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: cc.pad; leftMargin: cc.pad + 4 }
        height: 52
        spacing: 6
        Column {
            Layout.fillWidth: true
            Text {
                text: Sys.time()
                color: Theme.text
                font { family: Theme.displayFont; pixelSize: Theme.fontDisplay - 2; weight: Theme.displayWeight; letterSpacing: -0.5; features: { "tnum": 1 } }
            }
            Text {
                text: Qt.formatDateTime(Sys.now, "dddd, d MMMM")
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium }
            }
        }
        Row {   // battery, as a readout
            visible: Sys.hasBattery
            Layout.alignment: Qt.AlignVCenter
            Layout.rightMargin: 4
            spacing: 4
            Text { anchors.verticalCenter: parent.verticalCenter; text: Sys.batteryGlyph; color: Sys.batteryLow ? Theme.error : Sys.charging ? Theme.success : Theme.subtext
                   font { family: Theme.iconFont; pixelSize: 16 } }
            Text { anchors.verticalCenter: parent.verticalCenter; text: Sys.batteryPct + "%"; color: Theme.subtext
                   font { family: Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } } }
        }
        Repeater {
            model: [
                { glyph: "\u{F0493}", tip: "Settings", run: () => { popup.hide(); SettingsApp.show("") } },
                { glyph: "\u{F033E}", tip: "Lock", run: () => { popup.hide(); Quickshell.execDetached(["loginctl", "lock-session"]) } },
                { glyph: "\u{F0425}", tip: "Power", run: () => { popup.hide(); PowerMenu.show() } }
            ]
            Rectangle {
                required property var modelData
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 34; implicitHeight: 34
                radius: Theme.radius === 0 ? 0 : 17
                color: hdrArea.pressed ? Theme.fillActive : hdrArea.containsMouse ? Theme.fillHover : Theme.fill
                scale: hdrArea.pressed ? Theme.pressScale : 1
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                Text { anchors.centerIn: parent; text: modelData.glyph; color: modelData.tip === "Power" ? Theme.error : Theme.text; font { family: Theme.iconFont; pixelSize: 16 } }
                MouseArea { id: hdrArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: containsMouse ? cc.hint(parent, modelData.tip) : cc.unhint(parent)
                            onClicked: modelData.run() }
            }
        }
    }

    Flickable {
        id: scroller
        anchors { fill: parent; margins: cc.pad; topMargin: cc.pad + header.height + cc.gap }
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        ScrollBar.vertical: GlassScrollBar {}

    GridLayout {   // one column; each section takes the row of its place in cc.shownSections
        id: content
        width: scroller.width
        columns: 1
        rowSpacing: cc.gap

        ControlCenterConnections {}
        ControlCenterToggles {}
        ControlCenterMedia {}
        ControlCenterSliders {}
        ControlCenterPower {}
        ControlCenterShortcuts {}

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
}
