pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Numbers for the menu bar's CPU, memory and network speed items, read every two seconds while
// a bar shows them (Console's readout).
Singleton {
    id: root

    property real cpu: 0          // 0..1
    property real memUsed: 0      // GiB
    property real memTotal: 0
    property real down: 0         // bytes per second, all interfaces but loopback
    property real up: 0
    property var last: null       // previous { idle, all, rx, tx, t }

    // "1.2 MB/s", "340 KB/s"
    function speed(b) { return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : Math.round(b / 1024) + " KB/s" }

    Process {
        id: read
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; tail -n +3 /proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                let idle = 0, all = 0, rx = 0, tx = 0
                for (const line of text.trim().split("\n")) {
                    const p = line.trim().split(/[\s:]+/)
                    if (p[0] === "cpu") { const t = p.slice(1).map(Number); idle = t[3] + t[4]; all = t.reduce((a, b) => a + b, 0) }
                    else if (p[0] === "MemTotal") root.memTotal = p[1] / 1048576
                    else if (p[0] === "MemAvailable") root.memUsed = root.memTotal - p[1] / 1048576
                    // virtual links (loopback, containers, bridges, VPNs) repeat traffic already counted
                    else if (!/^(lo|docker|br-|veth|virbr|tun|tap|wg)/.test(p[0]) && p.length > 9) { rx += Number(p[1]); tx += Number(p[9]) }
                }
                const t = Date.now(), l = root.last
                if (l) {
                    const s = Math.max(0.001, (t - l.t) / 1000)
                    root.cpu = Math.max(0, Math.min(1, 1 - (idle - l.idle) / Math.max(1, all - l.all)))
                    root.down = Math.max(0, (rx - l.rx) / s)
                    root.up = Math.max(0, (tx - l.tx) / s)
                }
                root.last = { idle, all, rx, tx, t }
            }
        }
    }
    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: Theme.bar.kind === "readout"   // Console's readout shows CPU and memory
        onTriggered: read.running = true
    }
}
