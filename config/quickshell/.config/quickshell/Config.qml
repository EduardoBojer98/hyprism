pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The one settings source for the desktop: quickshell/settings.json (in the repo through the
// stow link). Every component reads Config.<section>.<option>; the Settings app writes through
// set(), which validates. The file is watched, so a hand edit or a git checkout applies live.
// Values Hyprland owns (displays, keyboard, idle) stay in hypr/settings/ (*.lua, hypridle.conf).
Singleton {
    id: root

    readonly property alias appearance: adapter.appearance
    readonly property alias dock: adapter.dock
    readonly property alias launcher: adapter.launcher
    readonly property alias clipboard: adapter.clipboard
    readonly property alias notifications: adapter.notifications
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
    readonly property alias battery: adapter.battery
    readonly property alias hotCorners: adapter.hotCorners
    readonly property bool loaded: file.loaded

    // Allowed values; set() refuses anything else. Numbers are [min, max].
    readonly property var schema: ({
        appearance: {
            theme: Themes.ids,
            custom: "object", terminal: "bool", wallpaper: "bool", fontScale: [0.85, 1.25], motion: ["full", "reduced", "off"],
            iconTheme: "string", cursorTheme: "string", cursorSize: [16, 64]
        },
        dock: { enabled: "bool", position: ["bottom", "left", "right", "top"], size: ["compact", "regular", "roomy"], hiddenOn: "list",
                iconSize: [24, 72], autoHide: "bool", showRunning: "bool", thumbnails: "bool", thumbRefresh: [10, 86400], pinned: "list" },
        launcher: { webSearch: "string", showFiles: "bool", actions: "list", usage: "object",
                    columns: [5, 9], startView: ["theme", "home", "apps", "search"], recent: "list", order: "list", clipboardInside: "bool" },
        clipboard: { maxItems: [20, 2000], maxAgeDays: [0, 365], images: "bool", paused: "bool",
                     skipSensitive: "bool", autoPaste: "bool" },
        notifications: { dnd: "bool", timeoutSec: [2, 30], historyMax: [10, 500], sound: "string", volume: [0, 100],
                         mutedApps: "list" },
        caffeine: { defaultMinutes: [0, 600], on: "bool", minutes: [0, 600], endsAt: [0, 1e15] },
        nightLight: { mode: ["off", "on", "sun", "schedule"], temperature: [2500, 6000], from: "time", to: "time" },
        controlCenter: { showHardware: "bool", slidersOpen: "bool", style: ["panel", "compact", "borderless"], width: [280, 460], sections: "list", tiles: "list", toggles: "list", shortcuts: "list", hidden: "list" },
        keybinds: { overrides: "object" },
        lockscreen: { wallpaper: "string",
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
        system: { taskManager: "string" },
        wallpaper: { folders: "list", current: "string", slideshow: "bool", interval: [1, 1440],
                     source: ["all", "selected"], selected: "list", order: ["shuffle", "name"], blur: [0, 30] },
        bar: { position: ["theme", "top", "bottom", "left", "right"], size: [0, 96], floating: ["theme", "floating", "attached"], margin: [0, 40],
               hiddenOn: "list", custom: "bool", start: "list", center: "list", end: "list",
               clock24: "bool", seconds: "bool", date: ["full", "short", "none"],
               windowTitle: "bool" },
        battery: { warn: "bool", warnAt: [5, 50], criticalAt: [2, 20] },
        hotCorners: { topLeft: "string", topRight: "string", bottomLeft: "string", bottomRight: "string" },
        weather: { city: "string", latitude: [-90, 90], longitude: [-180, 180], days: [1, 16],
                   showHourly: "bool", showDetails: "bool", units: ["celsius", "fahrenheit"] }
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
        // debounced: a burst of our own writes (reset) must not reload a half-written state
        onFileChanged: reloadLater.restart()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.repair()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        adapter: ConfigData { id: adapter }
    }
    Timer { id: reloadLater; interval: 250; onTriggered: file.reload() }

    Component { id: defaults; ConfigData {} }

    // After every load: carry old names forward, then put back the default for anything missing or
    // out of range, so a hand edit, an old file or a half-written one never breaks the desktop.
    // A file that isn't JSON at all is kept as settings.json.broken and replaced by the defaults.
    readonly property var renamedThemes: ({ workstation: "glass", canvas: "glass", noir: "console", garden: "pebble",
                                            zen: "glass", mist: "atlas", halo: "pebble" })   // themes removed 2026-11
    function repair() {
        let raw
        try { raw = JSON.parse(file.text()) } catch (e) {
            console.warn("settings.json is not valid JSON; keeping it as settings.json.broken and starting from defaults")
            Quickshell.execDetached(["cp", "-f", file.path, file.path + ".broken"])
            reset("appearance"); for (const s of Object.keys(schema)) if (s !== "appearance") reset(s)
            return
        }
        const a = adapter.appearance
        const oldTheme = raw?.appearance?.rice   // settings from before "rices" were called themes
        if (typeof oldTheme === "string") a.theme = renamedThemes[oldTheme] ?? oldTheme
        if (!Themes.ids.includes(a.theme)) a.theme = renamedThemes[a.theme] ?? Themes.ids[0]
        if (adapter.launcher.startView === "rice") adapter.launcher.startView = "theme"
        if (raw?.appearance?.animations === false && raw?.appearance?.motion === undefined) a.motion = "off"   // the old on/off switch
        const fresh = defaults.createObject(null)
        for (const section of Object.keys(schema))
            for (const key of Object.keys(schema[section]))
                if (problem(schema[section][key], adapter[section][key])) {
                    console.warn("settings.json: " + section + "." + key + " was invalid, using the default")
                    adapter[section][key] = fresh[section][key]
                }
        fresh.destroy()
    }
}
