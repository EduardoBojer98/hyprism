pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Phone link through KDE Connect (kdeconnectd, its D-Bus API read with busctl, actions with kdeconnect-cli).
// The phone's notifications reach the shell's own notification server: kdeconnectd posts them like any app.
// Media: kdeconnectd lists the phone's players as MPRIS players, so the Control Center's media card shows them,
// and its mpriscontrol plugin ("remote") lets the phone control this computer's players.
// Clipboard sync, notifications and remote are KDE Connect's own per-device plugin switches (kept in its config,
// not settings.json). Settings > Phone; the Control Center's Phone tile.
//   qs ipc call phone status | ring | send <path> | pick | refresh
Singleton {
    id: root

    readonly property bool enabled: Config.phone.enabled
    property bool installed: true    // kdeconnect-cli on the PATH (until the first read says otherwise)
    property bool daemon: false      // kdeconnectd answers on D-Bus
    property bool read: false        // the first read is in
    property var devices: []         // { id, name, type, reachable, paired, requested, charge, charging, clipboard, notifications, remote }
    readonly property var paired: devices.filter(d => d.paired)
    readonly property var nearby: devices.filter(d => !d.paired && d.reachable)
    // the phone: the one picked in Settings, else the first paired one, reachable first
    readonly property var phone: paired.find(d => d.id === Config.phone.device)
                                 ?? paired.slice().sort((a, b) => b.reachable - a.reachable)[0] ?? null
    readonly property bool ready: enabled && (phone?.reachable ?? false)
    // off · missing (not installed) · starting (daemon not answering) · none (no device seen) · unpaired · away · ready
    readonly property string state: !enabled ? "off" : !installed ? "missing" : !read ? "starting" : !daemon ? "starting"
                                  : phone ? (phone.reachable ? "ready" : "away") : nearby.length ? "unpaired" : "none"
    readonly property string status: ({ off: "Off", missing: "Not installed", starting: "Starting…", none: "No phone found",
                                        unpaired: "Not paired", away: "Not nearby",
                                        ready: phone && phone.charge >= 0 ? phone.charge + "% battery" + (phone.charging ? ", charging" : "") : "Connected" })[state]
    readonly property string glyph: "\u{F011C}"
    // the phone's battery, the bar's way (Sys.batteryGlyph)
    function battGlyph(d) {
        if (!d || d.charge < 0) return ""
        const p = d.charge
        return d.charging ? "\u{F0084}" : p > 90 ? "\u{F0079}" : p > 60 ? "\u{F0080}" : p > 35 ? "\u{F007E}" : p > 15 ? "\u{F007B}" : "\u{F008E}"
    }
    // what a plugin switch maps to in KDE Connect
    readonly property var plugins: ({ clipboard: "kdeconnect_clipboard", notifications: "kdeconnect_notifications", remote: "kdeconnect_mpriscontrol" })

    // Several watchers (Control Center, Settings) ask for fresh reads while they are open
    property int watchers: 0
    function watch(on) { watchers = Math.max(0, watchers + (on ? 1 : -1)); if (on) refresh() }
    function refresh() { if (enabled && !reader.running) reader.running = true }

    function cli(...args) { Quickshell.execDetached(["kdeconnect-cli"].concat(args)) }
    function pair(id) { cli("-d", id, "--pair"); later.restart() }
    function unpair(id) { cli("-d", id, "--unpair"); later.restart() }
    function ring() { if (ready) cli("-d", phone.id, "--ring") }
    function send(paths) {
        if (!ready || !paths.length) return
        if (sender.running) { sender.queue = sender.queue.concat([paths]); return }   // one share at a time, the rest wait
        sender.count = paths.length
        sender.command = ["kdeconnect-cli", "-d", phone.id, "--share"].concat(paths)
        sender.running = true
    }
    function pick() { if (ready && !picker.running) picker.running = true }
    // a plugin switch: at once on screen, then in KDE Connect (and read back)
    function setPlugin(key, on) {
        if (!phone) return
        devices = devices.map(d => d.id === phone.id ? Object.assign({}, d, { [key]: on }) : d)
        Quickshell.execDetached(["busctl", "--user", "call", "org.kde.kdeconnect", "/modules/kdeconnect/devices/" + phone.id,
                                 "org.kde.kdeconnect.device", "setPluginEnabled", "sb", plugins[key], on ? "true" : "false"])
        later.restart()
    }
    // the daemon is D-Bus activated; started by hand where that isn't set up
    function start() {
        Quickshell.execDetached(["sh", "-c", "for d in /usr/lib/kdeconnectd /usr/libexec/kdeconnectd /usr/lib/*/libexec/kdeconnectd kdeconnectd; do "
                                           + "command -v \"$d\" >/dev/null && exec setsid \"$d\"; done"])
        later.restart()
    }
    // one click for "not installed": the package list (it holds kdeconnect) in a terminal
    function install() { BuiltinActions.inRepo("./install.sh --only packages") }
    function setEnabled(on) {
        Config.set("phone", "enabled", on)
        if (on) refresh()
        else { Quickshell.execDetached(["pkill", "-x", "kdeconnectd"]); daemon = false; devices = [] }
    }

    // One read: "missing" (no kdeconnect-cli), "nodaemon", or "ok" and one JSON line per known device.
    // Values that can't be read (a plugin that isn't loaded while the phone is away) come back null.
    Process {
        id: reader
        command: ["sh", "-c", `
command -v kdeconnect-cli >/dev/null && command -v jq >/dev/null || { echo missing; exit 0; }
k=org.kde.kdeconnect
ids=$(busctl --user -j call $k /modules/kdeconnect $k.daemon devices bb false false 2>/dev/null) || { echo nodaemon; exit 0; }
echo ok
j() { r=$(busctl --user -j "$@" 2>/dev/null) && printf '%s' "$r" | jq -c '.data | if type == "array" then .[0] else . end' || echo null; }
for id in $(printf '%s' "$ids" | jq -r '.data[0][]'); do
  p=/modules/kdeconnect/devices/$id
  printf '{"id":"%s","name":%s,"type":%s,"reachable":%s,"paired":%s,"requested":%s,"charge":%s,"charging":%s,"clipboard":%s,"notifications":%s,"remote":%s}\\n' "$id" \\
    "$(j get-property $k $p $k.device name)" "$(j get-property $k $p $k.device type)" "$(j get-property $k $p $k.device isReachable)" \\
    "$(j get-property $k $p $k.device isPaired)" "$(j get-property $k $p $k.device isPairRequested)" \\
    "$(j get-property $k $p/battery $k.device.battery charge)" "$(j get-property $k $p/battery $k.device.battery isCharging)" \\
    "$(j call $k $p $k.device isPluginEnabled s kdeconnect_clipboard)" "$(j call $k $p $k.device isPluginEnabled s kdeconnect_notifications)" \\
    "$(j call $k $p $k.device isPluginEnabled s kdeconnect_mpriscontrol)"
done`]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    function parse(text) {
        const lines = text.trim().split("\n")
        installed = lines[0] !== "missing"
        daemon = lines[0] === "ok"
        const out = []
        for (const l of lines.slice(1)) {
            let d; try { d = JSON.parse(l) } catch (e) { continue }
            if (!/^[A-Za-z0-9_-]{1,80}$/.test(d.id)) continue   // ids go to kdeconnect-cli and D-Bus paths
            out.push({ id: d.id, name: typeof d.name === "string" && d.name ? d.name : "Phone", type: d.type ?? "phone",
                       reachable: d.reachable === true, paired: d.paired === true, requested: d.requested === true,
                       charge: typeof d.charge === "number" ? d.charge : -1, charging: d.charging === true,
                       clipboard: d.clipboard !== false, notifications: d.notifications !== false, remote: d.remote !== false })
        }
        devices = out
        if (installed && !daemon && !read) start()   // first read and no daemon: start it once
        read = true
    }
    Timer { id: later; interval: 1500; onTriggered: root.refresh() }
    // fresh every 10 s while something shows the phone, else every minute (battery in the tile, a phone coming home)
    Timer { interval: root.watchers > 0 ? 10000 : 60000; running: root.enabled && root.installed; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }

    Process {
        id: picker
        command: ["zenity", "--file-selection", "--multiple", "--separator=\n", "--title=Send to " + (root.phone?.name ?? "phone"),
                  "--filename=" + Quickshell.env("HOME") + "/"]
        stdout: StdioCollector { onStreamFinished: root.send(text.split("\n").filter(p => p.startsWith("/"))) }
    }
    Process {
        id: sender
        property int count: 0
        property var queue: []
        onExited: code => {
            Notifications.post(code === 0 ? (count === 1 ? "File sent" : count + " files sent") : "Couldn't send",
                                             code === 0 ? "To " + (root.phone?.name ?? "your phone") : "Is " + (root.phone?.name ?? "the phone") + " still nearby?",
                                             code === 0 ? "low" : "normal", "smartphone")
            if (queue.length) { const next = queue[0]; queue = queue.slice(1); Qt.callLater(() => root.send(next)) }
        }
    }

    IpcHandler {
        target: "phone"
        function status(): string { return JSON.stringify({ state: root.state, status: root.status, phone: root.phone }) }
        function ring(): void { root.ring() }
        function pick(): void { root.pick() }
        function send(path: string): void { root.send([path]) }
        function refresh(): void { root.refresh() }
    }
}
