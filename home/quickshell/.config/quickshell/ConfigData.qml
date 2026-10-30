import Quickshell.Io

// Defaults for every desktop option (Config.qml). A key missing from settings.json takes the
// value here; Reset in the Settings app copies these back.
JsonAdapter {
    property JsonObject appearance: JsonObject {
        property string mode: "light"           // "light" or "dark"
        property string accent: "blue"          // a system colour name (Theme.accents)
        property real glassOpacity: 0.55        // tint over the blur (0.2 clear .. 0.9 solid)
        property real radiusScale: 1            // 0 square .. 1.5 extra round
        property real fontScale: 1
        property string font: "Inter"
        property bool animations: true
        property string iconTheme: "Papirus-Dark"
        property string border: "rainbow"       // focused window border: "rainbow" or "accent"
        property int borderSpin: 60             // seconds x10 per rainbow turn (0 = still)
        property int borderSize: 2              // px
    }
    property JsonObject dock: JsonObject {
        property int iconSize: 44
        property bool autoHide: true
        property bool showRunning: true
        property list<string> pinned: ["firefox", "google-chrome", "com.microsoft.VSCode", "com.mitchellh.ghostty", "org.kde.dolphin"]
    }
    property JsonObject launcher: JsonObject {
        property string webSearch: "https://duckduckgo.com/?q=%s"
        property list<string> fileRoots: ["~"]
        property bool showFiles: true
        // [{ name, kind: "command"|"terminal"|"open"|"snippet", value, confirm }]
        property list<var> actions: []
        property var usage: ({})                // launch counts, for ranking
        property string placement: "center"     // center | cursor
        property string startView: "apps"       // apps (grid until you type) | search (empty pill)
        // result groups, best first; a group missing from the list is hidden
        property list<string> order: ["apps", "files", "calc", "settings", "actions", "web"]
        property bool clipboardInside: true     // Spotlight's clipboard button shows history in the panel
    }
    property JsonObject clipboard: JsonObject {
        property int maxItems: 300
        property int maxAgeDays: 30             // 0 = keep forever (pins are always kept)
        property bool images: true
        property bool paused: false
        property bool skipSensitive: true       // skip copies password managers mark as secret
        property bool autoPaste: true
    }
    property JsonObject notifications: JsonObject {
        property bool dnd: false
        property int timeoutSec: 6
        property int historyMax: 100
    }
    property JsonObject caffeine: JsonObject {
        property int defaultMinutes: 0          // 0 = until turned off
    }
    property JsonObject nightLight: JsonObject {
        property string mode: "off"             // off | on | sun | schedule
        property int temperature: 4000
        property string from: "21:00"
        property string to: "07:00"
    }
    property JsonObject controlCenter: JsonObject {
        property bool showMedia: true
        property bool showHardware: true
    }
    property JsonObject keybinds: JsonObject {
        // id -> { keys: "SUPER + K" ("" = turned off), label, group, def } (Settings > Keyboard Shortcuts)
        property var overrides: ({})
    }
    property JsonObject weather: JsonObject {
        property string city: "Belgrade"
        property real latitude: 44.82
        property real longitude: 20.46
    }
}
