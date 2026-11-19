pragma Singleton
import Quickshell
import Quickshell.Networking
import QtQuick

// The desktop's own actions, in the shape Actions.qml describes. `group` and `words` are for the launcher (its
// Actions mode lists them by group, in this order); `when` keeps hardware-only ones where the hardware is.
// Ids are saved in settings.json (launcher history, hot corners, Control Center layout, shortcuts): never rename one.
// Built-in commands start detached, like before the registry: most open a picker and wait for you.
Singleton {
    id: root

    function cmd(...argv) { return { type: "command", argv: argv, detach: true } }
    function fn(f) { return { type: "internal", fn: f } }
    function on(f) { return { type: "internal", on: f } }
    // a launcher action: id, group, name, words, icon, run, then anything else (kind, state, when, showIn)
    function a(id, group, name, words, icon, run, extra) {
        return Object.assign({ id: id, group: group, name: name, words: words, icon: icon, kind: "button", run: run, showIn: ["launcher"] }, extra ?? {})
    }
    function toggle(state, extra) { return Object.assign({ kind: "toggle", state: on(state) }, extra ?? {}) }
    readonly property var cc: ["launcher", "controlcenter"]
    readonly property var corner: ["launcher", "corner", "controlcenter"]

    readonly property var system: [
        a("shot", "Screens & capture", "Screenshot an area", "screenshot capture annotate satty", "\u{F0104}", cmd("sh", "-c", "sleep 0.3; screenshot"), { showIn: cc }),
        a("shot-all", "Screens & capture", "Screenshot all screens", "screenshot capture full screen all monitors", "\u{F0104}", cmd("sh", "-c", "sleep 0.3; screenshot all")),
        a("shot-window", "Screens & capture", "Screenshot the focused window", "screenshot capture window", "\u{F0104}", cmd("sh", "-c", "sleep 0.3; screenshot window")),
        a("shot-delay", "Screens & capture", "Screenshot in 5 seconds", "screenshot capture delay timer menu tooltip", "\u{F0104}", cmd("screenshot", "delay", "5")),
        a("shot-pin", "Screens & capture", "Pin an area on screen", "screenshot pin sticky float keep on top", "\u{F0104}", cmd("sh", "-c", "sleep 0.3; screenshot pin")),
        a("shot-unpin", "Screens & capture", "Remove all pinned screenshots", "screenshot pin unpin clear remove close", "\u{F0104}", fn(() => Pins.clear())),
        a("record", "Screens & capture", "Record the screen", "record recording video screencast capture", "\u{F044A}", cmd("sh", "-c", "sleep 0.3; record"), { when: { recording: false } }),
        a("record-area", "Screens & capture", "Record an area", "record recording video screencast capture region", "\u{F044A}", cmd("sh", "-c", "sleep 0.3; record area"), { when: { recording: false } }),
        a("record-stop", "Screens & capture", "Stop recording", "record recording video stop end save", "\u{F044A}", cmd("record", "stop"), { when: { recording: true } }),
        a("ocr", "Screens & capture", "Copy text from screen", "ocr text recognise recognize screenshot", "\u{F0A3B}", cmd("sh", "-c", "sleep 0.3; screentext"), { showIn: cc }),
        a("picker", "Screens & capture", "Pick a colour", "colour color picker", "\u{F0266}", cmd("sh", "-c", "sleep 0.3; hyprpicker -a"), { showIn: cc }),
        a("overview", "Screens & capture", "Mission Control", "overview windows workspaces mission control expose", "\u{F0570}", fn(() => MissionControl.toggle()), { showIn: corner }),
        a("nightlight", "Screens & capture", "Night Light", "night light warm blue filter eyes evening", "\u{F0599}", fn(() => NightLight.toggle()), toggle(() => NightLight.active, { showIn: cc })),
        a("displays", "Screens & capture", "Displays", "displays screens monitor resolution scale rotate", "\u{F0379}", fn(() => SettingsApp.show("displays"))),
        a("monswitch", "Screens & capture", "Hand the shared monitor over / back", "monitor switch pc input shared kvm", "\u{F0379}", cmd("monswitch", "toggle"),
          toggle(() => ControlCenter.monitorHere, { when: { hardware: "monitorSwitch" }, showIn: cc })),
        a("wifi", "Network & sound", "Wi-Fi", "wifi wi-fi network internet connect wireless", "\u{F05A9}", fn(() => ControlCenter.showSection("wifi")), { when: { hardware: "wifi" } }),
        a("bluetooth", "Network & sound", "Bluetooth", "bluetooth pair headphones devices", "\u{F00AF}", fn(() => ControlCenter.showSection("bt")), { when: { hardware: "bluetooth" } }),
        a("sound-out", "Network & sound", "Sound output", "sound audio output speakers headphones volume", "\u{F057E}", fn(() => ControlCenter.showSection("out"))),
        a("sound-in", "Network & sound", "Sound input", "sound audio input microphone mic", "\u{F036C}", fn(() => ControlCenter.showSection("in"))),
        a("wifi-settings", "Network & sound", "Wi-Fi settings", "wifi wi-fi network settings", "\u{F05A9}", fn(() => SettingsApp.show("network")), { when: { hardware: "wifi" } }),
        a("bluetooth-settings", "Network & sound", "Bluetooth settings", "bluetooth settings", "\u{F00AF}", fn(() => SettingsApp.show("bluetooth")), { when: { hardware: "bluetooth" } }),
        a("sound-settings", "Network & sound", "Sound settings", "sound audio settings volume", "\u{F057E}", fn(() => SettingsApp.show("sound"))),
        a("phone", "Phone", "Phone", "phone kde connect kdeconnect mobile android battery", "\u{F011C}",
          fn(() => ControlCenter.open ? ControlCenter.view.toggleExpanded("phone") : ControlCenter.showSection("phone")), toggle(() => Phone.ready, { showIn: cc })),
        a("phone-ring", "Phone", "Ring my phone", "phone find ring lost locate kde connect", "\u{F009E}", fn(() => Phone.ring()), { when: { hardware: "phone" } }),
        a("phone-send", "Phone", "Send files to my phone", "phone send share file transfer kde connect", "\u{F048A}", fn(() => Phone.pick()), { when: { hardware: "phone" } }),
        a("phone-settings", "Phone", "Phone settings", "phone kde connect pair settings", "\u{F011C}", fn(() => SettingsApp.show("phone"))),
        a("clipboard", "System", "Clipboard history", "clipboard paste history", "\u{F014C}", fn(() => Clipboard.toggle()), { showIn: cc }),
        a("keys", "System", "Keyboard shortcuts", "shortcuts keys keybinds hotkeys cheat sheet cheatsheet help", "\u{F0313}", fn(() => Cheatsheet.show())),
        a("focus", "Focus", "Focus", "focus mode work concentrate quiet do not disturb", "\u{F0594}", fn(() => Focus.toggle()),
          toggle(() => Focus.mode !== null || Notifications.dnd, { showIn: cc })),
        a("focus-settings", "Focus", "Focus settings", "focus modes schedule edit settings", "\u{F0594}", fn(() => SettingsApp.show("focus"))),
        a("dnd", "System", "Do Not Disturb", "dnd quiet silence notifications mute", "\u{F009B}", fn(() => Notifications.toggleDnd()), toggle(() => Notifications.dnd, { showIn: cc })),
        a("caffeine", "System", "Caffeine: keep awake", "caffeine awake inhibit sleep coffee", "\u{F0176}", fn(() => Caffeine.toggle()), toggle(() => Caffeine.active, { showIn: cc })),
        a("welcome", "System", "Welcome", "welcome first start tour intro help getting started", "\u{F02FD}", fn(() => Welcome.show())),
        a("update", "System", "Update the system and Hyprism", "update upgrade install packages hyprism system", "\u{F02FD}", fn(() => root.inRepo("./install.sh update"))),
        a("doctor", "System", "Check this computer (doctor)", "doctor check health diagnose problems repair", "\u{F02FD}", fn(() => root.inRepo("./install.sh doctor"))),
        a("rog", "System", "ROG Control Center", "rog asus fans gpu", "\u{F0493}", cmd("rog-control-center"), { when: { hardware: "asus" } }),
        a("lock", "Power", "Lock screen", "lock", "\u{F033E}", cmd("loginctl", "lock-session"), { showIn: ["launcher", "corner"] }),
        a("suspend", "Power", "Sleep", "suspend sleep", "\u{F04B2}", cmd("systemctl", "suspend")),
        a("hibernate", "Power", "Hibernate", "hibernate", "\u{F0717}", cmd("systemctl", "hibernate"), { when: { hardware: "canHibernate" } }),
        a("logout", "Power", "Log out", "logout log out exit", "\u{F0343}", cmd("hyprshutdown")),
        a("reboot", "Power", "Restart", "restart reboot", "\u{F0709}", cmd("systemctl", "reboot")),
        a("poweroff", "Power", "Shut down", "shutdown shut down power off", "\u{F0425}", cmd("systemctl", "poweroff")),
        a("powermenu", "Power", "Power menu", "power menu shutdown restart log out sleep", "\u{F0425}", fn(() => PowerMenu.show())),
    ]

    // Control Center tiles that aren't launcher actions (Control Center keeps how each one looks)
    function tile(id, name, icon, run, extra) { return Object.assign({ id: id, name: name, icon: icon, kind: "button", run: run, showIn: ["controlcenter"] }, extra ?? {}) }
    readonly property var tiles: [
        tile("wifi-toggle", "Wi-Fi on / off", "\u{F05A9}", fn(() => { Networking.wifiEnabled = !Networking.wifiEnabled }), toggle(() => Networking.wifiEnabled, { when: { hardware: "wifi" } })),
        tile("bt", "Bluetooth on / off", "\u{F00AF}", fn(() => { if (Sys.adapter) Sys.adapter.enabled = !Sys.adapter.enabled }), toggle(() => Sys.adapter?.enabled ?? false, { when: { hardware: "bluetooth" } })),
        tile("record-toggle", "Record the screen under the mouse", "\u{F044A}",
             fn(() => { if (!Sys.recording) ControlCenter.hide(); Quickshell.execDetached(["sh", "-c", "sleep 0.3; record " + (Sys.recording ? "stop" : "screen")]) }),
             toggle(() => Sys.recording)),
        tile("darkmode", "Dark mode", "\u{F050E}", fn(() => Config.set("appearance", "mode", Theme.light ? "dark" : "light")), toggle(() => !Theme.light)),
        tile("floatall", "New windows floating or tiled", "\u{F05B2}", fn(() => Config.set("windows", "floatAll", !Config.windows.floatAll)),
             toggle(() => Config.windows.floatAll)),
        tile("micmute", "Microphone on / off", "\u{F036C}", fn(() => { if (Sys.source?.audio) Sys.source.audio.muted = !Sys.source.audio.muted }),
             toggle(() => !(Sys.source?.audio?.muted ?? true), { when: { hardware: "mic" } })),
        tile("airplane", "Airplane mode", "\u{F001D}", fn(() => { const on = ControlCenter.airplane; Networking.wifiEnabled = on; if (Sys.adapter) Sys.adapter.enabled = on }),
             toggle(() => ControlCenter.airplane, { when: { hardware: "wifi" } })),
        tile("keylight", "Keyboard light: next level", "\u{F0E5B}", fn(() => ControlCenter.setKbd((ControlCenter.kbdLight + 1) % 4)),
             toggle(() => ControlCenter.kbdLight > 0, { when: { hardware: "keylight" } })),
        tile("keyboard", "On-screen keyboard", "\u{F030C}", fn(() => Osk.toggle()), toggle(() => Osk.visible, { when: { hardware: "osk" } })),
        tile("touchpad", "Touchpad on / off", "\u{F0E40}", fn(() => Inputs.setTouchpad(!Inputs.touchpad)), toggle(() => Inputs.touchpad, { when: { hardware: "touchpad" } })),
        tile("touchscreen", "Touchscreen on / off", "\u{F0741}", fn(() => Inputs.setTouchscreen(!Inputs.touchscreen)), toggle(() => Inputs.touchscreen, { when: { hardware: "touchscreen" } })),
        tile("emoji", "Emoji picker", "\u{F0785}", cmd("sh", "-c", "sleep 0.3; emojipick")),
    ]

    // Panels and flyouts a bar click can open (BarActions' old "panel:<name>")
    function panel(name, label, icon, f, extra) { return Object.assign({ id: "panel-" + name, name: label, icon: icon, kind: "button", run: fn(f), showIn: ["bar"] }, extra ?? {}) }
    readonly property var panels: [
        panel("controlcenter", "Control Center", "\u{F0493}", () => ControlCenter.toggle(), { showIn: ["bar", "corner"] }),
        panel("launcher", "Spotlight", "\u{F0349}", () => Launcher.toggle(), { showIn: ["bar", "corner"] }),
        panel("notifications", "Notifications", "\u{F009A}", () => NotificationCenter.toggle(), { showIn: ["bar", "corner"] }),
        panel("calendar", "Calendar", "\u{F00ED}", () => Calendar.toggle()),
        panel("weather", "Weather", "\u{F0595}", () => Weather.toggle()),
        panel("system", "System monitor", "\u{F035B}", () => Sensors.toggle()),
        panel("power", "Power menu", "\u{F0425}", () => PowerMenu.toggle()),
        panel("clipboard", "Clipboard", "\u{F014C}", () => Clipboard.toggle()),
        panel("cheatsheet", "Shortcut list", "\u{F0313}", () => Cheatsheet.toggle()),
        panel("volume", "Volume", "\u{F057E}", () => Flyouts.toggle("volume")),
        panel("network", "Network", "\u{F05A9}", () => Flyouts.toggle("network")),
        panel("bluetooth", "Bluetooth", "\u{F00AF}", () => Flyouts.toggle("bluetooth")),
        panel("brightness", "Brightness", "\u{F00DF}", () => Flyouts.toggle("brightness")),
        panel("media", "Media", "\u{F075A}", () => Flyouts.toggle("media")),
        panel("battery", "Battery", "\u{F0079}", () => Flyouts.toggle("battery")),
    ]

    // Appearance: a theme folder is an action the moment it exists; the bar layouts are Config.bar.presets
    readonly property var appearance: {
        const ap = (id, name, words, icon, f) => a(id, "Appearance", name, words, icon, fn(f))
        const out = [ap("themes", "Themes…", "themes appearance look design wallpaper", "\u{F03D8}", () => SettingsApp.show("appearance"))]
        for (const t of Themes.list) out.push(ap("theme-" + t.id, "Theme: " + t.name, "theme look design " + t.id, "\u{F03D8}", () => Config.set("appearance", "theme", t.id)))
        out.push(ap("mode-light", "Light mode", "light mode day bright appearance", "\u{F03D8}", () => Config.set("appearance", "mode", "light")),
                 ap("mode-dark", "Dark mode", "dark mode night appearance", "\u{F03D8}", () => Config.set("appearance", "mode", "dark")),
                 ap("mode-theme", "Theme's own light/dark", "theme default own light dark mode appearance auto", "\u{F03D8}", () => Config.set("appearance", "mode", "theme")),
                 ap("bar-theme", "Bar layout: theme's own", "bar layout menu bar preset theme own default", "\u{F0E7F}", () => Config.set("bar", "preset", "theme")))
        for (const name of Object.keys(Config.bar.presets ?? {}))
            out.push(ap("bar-" + name, "Bar layout: " + name.charAt(0).toUpperCase() + name.slice(1), "bar layout menu bar preset " + name, "\u{F0E7F}", () => Config.set("bar", "preset", name)))
        return out
    }

    // one action per Focus mode (Settings > Focus), and one to turn Focus off
    readonly property var focusModes: Focus.modes.map(m => a("focus-" + m.id, "Focus", "Focus: " + m.name, "focus mode " + m.name.toLowerCase(), m.icon || "\u{F0594}",
                                                              fn(() => Focus.set(m.id)), toggle(() => Config.focus.active === m.id, { off: fn(() => Focus.off()) })))
        .concat([a("focus-off", "Focus", "Focus: off", "focus mode off end stop", "\u{F0594}", fn(() => Focus.off()))])

    readonly property var list: appearance.concat(system, focusModes, tiles, panels)

    // A command from the repo in a terminal that stays open. The shell's files are symlinks into the repo, so
    // the repo is wherever shell.qml really lives (same way as Settings > About).
    function inRepo(c) {
        Quickshell.execDetached(["sh", "-c", "repo=$(git -C \"$(dirname \"$(readlink -f \"$HOME/.config/quickshell/shell.qml\")\")\" rev-parse --show-toplevel) || exit 1; "
            + "exec ghostty +new-window -e sh -c 'cd \"$0\" && $1; echo; read -p \"Press Enter to close\" _' \"$repo\" \"$1\"", "sh", c])
    }
}
