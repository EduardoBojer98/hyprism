pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The one settings source for the desktop: quickshell/settings.json (in the repo through the
// stow link). Every component reads Config.<section>.<option>; the Settings app writes through
// set(), which validates. The file is watched, so a hand edit or a git checkout applies live.
// Values Hyprland owns (displays, keyboard, idle) stay in hypr/settings/*.lua and hypridle.conf.
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
    readonly property bool loaded: file.loaded

    // Allowed values; set() refuses anything else. Numbers are [min, max].
    readonly property var schema: ({
        appearance: {
            accent: ["blue", "lavender", "mauve", "pink", "peach", "yellow", "green", "teal", "sky"],
            glassOpacity: [0.2, 0.9], radiusScale: [0, 1.5], fontScale: [0.85, 1.25],
            font: "string", animations: "bool", iconTheme: "string"
        },
        dock: { iconSize: [32, 64], autoHide: "bool", showRunning: "bool", pinned: "list" },
        launcher: { webSearch: "string", fileRoots: "list", showFiles: "bool", actions: "list", usage: "object" },
        clipboard: { maxItems: [20, 2000], maxAgeDays: [0, 365], images: "bool", paused: "bool",
                     skipSensitive: "bool", autoPaste: "bool" },
        notifications: { dnd: "bool", timeoutSec: [2, 30], historyMax: [10, 500] },
        caffeine: { defaultMinutes: [0, 600] },
        nightLight: { mode: ["off", "on", "sun", "schedule"], temperature: [2500, 6000], from: "time", to: "time" },
        controlCenter: { showMedia: "bool", showHardware: "bool" },
        weather: { city: "string", latitude: [-90, 90], longitude: [-180, 180] }
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
        else if (rule === "string" && typeof value !== "string") return "Must be text"
        adapter[section][key] = value
        return ""
    }

    // Put a whole section back to its defaults
    function reset(section) {
        const fresh = defaults.createObject(null)
        for (const key in schema[section]) adapter[section][key] = fresh[section][key]
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
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        adapter: ConfigData { id: adapter }
    }

    Component { id: defaults; ConfigData {} }
}
