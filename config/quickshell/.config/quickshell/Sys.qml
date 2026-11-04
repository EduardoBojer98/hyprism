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

// Live system state that every bar layout shows in its own way: sound, battery, network,
// Bluetooth, media, the focused app, the clock. One copy for the whole shell.
Singleton {
    id: root

    // ---- sound -------------------------------------------------------------------------------------
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string volumeGlyph: muted || volume === 0 ? "\u{F075F}" : volume < 0.34 ? "\u{F057F}" : volume < 0.67 ? "\u{F0580}" : "\u{F057E}"
    function nudgeVolume(d) { const a = sink?.audio; if (a) a.volume = Math.max(0, Math.min(1, a.volume + d * 0.05)) }
    function toggleMute() { const a = sink?.audio; if (a) a.muted = !a.muted }
    PwObjectTracker { objects: [root.sink] }

    // ---- screen brightness (brightnessctl; -1 = no backlight, e.g. a desktop) -------------------------
    property int brightness: -1
    function readBrightness() { brightnessRead.running = true }
    function nudgeBrightness(d) { Quickshell.execDetached(["sh", "-c", "brightnessctl -q set " + (d > 0 ? "5%+" : "5%-") + " && qs ipc call osd brightness $(brightnessctl -m | cut -d, -f4 | tr -d %)"]) }
    Process {
        id: brightnessRead
        running: true
        command: ["sh", "-c", "brightnessctl -l -c backlight -m 2>/dev/null | head -1 | cut -d, -f4 | tr -d %"]
        stdout: StdioCollector { onStreamFinished: root.brightness = text.trim() === "" ? -1 : Number(text.trim()) }
    }

    // ---- battery -----------------------------------------------------------------------------------
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isPresent ?? false
    readonly property int batteryPct: Math.round((battery?.percentage ?? 0) * 100)
    readonly property bool plugged: !UPower.onBattery
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property bool batteryLow: batteryPct <= 15 && !plugged
    readonly property string batteryGlyph: charging ? "\u{F0084}" : batteryPct > 90 ? "\u{F0079}" : batteryPct > 60 ? "\u{F0080}"
        : batteryPct > 35 ? "\u{F007E}" : batteryPct > 15 ? "\u{F007B}" : "\u{F008E}"

    // ---- network -----------------------------------------------------------------------------------
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var network: wifi?.networks.values.find(n => n.connected) ?? null
    readonly property bool wired: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property int signal: network ? Math.round(network.signalStrength * 100) : -1
    readonly property string networkName: wired ? "Wired" : network?.name ?? (wifiOn ? "Not connected" : "Wi-Fi off")
    readonly property string networkGlyph: wired ? "\u{F0200}" : !wifiOn ? "\u{F092E}" : signal < 0 ? "\u{F092F}"
        : signal > 66 ? "\u{F0928}" : signal > 33 ? "\u{F0925}" : "\u{F091F}"

    // ---- Bluetooth -----------------------------------------------------------------------------------
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property bool btLinked: adapter?.devices.values.some(d => d.connected) ?? false

    // ---- media ---------------------------------------------------------------------------------------
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property string track: [player?.trackTitle, player?.trackArtist].filter(x => x).join(" · ")

    // ---- focused app (Hyprland activewindow events) ----------------------------------------------
    property string appClass: ""
    property string appTitle: ""
    readonly property var appEntry: appClass && DesktopEntries.applications.values.length ? DesktopEntries.heuristicLookup(appClass) : null
    // no desktop entry: "com.anthropic.Claude" -> "Claude"
    readonly property string appName: appEntry?.name ?? (appClass.split(".").pop().replace(/^./, c => c.toUpperCase()))
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activewindow") return
            const comma = event.data.indexOf(",")
            root.appClass = event.data.slice(0, comma)
            root.appTitle = event.data.slice(comma + 1)
        }
    }
    Process {
        running: true
        command: ["hyprctl", "-j", "activewindow"]
        stdout: StdioCollector {
            onStreamFinished: { try { const w = JSON.parse(text); root.appClass = w.class ?? ""; root.appTitle = w.title ?? "" } catch (e) {} }
        }
    }

    // ---- clock ---------------------------------------------------------------------------------------
    SystemClock { id: clock; precision: Config.bar.seconds ? SystemClock.Seconds : SystemClock.Minutes }
    readonly property date now: clock.date
    readonly property bool h24: Config.bar.clock24
    function time(d) { return Qt.formatDateTime(d ?? now, h24 ? "HH:mm" : "h:mm") }
    function hours(d) { return Qt.formatDateTime(d ?? now, h24 ? "HH" : "h") }
    function minutes(d) { return Qt.formatDateTime(d ?? now, "mm") }
    readonly property string clockFormat: (({ full: "ddd d MMM  ", short: "d MMM  ", none: "" })[Config.bar.date] ?? "ddd d MMM  ")
        + (h24 ? "HH:mm" : "h:mm") + (Config.bar.seconds ? ":ss" : "") + (h24 ? "" : " AP")
    readonly property string clockText: Qt.formatDateTime(now, clockFormat)

    // ---- screen recording (~/.local/bin/record tells us when it starts and stops) ---------------
    property bool recording: false
    Process { running: true; command: ["record", "status"]; stdout: StdioCollector { onStreamFinished: root.recording = text.trim() === "on" } }
    IpcHandler {
        target: "recorder"
        function recording(on: bool): void { root.recording = on }
    }

    // ---- workspaces of one monitor, in order ---------------------------------------------------
    function workspacesOf(monitor) {
        return Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor).sort((a, b) => a.id - b.id)
    }
    function roman(n) {
        const r = [[10, "x"], [9, "ix"], [5, "v"], [4, "iv"], [1, "i"]]; let s = ""
        for (const [v, l] of r) while (n >= v) { s += l; n -= v }
        return s
    }
}
