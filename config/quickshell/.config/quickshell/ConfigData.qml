import Quickshell.Io

// Defaults for every desktop option (Config.qml). A key missing from settings.json takes the
// value here; Reset in the Settings app copies these back.
JsonAdapter {
    property JsonObject appearance: JsonObject {
        property string theme: "pebble"          // the whole desktop design (Themes.qml): layout, type, shape, colour, motion
        property var custom: ({})               // your adjustments per theme: { pebble: { accent: "#ff9e7a", radius: 12, ... } } (Themes.adjustable)
        property bool terminal: true            // Ghostty follows the theme (ThemeSync writes ghostty/theme.conf)
        property bool wallpaper: true           // the theme's own wallpaper; off = keep yours (Settings > Wallpaper)
        property real fontScale: 1
        property string motion: "full"          // full (the theme's own motion) | reduced (short fades, nothing moves) | off
        property string iconTheme: "Papirus-Dark"
        property string cursorTheme: "default"   // a folder in ~/.local/share/icons, ~/.icons or /usr/share/icons; "default" = the system's cursor
        property int cursorSize: 24
    }
    property JsonObject dock: JsonObject {
        property bool enabled: true             // every theme has a dock; off hides it everywhere
        property string position: "bottom"      // bottom | left | right | top (stacks beside the bar if they share an edge)
        property string size: "regular"         // compact | regular | roomy: the padding around the icons
        property list<string> hiddenOn: []      // monitor names (e.g. "eDP-1") without a dock
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
        // look (Search & Widgets > Spotlight)
        property int columns: 7                 // apps per row in the apps grid
        property string startView: "theme"       // theme (the theme's own) | home (suggestions until you type) | apps (grid) | search (empty pill)
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
        property string style: "panel"          // panel (current), compact (denser), borderless (flat tiles, no outlines)
        property int width: 330                 // panel width in px (280..460)
        property list<string> sections: []
        property list<string> tiles: []
        property list<string> toggles: []
        property list<string> shortcuts: []
        property list<string> hidden: ["colorpicker", "mission"]
    }
    // Lock screen: LockScreen.qml lays it out, ThemeSync writes it to hypr/settings/hyprlock-theme.conf
    property JsonObject lockscreen: JsonObject {
        property string clock: "theme"          // theme | big | stacked | terminal | readout | small
        property string position: "theme"       // theme | center | top | bottom | left
        property bool date: true
        property bool greeting: false           // "Welcome back, <name>" above the clock
        property string avatar: ""              // a picture of you (path), "" = none
        property list<string> widgets: ["battery", "layout"]   // battery, layout (in the password field), media
        property string wallpaper: ""           // full path; empty = the desktop wallpaper
        property int blur: 3                    // blur passes, 0 = sharp
        property real brightness: 0.72
    }
    // Window behaviour, animations and per-app rules: ThemeSync writes them to hypr/settings/windows.lua
    // (hypr/modules/windows.lua has the same defaults)
    property JsonObject windows: JsonObject {
        property string layout: "dwindle"       // "dwindle" (split), "master" (main + stack) or "scrolling"
        property int newSplit: 0                // dwindle: 0 where the mouse is, 1 left/top, 2 right/bottom
        property bool smartSplit: false         // dwindle: split by where in the window the mouse is
        property string masterNew: "slave"      // master: new windows join the stack ("slave") or become main
        property string masterSide: "left"      // master: where the main window sits
        property real columnWidth: 0.5          // scrolling: share of the screen per column
        property bool followMouse: true
        property bool focusOnActivate: false    // apps may bring themselves to the front
        property bool warpCursor: true          // pointer jumps to the window focused from the keyboard
        property bool backAndForth: false       // the current desktop's shortcut goes back to the last one
        property real inactiveOpacity: 0.96
        property bool dimInactive: false
        property real dimStrength: 0.2
        property bool resizeOnBorder: true
        property bool snap: false               // floating windows snap to edges and each other
        property bool hideCursorTyping: false
        property bool titleBars: true           // hyprbars: title bar with buttons on apps that draw none
        property var apps: []                   // [{ id, name, class (regex), open: normal|float|pin|maximize|fullscreen, workspace: 0 = any }]
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
        // place and shape: "theme" (or 0) keeps the active theme's own (Themes.qml bar)
        property string position: "theme"       // theme | top | bottom | left | right
        property int size: 0                    // px across the bar, 0 = the theme's
        property string floating: "theme"       // theme | floating (away from the screen edges) | attached
        property int margin: 8                  // gap around a floating bar, px
        property list<string> hiddenOn: []      // monitor names (e.g. "eDP-1") without a bar
        // the items (BarWidget.qml ids) in each section; custom = false uses the theme's own
        property bool custom: false
        property list<string> start: []
        property list<string> center: []
        property list<string> end: []
        // clock and title
        property bool clock24: true
        property bool seconds: false
        property string date: "full"            // "full" (Fri 30 Oct), "short" (30 Oct) or "none"
        property bool windowTitle: true          // the focused window's title after the app name
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
        property int blur: 0                     // desktop only (a blurred copy in ~/.cache); 0 = sharp
    }
}
