pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// System readings for the bar (the system-info item) and anything else that wants them.
// One `metrics watch` process (~/.local/bin/metrics) feeds every reader, and it only runs while somebody
// visible has asked for something (want / unwant), so nothing is measured for a hidden bar.
//
// Adding a reading: one entry in `registry` below (and, if the numbers aren't measured yet, one m_<name>
// function in the metrics script). Each entry:
//   from      the script metric it comes from        name / word / glyph   how it is labelled
//   value     d => a number (for thresholds, "only above" and the sparkline), or undefined when this computer
//             doesn't have it (the reading is then skipped everywhere)
//   text      d => the short reading ("45%")         detail   d => one longer line for the tooltip (optional)
//   warn / critical   default levels (your settings can replace them)
Singleton {
    id: root

    property var data: ({})          // the latest line from the script
    property var history: ({})       // registry id -> its last numbers, oldest first
    readonly property int keep: 24   // how many the sparkline shows
    property int interval: 2         // seconds between readings (the fastest any reader asked for)

    // --- who is reading: registry ids, counted, so two bars asking for cpu still mean one measurement
    property var wanted: ({})
    function want(ids, seconds) {
        const w = Object.assign({}, wanted)
        for (const id of ids) if (registry[id]) w[id] = (w[id] ?? 0) + 1
        wanted = w
        if (seconds >= 1) interval = Math.min(interval, Math.round(seconds))
    }
    function unwant(ids) {
        const w = Object.assign({}, wanted)
        for (const id of ids) if (w[id]) { w[id]--; if (w[id] <= 0) delete w[id] }
        wanted = w
    }
    readonly property var sources: Array.from(new Set(Object.keys(wanted).map(id => registry[id].from))).sort()
    readonly property string sourceList: sources.join(",")
    onSourceListChanged: restart.restart()
    onIntervalChanged: restart.restart()
    // a changed list needs a new process; wait a moment so several changes become one restart
    Timer { id: restart; interval: 150; onTriggered: { reader.running = false; reader.running = root.sourceList !== "" } }
    Process {
        id: reader
        command: ["metrics", "watch", root.sourceList, String(root.interval)]
        stdout: SplitParser {
            onRead: line => {
                let d
                try { d = JSON.parse(line) } catch (e) { return }
                root.data = d
                const h = Object.assign({}, root.history)
                for (const id of Object.keys(root.wanted)) {
                    const v = root.registry[id].value(d)
                    if (typeof v !== "number") continue
                    h[id] = (h[id] ?? []).concat([v]).slice(-root.keep)
                }
                root.history = h
            }
        }
    }

    // --- reading them
    function has(id) { return registry[id] !== undefined && typeof registry[id].value(data) === "number" }
    function value(id) { return has(id) ? registry[id].value(data) : -1 }
    function text(id) { return has(id) ? registry[id].text(data) : "" }
    function detail(id) { return !has(id) ? "" : registry[id].detail ? registry[id].detail(data) : registry[id].name + "  " + registry[id].text(data) }
    // the last readings as a row of bars, lowest to highest of what was seen
    function spark(id) {
        const h = history[id] ?? []
        if (h.length < 2) return ""
        const top = Math.max(...h, registry[id].top ?? 0, 1)
        return h.map(v => "▁▂▃▄▅▆▇█"[Math.max(0, Math.min(7, Math.floor(v / top * 7.99)))]).join("")
    }
    readonly property var ids: Object.keys(registry)

    // --- small formatters
    function bytes(n) { return n >= 1e9 ? (n / 1e9).toFixed(1) + "G" : n >= 1e6 ? (n / 1e6).toFixed(1) + "M" : n >= 1e3 ? Math.round(n / 1e3) + "K" : Math.round(n) + "B" }
    function span(minutes) { return minutes >= 60 ? Math.floor(minutes / 60) + "h " + String(Math.round(minutes % 60)).padStart(2, "0") + "m" : Math.round(minutes) + "m" }
    function days(seconds) { const d = Math.floor(seconds / 86400), h = Math.floor(seconds % 86400 / 3600), m = Math.floor(seconds % 3600 / 60); return d > 0 ? d + "d " + h + "h" : h > 0 ? h + "h " + m + "m" : m + "m" }
    function card(g, label) {   // one line about a graphics card, with whatever it reports
        const parts = []
        if (g.pct !== undefined) parts.push(g.pct + "%")
        if (g.temp !== undefined) parts.push(Math.round(g.temp) + "°")
        if (g.vram_total) parts.push((g.vram_used / 1024).toFixed(1) + "/" + (g.vram_total / 1024).toFixed(1) + "G")
        if (g.watts !== undefined) parts.push(g.watts.toFixed(1) + "W")
        return label + "  " + (parts.length ? parts.join("  ") : g.state ?? "")
    }

    readonly property var registry: ({
        cpu:       { from: "cpu", name: "CPU load", word: "cpu", glyph: "\u{F0EE0}", top: 100, warn: 85, critical: 95,
                     value: d => d.cpu?.pct, text: d => d.cpu.pct + "%",
                     detail: d => "CPU  " + d.cpu.pct + "%   cores " + d.cpu.cores.map(c => "▁▂▃▄▅▆▇█"[Math.min(7, Math.floor(c / 12.6))]).join("") },
        cpu_temp:  { from: "cpu_temp", name: "CPU temperature", word: "temp", glyph: "\u{F050F}", top: 100, warn: 85, critical: 95,
                     value: d => d.cpu_temp, text: d => Math.round(d.cpu_temp) + "°" },
        cpu_freq:  { from: "cpu_freq", name: "CPU frequency", word: "freq", glyph: "\u{F04C5}",
                     value: d => d.cpu_freq, text: d => (d.cpu_freq / 1000).toFixed(1) + "GHz" },
        gpu:       { from: "gpu", name: "Graphics load", word: "gpu", glyph: "\u{F08AE}", top: 100, warn: 85, critical: 95,
                     value: d => d.gpu?.pct, text: d => d.gpu.pct + "%", detail: d => root.card(d.gpu, "GPU") },
        gpu_temp:  { from: "gpu", name: "Graphics temperature", word: "gpu", glyph: "\u{F050F}", top: 100, warn: 85, critical: 95,
                     value: d => d.gpu?.temp, text: d => Math.round(d.gpu.temp) + "°" },
        gpu_vram:  { from: "gpu", name: "Graphics memory", word: "vram", glyph: "\u{F08AE}", top: 100, warn: 90, critical: 97,
                     value: d => d.gpu?.vram_total ? Math.round(100 * d.gpu.vram_used / d.gpu.vram_total) : undefined,
                     text: d => (d.gpu.vram_used / 1024).toFixed(1) + "G" },
        gpu_power: { from: "gpu", name: "Graphics power", word: "gpu", glyph: "\u{F0E0E}",
                     value: d => d.gpu?.watts, text: d => d.gpu.watts.toFixed(1) + "W" },
        // the second card: asleep it shows "off"; its numbers appear only while something is using it
        dgpu:      { from: "dgpu", name: "Second graphics card", word: "dgpu", glyph: "\u{F08AE}", top: 100, warn: 85, critical: 95,
                     value: d => d.dgpu ? (d.dgpu.pct ?? 0) : undefined,
                     text: d => d.dgpu.pct !== undefined ? d.dgpu.pct + "%" : d.dgpu.state === "suspended" ? "off" : d.dgpu.state,
                     detail: d => root.card(d.dgpu, "Second GPU") + (d.dgpu.state === "suspended" ? " (powered off)" : "") },
        dgpu_temp: { from: "dgpu", name: "Second card temperature", word: "dgpu", glyph: "\u{F050F}", top: 100, warn: 85, critical: 95,
                     value: d => d.dgpu?.temp, text: d => Math.round(d.dgpu.temp) + "°" },
        dgpu_vram: { from: "dgpu", name: "Second card memory", word: "vram", glyph: "\u{F08AE}", top: 100, warn: 90, critical: 97,
                     value: d => d.dgpu?.vram_total ? Math.round(100 * d.dgpu.vram_used / d.dgpu.vram_total) : undefined,
                     text: d => (d.dgpu.vram_used / 1024).toFixed(1) + "G" },
        dgpu_power: { from: "dgpu", name: "Second card power", word: "dgpu", glyph: "\u{F0E0E}",
                     value: d => d.dgpu?.watts, text: d => Number(d.dgpu.watts).toFixed(1) + "W" },
        ram:       { from: "ram", name: "Memory", word: "mem", glyph: "\u{F035B}", top: 100, warn: 85, critical: 95,
                     value: d => d.ram?.pct, text: d => (d.ram.used / 1024).toFixed(1) + "G",
                     detail: d => "Memory  " + (d.ram.used / 1024).toFixed(1) + " of " + (d.ram.total / 1024).toFixed(1) + " GB  (" + d.ram.pct + "%)" },
        swap:      { from: "swap", name: "Swap", word: "swap", glyph: "\u{F04E1}", top: 100, warn: 50, critical: 80,
                     value: d => d.swap?.pct, text: d => d.swap.pct + "%",
                     detail: d => "Swap  " + (d.swap.used / 1024).toFixed(1) + " of " + (d.swap.total / 1024).toFixed(1) + " GB" },
        // the fullest disk decides the reading; the tooltip lists every one
        disk:      { from: "disk", name: "Disk space", word: "disk", glyph: "\u{F02CA}", top: 100, warn: 85, critical: 95,
                     value: d => d.disk?.length ? Math.max(...d.disk.map(m => m.pct)) : undefined,
                     text: d => Math.max(...d.disk.map(m => m.pct)) + "%",
                     detail: d => d.disk.map(m => m.mount + "  " + m.used.toFixed(0) + " of " + m.total.toFixed(0) + " GB (" + m.pct + "%)").join("\n") },
        disk_io:   { from: "diskio", name: "Disk activity", word: "io", glyph: "\u{F02CA}",
                     value: d => d.diskio ? d.diskio.read + d.diskio.write : undefined,
                     text: d => root.bytes(d.diskio.read + d.diskio.write) + "/s",
                     detail: d => "Disk  read " + root.bytes(d.diskio.read) + "/s  write " + root.bytes(d.diskio.write) + "/s" },
        net_down:  { from: "net", name: "Download speed", word: "down", glyph: "\u{F01DA}",
                     value: d => d.net?.down, text: d => root.bytes(d.net.down) + "/s" },
        net_up:    { from: "net", name: "Upload speed", word: "up", glyph: "\u{F0552}",
                     value: d => d.net?.up, text: d => root.bytes(d.net.up) + "/s" },
        net:       { from: "net", name: "Network", word: "net", glyph: "\u{F05A9}",
                     value: d => d.net ? d.net.down + d.net.up : undefined,
                     text: d => "↓" + root.bytes(d.net.down) + " ↑" + root.bytes(d.net.up),
                     detail: d => "Network  " + (d.net.iface || "no route") + (Sys.netName ? " (" + Sys.netName + ")" : "") + "  ↓ " + root.bytes(d.net.down) + "/s  ↑ " + root.bytes(d.net.up) + "/s" },
        battery:   { from: "battery", name: "Battery", word: "bat", glyph: "\u{F0079}", top: 100,
                     value: d => d.battery?.pct, text: d => d.battery.pct + "%",
                     detail: d => "Battery  " + d.battery.pct + "%  " + d.battery.state + (d.battery.watts > 0 ? "  " + d.battery.watts.toFixed(1) + " W" : "")
                                  + (d.battery.minutes !== undefined ? "  " + root.span(d.battery.minutes) + (d.battery.state === "charging" ? " to full" : " left") : "") },
        battery_power: { from: "battery", name: "Battery power", word: "watts", glyph: "\u{F0E0E}",
                     value: d => d.battery?.watts, text: d => d.battery.watts.toFixed(1) + "W" },
        battery_time: { from: "battery", name: "Battery time", word: "left", glyph: "\u{F0954}",
                     value: d => d.battery?.minutes, text: d => root.span(d.battery.minutes) },
        fans:      { from: "fans", name: "Fan speed", word: "fan", glyph: "\u{F0210}",
                     value: d => d.fans?.length ? Math.max(...d.fans) : undefined, text: d => Math.max(...d.fans) + "rpm",
                     detail: d => "Fans  " + d.fans.map(f => f + " rpm").join("  ") },
        profile:   { from: "profile", name: "Power profile", word: "mode", glyph: "\u{F0E0E}",
                     value: d => d.profile === undefined ? undefined : 0, text: d => d.profile },
        uptime:    { from: "uptime", name: "Uptime", word: "up", glyph: "\u{F0954}",
                     value: d => d.uptime, text: d => root.days(d.uptime) },
        load:      { from: "load", name: "Load average", word: "load", glyph: "\u{F04C5}",
                     value: d => d.load?.[0], text: d => d.load[0].toFixed(2),
                     detail: d => "Load  " + d.load.map(l => l.toFixed(2)).join("  ") + "  (1, 5, 15 minutes)" }
    })
}
