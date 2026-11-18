pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// The one settings source for the desktop: ~/.config/quickshell/settings.json (yours, never in the
// repo). Every component reads Config.<section>.<option>; the Settings app writes through
// set(), which validates. The file is watched, so a hand edit or a git checkout applies live.
// Values Hyprland owns (displays, keyboard, idle) stay in hypr/settings/ (*.lua, hypridle.conf).
Singleton {
    id: root

    readonly property alias appearance: adapter.appearance
    readonly property alias dock: adapter.dock
    readonly property alias launcher: adapter.launcher
    readonly property alias clipboard: adapter.clipboard
    readonly property alias notifications: adapter.notifications
    readonly property alias osd: adapter.osd
    readonly property alias caffeine: adapter.caffeine
    readonly property alias nightLight: adapter.nightLight
    readonly property alias controlCenter: adapter.controlCenter
    readonly property alias weather: adapter.weather
    readonly property alias keybinds: adapter.keybinds
    readonly property alias actions: adapter.actions
    readonly property alias windows: adapter.windows
    readonly property alias lockscreen: adapter.lockscreen
    readonly property alias calendar: adapter.calendar
    readonly property alias language: adapter.language
    readonly property alias startup: adapter.startup
    readonly property alias system: adapter.system
    readonly property alias wallpaper: adapter.wallpaper
    readonly property alias bar: adapter.bar
    readonly property alias idle: adapter.idle
    readonly property alias input: adapter.input
    readonly property alias displays: adapter.displays
    readonly property alias workspaces: adapter.workspaces
    readonly property alias apps: adapter.apps
    readonly property alias monitorShare: adapter.monitorShare
    readonly property alias capture: adapter.capture
    readonly property alias battery: adapter.battery
    readonly property alias hotCorners: adapter.hotCorners
    readonly property alias missionControl: adapter.missionControl
    readonly property bool loaded: file.loaded

    // Allowed values; set() refuses anything else. Numbers are [min, max].
    readonly property var schema: ({
        appearance: {
            theme: Themes.ids,
            mode: ["theme", "light", "dark"], custom: "object", terminal: "bool", wallpaper: "bool", wallpaperColours: "bool", fontScale: [0.85, 1.25], motion: ["full", "reduced", "off"], motionStyle: ["theme", "smooth", "snappy", "springy", "minimal"],
            iconTheme: "string", monoTray: "bool", cursorTheme: "string", cursorSize: [16, 64]
        },
        dock: { enabled: "bool", size: ["compact", "regular", "roomy"], hiddenOn: "list",
                iconSize: [24, 72], autoHide: "bool", showRunning: "bool", combine: "bool", barLabels: ["icon", "name", "title"], nameOnly: "bool", previews: "bool", thumbnails: "bool", thumbRefresh: [10, 86400], pinned: "list", widgets: "list" },
        launcher: { webSearch: "string", showFiles: "bool", usage: "object",
                    style: ["theme", "spotlight", "launchpad", "drawer", "sidebar", "terminal"],
                    columns: [5, 9], startView: ["theme", "home", "apps", "search"], recent: "list", order: "list", clipboardInside: "bool", position: ["center", "pointer", "theme"],
                    size: [80, 130], rows: ["style", "standard", "compact", "cards", "text"], home: "list", dim: ["style", "none", "light", "dark"],
                    corners: ["style", "sharp", "soft", "round"], hints: "bool", subtitles: "bool", maxResults: [10, 80], quickActions: "list",
                    quickLook: "bool", converters: "bool" },
        clipboard: { maxItems: [20, 2000], maxAgeDays: [0, 365], images: "bool", paused: "bool",
                     skipSensitive: "bool", autoPaste: "bool" },
        notifications: { dnd: "bool", timeoutSec: [2, 30], timeoutLowSec: [2, 30], timeoutCriticalSec: [0, 120], maxVisible: [1, 8],
                         groupByApp: "bool", showIcons: "bool",
                         style: ["theme", "card", "bubble", "line", "block", "tag", "compact"],
                         position: ["theme", "top-left", "top", "top-right", "bottom-left", "bottom", "bottom-right"],
                         dndSchedule: "bool", dndFrom: "time", dndTo: "time",
                         historyMax: [10, 500], sound: "string", soundLow: "string", soundCritical: "string", volume: [0, 100],
                         mutedApps: "list" },
        osd: { timeoutMs: [600, 5000], volume: "bool", brightness: "bool", micMute: "bool", layout: "bool", capsLock: "bool", position: ["bottom", "top", "center"] },
        caffeine: { defaultMinutes: [0, 600], on: "bool", minutes: [0, 600], endsAt: [0, 1e15] },
        nightLight: { mode: ["off", "on", "sun", "schedule"], temperature: [2500, 6000], from: "time", to: "time" },
        controlCenter: { showHardware: "bool", style: ["panel", "compact", "borderless"], width: [280, 460], sections: "list", tiles: "list", sliders: "list", toggles: "list", folded: "list", hidden: "list", layouts: "object" },
        keybinds: { overrides: "object", custom: "shortcuts" },
        actions: { list: "actions" },
        lockscreen: { clock: ["theme", "big", "stacked", "terminal", "readout", "small"], position: ["theme", "center", "top", "bottom", "left"],
                      date: "bool", greeting: "bool", avatar: "string", widgets: "list", wallpaper: "string",
                      blur: [0, 6], brightness: [0.3, 1] },
        windows: { layout: ["dwindle", "master", "scrolling"], newSplit: [0, 2], smartSplit: "bool",
                   masterNew: ["master", "slave"], masterSide: ["left", "right", "top", "center"], columnWidth: [0.3, 1],
                   followMouse: "bool", focusOnActivate: "bool", warpCursor: "bool", backAndForth: "bool",
                   inactiveOpacity: [0.6, 1], dimInactive: "bool", dimStrength: [0.05, 0.6], resizeOnBorder: "bool",
                   snap: "bool", hideCursorTyping: "bool", titleBars: "bool", edgeSnap: "bool", floatAll: "bool", apps: "list",
                   titleBarSize: ["theme", "small", "medium", "large"], titleButtons: ["right", "left"], titleAlign: ["center", "left"], maxButton: ["float", "fill"],
                   border: ["theme", "accent", "gradient", "neon", "mono", "rainbow", "sunset", "ocean", "custom"], borderAngle: [0, 359],
                   borderColors: "list", borderAnimate: "bool", rainbowSpeed: [1, 10], rainbowOnBattery: "bool" },
        calendar: { holidays: "bool", country: "string", localNames: "bool", observances: "bool", moon: "bool",
                    weekNumbers: "bool", firstDay: ["monday", "sunday"] },
        language: { languages: "list", formats: "string" },
        startup: { apps: "list" },
        system: { taskManager: "string", welcomed: "bool" },
        wallpaper: { folders: "list", current: "string", slideshow: "bool", interval: [1, 1440],
                     source: ["all", "selected"], selected: "list", order: ["shuffle", "name"], blur: [0, 30] },
        bar: { margin: [0, 40], hiddenOn: "list", batteryPercent: ["inside", "beside", "off"],
               clock24: "bool", seconds: "bool",
               windowTitle: "bool", items: "object", preset: "string", presets: "object", monitors: "object", layout: "object" },
        battery: { warn: "bool", warnAt: [5, 50], criticalAt: [2, 20] },
        missionControl: { screens: ["all", "this"], click: ["switch", "browse"], newTile: "bool", size: ["small", "medium", "large"] },
        hotCorners: { topLeft: "string", topRight: "string", bottomLeft: "string", bottomRight: "string" },
        weather: { locations: "places", units: ["celsius", "fahrenheit"], days: [0, 16], hours: [0, 48],
                   details: "list", refreshMin: [10, 180] },
        capture: { folder: "string", recordFolder: "string", after: ["edit", "copy", "save"], delay: [0, 10],
                   audio: ["none", "desktop", "mic"], notify: "bool" },
        idle: { lockMin: [0, 240], sleepMin: [0, 480], sleepOnPowerMin: [0, 480], imported: "bool" },
        input: { layouts: "layouts", shortcut: [0, 3], repeatRate: [1, 100], repeatDelay: [100, 2000], sensitivity: [-1, 1],
                 naturalScroll: "bool", tapToClick: "bool", disableWhileTyping: "bool", clickMethod: ["buttonareas", "clickfinger"],
                 scrollFactor: [0.2, 3], middleEmulation: "bool", dragLock: "bool", imported: "bool" },
        displays: { layout: "displays", autoHdr: "bool", sendContentType: "bool", xwaylandNativeScale: "bool",
                    vrr: ["off", "on", "fullscreen"], preferHighRefresh: "bool", presets: "presets", defaultPreset: "string",
                    newScreen: ["right", "left", "above", "below", "mirror"], imported: "bool" },
        workspaces: { mode: ["dynamic", "fixed"], count: [1, 10], screens: "displays" },
        apps: { terminal: "command" },
        monitorShare: { enabled: "bool", output: "name", thisInput: "ddc", otherInput: "ddc", mirror: "name", mirrorMode: "mode", imported: "bool" }
    })

    // Why a value breaks its rule, or "" when it's fine. Lists from settings.json arrive as QML lists, so
    // anything with a length counts as a list.
    function problem(rule, value) {
        if (Array.isArray(rule) && typeof rule[0] === "number")
            return typeof value !== "number" || isNaN(value) || value < rule[0] || value > rule[1] ? "Must be between " + rule[0] + " and " + rule[1] : ""
        if (Array.isArray(rule)) return rule.includes(value) ? "" : "Must be one of " + rule.join(", ")
        if (rule === "bool") return typeof value === "boolean" ? "" : "Must be on or off"
        if (rule === "list") return value !== null && typeof value === "object" && typeof value.length === "number" ? "" : "Must be a list"
        if (rule === "object") return value !== null && typeof value === "object" ? "" : "Must be an object"
        if (rule === "time") return /^([01]\d|2[0-3]):[0-5]\d$/.test(value) ? "" : "Use HH:MM"
        if (rule === "color") return /^#[0-9a-fA-F]{6}$/.test(value) ? "" : "Use a colour like #ff7a59"
        if (rule === "string") return typeof value === "string" ? "" : "Must be text"
        // values that end up in generated config files: plain characters only
        if (rule === "name") return typeof value === "string" && /^[A-Za-z0-9._-]*$/.test(value) ? "" : "Letters, digits, . _ - only"
        if (rule === "command") return typeof value === "string" && /^[A-Za-z0-9 +._\/-]{1,80}$/.test(value) ? "" : "Letters, digits, space and + - _ . / only"
        if (rule === "ddc") return typeof value === "string" && /^(0x[0-9a-fA-F]{1,2})?$/.test(value) ? "" : "Use an input code like 0x11"
        if (rule === "mode") return typeof value === "string" && /^(\d{3,5}x\d{3,5}(@\d{2,3}(\.\d+)?)?)?$/.test(value) ? "" : "Use a mode like 1920x1080@60"
        if (rule === "layouts") return value && typeof value.length === "number" && value.length >= 1 && value.length <= 4
            && Array.from(value).every(l => /^[a-z]{2,8}$/.test(l?.code ?? "") && /^[a-z0-9_-]*$/.test(l?.variant ?? "")) ? "" : "One to four keyboard layouts"
        if (rule === "places") return value && typeof value.length === "number" && value.length <= 20
            && Array.from(value).every(l => typeof l?.name === "string" && l.name.length > 0
                && typeof l?.latitude === "number" && Math.abs(l.latitude) <= 90
                && typeof l?.longitude === "number" && Math.abs(l.longitude) <= 180) ? "" : "Up to 20 places, each with a name and coordinates"
        // your actions: each one checked by Actions.problem (repair() drops a bad one alone, with a warning)
        if (rule === "actions") return value && typeof value.length === "number" && value.length <= 200
            && Array.from(value).every((a, i, all) => !Actions.problem(a) && all.findIndex(b => b.id === a.id) === i) ? "" : "Up to 200 valid actions with different ids"
        // keys and an action id go into hypr/settings/keybinds.lua: plain characters only (binds.lua checks again)
        if (rule === "shortcuts") return value && typeof value.length === "number" && value.length <= 100
            && Array.from(value).every(c => /^[A-Za-z0-9_+: ]{1,60}$/.test(c?.keys ?? "") && /^[a-z0-9][a-z0-9-]*$/.test(c?.action ?? "")) ? "" : "Shortcuts need keys and an action id"
        if (rule === "displays") return value !== null && typeof value === "object" && Object.keys(value).every(displayKeyOk) ? "" : "Unknown display names"
        if (rule === "presets") return value && typeof value.length === "number" && value.length <= 20
            && Array.from(value).every(p => /^[a-z0-9-]{1,40}$/.test(p?.id ?? "") && typeof p.name === "string" && p.name.length > 0 && p.name.length <= 40
                && !/[\x00-\x1f]/.test(p.name) && typeof p.auto === "boolean" && p.outputs !== null && typeof p.outputs === "object"
                && Object.keys(p.outputs).length > 0 && Object.keys(p.outputs).every(k => displayKeyOk(k) && displayOutputOk(p.outputs[k]))) ? "" : "Up to 20 presets, each with a name and its screens"
        return ""
    }
    // a connector or a description (make model serial)
    function displayKeyOk(n) { return /^[^"\\\x00-\x1f]{1,120}$/.test(n) }
    // one screen inside a saved layout or preset
    function displayOutputOk(o) {
        return o !== null && typeof o === "object" && (o.mode === undefined || !problem("mode", o.mode))
            && (o.position === undefined || /^-?\d{1,6}x-?\d{1,6}$/.test(o.position))
            && (o.scale === undefined || (typeof o.scale === "number" && o.scale >= 0.25 && o.scale <= 10))
            && (o.transform === undefined || [0, 1, 2, 3, 4, 5, 6, 7].includes(o.transform))
            && (o.vrr === undefined || [0, 1, 2].includes(o.vrr)) && (o.bitdepth === undefined || [8, 10].includes(o.bitdepth))
            && (o.mirror === undefined || typeof o.mirror === "string") && (o.disabled === undefined || typeof o.disabled === "boolean")
    }

    // Set one option. Returns "" when saved, or the reason it was refused.
    function set(section, key, value) {
        const rule = schema[section]?.[key]
        if (rule === undefined) return "Unknown setting " + section + "." + key
        if (Array.isArray(rule) && typeof rule[0] === "number") value = Number(value)
        const why = problem(rule, value)
        if (why) return why
        if (["displays", "keybinds", "actions"].includes(section)) checkpoint(section)   // big changes: a restore point first
        adapter[section][key] = value
        return ""
    }

    // Put a whole section back to its defaults
    function reset(section, keys) {   // keys: only these (default: the whole section)
        const fresh = defaults.createObject(null)
        for (const key of keys ?? Object.keys(schema[section])) if (schema[section][key] !== undefined) adapter[section][key] = fresh[section][key]
        fresh.destroy()
    }

    // `qs ipc call config set appearance accent '"mauve"'` (value is JSON) / `… get appearance accent`
    IpcHandler {
        target: "config"
        function set(section: string, key: string, json: string): string {
            let v; try { v = JSON.parse(json) } catch (e) { v = json }
            return root.set(section, key, v) || "ok"
        }
        function get(section: string, key: string): string { return JSON.stringify(adapter[section]?.[key]) }
        function reset(section: string): void { root.reset(section) }
    }

    FileView {
        id: file
        path: Quickshell.shellDir + "/settings.json"
        watchChanges: true
        atomicWrites: true
        // only someone else's edit is reloaded (a hand edit, a git checkout): reloading our own writes could read an
        // older one back over a newer change (several settings changed at once, e.g. saving a theme)
        property real ownWriteAt: 0
        onFileChanged: if (Date.now() - ownWriteAt > 1000) reloadLater.restart()
        // one write per burst of changes: overlapping writes can finish out of order and put older values back
        onAdapterUpdated: { ownWriteAt = Date.now(); writeLater.restart() }
        onLoaded: root.repair()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        adapter: ConfigData { id: adapter }
    }
    Timer { id: reloadLater; interval: 250; onTriggered: file.reload() }
    Timer { id: writeLater; interval: 60; onTriggered: { if (snapshot.running) return; file.ownWriteAt = Date.now(); file.writeAdapter() } }

    // A restore point before a big change (set() calls it for displays, keybinds and actions). The next write
    // waits until the copy is taken, so the copy holds the settings from before the change.
    function checkpoint(reason) { if (!snapshot.running) { snapshot.command = ["settings-snapshot", "take", reason]; snapshot.running = true } }
    Process { id: snapshot; onRunningChanged: if (!running) writeLater.restart() }   // also when it failed to start

    Component { id: defaults; ConfigData {} }

    // After every load: carry old names forward, then put back the default for anything missing or
    // out of range, so a hand edit, an old file or a half-written one never breaks the desktop.
    // A file that isn't JSON at all is kept as settings.json.broken and replaced by the defaults.
    // every theme that ever shipped -> the one of today's three closest to it (2026-11-15 kept three)
    readonly property var renamedThemes: ({ workstation: "pebble", canvas: "pebble", zen: "pebble", halo: "pebble", garden: "pebble",
                                            glass: "pebble", noir: "monolith", console: "monolith", reactor: "monolith",
                                            mist: "poster", atlas: "poster" })
    // The saved theme must exist. Only judged once the theme folders are read (Themes.ready), or every
    // theme would look missing during the first moments and your choice would be lost.
    function checkTheme() {
        const a = adapter.appearance
        if (Themes.ready && !Themes.ids.includes(a.theme)) a.theme = renamedThemes[a.theme] ?? defaultTheme()
    }
    function defaultTheme() {
        const fresh = defaults.createObject(null), want = fresh.appearance.theme
        fresh.destroy()
        return Themes.ids.includes(want) ? want : Themes.ids[0]
    }
    Connections { target: Themes; function onReadyChanged() { if (file.loaded) root.checkTheme() } }
    // ---- format 7 (displays) -------------------------------------------------------------------------------
    // Screens were saved by connector (HDMI-A-1); they are now saved by description (make model serial), so a layout
    // follows a monitor to another port. Only screens connected now are renamed; others keep their connector name.
    // Runs on load and again when Hyprland first lists the screens (at login it often hasn't yet), so it isn't skipped.
    function migrateDisplays() {
        if (adapter.version >= 7 || Hyprland.monitors.values.length === 0) return
        const key = n => Displays.keyForName(n)
        const rekey = o => { const out = {}; for (const n of Object.keys(o ?? {})) out[key(n)] = o[n]; return out }
        const lay = JSON.parse(JSON.stringify(adapter.displays.layout ?? {}))
        for (const n of Object.keys(lay)) if (lay[n]?.mirror) lay[n].mirror = key(lay[n].mirror)
        adapter.displays.layout = rekey(lay)
        const ws = JSON.parse(JSON.stringify(adapter.workspaces.screens ?? {}))
        for (const n of Object.keys(ws)) ws[n] = key(ws[n])
        adapter.workspaces.screens = ws
        adapter.bar.hiddenOn = Array.from(adapter.bar.hiddenOn).map(key)
        adapter.dock.hiddenOn = Array.from(adapter.dock.hiddenOn).map(key)
        adapter.version = 8   // format 8 (actions, in repair()) needs no screens, so it has run already
    }
    // ---- end format 7
    Connections { target: Hyprland.monitors; function onValuesChanged() { if (file.loaded) root.migrateDisplays() } }
    function repair() {
        let raw
        try { raw = JSON.parse(file.text()) } catch (e) {
            console.warn("settings.json is not valid JSON; keeping it as settings.json.broken and starting from defaults")
            // the text as it is now goes in as an argument, so the defaults written next can't race the copy
            Quickshell.execDetached(["sh", "-c", 'printf "%s" "$2" > "$1"', "sh", file.path + ".broken", file.text()])
            reset("appearance"); for (const s of Object.keys(schema)) if (s !== "appearance") reset(s)
            return
        }
        const a = adapter.appearance
        const oldTheme = raw?.appearance?.rice   // settings from before "rices" were called themes
        if (typeof oldTheme === "string") a.theme = renamedThemes[oldTheme] ?? oldTheme
        checkTheme()
        // adjustments saved for a removed theme move to its successor, unless the successor has its own
        const oldCustom = a.custom ?? {}
        if (Object.keys(oldCustom).some(k => renamedThemes[k] !== undefined)) {
            const kept = {}
            for (const k of Object.keys(oldCustom)) if (renamedThemes[k] === undefined) kept[k] = oldCustom[k]
            for (const k of Object.keys(oldCustom)) {
                const to = renamedThemes[k]
                if (to !== undefined && kept[to] === undefined) kept[to] = oldCustom[k]
            }
            a.custom = JSON.parse(JSON.stringify(kept))
        }
        // before 2026-11-15 the bar's place and items were kept per theme (or as a named preset): the active
        // theme's become your one layout, and the per-theme copies go
        if (!Object.keys(adapter.bar.layout ?? {}).length) {
            const all = JSON.parse(JSON.stringify(a.custom ?? {})), m = all[a.theme] ?? {}
            const preset = adapter.bar.preset !== "theme" ? adapter.bar.presets?.[adapter.bar.preset] : undefined
            const l = {}
            if (m.barEdge) l.edge = m.barEdge
            if (m.barSize) l.size = m.barSize
            if (m.barFloating !== undefined) l.floating = m.barFloating
            if (m.dock) l.dock = m.dock
            const it = m.barItems ?? preset
            if (it) Object.assign(l, { start: it.start ?? [], center: it.center ?? [], end: it.end ?? [] })
            if (Object.keys(l).length) {
                adapter.bar.layout = l
                for (const t of Object.keys(all)) for (const k of ["barEdge", "barSize", "barFloating", "barItems", "dock"]) delete all[t][k]
                a.custom = all
                adapter.bar.preset = "theme"
            }
        }
        // before 2026-11-15 one bar.date served the bar's only clock; each clock now has its own date settings
        const rd = raw?.bar?.date, rc = raw?.bar?.items?.clock
        if ((rd === "short" || rd === "none") && rc?.date === undefined && rc?.weekday === undefined) {
            const all = JSON.parse(JSON.stringify(adapter.bar.items ?? {}))
            all.clock = Object.assign(all.clock ?? {}, rd === "none" ? { date: false } : { weekday: "none" })
            adapter.bar.items = all
        }
        if (adapter.launcher.startView === "rice") adapter.launcher.startView = "theme"
        // format 1 (before 2026-11-05) saved the dock's place as "bottom" for everyone: follow the theme now
        // format 2 kept one bar layout and dock place for every theme, so an edit made in one theme broke the
        // others: it moves into the active theme's own adjustments (Themes.resolve)
        if ((raw?.version ?? 1) < 3) {
            const rb = raw?.bar ?? {}, mine = {}
            const edges = ["top", "bottom", "left", "right"]
            if (edges.includes(rb.position)) mine.barEdge = rb.position
            if (typeof rb.size === "number" && rb.size >= 20) mine.barSize = rb.size
            if (rb.floating === "floating" || rb.floating === "attached") mine.barFloating = rb.floating === "floating"
            if (rb.custom === true) mine.barItems = { start: rb.start ?? [], center: rb.center ?? [], end: rb.end ?? [] }
            const dp = raw?.dock?.position   // format 1 saved "bottom" for everyone: that meant the theme's own
            if (dp === "bar" || (edges.includes(dp) && !(dp === "bottom" && (raw?.version ?? 1) < 2))) mine.dock = dp
            if (Object.keys(mine).length) {
                const all = JSON.parse(JSON.stringify(a.custom ?? {}))
                all[a.theme] = Object.assign(all[a.theme] ?? {}, mine)
                a.custom = all
            }
            adapter.version = 3
        }
        // format 3 saved Papirus-Dark icons and the system cursor for everyone: every theme has its own now
        if ((raw?.version ?? 1) < 4) {
            if (adapter.appearance.iconTheme === "Papirus-Dark") adapter.appearance.iconTheme = "theme"
            if (adapter.appearance.cursorTheme === "default") adapter.appearance.cursorTheme = "theme"
            adapter.version = 4
        }
        // format 5 (windows): a rainbow frame turned on its own; whether a frame turns is now its own switch
        // (windows.borderAnimate), so a saved rainbow keeps turning
        if ((raw?.version ?? 1) < 5) {
            if (adapter.windows.border === "rainbow") adapter.windows.borderAnimate = true
            adapter.version = 5
        }
        // format 6 (bar): bar.layout held one bar shape for every theme; now the shape (edge, size, floating, the
        // dock's place) belongs to each theme and bar.layout keeps only the item lists. The saved shape moves into
        // the current theme's adjustments, so nothing on screen changes; other themes get their own shape back.
        if ((raw?.version ?? 1) < 6) {
            const l = JSON.parse(JSON.stringify(adapter.bar.layout ?? {})), mine = {}
            if (["top", "bottom", "left", "right"].includes(l.edge)) mine.barEdge = l.edge
            if (typeof l.size === "number") mine.barSize = l.size
            if (typeof l.floating === "boolean") mine.barFloating = l.floating
            if (typeof l.dock === "string" && l.dock !== "") mine.dock = l.dock
            for (const k of ["edge", "size", "floating", "dock"]) delete l[k]
            if (Object.keys(mine).length) {
                const all = JSON.parse(JSON.stringify(a.custom ?? {}))
                all[a.theme] = Object.assign(all[a.theme] ?? {}, mine)
                a.custom = all
            }
            adapter.bar.layout = l
            adapter.version = 6
        }
        migrateDisplays()   // format 7 (below)
        // format 8: your launcher actions (launcher.actions) became actions of the registry (actions.list, Actions.qml),
        // and the launcher's history names them by id
        if ((raw?.version ?? 1) < 8) {
            const ids = {}, list = JSON.parse(JSON.stringify(adapter.actions.list ?? []))
            for (const c of Array.from(raw?.launcher?.actions ?? [])) {
                if (typeof c?.name !== "string" || typeof c?.value !== "string" || !c.name.trim() || !c.value.trim()) continue
                let id = c.name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 40) || "action"
                while (list.some(a => a.id === id) || Actions.builtinIds.includes(id)) id += "-2"
                const run = c.kind === "snippet" || c.kind === "open" ? { type: c.kind, value: c.value }
                          : c.kind === "terminal" ? { type: "terminal", argv: ["sh", "-c", c.value] } : { type: "shell", value: c.value }
                list.push({ id: id, name: c.name.trim().slice(0, 60), icon: ({ snippet: "\u{F0187}", open: "\u{F024B}" })[c.kind] ?? "\u{F018D}",
                            kind: "button", run: run, confirm: c.confirm === true, showIn: ["launcher"] })
                ids["custom:" + c.name] = "action:" + id
            }
            adapter.actions.list = list
            const l = adapter.launcher, usage = {}
            l.recent = Array.from(l.recent ?? []).map(k => ids[k] ?? k)
            for (const [k, n] of Object.entries(l.usage ?? {})) usage[ids[k] ?? k] = n
            l.usage = usage
            if (adapter.version >= 7) adapter.version = 8   // else migrateDisplays() sets it once there are screens
        }
        // a bad action is dropped alone, so one typo in settings.json doesn't take the others with it
        const acts = Array.from(adapter.actions.list ?? [])
        const good = acts.filter((a, i) => {
            const why = Actions.problem(a) || (acts.findIndex(b => b?.id === a.id) !== i ? "a second action with this id" : "")
            if (why) console.warn("settings.json: action " + JSON.stringify(a?.id ?? i) + " dropped: " + why)
            return !why
        })
        if (good.length !== acts.length) adapter.actions.list = JSON.parse(JSON.stringify(good))
        // before 2026-11-15 the weather had one place and two switches
        const rw = raw?.weather ?? {}
        if (rw.locations === undefined && typeof rw.city === "string" && typeof rw.latitude === "number" && typeof rw.longitude === "number")
            adapter.weather.locations = [{ name: rw.city, region: "", country: "", latitude: rw.latitude, longitude: rw.longitude }]
        if (rw.hours === undefined && rw.showHourly === false) adapter.weather.hours = 0
        if (rw.details === undefined && rw.showDetails === false) adapter.weather.details = []
        if (raw?.appearance?.animations === false && raw?.appearance?.motion === undefined) a.motion = "off"   // the old on/off switch
        const fresh = defaults.createObject(null)
        for (const section of Object.keys(schema))
            for (const key of Object.keys(schema[section])) {
                if (section === "appearance" && key === "theme") continue   // judged by checkTheme, once the theme folders are read
                if (problem(schema[section][key], adapter[section][key])) {
                    console.warn("settings.json: " + section + "." + key + " was invalid, using the default")
                    adapter[section][key] = fresh[section][key]
                }
            }
        // the built-in bar presets an older file lacks come back; ones you edited stay as they are
        const have = JSON.parse(JSON.stringify(adapter.bar.presets ?? {})), builtIn = fresh.bar.presets
        const missing = Object.keys(builtIn).filter(n => have[n] === undefined)
        if (missing.length) { for (const n of missing) have[n] = JSON.parse(JSON.stringify(builtIn[n])); adapter.bar.presets = have }
        fresh.destroy()
    }
}
