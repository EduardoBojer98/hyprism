import Quickshell.Io

// Defaults for every desktop option (Config.qml). A key missing from settings.json takes the
// value here; Reset in the Settings app copies these back.
JsonAdapter {
    property int version: 8                     // settings format; Config.repair() upgrades older files
    property JsonObject appearance: JsonObject {
        property string theme: "pebble"         // the whole desktop design (Themes.qml): layout, type, shape, colour, motion
        property string mode: "theme"           // theme (each theme's own) | light | dark | wallpaper | mixed: every theme has both halves (Themes.qml alt)
        property string desktopMode: "dark"     // mode "mixed": the bar, dock, panels, lock screen and window frames
        property string appMode: "light"        // mode "mixed": apps (GTK, Qt, KDE, the terminal) and their title bars
        property var custom: ({})               // your adjustments per theme: { pebble: { accent: "#ff9e7a", radius: 12, ... } } (Themes.adjustable)
        property bool terminal: true            // Ghostty follows the theme (ThemeSync writes ghostty/theme.conf)
        property bool wallpaper: true           // the theme's own wallpaper; off = keep yours (Settings > Wallpaper)
        property bool wallpaperColours: false   // the accents follow your own wallpaper (WallpaperColours.qml); off = the theme's own
        property real fontScale: 1
        property string motion: "full"          // full (the theme's own motion) | reduced (short fades, nothing moves) | off
        property string motionStyle: "theme"    // the motion look (Theme.qml looks): theme (its own) | smooth | snappy | springy | minimal
        property string iconTheme: "theme"      // theme (the theme's own) | a folder in ~/.local/share/icons or /usr/share/icons
        property bool monoTray: true            // tray icons in the bar's ink (off: the apps' own colours)
        property string cursorTheme: "theme"     // theme (the theme's own) | a folder in ~/.local/share/icons, ~/.icons or /usr/share/icons | default (the system's)
        property int cursorSize: 24
    }
    // Ghostty and fish: ThemeSync writes ghostty/theme.conf (live) and hyprism/fish.fish (new shells); theme = the theme's term look
    property JsonObject terminal: JsonObject {
        property string cursor: "theme"         // theme | block | bar | underline | block_hollow
        property string blink: "theme"          // theme | on | off
        property string opacity: "theme"        // theme (see-through in glass themes) | solid | soft | clear
        property string padding: "theme"        // theme | tight | normal | roomy
        property bool trail: false              // cursor animation shaders (ghostty/shaders/): a smear per jump, then the typing effect; full motion, on AC only
        property string typing: "pulse"         // typing effect: pulse | sparks | ghost | ripple | none (hyprism-type-NAME.glsl)
        property bool transientPrompt: false    // starship's transient prompt: past prompts shrink to one symbol
        property string greeting: "default"     // default (the distro's) | off | fastfetch | pokemon (a random one as fastfetch's logo) | bonsai (cbonsai + fortune)
    }
    property JsonObject dock: JsonObject {
        property bool enabled: true             // every theme has a dock; off hides it everywhere
        property string size: "regular"         // compact | regular | roomy: the padding around the icons
        property list<string> hiddenOn: []      // monitor names (e.g. "eDP-1") without a dock
        property int iconSize: 44               // the dock's size: Settings presets 36 / 44 / 52 / 60, or any size 24-72 on its slider
        property bool autoHide: false           // visible by default; true slides it away until the pointer reaches its edge
        property bool showRunning: true
        property string barLabels: "icon"       // open windows in the dock inside the bar: icon | name (app name) | title (window title)
        property bool nameOnly: false           // open windows show just their app's name, no icon, picture or title (dock and bar)
        property bool combine: false            // like Windows' "combine taskbar buttons": open apps share their icon
        property bool previews: true            // combined: hover an open app for a picture of each window
        property bool thumbnails: true          // off: open windows show only their app icon
        property int thumbRefresh: 60           // s between still pictures (live only while hovered)
        property list<string> widgets: []       // small tiles after the open windows, in order: ids of Theme.dockWidgets (clock, date, weather, media, …)
        property list<string> pinned: ["firefox", "google-chrome", "com.microsoft.VSCode", "com.mitchellh.ghostty", "org.gnome.Nautilus"]
    }
    property JsonObject missionControl: JsonObject {
        property string screens: "all"          // all: every screen's workspaces, grouped by screen | this: only the screen it opens on
        property string click: "switch"         // a workspace clicked: switch (go there and close) | browse (show its windows first)
        property bool newTile: true             // the "New workspace" tile at the end of the row
        property string size: "medium"          // small | medium | large workspace pictures
    }
    property JsonObject launcher: JsonObject {
        property string webSearch: "https://duckduckgo.com/?q=%s"
        property bool showFiles: true
        property var usage: ({})                // launch counts, for ranking
        // look (Search & Launcher > Style)
        property string style: "theme"          // theme (the theme's own) | spotlight | launchpad | drawer | sidebar | terminal (Launcher.qml styles)
        property int columns: 7                 // apps per row in the apps grid (fewer when the panel is too narrow)
        property string startView: "theme"      // theme (the style's own) | home (suggestions until you type) | apps (grid) | search (empty field)
        property list<string> recent: []        // result keys, most recent first, for the home view
        // result groups, best first; a group missing from the list is hidden
        property list<string> order: ["apps", "files", "calc", "settings", "actions", "web"]
        property bool clipboardInside: true     // Spotlight's clipboard button shows history in the panel
        property string position: "theme"       // theme (the style's own place) | center (middle of the screen) | pointer (around the mouse pointer)
        // your adjustments over the style (Search & Launcher > Adjust); "style" = what the style does
        property int size: 100                  // percent of the style's width, search height and icons (80..130)
        property string rows: "style"           // style | standard | compact (one line) | cards (tall, big icons) | text (no icons)
        property list<string> home: ["glance", "frequent", "recent", "quick"]   // suggestions allowed: glance (weather, next event, last copy), frequent, recent, quick (actions)
        property string dim: "style"            // style | none | light | dark: the screen behind it
        property string corners: "style"        // style | sharp | soft | round
        property bool hints: true               // the key hints under the results
        property bool subtitles: true           // the second line under a result (path, description)
        property int maxResults: 40             // results listed at most (10..80)
        property list<string> quickActions: ["shot", "ocr", "picker", "overview", "caffeine", "lock"]   // action ids, in order
        property bool quickLook: true           // Space on a file result previews it (QuickLook.qml)
        property bool converters: true          // units, currencies, time zones and dates beside the calculator (Convert.js)
        property var padLayout: []              // Launchpad's order: app ids and folders { name, apps: [ids] }; [] = by name
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
        property int timeoutSec: 6                       // how long a normal popup stays (s)
        property int timeoutLowSec: 4                    // how long a low-priority popup stays (s)
        property int timeoutCriticalSec: 0               // how long a critical popup stays (s); 0 = until dismissed
        property int maxVisible: 4                       // popups on screen at once; the rest wait in the notification centre
        property bool groupByApp: true                   // one popup per app (with a count) and the history grouped by app
        property bool showIcons: true                    // the app's icon or the notification's picture
        property string style: "theme"                   // popup look: theme | card | bubble | line | block | tag | compact
        property string position: "theme"               // theme | top-left | top | top-right | bottom-left | bottom | bottom-right
        property bool dndSchedule: false                 // Do Not Disturb every day between dndFrom and dndTo
        property string dndFrom: "22:00"
        property string dndTo: "07:00"
        property int historyMax: 100
        property string sound: "message-new-instant"   // normal priority: a freedesktop sound name (Notifications.sounds), "" = none
        property string soundLow: ""                     // low priority sound, "" = none
        property string soundCritical: "window-attention"   // critical sound, "" = none
        property int volume: 60                          // %
        property list<string> mutedApps: []              // app names that only go to the notification centre
    }
    property JsonObject osd: JsonObject {   // the pop-up that confirms volume, brightness, mic, layout and caps lock changes
        property int timeoutMs: 1400
        property bool volume: true
        property bool brightness: true
        property bool micMute: true
        property bool layout: true
        property bool capsLock: true            // shows Caps Lock on/off (read from the keyboard light when the key is pressed, if it has one)
        property string position: "bottom"      // bottom | top | center
    }
    property JsonObject caffeine: JsonObject {
        property int defaultMinutes: 0          // 0 = until turned off
        // the current state, so Caffeine stays on (or off) across shell reloads, logouts and reboots
        property bool on: false
        property int minutes: 0                 // length of the current run, 0 = until turned off
        property real endsAt: 0                 // ms since epoch, 0 = until turned off
    }
    // Focus modes (Focus.qml, Settings > Focus): Do Not Disturb with apps let through, a wallpaper, apps to open,
    // Night Light and Caffeine, and a schedule (days 0 = Sunday … 6, from-to). One mode is active at a time.
    property JsonObject focus: JsonObject {
        property var modes: [
            { id: "work", name: "Work", icon: "\u{F00D6}", dnd: true, allow: ["Slack", "Microsoft Teams", "Thunderbird"], wallpaper: "", apps: [],
              nightLight: false, caffeine: false, schedule: { on: false, days: [1, 2, 3, 4, 5], from: "09:00", to: "17:00" } },
            { id: "call", name: "Client call", icon: "\u{F03F2}", dnd: true, allow: [], wallpaper: "", apps: [],
              nightLight: false, caffeine: true, schedule: { on: false, days: [1, 2, 3, 4, 5], from: "10:00", to: "11:00" } },
            { id: "sleep", name: "Sleep", icon: "\u{F02E3}", dnd: true, allow: [], wallpaper: "", apps: [],
              nightLight: true, caffeine: false, schedule: { on: false, days: [0, 1, 2, 3, 4, 5, 6], from: "22:00", to: "07:00" } }
        ]
        property string active: ""              // the mode on now (its id), "" = off
        property string last: "work"            // the one the Focus tile turns back on
        property bool auto: false               // the active mode was turned on by its schedule (and ends with it)
        property var restore: ({})              // what the active mode changed, put back when it ends: { wallpaper, nightLight, caffeine }
    }
    property JsonObject phone: JsonObject {     // phone link through KDE Connect (Phone.qml, Settings > Phone)
        property bool enabled: true             // off: kdeconnectd is stopped and the shell stops asking
        property string device: ""              // the phone's KDE Connect id; "" = the first paired one
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
        property string style: "panel"          // panel (current), compact (denser), borderless (flat tiles, no outlines)
        property int width: 330                 // panel width in px (280..460)
        property list<string> sections: []
        property list<string> tiles: []
        property list<string> sliders: []
        property list<string> toggles: []
        property list<string> folded: ["screen", "sound", "power"]   // cards folded to one line (click a card's title): screen, sound, power
        property list<string> hidden: ["colorpicker", "mission", "airplane", "clipboard", "ocr", "emoji"]
        property var layouts: ({})              // layouts you kept (Settings > Control Center): name -> { style, width, sections, … }
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
        property bool wallpaperColours: false   // its accents come from the picture it shows (WallpaperColours.qml); off = the desktop's
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
        property real inactiveOpacity: 1
        property bool dimInactive: false
        property real dimStrength: 0.2
        property bool resizeOnBorder: true
        property bool snap: false               // floating windows snap to edges and each other
        property bool hideCursorTyping: false
        property bool titleBars: true           // hyprbars: title bar with buttons on apps that draw none
        property string titleBarSize: "theme"   // title bar height: theme (its density) | small | medium | large
        property string titleButtons: "right"   // title bar buttons on the right or left (close outermost)
        property string maxButton: "float"   // title-bar and apps' maximise button: float, maximise a floating window; or fill the screen
        property bool floatAll: false           // new windows open floating instead of tiled
        property bool edgeSnap: true            // a floating window dropped on a screen edge fills that half, a corner a quarter, top: maximised
        property string titleAlign: "center"    // window title in the bar: center | left
        property string border: "theme"         // focused window's frame: theme (its own) | accent | gradient (accent to accent2) | neon (accent with a glow) | mono (text colour) | rainbow | sunset | ocean | custom (borderColors)
        property int borderAngle: 45            // direction of a frame of several colours, in degrees
        property list<string> borderColors: ["#ff7a59", "#7a5cff"]   // custom frame: two or three colours like "#ff7a59"
        property bool borderAnimate: false      // a frame of several colours turns (needs animations on Full; costs battery)
        property int rainbowSpeed: 5            // turning frame: 1 slow .. 10 fast
        property bool rainbowOnBattery: false   // a turning frame keeps turning on battery (it redraws every frame); off = it stands still
        property var apps: []                   // [{ id, name, class (regex), open: normal|float|pin|maximize|fullscreen, workspace: 0 = any }]
    }
    property JsonObject keybinds: JsonObject {
        // id -> { keys: "SUPER + K" ("" = turned off), label, group, def } (Settings > Keyboard Shortcuts)
        property var overrides: ({})
        property var custom: []                 // your shortcuts: [{ keys: "SUPER + D", action: "<action id>" }]; each runs `qs ipc call actions run <id>`
        property var portal: []                 // keys for shortcuts apps ask for through the portal: [{ keys, name: "appid:id", label }]; bound to hl.dsp.global(name)
    }
    // your own buttons and toggles (Settings > Actions, Actions.qml): [{ id, name, icon, kind, run: { type, argv | value }, ... }]
    property JsonObject actions: JsonObject {
        property var list: []                   // shown in Spotlight, bar clicks or hot corners; see docs/decisions/0002-action-registry.md
    }
    property JsonObject weather: JsonObject {
        // saved places, in your order: [{ name, region, country, latitude, longitude }]; Settings > Weather adds them
        // from a search. Empty = the panel asks for a place. Night Light's sunset mode uses the first one.
        property var locations: []             // saved places [{ name, region, country, latitude, longitude }]; the first is the default
        property string units: "celsius"         // "celsius" (km/h) or "fahrenheit" (mph)
        property int days: 7                     // days in the forecast list (0 = no daily list)
        property int hours: 12                   // hours in the hourly strip (0 = no hourly strip)
        property list<string> details: ["feels", "humidity", "wind", "uv", "rain", "sun"]   // readings under the current conditions, in order
        property int refreshMin: 15              // minutes between updates
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
        // clock and title. Each clock on the bar has its own time and date settings (bar.items.<id>, see
        // bar/items/clock/format.js); these two are what a clock uses until it has its own
        property bool clock24: true             // 24-hour time: the lock screen's, and a bar clock's until it has its own h24
        property bool seconds: false            // seconds: the dock clock's hand, and a bar clock's until it has its own
        property string batteryPercent: "beside"  // the battery's percentage: inside (the icon) | beside | off
        property bool windowTitle: true          // the focused window's title after the app name
        // your settings per item, over its bar/items/<id>/defaults.json. Every item understands: enabled, icon,
        // format, click, rightClick, scroll, tooltip, warn, critical, interval (docs/bar.md). A second copy of an item
        // on the bar is "<id>#2" (then #3…) and has its own entry here. Example:
        //   { "weather": { "click": "panel:calendar" }, "brightness": { "enabled": false } }
        property var items: ({})               // item or copy ("clock", "clock#2") -> its settings (docs/bar.md)
        // which items the bar holds: "theme" = the theme's own layout (Settings > Menu Bar, per theme); any other
        // value names an entry of `presets`. A screen listed in `monitors` uses its own preset instead.
        property string preset: "theme"
        // name -> { start: ["controls", ids], center: [ids], end: [ids] }. These four ship with the desktop; repair() puts
        // back any that an older settings.json lacks (it never overwrites one you changed).
        property var presets: ({
            minimal: { start: ["controls", "launcher", "workspaces"], center: ["clock"], end: ["status", "battery", "power"] },
            full: { start: ["controls", "launcher", "workspaces", "window"], center: ["clock", "date", "weather"],
                    end: ["sysinfo", "media", "updates", "tray", "keyboard", "notifications", "status", "battery", "power"] },
            laptop: { start: ["controls", "launcher", "workspaces"], center: ["clock"],
                      end: ["sysinfo", "brightness", "power-profile", "updates", "keyboard", "notifications", "status", "battery"] },
            external: { start: ["controls", "launcher", "workspaces", "window"], center: ["clock", "date"],
                        end: ["sysinfo", "weather", "media", "updates", "tray", "notifications", "status", "power"] }
        })
        // your bar: { edge, size, floating, dock ("bar" or an edge), start, center, end }. Empty = the theme's own;
        // the first change in Settings > Menu Bar copies the theme's into it, and it then stays when you switch theme
        property var layout: ({})
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
        property int blur: 0                     // desktop only (a blurred copy in ~/.cache; for a video its still frame, not the video); 0 = sharp
        property string livePause: "fullscreen"  // a video wallpaper pauses behind "fullscreen" windows or any "windows" on its workspace
        property bool liveOnBattery: false       // a video wallpaper plays on battery too (about doubles idle power); off = paused
        property var screens: ({})               // a screen with its own wallpaper: { "HDMI-A-1": full path }; the rest show current
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
        // every mouse and keyboard, unless an app of its own (Solaar, a vendor tool) sets the device itself
        property bool mouseNaturalScroll: false  // a mouse wheel's direction (the touchpad has its own)
        property real mouseScrollFactor: 1.0     // a mouse wheel's scroll speed, 0.2..3
        property string accelProfile: "adaptive" // "adaptive" (faster moves go further) or "flat" (the same distance at any speed)
        property bool leftHanded: false          // swap the left and right buttons
        property bool mouseByApp: false          // an app (Solaar, Piper, input-remapper) sets the mouse: the four above stay at libinput's defaults
        property bool numlock: false             // Num Lock on when you log in
        property string capsLock: "caps"         // the Caps Lock key: "caps", "escape", "ctrl" or "off"
        property bool swipeInvert: false         // workspace swipes go the other way
        property bool swipeCreate: false         // swiping past the last workspace makes a new one
        property bool swipeForever: false        // one long swipe goes through several workspaces
        property bool imported: false
    }
    property JsonObject touch: JsonObject {     // Settings > Touch & Tablet
        property string output: ""               // the screen the touchscreen and pen belong to; empty = the laptop's own panel
        property bool swipe: false               // three fingers sideways on the screen switch workspaces
        property bool autoRotate: true           // tablet mode turns the screen with the device (~/.local/bin/panel)
        property bool oskInTablet: false         // tablet mode shows the on-screen keyboard
        property bool oskAuto: false             // the on-screen keyboard pops up when a text field is tapped
        property bool oskLayouts: true           // the on-screen keyboard offers your keyboard layouts
    }
    property JsonObject displays: JsonObject {
        property var layout: ({})                // screen (description, or connector when two share one) -> { mode, position, scale, transform, vrr, bitdepth, mirror, disabled }
        property var presets: []                 // saved layouts: [{ id, name, auto, outputs: { screen -> as layout } }]; Settings > Displays > Presets
        property string defaultPreset: ""        // id of the preset the display switcher offers first, and `qs ipc call displays preset` with no name applies
        property bool autoHdr: false             // switch a screen's colour space on fullscreen video (HDR screens)
        property bool sendContentType: false     // tell the screen what is playing (some screens blank briefly when it changes)
        property bool xwaylandNativeScale: true  // old X11 apps draw sharp but small, instead of stretched
        property string vrr: "off"               // adaptive sync: off | on | fullscreen
        property bool preferHighRefresh: true    // new screens start at their highest refresh rate
        property string newScreen: "right"       // a screen with no saved layout: right | left | above | below (of the others) | mirror
        property string main: ""                 // the main screen (key as in layout): notifications, OSD, workspace 1 and the pointer start there; "" = the screen you work on
        property bool barOnMainOnly: false       // the menu bar only on the main screen
        property bool imported: false
    }
    property JsonObject workspaces: JsonObject {   // Settings > Displays > Workspaces (SettingsSync writes hypr/settings/workspaces.lua)
        property string mode: "dynamic"          // dynamic: made when needed on the screen you're on | fixed: always there, each on its screen
        property int count: 10                   // fixed: how many (Super+1..0 reach the first ten)
        property var screens: ({})               // fixed: workspace number -> output name; missing = the screen you're on
    }
    property JsonObject capture: JsonObject {   // screenshots and recordings (~/.local/bin/screenshot, record)
        property string folder: "~/Pictures/Screenshots"
        property string recordFolder: "~/Videos/Recordings"
        property string after: "edit"           // after a region/window/screen capture: edit (annotate in Satty) | copy | save (and copy)
        property int delay: 0                   // seconds before a full-screen capture
        property string audio: "none"           // recordings: none | desktop | mic
        property bool notify: true              // a notification with the picture after each capture
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
        property var more: []                    // up to 3 more monitors switched with it: [{ output, thisInput, otherInput }]
        property bool imported: false
    }
}
