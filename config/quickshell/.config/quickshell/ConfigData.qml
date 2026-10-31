import Quickshell.Io

// Defaults for every desktop option (Config.qml). A key missing from settings.json takes the
// value here; Reset in the Settings app copies these back.
JsonAdapter {
    property JsonObject appearance: JsonObject {
        property string mode: "dark"           // "light", "dark" or "auto" (light from sunrise to sunset)
        property string accent: "theme"         // "theme" (the theme's own), a palette name (Theme.accents) or "custom"
        property string customAccent: "#ff7a59" // used when accent is "custom"
        property string theme: "midnight"       // colour theme (Theme.themes): glass base, text and its own accent
        property bool terminal: true            // Ghostty follows the theme (ThemeSync writes ghostty/theme.conf)
        property real glassOpacity: 0.55        // tint over the blur (0.2 clear .. 0.9 solid)
        property real radiusScale: 1            // 0 square .. 1.5 extra round
        property real fontScale: 1
        property string font: "Inter"
        property bool animations: true
        property string iconTheme: "Papirus-Dark"
        property string cursorTheme: "oreo_white_cursors" // a folder in ~/.local/share/icons, ~/.icons or /usr/share/icons
        property int cursorSize: 24
        property string border: "rainbow"       // focused window border: "rainbow" or "accent"
        property int borderSpin: 60             // seconds x10 per rainbow turn (0 = still)
        property int borderSize: 2              // px
        property int gaps: 10                   // px around windows; between windows it is half
    }
    property JsonObject dock: JsonObject {
        property int iconSize: 44
        property bool autoHide: true
        property bool showRunning: true
        property bool thumbnails: true          // off: open windows show only their app icon
        property int thumbRefresh: 60           // s between still pictures (live only while hovered)
        property list<string> pinned: ["firefox", "google-chrome", "com.microsoft.VSCode", "com.mitchellh.ghostty", "org.kde.dolphin"]
    }
    property JsonObject launcher: JsonObject {
        property string webSearch: "https://duckduckgo.com/?q=%s"
        property bool showFiles: true
        // [{ name, kind: "command"|"terminal"|"open"|"snippet", value, confirm }]
        property list<var> actions: []
        property var usage: ({})                // launch counts, for ranking
        property string placement: "center"     // center | cursor
        property string startView: "home"       // home (suggestions until you type) | apps (grid) | search (empty pill)
        property list<string> recent: []        // result keys, most recent first, for the home view
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
        property string sound: "message-new-instant"   // a freedesktop sound name (Notifications.sounds), "" = none
        property int volume: 60                          // %
        property string position: "top-right"            // where popups appear: top-right, top-center, top-left
        property list<string> mutedApps: []              // app names that only go to the notification centre
    }
    property JsonObject caffeine: JsonObject {
        property int defaultMinutes: 0          // 0 = until turned off
        // the current state, so Caffeine stays on (or off) across shell reloads, logouts and reboots
        property bool on: false
        property int minutes: 0                 // length of the current run, 0 = until turned off
        property real endsAt: 0                 // ms since epoch, 0 = until turned off
    }
    property JsonObject nightLight: JsonObject {
        property string mode: "off"             // off | on | sun | schedule
        property int temperature: 4000
        property string from: "21:00"
        property string to: "07:00"
    }
    // order of the Control Center's sections and tiles (ControlCenter.defaults lists them; missing ones
    // go at the end) and what's hidden; edited in Settings > Control Center
    property JsonObject controlCenter: JsonObject {
        property bool showHardware: true
        property bool slidersOpen: true
        property list<string> sections: []
        property list<string> tiles: []
        property list<string> toggles: []
        property list<string> shortcuts: []
        property list<string> hidden: ["darkmode", "colorpicker", "mission"]
    }
    property JsonObject keybinds: JsonObject {
        // id -> { keys: "SUPER + K" ("" = turned off), label, group, def } (Settings > Keyboard Shortcuts)
        property var overrides: ({})
    }
    property JsonObject weather: JsonObject {
        property string city: "Belgrade"
        property real latitude: 44.82
        property real longitude: 20.46
        property int days: 7                     // forecast days in the weather dropdown
        property bool showHourly: true           // next 12 hours strip
        property bool showDetails: true          // feels like, humidity, wind, UV, sunrise/sunset
        property string units: "celsius"         // "celsius" (km/h) or "fahrenheit" (mph)
    }
    property JsonObject system: JsonObject {
        property string taskManager: "auto"      // desktop id, or "auto": first installed (Sensors.taskManagers)
    }
    property JsonObject calendar: JsonObject {
        property bool holidays: true            // public holidays (date.nager.at, cached per year)
        property string country: "RS"           // ISO country code for holidays
        property bool localNames: false         // holiday names in the country's language
        property bool observances: true         // worldwide days: New Year, Earth Day, …
        property bool moon: false               // new / full moon and quarters
        property bool weekNumbers: false
        property string firstDay: "monday"      // monday | sunday
    }
    property JsonObject language: JsonObject {
        property list<string> languages: ["en_US"]   // glibc locale ids; the first is the apps' language, the rest fallbacks
        property string formats: ""                  // locale id for dates, numbers, units; "" = the first language
    }
    property JsonObject startup: JsonObject {
        property list<string> apps: []           // desktop entry ids opened at login (startup-apps)
    }
    property JsonObject bar: JsonObject {
        property bool clock24: true
        property bool seconds: false
        property string date: "full"            // "full" (Fri 30 Oct), "short" (30 Oct) or "none"
        property bool batteryPercent: true
        property bool windowTitle: true          // the focused window's title after the app name
        // what each part of the bar shows, in order (all items: Bar.qml's widgets)
        property list<string> left: ["logo", "desktops", "app"]
        property list<string> center: ["weather", "clock"]
        property list<string> right: ["tray", "temperatures", "keyboard", "status", "notifications"]
    }
    property JsonObject battery: JsonObject {
        property bool warn: true                 // a notification when the battery runs low
        property int warnAt: 15                  // %
        property int criticalAt: 5               // %, a critical notification that stays
    }
    // what pushing the pointer into a screen corner does: HotCorners.actions ("" = nothing)
    property JsonObject hotCorners: JsonObject {
        property string topLeft: ""
        property string topRight: ""
        property string bottomLeft: ""
        property string bottomRight: ""
    }
    property JsonObject wallpaper: JsonObject {
        property list<string> folders: ["~/Pictures/Wallpapers"]
        property string current: ""             // full path; empty = whatever hypr/settings/wallpaper points at
        property bool slideshow: false
        property int interval: 30                // minutes between slideshow changes
        property string source: "all"            // "all": every image in the folders, "selected": only picked ones
        property list<string> selected: []       // full paths for source "selected"
        property string order: "shuffle"         // "shuffle" or "name"
    }
}
