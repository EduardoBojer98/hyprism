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
            mode: ["light", "dark", "auto"],
            accent: ["theme", "blue", "lavender", "mauve", "pink", "red", "peach", "yellow", "green", "mint", "teal", "sky", "champagne", "silver", "custom"],
            customAccent: "color", theme: ["midnight", "graphite", "cocoa", "catppuccin", "tokyonight", "dracula", "nord", "gruvbox", "rosepine", "everforest", "kanagawa", "onedark", "solarized"],
            terminal: "bool",
            glassOpacity: [0.2, 0.9], radiusScale: [0, 1.5], fontScale: [0.85, 1.25],
            font: "string", animations: "bool", iconTheme: "string",
            border: ["rainbow", "accent"], borderSpin: [0, 100], borderSize: [1, 4], gaps: [0, 40]
        },
        dock: { iconSize: [32, 64], autoHide: "bool", showRunning: "bool", thumbnails: "bool", thumbRefresh: [10, 86400], pinned: "list" },
        launcher: { webSearch: "string", showFiles: "bool", actions: "list", usage: "object",
                    placement: ["center", "cursor"], startView: ["home", "apps", "search"], recent: "list", order: "list", clipboardInside: "bool" },
        clipboard: { maxItems: [20, 2000], maxAgeDays: [0, 365], images: "bool", paused: "bool",
                     skipSensitive: "bool", autoPaste: "bool" },
        notifications: { dnd: "bool", timeoutSec: [2, 30], historyMax: [10, 500], sound: "string", volume: [0, 100],
                         position: ["top-right", "top-center", "top-left"], mutedApps: "list" },
        caffeine: { defaultMinutes: [0, 600], on: "bool", minutes: [0, 600], endsAt: [0, 1e15] },
        nightLight: { mode: ["off", "on", "sun", "schedule"], temperature: [2500, 6000], from: "time", to: "time" },
        controlCenter: { showHardware: "bool", slidersOpen: "bool", sections: "list", tiles: "list", toggles: "list", shortcuts: "list", hidden: "list" },
        keybinds: { overrides: "object" },
        calendar: { holidays: "bool", country: "string", localNames: "bool", observances: "bool", moon: "bool",
                    weekNumbers: "bool", firstDay: ["monday", "sunday"] },
        language: { languages: "list", formats: "string" },
        startup: { apps: "list" },
        system: { taskManager: "string" },
        wallpaper: { folders: "list", current: "string", slideshow: "bool", interval: [1, 1440],
                     source: ["all", "selected"], selected: "list", order: ["shuffle", "name"] },
        bar: { clock24: "bool", seconds: "bool", date: ["full", "short", "none"],
               batteryPercent: "bool", windowTitle: "bool", left: "list", center: "list", right: "list" },
        battery: { warn: "bool", warnAt: [5, 50], criticalAt: [2, 20] },
        hotCorners: { topLeft: "string", topRight: "string", bottomLeft: "string", bottomRight: "string" },
        weather: { city: "string", latitude: [-90, 90], longitude: [-180, 180], days: [1, 16],
                   showHourly: "bool", showDetails: "bool", units: ["celsius", "fahrenheit"] }
    })

    // Set one option. Returns "" when saved, or the reason it was refused.
    function set(section, key, value) {
        const rule = schema[section]?.[key]
        if (rule === undefined) return "Unknown setting " + section + "." + key
        if (Array.isArray(rule) && typeof rule[0] === "number") {
            value = Number(value)
            if (isNaN(value) || value < rule[0] || value > rule[1]) return "Must be between " + rule[0] + " and " + rule[1]
        } else if (Array.isArray(rule)) {
            if (!rule.includes(value)) return "Must be one of " + rule.join(", ")
        } else if (rule === "bool" && typeof value !== "boolean") return "Must be on or off"
        else if (rule === "list" && !Array.isArray(value)) return "Must be a list"
        else if (rule === "time" && !/^([01]\d|2[0-3]):[0-5]\d$/.test(value)) return "Use HH:MM"
        else if (rule === "color" && !/^#[0-9a-fA-F]{6}$/.test(value)) return "Use a colour like #ff7a59"
        else if (rule === "string" && typeof value !== "string") return "Must be text"
        adapter[section][key] = value
        return ""
    }

    // Put a whole section back to its defaults
    function reset(section, keys) {   // keys: only these (default: the whole section)
        const fresh = defaults.createObject(null)
        for (const key of keys ?? Object.keys(schema[section])) adapter[section][key] = fresh[section][key]
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
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        adapter: ConfigData { id: adapter }
    }
    Timer { id: reloadLater; interval: 250; onTriggered: file.reload() }

    Component { id: defaults; ConfigData {} }
}
