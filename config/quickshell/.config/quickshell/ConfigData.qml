import Quickshell.Io

// Defaults for every desktop option (Config.qml). A key missing from settings.json takes the
// value here; Reset in the Settings app copies these back.
JsonAdapter {
    property int version: 3                     // settings format; Config.repair() upgrades older files
    property JsonObject appearance: JsonObject {
        property string theme: "reactor"         // the whole desktop design (Themes.qml): layout, type, shape, colour, motion
        property var userThemes: ({})           // your own themes (Theme builder): { "custom-name": { name, base, ...parts } }
        property string mode: "theme"           // theme (each theme's own) | light | dark: every theme has both halves (Themes.qml alt)
        property var custom: ({})               // your adjustments per theme: { pebble: { accent: "#ff9e7a", radius: 12, ... } } (Themes.adjustable)
        property bool terminal: true            // Ghostty follows the theme (ThemeSync writes ghostty/theme.conf)
        property bool wallpaper: true           // the theme's own wallpaper; off = keep yours (Settings > Wallpaper)
        property bool wallpaperColours: false   // the accents follow your own wallpaper (WallpaperColours.qml); off = the theme's own
        property real fontScale: 1
        property string motion: "full"          // full (the theme's own motion) | reduced (short fades, nothing moves) | off
        property string iconTheme: "Papirus-Dark"
        property bool monoTray: true            // tray icons in the bar's ink (off: the apps' own colours)
        property string cursorTheme: "default"   // a folder in ~/.local/share/icons, ~/.icons or /usr/share/icons; "default" = the system's cursor
        property int cursorSize: 24
    }
    property JsonObject dock: JsonObject {
        property bool enabled: true             // every theme has a dock; off hides it everywhere
        property string size: "regular"         // compact | regular | roomy: the padding around the icons
        property list<string> hiddenOn: []      // monitor names (e.g. "eDP-1") without a dock
        property int iconSize: 44
        property bool autoHide: false           // visible by default; true slides it away until the pointer reaches its edge
        property bool showRunning: true
        property string barLabels: "icon"       // open windows in the dock inside the bar: icon | name (app name) | title (window title)
        property bool combine: false            // like Windows' "combine taskbar buttons": open apps share their icon
        property bool previews: true            // combined: hover an open app for a picture of each window
        property bool thumbnails: true          // off: open windows show only their app icon
        property int thumbRefresh: 60           // s between still pictures (live only while hovered)
        property list<string> widgets: []       // small tiles after the open windows, in order: ids of Theme.dockWidgets (clock, date, weather, media, …)
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
    property JsonObject osd: JsonObject {   // the pop-up that confirms volume, brightness, mic, layout and caps lock changes
        property int timeoutMs: 1400
        property bool volume: true
        property bool brightness: true
        property bool micMute: true
        property bool layout: true
        property bool capsLock: true            // polls the keyboard's caps lock light every 500 ms while on (if it has one)
        property string position: "bottom"      // bottom | top | center
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
        property bool welcomed: false            // the first-login hint has been shown (shell.qml)
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
        // where the bar goes, its size, shape and items are set per theme (Config.appearance.custom, Themes.resolve)
        property int margin: 8                  // gap around a floating bar, px
        property list<string> hiddenOn: []      // monitor names (e.g. "eDP-1") without a bar
        // clock and title
        property bool clock24: true
        property bool seconds: false
        property string date: "full"            // "full" (Fri 30 Oct), "short" (30 Oct) or "none"
        property string batteryPercent: "beside"  // the battery's percentage: inside (the icon) | beside | off
        property bool windowTitle: true          // the focused window's title after the app name
        // your settings per item, over its bar/items/<id>/defaults.json. Every item understands: enabled, icon,
        // format, click, rightClick, scroll, tooltip, warn, critical, interval (docs/bar.md). Example:
        //   { "weather": { "click": "panel:calendar" }, "brightness": { "enabled": false } }
        property var items: ({})
        // which items the bar holds: "theme" = the theme's own layout (Settings > Menu Bar, per theme); any other
        // value names an entry of `presets`. A screen listed in `monitors` uses its own preset instead.
        property string preset: "theme"
        // name -> { start: ["controls", ids], center: [ids], end: [ids] }. These four ship with the desktop; repair() puts
        // back any that an older settings.json lacks (it never overwrites one you changed).
        property var presets: ({
            minimal: { start: ["controls", "launcher", "workspaces"], center: ["clock"], end: ["status", "battery", "power"] },
            full: { start: ["controls", "launcher", "workspaces", "window"], center: ["clock", "date", "weather"],
                    end: ["sysinfo", "media", "tray", "keyboard", "notifications", "status", "battery", "power"] },
            laptop: { start: ["controls", "launcher", "workspaces"], center: ["clock"],
                      end: ["sysinfo", "brightness", "power-profile", "keyboard", "notifications", "status", "battery"] },
            external: { start: ["controls", "launcher", "workspaces", "window"], center: ["clock", "date"],
                        end: ["sysinfo", "weather", "media", "tray", "notifications", "status", "power"] }
        })
        property var monitors: ({})             // screen name (e.g. "eDP-1") -> preset name; unlisted or "" follows `preset`
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
    // Hyprland-side settings: Settings edits these; SettingsSync.qml writes the files Hyprland, hypridle and
    // monswitch read from them. imported: the values were read once from the file written before (no loss).
    property JsonObject idle: JsonObject {
        property int lockMin: 5                  // minutes to lock; 0 = never
        property int sleepMin: 20                // minutes to sleep on battery (the only value used without a battery counts as sleepOnPowerMin); 0 = never
        property int sleepOnPowerMin: 0          // minutes to sleep on mains power; 0 = never
        property bool imported: false
    }
    property JsonObject input: JsonObject {
        property var layouts: [{ code: "us", variant: "" }]   // xkb layouts, the first is the default (max 4)
        property int shortcut: 3                 // extra layout switch: 0 Alt+Shift, 1 Ctrl+Shift, 2 Caps Lock, 3 none (Super+Ctrl+Space always works)
        property int repeatRate: 25              // keys per second while held
        property int repeatDelay: 600            // ms before a held key repeats
        property real sensitivity: 0             // pointer speed, -1..1
        property bool naturalScroll: true
        property bool tapToClick: true
        property bool disableWhileTyping: true   // touchpad ignores the palm while typing
        property string clickMethod: "clickfinger"   // "clickfinger" (1, 2, 3 fingers = left, right, middle) or "buttonareas" (bottom corners)
        property real scrollFactor: 1.0          // touchpad scroll speed, 0.2..3
        property bool middleEmulation: false     // left + right together = middle click
        property bool dragLock: false            // lift the finger mid-drag without dropping the item
        property bool imported: false
    }
    property JsonObject displays: JsonObject {
        property var layout: ({})                // output -> { mode, position, scale, transform, vrr, bitdepth, mirror, disabled }
        property bool autoHdr: false             // switch a screen's colour space on fullscreen video (HDR screens)
        property bool sendContentType: false     // tell the screen what is playing (some screens blank briefly when it changes)
        property bool xwaylandNativeScale: true  // old X11 apps draw sharp but small, instead of stretched
        property string vrr: "off"               // adaptive sync: off | on | fullscreen
        property bool preferHighRefresh: true    // new screens start at their highest refresh rate
        property string newScreen: "right"       // a screen with no saved layout: right | left | above | below (of the others) | mirror
        property bool imported: false
    }
    property JsonObject workspaces: JsonObject {   // Settings > Displays > Workspaces (SettingsSync writes hypr/settings/workspaces.lua)
        property string mode: "dynamic"          // dynamic: made when needed on the screen you're on | fixed: always there, each on its screen
        property int count: 10                   // fixed: how many (Super+1..0 reach the first ten)
        property var screens: ({})               // fixed: workspace number -> output name; missing = the screen you're on
    }
    property JsonObject apps: JsonObject {
        property string terminal: "ghostty +new-window"   // command the terminal key runs (SettingsSync writes hypr/settings/apps.lua)
    }
    property JsonObject monitorShare: JsonObject {   // a monitor shared with another computer (~/.local/bin/monswitch)
        property bool enabled: false
        property string output: ""               // Hyprland output name, e.g. HDMI-A-1
        property string thisInput: "0x11"        // DDC input (VCP 0x60) this computer is on
        property string otherInput: "0x12"       // the other computer's input
        property string mirror: ""               // screen it mirrors while away (keeps a signal); empty = this computer's own screen, "none" = no mirror
        property string mirrorMode: ""           // the mode for that mirror, e.g. 1920x1080@60; empty = the screen's own
        property bool imported: false
    }
}
