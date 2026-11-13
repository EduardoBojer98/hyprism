pragma Singleton
import Quickshell
import Quickshell.Io
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
    readonly property alias battery: adapter.battery
    readonly property alias hotCorners: adapter.hotCorners
    readonly property bool loaded: file.loaded

    // Allowed values; set() refuses anything else. Numbers are [min, max].
    readonly property var schema: ({
        appearance: {
            theme: Themes.ids,
            mode: ["theme", "light", "dark"], custom: "object", userThemes: "object", terminal: "bool", wallpaper: "bool", wallpaperColours: "bool", fontScale: [0.85, 1.25], motion: ["full", "reduced", "off"],
            iconTheme: "string", monoTray: "bool", cursorTheme: "string", cursorSize: [16, 64]
        },
        dock: { enabled: "bool", size: ["compact", "regular", "roomy"], hiddenOn: "list",
                iconSize: [24, 72], autoHide: "bool", showRunning: "bool", combine: "bool", barLabels: ["icon", "name", "title"], previews: "bool", thumbnails: "bool", thumbRefresh: [10, 86400], pinned: "list", widgets: "list" },
        launcher: { webSearch: "string", showFiles: "bool", actions: "list", usage: "object",
                    style: ["theme", "spotlight", "command", "launchpad", "drawer", "sidebar", "terminal"],
                    columns: [5, 9], startView: ["theme", "home", "apps", "search"], recent: "list", order: "list", clipboardInside: "bool" },
        clipboard: { maxItems: [20, 2000], maxAgeDays: [0, 365], images: "bool", paused: "bool",
                     skipSensitive: "bool", autoPaste: "bool" },
        notifications: { dnd: "bool", timeoutSec: [2, 30], historyMax: [10, 500], sound: "string", volume: [0, 100],
                         mutedApps: "list" },
        osd: { timeoutMs: [600, 5000], volume: "bool", brightness: "bool", micMute: "bool", layout: "bool", capsLock: "bool", position: ["bottom", "top", "center"] },
        caffeine: { defaultMinutes: [0, 600], on: "bool", minutes: [0, 600], endsAt: [0, 1e15] },
        nightLight: { mode: ["off", "on", "sun", "schedule"], temperature: [2500, 6000], from: "time", to: "time" },
        controlCenter: { showHardware: "bool", slidersOpen: "bool", style: ["panel", "compact", "borderless"], width: [280, 460], sections: "list", tiles: "list", toggles: "list", shortcuts: "list", hidden: "list" },
        keybinds: { overrides: "object" },
        lockscreen: { clock: ["theme", "big", "stacked", "terminal", "readout", "small"], position: ["theme", "center", "top", "bottom", "left"],
                      date: "bool", greeting: "bool", avatar: "string", widgets: "list", wallpaper: "string",
                      blur: [0, 6], brightness: [0.3, 1] },
        windows: { layout: ["dwindle", "master", "scrolling"], newSplit: [0, 2], smartSplit: "bool",
                   masterNew: ["master", "slave"], masterSide: ["left", "right", "top", "center"], columnWidth: [0.3, 1],
                   followMouse: "bool", focusOnActivate: "bool", warpCursor: "bool", backAndForth: "bool",
                   inactiveOpacity: [0.6, 1], dimInactive: "bool", dimStrength: [0.05, 0.6], resizeOnBorder: "bool",
                   snap: "bool", hideCursorTyping: "bool", titleBars: "bool", apps: "list" },
        calendar: { holidays: "bool", country: "string", localNames: "bool", observances: "bool", moon: "bool",
                    weekNumbers: "bool", firstDay: ["monday", "sunday"] },
        language: { languages: "list", formats: "string" },
        startup: { apps: "list" },
        system: { taskManager: "string", welcomed: "bool" },
        wallpaper: { folders: "list", current: "string", slideshow: "bool", interval: [1, 1440],
                     source: ["all", "selected"], selected: "list", order: ["shuffle", "name"], blur: [0, 30] },
        bar: { margin: [0, 40], hiddenOn: "list", batteryPercent: ["inside", "beside", "off"],
               clock24: "bool", seconds: "bool", date: ["full", "short", "none"],
               windowTitle: "bool", items: "object", preset: "string", presets: "object", monitors: "object" },
        battery: { warn: "bool", warnAt: [5, 50], criticalAt: [2, 20] },
        hotCorners: { topLeft: "string", topRight: "string", bottomLeft: "string", bottomRight: "string" },
        weather: { city: "string", latitude: [-90, 90], longitude: [-180, 180], days: [1, 16],
                   showHourly: "bool", showDetails: "bool", units: ["celsius", "fahrenheit"] },
        idle: { lockMin: [0, 240], sleepMin: [0, 480], sleepOnPowerMin: [0, 480], imported: "bool" },
        input: { layouts: "layouts", shortcut: [0, 3], repeatRate: [1, 100], repeatDelay: [100, 2000], sensitivity: [-1, 1],
                 naturalScroll: "bool", tapToClick: "bool", disableWhileTyping: "bool", clickMethod: ["buttonareas", "clickfinger"],
                 scrollFactor: [0.2, 3], middleEmulation: "bool", dragLock: "bool", imported: "bool" },
        displays: { layout: "displays", autoHdr: "bool", sendContentType: "bool", xwaylandNativeScale: "bool",
                    vrr: ["off", "on", "fullscreen"], preferHighRefresh: "bool",
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
        if (rule === "displays") return value !== null && typeof value === "object" && Object.keys(value).every(n => /^[A-Za-z0-9._-]+$/.test(n)) ? "" : "Unknown display names"
        return ""
    }

    // Set one option. Returns "" when saved, or the reason it was refused.
    function set(section, key, value) {
        const rule = schema[section]?.[key]
        if (rule === undefined) return "Unknown setting " + section + "." + key
        if (Array.isArray(rule) && typeof rule[0] === "number") value = Number(value)
        const why = problem(rule, value)
        if (why) return why
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
    Timer { id: writeLater; interval: 60; onTriggered: { file.ownWriteAt = Date.now(); file.writeAdapter() } }

    Component { id: defaults; ConfigData {} }

    // After every load: carry old names forward, then put back the default for anything missing or
    // out of range, so a hand edit, an old file or a half-written one never breaks the desktop.
    // A file that isn't JSON at all is kept as settings.json.broken and replaced by the defaults.
    readonly property var renamedThemes: ({ workstation: "glass", canvas: "glass", noir: "console", garden: "pebble",
                                            zen: "glass", mist: "atlas", halo: "pebble" })   // themes removed 2026-11
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
