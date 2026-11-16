pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center, opened beside its bar item (the quick-settings item, Super+C,
// `qs ipc call controlcenter toggle`): one panel, most used first.
//   large tiles (Wi-Fi, Bluetooth) · a Screen card (brightness, DDC monitors) · a Sound card (output, microphone) · small buttons (Focus, Night Light,
//   Caffeine, Record, Screenshot ...) · media (while something plays) · power mode · a footer with the battery,
//   Arrange, Settings, Lock and Power. Notifications have their own panel (NotificationCenter.qml).
// Any tile can be large or small (Settings > Control Center drags it between the two): `items` describes each
// one once and both shapes draw from it. A tile's icon (or a click on a small one) toggles it; a large tile's
// body or a small one's chevron (right-click) opens its list underneath.
// The layout lives in ControlCenterBody.qml, so Settings shows the same body as a live preview. Each section is
// a ControlCenter<Section>.qml (Connections, Toggles, Media, Sliders, Power); tiles and rows are ControlCenter<Block>.qml.
// Sections read the system from services (Sys, PowerMode, Sensors) and their panel's state from `host`
// (a PanelState), so the same section also works in a bar item's flyout (Flyouts.qml).
Singleton {
    id: cc

    readonly property bool open: popup.open
    // ---- layout (Settings > Control Center): order of sections and tiles, and what's hidden ----
    // `tiles` (large) and `toggles` (small) share their ids: an id sits in one of the two
    readonly property var defaults: ({
        sections: ["connections", "screen", "audio", "toggles", "media", "power"],
        tiles: ["wifi", "bt"],
        sliders: ["sound", "mic"],   // the Sound card's rows
        toggles: ["focus", "nightlight", "caffeine", "darkmode", "micmute", "airplane", "monitor", "keylight", "keyboard", "touchpad", "touchscreen", "record", "screenshot", "clipboard", "ocr", "emoji", "colorpicker", "mission"]
    })
    // the saved order; anything never saved goes to its default group, at its default place
    function order(group) {
        const cfg = Config.controlCenter
        const shared = group === "tiles" || group === "toggles"
        const known = shared ? defaults.tiles.concat(defaults.toggles) : defaults[group]
        const out = Array.from(cfg[group] ?? []).filter((id, i, all) => known.includes(id) && all.indexOf(id) === i)
        const elsewhere = shared ? Array.from(cfg[group === "tiles" ? "toggles" : "tiles"] ?? []) : []
        defaults[group].forEach((id, i) => { if (!out.includes(id) && !elsewhere.includes(id)) out.splice(Math.min(i, out.length), 0, id) })
        return out
    }
    function available(id) {
        switch (id) {
        case "monitor": return Machine.monitorSwitch
        case "micmute": return Sys.source !== null
        case "keylight": return Machine.kbdDevice !== ""
        case "touchpad": return Inputs.touchpadName !== ""
        case "media": return Sys.player !== null
        default: return true
        }
    }
    function shown(group) { return order(group).filter(id => !Config.controlCenter.hidden.includes(id) && available(id)) }
    readonly property var shownSections: shown("sections")
    // a section's place and whether it shows; the shared modules don't know about it
    function row(id) { return Math.max(0, shownSections.indexOf(id)) }
    function shows(id) { return shownSections.includes(id) }
    readonly property var shownTiles: shown("tiles")
    readonly property var shownToggles: shown("toggles")
    readonly property var shownSliders: shown("sliders")

    // sections and sliders, for the editor in Settings > Control Center (tiles describe themselves in `items`)
    readonly property var itemInfo: ({
        connections: { label: "Large tiles", glyph: "\u{F0570}", group: "tiles", about: "Big tiles with their state; Wi-Fi and Bluetooth open their lists" },
        screen: { label: "Screen", glyph: "\u{F00DF}", about: "Brightness and external monitors; hidden when nothing can be dimmed" },
        audio: { label: "Sound", glyph: "\u{F057E}", group: "sliders", about: "Output and microphone, each with its device list" },
        toggles: { label: "Small buttons", glyph: "\u{F0176}", group: "toggles", about: "A compact grid: click to switch, right-click for options" },
        media: { label: "Media", glyph: "\u{F075A}", about: "Only while something plays" },
        power: { label: "Power mode", glyph: "\u{F0079}", about: "Silent, Balanced or Performance" },
        sound: { label: "Output", glyph: "\u{F057E}" },
        mic: { label: "Microphone", glyph: "\u{F036C}" }
    })
    function info(id) { return itemInfo[id] ?? items[id] ?? { label: id, glyph: "" } }

    // Every tile, once: what it shows (glyph, label, status), whether it's on, what a click does and which list
    // it opens (`list`: a ControlCenterDrops name). `action` tiles run something and are never "on".
    readonly property var items: ({
        wifi: { label: "Wi-Fi", glyph: Networking.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}", list: "wifi",
                status: !Networking.wifiEnabled ? "Off" : (Sys.wifi?.networks.values.find(n => n.connected)?.name ?? "Not connected"),
                active: Networking.wifiEnabled, run: () => { Networking.wifiEnabled = !Networking.wifiEnabled } },
        bt: { label: "Bluetooth", glyph: Sys.adapter?.enabled ? "\u{F00AF}" : "\u{F00B2}", list: "bt",
              status: !Sys.adapter ? "Unavailable" : !Sys.adapter.enabled ? "Off"
                    : (Sys.adapter.devices.values.filter(d => d.connected).map(d => d.name).join(", ") || "On"),
              active: Sys.adapter?.enabled ?? false, run: () => { if (Sys.adapter) Sys.adapter.enabled = !Sys.adapter.enabled } },
        focus: { label: "Focus", glyph: "\u{F0594}", status: Notifications.dndStatus, active: Notifications.dnd,
                 hint: "Do Not Disturb: only critical notifications pop up", run: () => Notifications.toggleDnd() },
        nightlight: { label: "Night Light", glyph: "\u{F0599}", active: NightLight.active, run: () => NightLight.toggle(),
                      status: ({ off: "Off", on: "On", sun: "Sunset to sunrise", schedule: `${Config.nightLight.from}–${Config.nightLight.to}` })[Config.nightLight.mode] },
        caffeine: { label: "Caffeine", glyph: "\u{F0176}", list: "caffeine", status: Caffeine.remaining(cc.now.getTime()),
                    active: Caffeine.active, hint: "Keeps the screen awake", run: () => Caffeine.toggle() },
        monitor: { label: "Monitor", glyph: "\u{F0379}", active: cc.monitorHere, status: cc.monitorHere ? "Here" : "Other PC",
                   hint: cc.monitorHere ? "Shared monitor shows this computer: click to hand it over" : "Shared monitor shows the other computer: click to take it back",
                   run: () => Quickshell.execDetached(["monswitch", "toggle"]) },
        keylight: { label: "Key light", glyph: cc.kbdLight > 0 ? "\u{F0E5B}" : "\u{F0E5A}", active: cc.kbdLight > 0,
                    status: ["Off", "Low", "Medium", "High"][cc.kbdLight], hint: "Keyboard backlight: click for the next level",
                    run: () => cc.setKbd((cc.kbdLight + 1) % 4) },
        keyboard: { label: "Keyboard", glyph: "\u{F030C}", active: Osk.visible, status: Osk.visible ? "Shown" : "Hidden",
                    hint: "On-screen keyboard", run: () => Osk.toggle() },
        touchpad: { label: "Touchpad", glyph: Inputs.touchpad ? "\u{F0E40}" : "\u{F0E41}", active: Inputs.touchpad,
                    status: Inputs.touchpad ? "On" : "Off", hint: "Back on at the next login", run: () => Inputs.setTouchpad(!Inputs.touchpad) },
        touchscreen: { label: "Touch", glyph: "\u{F0741}", active: Inputs.touchscreen, status: Inputs.touchscreen ? "On" : "Off",
                       hint: "Touchscreen and pen; back on at the next login", run: () => Inputs.setTouchscreen(!Inputs.touchscreen) },
        record: { label: "Record", glyph: "\u{F044A}", active: Sys.recording, status: Sys.recording ? "Recording" : "Off",
                  hint: "The screen under the mouse (Super+Alt+R)",
                  run: () => { if (!Sys.recording) cc.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; record " + (Sys.recording ? "stop" : "screen")]) } },
        screenshot: { label: "Screenshot", glyph: "\u{F0100}", action: true, status: "", hint: "Opens the screenshot tool",
                      run: () => { cc.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; screenshot"]) } },
        colorpicker: { label: "Colour", glyph: "\u{F020A}", action: true, status: "", hint: "Pick a colour on screen and copy it",
                       run: () => { cc.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; hyprpicker -a"]) } },
        mission: { label: "Windows", glyph: "\u{F0570}", action: true, status: "", hint: "Every window at a glance",
                   run: () => { cc.hide(); MissionControl.toggle() } },
        darkmode: { label: "Dark mode", glyph: "\u{F050E}", active: !Theme.light, status: Theme.light ? "Light" : "Dark",
                    hint: "Every theme in its light or dark version", run: () => Config.set("appearance", "mode", Theme.light ? "dark" : "light") },
        micmute: { label: "Microphone", glyph: Sys.source?.audio?.muted ? "\u{F036D}" : "\u{F036C}", active: !(Sys.source?.audio?.muted ?? true),
                   status: !Sys.source ? "None" : Sys.source.audio?.muted ? "Muted" : "On", hint: "Mute or unmute the microphone",
                   run: () => { if (Sys.source?.audio) Sys.source.audio.muted = !Sys.source.audio.muted } },
        airplane: { label: "Airplane", glyph: "\u{F001D}", active: cc.airplane, status: cc.airplane ? "On" : "Off",
                    hint: "Wi-Fi and Bluetooth off together (on again together)",
                    run: () => { const on = cc.airplane; Networking.wifiEnabled = on; if (Sys.adapter) Sys.adapter.enabled = on } },
        clipboard: { label: "Clipboard", glyph: "\u{F014C}", action: true, status: "", hint: "What you copied (Super+V)",
                     run: () => { cc.hide(); Clipboard.toggle() } },
        ocr: { label: "Text", glyph: "\u{F0A3B}", action: true, status: "", hint: "Copy text from the screen: drag over it",
               run: () => { cc.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; screentext"]) } },
        emoji: { label: "Emoji", glyph: "\u{F0785}", action: true, status: "", hint: "Pick an emoji to paste",
                 run: () => { cc.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; emojipick"]) } }
    })
    // airplane: both radios off (one without an adapter counts as off)
    readonly property bool airplane: !Networking.wifiEnabled && !(Sys.adapter?.enabled ?? false)
    readonly property bool monitorHere: Hyprland.monitors.values.some(m => m.name === Machine.switchOutput)

    // what the sections share while the panel is open (folded-out list, Wi-Fi password, tooltip); flyouts have their own
    readonly property PanelState view: PanelState { popup: popup }
    property int kbdLight: 0           // 0-3
    property date now: new Date()

    readonly property string style: Config.controlCenter.style || "panel"
    readonly property int customWidth: Config.controlCenter.width || Theme.panelWidth
    readonly property int gap: style === "compact" ? Math.max(4, Theme.ccGap - 3) : Theme.ccGap   // between tiles
    readonly property int pad: style === "compact" ? Math.max(6, Theme.ccPad - 4) : Theme.ccPad   // panel padding
    readonly property int groupGap: style === "compact" ? gap : Theme.ccGroupGap                 // between sections


    function toggle() { popup.toggle() }
    function showSection(name) { if (!popup.open) popup.show(); view.expanded = name }   // a bar item opens its own part
    // the bell / Super+N: open (or close) scrolled down to the notifications
    function toggleNotifications() { NotificationCenter.toggle() }   // old entry point; notifications have their own panel

    // One tooltip for the whole panel, drawn above the scroll area so it is never clipped
    function hint(item, text) { view.hint(item, text) }
    function unhint(item) { view.unhint(item) }
    function hide() { popup.hide() }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { cc.toggle() }
        function close(): void { popup.hide() }
        // open with a dropdown showing: wifi, bt, caffeine, out (sound), in (microphone)
        function expand(name: string): void { cc.showSection(name) }
    }

    Connections {
        target: popup
        function onOpenChanged() { cc.opened(popup.open) }
    }
    function opened(visible) {
        if (Sys.wifi) Sys.wifi.scannerEnabled = visible
        if (visible) {
            Sys.readBrightness(); Hyprland.refreshMonitors(); kbdRead.running = Machine.kbdDevice !== ""; now = new Date()
            Notifications.now = new Date()
        }
        else view.reset()
    }

    Process {
        id: kbdRead
        command: ["brightnessctl", "-m", "-d", Machine.kbdDevice]   // asus::kbd_backlight,leds,1,33%,3
        stdout: StdioCollector { onStreamFinished: cc.kbdLight = parseInt(text.split(",")[2]) || 0 }
    }
    Timer { interval: 30000; repeat: true; running: popup.open; onTriggered: cc.now = new Date() }

    function setKbd(level) {
        kbdLight = level
        Quickshell.execDetached(["brightnessctl", "-q", "-d", Machine.kbdDevice, "set", String(level)])
    }

    readonly property int panelRadius: style === "compact" ? Theme.radiusLarge : style === "borderless" ? Theme.radius : Theme.radiusPanel

    CursorPopup {
    id: popup
    name: "controlcenter"
    placement: "topRight"
    boxWidth: cc.customWidth
    boxHeight: body.implicitHeight + cc.pad * 2

    Glass {   // the backdrop every tile sits on
        anchors.fill: parent
        strong: true
        radius: cc.panelRadius
        border.width: cc.style === "borderless" ? 0 : 1

        // empty background, inside the panel: a tile or a toggle above this still gets the click first
        MouseArea { anchors.fill: parent; Accessible.ignored: true; onClicked: popup.hide() }

        ControlCenterBody {
            id: body
            host: cc.view
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: cc.pad }
        }
    }

    Rectangle {   // the shared tooltip (cc.hint), kept inside the panel's edges
        id: hintBox
        readonly property var at: cc.view.hintItem ? cc.view.hintItem.mapToItem(hintBox.parent, 0, 0) : Qt.point(0, 0)
        readonly property bool fitsBelow: at.y + (cc.view.hintItem?.height ?? 0) + 6 + height <= hintBox.parent.height - 4
        z: 100
        opacity: cc.view.hintItem ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        width: Math.min(hintLabel.implicitWidth + Theme.spaceM * 2, hintBox.parent.width - 8)
        height: hintLabel.implicitHeight + Theme.spaceS
        x: Math.max(4, Math.min(at.x + (cc.view.hintItem?.width ?? 0) / 2 - width / 2, hintBox.parent.width - width - 4))
        y: fitsBelow ? at.y + (cc.view.hintItem?.height ?? 0) + 6 : at.y - height - 6
        radius: Theme.radiusSmall - 2
        color: Theme.menu
        border { color: Theme.stroke; width: 1 }
        Text {
            id: hintLabel
            anchors.centerIn: parent
            width: Math.min(implicitWidth, hintBox.parent.width - 8 - Theme.spaceM * 2)
            text: cc.view.hintText
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
    }
    }
}
