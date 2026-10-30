pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Night Light: warms the screens with hyprsunset. Config.nightLight.mode:
//   off · on · schedule (from → to) · sun (sunset → sunrise at the weather location)
// hyprsunset runs as a child that also waits on Quickshell's PID, so the colours go back to
// normal when it's turned off or if qs exits.  qs ipc call nightlight toggle | status
Singleton {
    id: root

    readonly property var cfg: Config.nightLight
    property date now: new Date()
    readonly property var sun: sunTimes(now, Config.weather.latitude, Config.weather.longitude)
    readonly property bool active: {
        const m = now.getHours() * 60 + now.getMinutes()
        switch (cfg.mode) {
        case "on": return true
        case "schedule": return within(m, minutes(cfg.from), minutes(cfg.to))
        case "sun": return sun !== null && within(m, sun.set, sun.rise)
        default: return false
        }
    }

    function minutes(hhmm) { const p = String(hhmm).split(":"); return parseInt(p[0]) * 60 + parseInt(p[1]) }
    function within(m, from, to) { return from <= to ? m >= from && m < to : m >= from || m < to }   // wraps midnight
    function clock(m) { return `${String(Math.floor(m / 60) % 24).padStart(2, "0")}:${String(Math.round(m) % 60).padStart(2, "0")}` }

    // Sunrise/sunset in local minutes after midnight (NOAA approximation, ±2 min). null at the poles.
    function sunTimes(date, lat, lon) {
        const rad = Math.PI / 180
        const start = new Date(date.getFullYear(), 0, 0)
        const day = Math.floor((date - start) / 86400000)
        const g = 2 * Math.PI / 365 * (day - 1)
        const eqtime = 229.18 * (0.000075 + 0.001868 * Math.cos(g) - 0.032077 * Math.sin(g) - 0.014615 * Math.cos(2 * g) - 0.040849 * Math.sin(2 * g))
        const decl = 0.006918 - 0.399912 * Math.cos(g) + 0.070257 * Math.sin(g) - 0.006758 * Math.cos(2 * g) + 0.000907 * Math.sin(2 * g) - 0.002697 * Math.cos(3 * g) + 0.00148 * Math.sin(3 * g)
        const cosH = Math.cos(90.833 * rad) / (Math.cos(lat * rad) * Math.cos(decl)) - Math.tan(lat * rad) * Math.tan(decl)
        if (cosH < -1 || cosH > 1) return null
        const ha = Math.acos(cosH) / rad
        const tz = -date.getTimezoneOffset()
        return { rise: 720 - 4 * (lon + ha) - eqtime + tz, set: 720 - 4 * (lon - ha) - eqtime + tz }
    }

    function toggle() { Config.set("nightLight", "mode", active ? "off" : "on") }

    Process {
        id: sunset
        property bool pause: false
        running: root.active && !pause
        command: ["sh", "-c", "hyprsunset -t \"$1\" & p=$!; tail --pid=$PPID -f /dev/null & t=$!; "
                            + "trap 'kill $p $t 2>/dev/null' TERM INT; wait -n $p $t; kill $p $t 2>/dev/null", "sh",
                  String(root.cfg.temperature)]
    }
    // Restart with the new warmth when the slider moves (debounced)
    Connections {
        target: root.cfg
        function onTemperatureChanged() { if (root.active) { sunset.pause = true; resume.restart() } }
    }
    Timer { id: resume; interval: 300; onTriggered: sunset.pause = false }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = new Date() }

    IpcHandler {
        target: "nightlight"
        function toggle(): void { root.toggle() }
        function status(): string {
            return `${root.active ? "on" : "off"} (mode ${root.cfg.mode}, ${root.cfg.temperature} K`
                 + (root.sun ? `, sunset ${root.clock(root.sun.set)}, sunrise ${root.clock(root.sun.rise)})` : ")")
        }
    }
}
