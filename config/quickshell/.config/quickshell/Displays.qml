pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// The screens: what is connected, the layout being edited, applying it, and the keep-or-revert countdown.
// Settings > Displays is a view of this. Apply saves the layout in settings.json (displays.layout);
// SettingsSync.qml writes hypr/settings/displays.lua and applies it live. Unless you keep it, the old layout
// comes back after 15 s. Hyprland's monitor events refresh it, so a plugged or unplugged screen shows at once.
Singleton {
    id: root

    property var monitors: []      // from hyprctl -j monitors all, each with .key (what the layout is saved under)
    property var edits: ({})       // key -> { mode, x, y, scale, transform, vrr, bitdepth, mirror, disabled }
    property var saved: ({})       // edits as last loaded, for Revert and the keep-or-revert countdown
    property var previous: null    // what to go back to while the countdown runs
    property bool dirty: false
    property string notice: ""     // one line for the page: a screen left or arrived while you had unsaved edits
    readonly property bool counting: countdown.running
    property alias left: countdown.left

    // What a screen is saved under: its description (make model serial), which follows the screen to any port, or
    // its connector name when it has none or another connected screen has the same one (two identical monitors)
    function keyOf(m, list) { return m.description && !list.some(o => o !== m && o.description === m.description) ? m.description : m.name }
    function keyForName(name) {
        const list = Hyprland.monitors.values, m = list.find(x => x.name === name)
        return m ? keyOf(m, list) : name
    }
    // does a saved key (description or connector name) mean this screen? Takes a HyprlandMonitor or a ShellScreen.
    function matches(key, screen) {
        const d = screen.description ?? Hyprland.monitors.values.find(x => x.name === screen.name)?.description ?? ""
        return key === screen.name || (d !== "" && key === d)
    }
    function label(m) { return m.name.startsWith("eDP") ? "Laptop" : (m.make || m.name).split(" ")[0] }
    function monitorOf(key) { return monitors.find(m => m.key === key) ?? null }
    function load() { read.running = true }
    Component.onCompleted: load()

    // A screen leaving or arriving: refresh Hyprland's list for the bar and dock, and ours for the editor
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["monitoraddedv2", "monitorremovedv2", "configreloaded"].includes(event.name)) refresh.restart()
        }
    }
    Timer { id: refresh; interval: 300; onTriggered: { Hyprland.refreshMonitors(); root.load() } }   // one refresh per burst of events

    Process {
        id: read
        // Hyprland reports the live state; adaptive sync's mode (on / fullscreen) only lives in the saved layout
        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = JSON.parse(text).filter(m => Machine.realScreen(m.name))
                const e = {}
                for (const m of list) {
                    m.key = root.keyOf(m, list)
                    // a screen that's off may report 0x0: its first (preferred) mode then
                    const first = (m.availableModes?.[0] ?? "1920x1080@60").split("@")
                    e[m.key] = { mode: m.width ? m.width + "x" + m.height + "@" + Math.round(m.refreshRate) : first[0] + "@" + Math.round(parseFloat(first[1])), x: m.x, y: m.y,
                                 scale: m.scale, transform: m.transform, vrr: Number(Config.displays.layout[m.key]?.vrr ?? 0),
                                 bitdepth: /2101010/.test(m.currentFormat) ? 10 : 8,
                                 mirror: m.mirrorOf && m.mirrorOf !== "none" ? m.mirrorOf : "", disabled: m.disabled === true }
                }
                // unsaved edits survive a screen coming or going, minus the ones for screens that left
                let next = e
                if (root.dirty) {
                    const gone = Object.keys(root.edits).filter(k => !e[k]), came = Object.keys(e).filter(k => !root.edits[k])
                    next = Object.assign({}, e)
                    for (const k of Object.keys(root.edits)) if (e[k]) next[k] = root.edits[k]
                    if (gone.length || came.length) {
                        const name = k => { const m = root.monitorOf(k) ?? list.find(x => x.key === k); return m ? root.label(m) : k }
                        root.notice = gone.length ? `${gone.map(name).join(", ")} left: its changes were dropped` : `${came.map(name).join(", ")} arrived`
                    }
                } else root.notice = ""
                root.monitors = list
                root.edits = next
                root.saved = e
            }
        }
    }

    function logicalSize(key) {
        const e = edits[key]
        if (!e) return { w: 0, h: 0 }
        const [w, h] = e.mode.split("@")[0].split("x").map(Number)
        const rotated = e.transform % 2 === 1
        return { w: Math.round((rotated ? h : w) / e.scale), h: Math.round((rotated ? w : h) / e.scale) }
    }

    function set(key, field, value) {
        const e = Object.assign({}, edits)
        e[key] = Object.assign({}, e[key], { [field]: value })
        edits = e
        dirty = true
    }
    function discard() { dirty = false; load() }

    // "" when the edited layout is fine, else why it can't be applied
    function problem() {
        const names = Object.keys(edits), shown = names.filter(n => !edits[n].disabled && !edits[n].mirror)
        if (names.length && !names.some(n => !edits[n].disabled)) return "Keep at least one screen on"
        for (const a of shown) for (const b of shown) {
            if (a >= b) continue
            const ea = edits[a], eb = edits[b], sa = logicalSize(a), sb = logicalSize(b)
            if (ea.x < eb.x + sb.w && eb.x < ea.x + sa.w && ea.y < eb.y + sb.h && eb.y < ea.y + sa.h)
                return `${label(monitorOf(a) ?? { name: a })} and ${label(monitorOf(b) ?? { name: b })} overlap: drag one clear of the other`
        }
        return ""
    }

    // Returns "" when applied, or why it was refused
    function apply(confirm) {
        const why = problem()
        if (why) { notice = why; return why }
        // Normalise so the top-left screen sits at 0,0
        const names = Object.keys(edits)
        const shown = names.filter(n => !edits[n].disabled && !edits[n].mirror)
        const minX = Math.min(...shown.map(n => edits[n].x)), minY = Math.min(...shown.map(n => edits[n].y))
        const out = {}
        for (const n of names) {
            const e = edits[n]
            if (e.disabled) { out[n] = { disabled: true }; continue }
            out[n] = { mode: e.mode, position: (e.x - minX) + "x" + (e.y - minY), scale: e.scale, transform: e.transform }
            if (e.vrr) out[n].vrr = e.vrr
            if (e.bitdepth === 10) out[n].bitdepth = 10
            if (e.mirror) out[n].mirror = e.mirror
        }
        if (confirm) { previous = saved; countdown.left = 15; countdown.start() }
        notice = ""
        dirty = false
        Config.set("displays", "layout", out)   // SettingsSync writes displays.lua and applies it
        reloadTimer.restart()
        return ""
    }
    Timer { id: reloadTimer; interval: 800; onTriggered: root.load() }

    // One switch for every screen, like a projector key: extend the desktop, mirror one picture, or one screen only
    readonly property string arrangement: {
        const names = Object.keys(edits), on = names.filter(n => !edits[n].disabled)
        if (on.length === 1 && names.length > 1) return "only:" + on[0]
        return on.some(n => edits[n].mirror) ? "mirror" : "extend"
    }
    function arrange(how) {
        const names = Object.keys(edits), e = {}
        // the picture to mirror or the screen kept on: the laptop panel when there is one, else the first screen
        const main = names.find(n => monitorOf(n)?.name.startsWith("eDP")) ?? names[0]
        let x = 0
        for (const n of names.slice().sort((a, b) => (a === main ? -1 : b === main ? 1 : 0))) {
            const one = Object.assign({}, edits[n], { disabled: false, mirror: "" })
            if (how === "mirror" && n !== main) one.mirror = main
            if (how.startsWith("only:")) one.disabled = n !== how.slice(5)
            if (how === "extend") { one.x = x; one.y = 0; x += logicalSize(n).w }   // side by side, main screen first
            e[n] = one
        }
        edits = e
        return apply(true)
    }
    function keep() { countdown.stop(); previous = null }
    function revert() { countdown.stop(); edits = previous; previous = null; apply(false) }
    Timer {
        id: countdown
        property int left: 15
        interval: 1000; repeat: true
        onTriggered: if (--left <= 0) root.revert()
    }
}
