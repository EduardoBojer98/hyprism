pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
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
    property var knownSet: null     // the connected screens as of the last load, to notice a change

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
    function isInternal(key) { return /^(eDP|LVDS|DSI)/.test(monitorOf(key)?.name ?? "") }   // the laptop's own panel
    function label(m) { return m.name.startsWith("eDP") ? "Laptop" : (m.make || m.name).split(" ")[0] }
    function monitorOf(key) { return monitors.find(m => m.key === key) ?? null }
    function load() { read.running = true }

    // The main screen (Config.displays.main): notifications, the OSD and toasts show there, workspace 1 and the
    // pointer start there. Unset or unplugged: popups follow the screen you are working on.
    readonly property var mainScreen: Config.displays.main ? Quickshell.screens.find(s => matches(Config.displays.main, s)) ?? null : null
    readonly property var popupScreen: mainScreen ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
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
                const set = list.map(m => m.key).sort().join("\n")
                if (root.knownSet !== null && set !== root.knownSet) settle.restart()   // a screen came or went
                root.knownSet = set
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

    // Screens that don't touch leave a gap the pointer can't cross. "" when every shown screen joins the others
    // edge to edge, else which screens are cut off (a warning: Apply still works, Snap together fixes it)
    function rectOf(n) { const s = logicalSize(n); return { x: edits[n].x, y: edits[n].y, w: s.w, h: s.h } }
    function touching(a, b) {
        const across = a.y < b.y + b.h && b.y < a.y + a.h, along = a.x < b.x + b.w && b.x < a.x + a.w
        return (across && (a.x + a.w === b.x || b.x + b.w === a.x)) || (along && (a.y + a.h === b.y || b.y + b.h === a.y))
    }
    function joined() {   // the screens reachable edge to edge from the main one (or the first)
        const shown = Object.keys(edits).filter(n => !edits[n].disabled && !edits[n].mirror)
        if (!shown.length) return { shown: shown, reach: [] }
        const reach = [shown.includes(Config.displays.main) ? Config.displays.main : shown[0]]
        for (let i = 0; i < reach.length; i++)
            for (const n of shown) if (!reach.includes(n) && touching(rectOf(reach[i]), rectOf(n))) reach.push(n)
        return { shown: shown, reach: reach }
    }
    function gap() {
        const j = joined(), apart = j.shown.filter(n => !j.reach.includes(n))
        if (!apart.length || problem()) return ""
        const name = n => label(monitorOf(n) ?? { name: n })
        if (j.shown.length === 2) return `${name(j.shown[0])} and ${name(j.shown[1])} don't touch: the pointer can't cross the gap`
        return `${apart.map(name).join(" and ")} ${apart.length > 1 ? "don't" : "doesn't"} touch the other screens: the pointer can't cross the gap`
    }
    // move each cut-off screen to the nearest free edge of the joined ones, nearest first
    function snapTogether() {
        const j = joined(), reach = j.reach, e = Object.assign({}, edits)
        let apart = j.shown.filter(n => !reach.includes(n))
        const R = n => { const s = logicalSize(n); return { x: e[n].x, y: e[n].y, w: s.w, h: s.h } }
        const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v))
        while (apart.length) {
            let best = null
            for (const n of apart) {
                const o = R(n)
                for (const c of reach.map(R)) {
                    // keep at least a good stretch of shared edge, so the pointer crosses easily
                    const ky = Math.min(200, o.h, c.h), kx = Math.min(200, o.w, c.w)
                    const y = clamp(o.y, c.y - o.h + ky, c.y + c.h - ky), x = clamp(o.x, c.x - o.w + kx, c.x + c.w - kx)
                    for (const p of [{ x: c.x + c.w, y: y }, { x: c.x - o.w, y: y }, { x: x, y: c.y + c.h }, { x: x, y: c.y - o.h }]) {
                        const r = { x: p.x, y: p.y, w: o.w, h: o.h }
                        if (reach.some(m => { const q = R(m); return r.x < q.x + q.w && q.x < r.x + r.w && r.y < q.y + q.h && q.y < r.y + r.h })) continue
                        const d = Math.hypot(p.x - o.x, p.y - o.y)
                        if (!best || d < best.d) best = { n: n, p: p, d: d }
                    }
                }
            }
            if (!best) break
            e[best.n] = Object.assign({}, e[best.n], { x: best.p.x, y: best.p.y })
            reach.push(best.n)
            apart = apart.filter(n => n !== best.n)
        }
        edits = e
        dirty = true
    }

    // edits -> the saved shape (what settings.json and displays.lua hold)
    function layoutOf(e) {
        // Normalise so the top-left screen sits at 0,0
        const names = Object.keys(e)
        const shown = names.filter(n => !e[n].disabled && !e[n].mirror)
        const minX = Math.min(...shown.map(n => e[n].x)), minY = Math.min(...shown.map(n => e[n].y))
        const out = {}
        for (const n of names) {
            const o = e[n]
            if (o.disabled) { out[n] = { disabled: true }; continue }
            out[n] = { mode: o.mode, position: (o.x - minX) + "x" + (o.y - minY), scale: o.scale, transform: o.transform }
            if (o.vrr) out[n].vrr = o.vrr
            if (o.bitdepth === 10) out[n].bitdepth = 10
            if (o.mirror) out[n].mirror = o.mirror
        }
        return out
    }

    // Returns "" when applied, or why it was refused
    function apply(confirm) {
        const why = problem()
        if (why) { notice = why; return why }
        if (confirm) { previous = saved; countdown.left = 15; countdown.start() }
        notice = ""
        dirty = false
        Config.set("displays", "layout", layoutOf(edits))   // SettingsSync writes displays.lua and applies it
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
        // the picture to mirror or the screen kept on: the main screen, else the laptop panel, else the first screen
        const main = names.includes(Config.displays.main) ? Config.displays.main : names.find(isInternal) ?? names[0]
        let x = 0
        for (const n of names.slice().sort((a, b) => (a === main ? -1 : b === main ? 1 : 0))) {
            if (how === "external" && isInternal(n) && names.length > 1) { e[n] = Object.assign({}, edits[n], { disabled: true, mirror: "" }); continue }
            const one = Object.assign({}, edits[n], { disabled: false, mirror: "" })
            if (how === "mirror" && n !== main) one.mirror = main
            if (how.startsWith("only:")) one.disabled = n !== how.slice(5)
            if (how === "extend" || how === "external") { one.x = x; one.y = 0; x += logicalSize(n).w }   // side by side, main screen first
            e[n] = one
        }
        edits = e
        return apply(true)
    }
    property bool switcherOpen: false
    DisplaySwitcher {}

    // ---- Identify: a big number on each screen for 2 s, in the order of the list on the Settings page ----------
    property bool identifying: false
    function identify() { identifying = true; identifyTimer.restart() }
    function numberOf(name) { return monitors.findIndex(m => m.name === name) + 1 }
    Timer { id: identifyTimer; interval: 2000; onTriggered: root.identifying = false }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            visible: root.identifying
            implicitWidth: 300
            implicitHeight: 300
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.namespace: "qs-display-identify"
            WlrLayershell.layer: WlrLayer.Overlay
            mask: Region {}   // never takes input
            Glass {
                anchors.fill: parent
                strong: true
                radius: Theme.radiusPanel
                Column {
                    anchors.centerIn: parent
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.numberOf(modelData.name); color: Theme.text; font { family: Theme.font; pixelSize: 160; weight: Font.Bold } }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontSize } }
                }
            }
        }
    }

    function keep() { countdown.stop(); previous = null }
    function revert() { countdown.stop(); edits = previous; previous = null; apply(false) }
    Timer {
        id: countdown
        property int left: 15
        interval: 1000; repeat: true
        onTriggered: if (--left <= 0) root.revert()
    }

    // ---- presets: saved layouts (Config.displays.presets) and the built-in ones made from what is connected ------
    readonly property var presets: Array.from(Config.displays.presets ?? [])
    readonly property var connectedKeys: monitors.map(m => m.key)
    readonly property string defaultPreset: Config.displays.defaultPreset
    // the screens a preset turns on that aren't connected now (it can be applied only when there are none)
    function missing(p) { return Object.keys(p.outputs).filter(k => !p.outputs[k].disabled && !connectedKeys.includes(k)) }
    function available(p) { return missing(p).length === 0 }
    // never stored: Extend / Mirror / Laptop only / External only, for the screens plugged in right now
    readonly property var builtInPresets: {
        const n = monitors.length, laptop = monitors.find(m => isInternal(m.key))
        const out = []
        if (n > 1) out.push({ id: "extend", name: "Extend", how: "extend" }, { id: "mirror", name: "Mirror", how: "mirror" })
        if (laptop && n > 1) out.push({ id: "laptop-only", name: "Laptop only", how: "only:" + laptop.key }, { id: "external-only", name: "External only", how: "external" })
        return out.map(p => Object.assign({ builtin: true }, p))
    }

    function savePresets(list) { return Config.set("displays", "presets", list) }
    function slug(name) { return name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 30) || "preset" }
    // the layout on screen now, under a name. Returns "" or why it was refused.
    function saveCurrent(name) {
        name = name.trim()
        if (!name) return "Give the preset a name"
        if (presets.length >= 20) return "Up to 20 presets"
        let id = slug(name), i = 2
        while (presets.some(p => p.id === id)) id = slug(name) + "-" + i++
        return savePresets(presets.concat([{ id: id, name: name.slice(0, 40), auto: false, outputs: layoutOf(saved) }]))
    }
    function rename(id, name) {
        name = name.trim()
        return name ? savePresets(presets.map(p => p.id === id ? Object.assign({}, p, { name: name.slice(0, 40) }) : p)) : "Give the preset a name"
    }
    function remove(id) {
        if (defaultPreset === id) Config.set("displays", "defaultPreset", "")
        return savePresets(presets.filter(p => p.id !== id))
    }
    function setDefault(id) { return Config.set("displays", "defaultPreset", defaultPreset === id ? "" : id) }
    function setAuto(id, on) { return savePresets(presets.map(p => p.id === id ? Object.assign({}, p, { auto: on }) : p)) }

    // A preset's layout as edits for the screens connected now; a connected screen it doesn't mention stays as it is
    function editsOf(p) {
        const e = {}
        for (const k of connectedKeys) {
            const o = p.outputs[k], base = saved[k]
            if (!o) e[k] = base
            else if (o.disabled) e[k] = Object.assign({}, base, { disabled: true })
            else {
                const [x, y] = (o.position ?? "0x0").split("x").map(Number)
                e[k] = { mode: o.mode ?? base.mode, x: x, y: y, scale: o.scale ?? 1, transform: o.transform ?? 0, vrr: o.vrr ?? 0,
                         bitdepth: o.bitdepth ?? 8, mirror: o.mirror ?? "", disabled: false }
            }
        }
        return e
    }
    // Through the same apply as the Apply button, so the keep-or-revert countdown covers it. Returns "" or why not.
    function applyPreset(id, confirm) {
        const p = presets.find(x => x.id === id)
        if (!p) return "No preset " + id
        const gone = missing(p)
        if (gone.length) return "Needs " + gone.map(k => label(monitorOf(k) ?? { name: k })).join(", ")
        edits = editsOf(p)
        return apply(confirm !== false)
    }
    // ---- auto-switch: a preset marked auto applies itself when exactly the screens it names are connected -------
    // Waits a moment for the screens to settle (a dock brings them up one by one). Never touches unsaved edits or a
    // running countdown, and applyPreset refuses a layout with no screen on.
    Timer { id: settle; interval: 1500; onTriggered: root.autoSwitch() }
    function autoSwitch() {
        if (counting || dirty) return
        const now = connectedKeys.slice().sort().join("\n")
        const hits = presets.filter(p => p.auto && Object.keys(p.outputs).sort().join("\n") === now)
        if (hits.length !== 1) return
        const p = hits[0], before = saved
        if (JSON.stringify(layoutOf(editsOf(p))) === JSON.stringify(layoutOf(saved))) return   // already looks like it
        if (applyPreset(p.id, false)) return
        undoTo = before
        toast.show("Switched to " + p.name)
    }
    property var undoTo: null       // the layout the Undo button goes back to
    DisplayToast { id: toast; onUndone: { if (root.undoTo) { root.edits = root.undoTo; root.undoTo = null; root.apply(false) } } }

    // "extend", "mirror", "external", "only:<screen>": from what is live, not from half-made edits
    function applyMode(how) {
        edits = saved
        return arrange(how)
    }
    // a name, id or built-in id from the keyboard or a script; empty = the default preset
    function run(what) {
        what = (what || defaultPreset).trim().toLowerCase()
        if (!what) return "No preset named and no default set"
        const p = presets.find(x => x.id === what || x.name.toLowerCase() === what)
        if (p) return applyPreset(p.id)
        const b = builtInPresets.find(x => x.id === what || x.name.toLowerCase() === what)
        return b ? applyMode(b.how) : "No preset " + what
    }

    // `qs ipc call displays preset <id|name>` · `mode extend|mirror|only:<screen>` · `list` · `identify` · `snap`
    IpcHandler {
        target: "displays"
        function preset(what: string): string { return root.run(what) || "ok" }
        function mode(how: string): string {
            const m = how.startsWith("only:") ? root.monitors.find(x => root.matches(how.slice(5), x)) : null
            if (how.startsWith("only:") && !m) return "No screen " + how.slice(5)
            return root.applyMode(m ? "only:" + m.key : how) || "ok"
        }
        function identify(): void { root.identify() }
        function snap(): string { root.snapTogether(); return root.gap() || "ok" }   // edits only: Apply to use them
        function switcher(): void { root.switcherOpen = !root.switcherOpen }
        function save(name: string): string { return root.saveCurrent(name) || "ok" }
        function list(): string {
            return JSON.stringify({
                screens: root.monitors.map(m => ({ key: m.key, name: m.name, label: root.label(m), mode: root.edits[m.key]?.mode, x: root.edits[m.key]?.x, y: root.edits[m.key]?.y, on: !root.edits[m.key]?.disabled })),
                gap: root.gap(),
                arrangement: root.arrangement,
                presets: root.builtInPresets.map(p => ({ id: p.id, name: p.name, builtin: true, available: true }))
                    .concat(root.presets.map(p => ({ id: p.id, name: p.name, builtin: false, available: root.available(p), auto: p.auto, default: p.id === root.defaultPreset })))
            })
        }
    }
}
