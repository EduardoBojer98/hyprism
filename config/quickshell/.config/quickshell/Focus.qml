pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Focus modes (Config.focus.modes, Settings > Focus): each one can turn on Do Not Disturb with some apps still let
// through, change the wallpaper, open apps, and turn on Night Light or Caffeine. One mode at a time; turning it off
// (or switching) puts back what it changed. Switched from the Control Center's Focus tile, the launcher, a mode's
// schedule (days and times), or `qs ipc call focus set <name|id> | off | toggle | status | list`.
// The bar's bell wears the mode's icon and name while one is on.
Singleton {
    id: root

    readonly property var modes: Array.from(Config.focus.modes ?? [])
    readonly property var mode: modes.find(m => m.id === Config.focus.active) ?? null
    readonly property bool dnd: mode?.dnd ?? false
    // a notification's app gets through this mode's Do Not Disturb
    function allows(app) { return !mode || (mode.allow ?? []).some(a => a.toLowerCase() === String(app).toLowerCase()) }
    function find(key) { const k = String(key).toLowerCase(); return modes.find(m => m.id === k || m.name.toLowerCase() === k) ?? null }

    // Switch: "" turns Focus off. What the old mode changed is put back first (restore), then the new one applies
    // and notes what to put back later (in settings.json, so a restart in between still restores).
    function set(id, bySchedule) {
        const next = modes.find(m => m.id === id) ?? null
        if ((next?.id ?? "") === Config.focus.active) return
        restore()
        Config.set("focus", "auto", bySchedule === true)
        Config.set("focus", "active", next?.id ?? "")
        if (!next) return
        Config.set("focus", "last", next.id)
        const back = {}
        if (next.wallpaper && next.wallpaper !== Wallpapers.current) { back.wallpaper = Wallpapers.current; Wallpapers.apply(next.wallpaper) }
        if (next.nightLight && !NightLight.active) { back.nightLight = Config.nightLight.mode; Config.set("nightLight", "mode", "on") }
        if (next.caffeine && !Caffeine.active) { back.caffeine = true; Caffeine.start(0) }
        Config.set("focus", "restore", back)
        for (const a of next.apps ?? []) {
            const e = DesktopEntries.byId(a) ?? DesktopEntries.heuristicLookup(a)
            if (e) e.execute()
        }
    }
    function restore() {
        const back = Config.focus.restore ?? {}
        if (back.wallpaper) Wallpapers.apply(back.wallpaper)
        if (back.nightLight) Config.set("nightLight", "mode", back.nightLight)
        if (back.caffeine && Caffeine.active) Caffeine.stop()
        Config.set("focus", "restore", {})
    }
    function off() { set("") }
    // the tile's click: off when anything is on (a mode or plain Do Not Disturb), else the last mode (or plain DND)
    function toggle() {
        if (mode) off()
        else if (Notifications.dnd) Notifications.toggleDnd()
        else if (find(Config.focus.last)) set(Config.focus.last)
        else Notifications.toggleDnd()
    }

    // ---- schedules: a mode's window (days, from-to; across midnight it belongs to the day it starts) ----
    property date now: new Date()
    function minutes(hhmm) { const p = String(hhmm).split(":"); return Number(p[0]) * 60 + Number(p[1]) }
    function inWindow(s, d) {
        if (!s?.on) return false
        const t = d.getHours() * 60 + d.getMinutes(), a = minutes(s.from), b = minutes(s.to), day = d.getDay(), days = Array.from(s.days ?? [])
        if (a === b) return false
        return a < b ? days.includes(day) && t >= a && t < b
                     : (days.includes(day) && t >= a) || (days.includes((day + 6) % 7) && t < b)
    }
    readonly property string scheduled: modes.find(m => inWindow(m.schedule, now))?.id ?? ""
    // only the edges act: a mode you turned off inside its window stays off until the next window
    // shortcut: a shell restart inside a window counts as an edge and turns the mode back on; fine unless that bites.
    onScheduledChanged: if (Config.loaded) apply()
    function apply() {
        if (scheduled) set(scheduled, true)
        else if (Config.focus.auto) off()
    }
    Connections { target: Config; function onLoadedChanged() { if (Config.loaded) Qt.callLater(root.apply) } }
    Timer { interval: 20000; running: true; repeat: true; onTriggered: root.now = new Date() }
    // next start or end of a schedule, for the Control Center and Settings: "Until 17:00" / "From Mon 09:00"
    function about(m) {
        const s = m?.schedule
        if (!s?.on || !(s.days ?? []).length) return ""
        const names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], days = Array.from(s.days)
        const when = days.length === 7 ? "Every day" : [1, 2, 3, 4, 5].every(d => days.includes(d)) && days.length === 5 ? "Weekdays"
                  : days.length === 2 && days.includes(0) && days.includes(6) ? "Weekends" : [1, 2, 3, 4, 5, 6, 0].filter(d => days.includes(d)).map(d => names[d]).join(" ")
        return when + " " + s.from + "–" + s.to
    }
    // what a mode does, in a few words: "Lets Slack and 2 more through · Caffeine"
    function summary(m) {
        const allow = Array.from(m?.allow ?? [])
        const out = [!m?.dnd ? "Notifications as usual" : allow.length ? "Lets " + allow[0] + (allow.length > 1 ? " and " + (allow.length - 1) + " more" : "") + " through" : "Silences notifications"]
        if (m?.nightLight) out.push("Night Light")
        if (m?.caffeine) out.push("Caffeine")
        if (m?.wallpaper) out.push("Wallpaper")
        if ((m?.apps ?? []).length) out.push("Opens " + m.apps.length + (m.apps.length === 1 ? " app" : " apps"))
        return out.join(" · ")
    }
    readonly property string status: mode ? (Config.focus.auto && mode.schedule?.on ? mode.name + " until " + mode.schedule.to : mode.name)
                                          : Notifications.dnd ? "Do Not Disturb" : "Off"

    // ---- editing (Settings > Focus) ----
    function save(list) { return Config.set("focus", "modes", JSON.parse(JSON.stringify(list))) }
    function update(id, changes) { return save(modes.map(m => m.id === id ? Object.assign({}, m, changes) : m)) }
    function add() {
        let n = 1
        while (modes.some(m => m.id === "mode-" + n)) n++
        save(modes.concat([{ id: "mode-" + n, name: "New mode", icon: "\u{F0594}", dnd: true, allow: [], wallpaper: "", apps: [],
                             nightLight: false, caffeine: false, schedule: { on: false, days: [1, 2, 3, 4, 5], from: "09:00", to: "17:00" } }]))
        return "mode-" + n
    }
    function remove(id) {
        if (Config.focus.active === id) off()
        save(modes.filter(m => m.id !== id))
    }
    // moon, briefcase, phone, laptop, pencil, school, headphones, music, dumbbell, meditation, bed, home, video, leaf
    readonly property var icons: ["\u{F0594}", "\u{F00D6}", "\u{F03F2}", "\u{F0322}", "\u{F03EB}", "\u{F0474}", "\u{F02CB}", "\u{F075A}",
                                  "\u{F01E6}", "\u{F117B}", "\u{F02E3}", "\u{F02DC}", "\u{F0567}", "\u{F032A}"]

    IpcHandler {
        target: "focus"
        function set(name: string): string { const m = root.find(name); if (!m) return "No mode called " + name; root.set(m.id); return "" }
        function off(): void { root.off() }
        function toggle(): void { root.toggle() }
        function status(): string { return root.status }
        function list(): string { return root.modes.map(m => m.id + "\t" + m.name).join("\n") }
    }
}
