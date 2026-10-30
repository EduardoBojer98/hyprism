pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Search engine behind the launcher. Each provider turns the query into results
//   { key, kind, title, subtitle, icon (theme name) | glyph, score 0..100, run() }
// and `results` merges them, best first. No category has to be picked: "firefox" finds the app,
// "bluetooth" the settings page, "2*21" the calculator, "~/proj" a folder, "> docker ps" a
// command, anything else falls through to a web search. Slow providers (files, qalc) answer
// asynchronously and slot in when ready.
Singleton {
    id: root

    property string query: ""
    property var files: []          // fd results for the current query
    property string calc: ""        // qalc answer for the current query

    readonly property string home: Quickshell.env("HOME")

    // ---- providers -----------------------------------------------------------------------------

    // Match quality of `text` against q (lower case): 0 none .. 1 exact
    function match(text, q, fuzzy) {
        const t = (text || "").toLowerCase()
        if (!t || !q) return 0
        if (t === q) return 1
        if (t.startsWith(q)) return 0.9
        if (t.includes(" " + q) || t.includes("-" + q) || t.includes("." + q)) return 0.75
        if (t.includes(q)) return 0.6
        if (!fuzzy || q.length < 3) return 0
        // initials: "vsc" -> "Visual Studio Code"
        const initials = t.split(/[\s\-_.]+/).map(w => w[0]).join("")
        return initials.startsWith(q) ? 0.5 : 0
    }

    function usageBonus(key) {
        const n = Config.launcher.usage?.[key] ?? 0
        return Math.min(12, Math.log2(n + 1) * 3)
    }

    function remember(key) {
        const u = Object.assign({}, Config.launcher.usage ?? {})
        u[key] = (u[key] ?? 0) + 1
        Config.set("launcher", "usage", u)
    }

    function apps(q) {
        const out = []
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue
            const s = Math.max(match(e.name, q, true),
                               match(e.genericName, q) * 0.8,
                               Math.max(0, ...e.keywords.map(k => match(k, q))) * 0.75,
                               match(e.comment, q) * 0.5,
                               Math.max(0, ...e.categories.map(c => match(c, q))) * 0.5)
            if (s > 0) out.push({ key: "app:" + e.id, kind: "Applications", title: e.name,
                subtitle: e.genericName || e.comment, icon: e.icon, entry: e,
                score: 40 + s * 50 + usageBonus("app:" + e.id), run: () => e.execute() })
        }
        return out
    }

    readonly property var settingsPages: [
        { id: "appearance", name: "Appearance & Themes", words: "theme accent colour color dark glass blur radius font animation" },
        { id: "icons", name: "Icons", words: "icon theme papirus" },
        { id: "dock", name: "Desktop & Dock", words: "dock desktop taskbar minimise minimize" },
        { id: "launcher", name: "Search & Launcher", words: "spotlight search launcher actions snippets shortcuts" },
        { id: "clipboard", name: "Clipboard", words: "clipboard copy paste history" },
        { id: "controlcenter", name: "Control Center", words: "control center quick settings" },
        { id: "notifications", name: "Notifications", words: "notification do not disturb dnd" },
        { id: "displays", name: "Displays", words: "display monitor screen resolution scale rotate night light" },
        { id: "sound", name: "Sound", words: "sound audio volume speaker microphone mic output input" },
        { id: "network", name: "Wi-Fi & Network", words: "wifi wi-fi network internet ethernet vpn" },
        { id: "bluetooth", name: "Bluetooth", words: "bluetooth pair headphones" },
        { id: "input", name: "Keyboard & Touchpad", words: "keyboard touchpad mouse layout repeat scroll" },
        { id: "keybinds", name: "Keyboard Shortcuts", words: "keybinds shortcuts hotkeys keys bindings keyboard" },
        { id: "asus", name: "ASUS Hardware", words: "asus rog fan fans curve power mode quiet balanced performance gpu nvidia temperature" },
        { id: "power", name: "Battery & Power", words: "battery power charge limit health" },
        { id: "wallpaper", name: "Wallpaper", words: "wallpaper background" },
        { id: "idle", name: "Lock & Sleep", words: "lock sleep suspend idle screen off caffeine" },
        { id: "apps", name: "Default Applications", words: "default apps browser mime open with" },
        { id: "about", name: "About", words: "about system version" },
    ]
    function settings(q) {
        const out = []
        for (const p of settingsPages) {
            const s = Math.max(match(p.name, q), ...p.words.split(" ").map(w => match(w, q) * 0.85))
            if (s > 0.5) out.push({ key: "settings:" + p.id, kind: "Settings", title: p.name, subtitle: "Settings",
                glyph: "\u{F0493}", score: 30 + s * 45, run: () => SettingsApp.show(p.id) })
        }
        return out
    }

    readonly property var systemActions: [
        { id: "lock", title: "Lock screen", words: "lock", glyph: "\u{F033E}", cmd: ["loginctl", "lock-session"] },
        { id: "suspend", title: "Sleep", words: "suspend sleep", glyph: "\u{F04B2}", cmd: ["systemctl", "suspend"] },
        { id: "hibernate", title: "Hibernate", words: "hibernate", glyph: "\u{F0717}", cmd: ["systemctl", "hibernate"] },
        { id: "logout", title: "Log out", words: "logout log out exit", glyph: "\u{F0343}", cmd: ["hyprshutdown"] },
        { id: "reboot", title: "Restart", words: "restart reboot", glyph: "\u{F0709}", cmd: ["systemctl", "reboot"] },
        { id: "poweroff", title: "Shut down", words: "shutdown shut down power off", glyph: "\u{F0425}", cmd: ["systemctl", "poweroff"] },
        { id: "monswitch", title: "Hand the Acer to the work PC / back", words: "monitor acer switch pc input", glyph: "\u{F0379}", cmd: ["monswitch", "toggle"] },
        { id: "shot", title: "Screenshot an area", words: "screenshot capture", glyph: "\u{F0104}", cmd: ["sh", "-c", "sleep 0.3; hyprshot -m region -o ~/Pictures/Screenshots"] },
        { id: "ocr", title: "Copy text from screen (OCR)", words: "ocr text recognise recognize screenshot", glyph: "\u{F0A3B}", cmd: ["sh", "-c", "sleep 0.3; screentext"] },
        { id: "picker", title: "Pick a colour", words: "colour color picker", glyph: "\u{F0266}", cmd: ["sh", "-c", "sleep 0.3; hyprpicker -a"] },
        { id: "clipboard", title: "Clipboard history", words: "clipboard paste history", glyph: "\u{F014C}", cmd: ["qs", "ipc", "call", "clipboard", "toggle"] },
        { id: "overview", title: "Mission Control", words: "overview windows workspaces mission control expose", glyph: "\u{F0570}", cmd: ["qs", "ipc", "call", "overview", "toggle"] },
        { id: "caffeine", title: "Caffeine: keep awake", words: "caffeine awake inhibit sleep coffee", glyph: "\u{F0176}", cmd: ["qs", "ipc", "call", "caffeine", "toggle"] },
        { id: "rog", title: "ROG Control Center", words: "rog asus fans gpu", glyph: "\u{F0493}", cmd: ["rog-control-center"] },
    ]
    function actions(q, all) {
        const out = []
        for (const a of systemActions) {
            const s = all ? 0.5 : Math.max(match(a.title, q), ...a.words.split(" ").map(w => match(w, q) * 0.9))
            if (s > 0.5 || all) out.push({ key: "action:" + a.id, kind: "Actions", title: a.title, glyph: a.glyph,
                score: 30 + s * 45 + usageBonus("action:" + a.id), run: () => Quickshell.execDetached(a.cmd) })
        }
        for (const [i, c] of (Config.launcher.actions ?? []).entries()) {
            const s = all ? 0.5 : match(c.name, q)
            if (s > 0.5 || all) out.push({ key: "custom:" + c.name, kind: "Actions", title: c.name,
                subtitle: (c.kind === "snippet" ? "Paste: " : "") + c.value, confirm: c.confirm === true,
                glyph: c.kind === "snippet" ? "\u{F0187}" : c.kind === "open" ? "\u{F024B}" : "\u{F018D}",
                score: 40 + s * 50 + usageBonus("custom:" + c.name), run: () => runCustom(c) })
        }
        return out
    }

    // A user-defined action from Settings > Search & Launcher
    function runCustom(c) {
        if (c.kind === "snippet") Clipboard.pasteText(c.value)
        else if (c.kind === "open") Quickshell.execDetached(["xdg-open", c.value.replace(/^~/, home)])
        else if (c.kind === "terminal") Quickshell.execDetached(["ghostty", "-e", "sh", "-c", c.value + "; echo; read -p 'Press Enter to close' _"])
        else Quickshell.execDetached(["sh", "-c", c.value])
    }

    function command(raw) {
        const cmd = raw.replace(/^>\s*/, "")
        if (!cmd) return []
        return [
            { key: "cmd", kind: "Command", title: cmd, subtitle: "Run in a terminal", glyph: "\u{F018D}", score: 100,
              run: () => Quickshell.execDetached(["ghostty", "-e", "sh", "-c", cmd + "; echo; read -p 'Press Enter to close' _"]) },
            { key: "cmd-bg", kind: "Command", title: cmd, subtitle: "Run in the background", glyph: "\u{F0A2D}", score: 99,
              run: () => Quickshell.execDetached(["sh", "-c", cmd]) },
        ]
    }

    function fileResults(q) {
        return files.map((f, i) => {
            const name = f.replace(/\/$/, "").split("/").pop()
            const dir = f.endsWith("/")
            return { key: "file:" + f, kind: dir ? "Folders" : "Files", title: name, subtitle: f.replace(home, "~"),
                     glyph: dir ? "\u{F024B}" : fileGlyph(f), path: f,
                     score: (q.startsWith("~") || q.startsWith("/") ? 85 : 32) - i * 0.1,
                     run: () => Quickshell.execDetached(["xdg-open", f]) }
        })
    }

    function fileGlyph(path) {
        const ext = path.split(".").pop().toLowerCase()
        if (["png", "jpg", "jpeg", "webp", "gif", "svg"].includes(ext)) return "\u{F021F}"
        if (ext === "pdf") return "\u{F0226}"
        if (["doc", "docx", "odt", "xls", "xlsx", "ods", "ppt", "pptx"].includes(ext)) return "\u{F0219}"
        if (["js", "ts", "tsx", "jsx", "php", "py", "lua", "qml", "sh", "css", "scss", "html", "json", "liquid"].includes(ext)) return "\u{F0169}"
        if (["zip", "tar", "gz", "zst", "7z"].includes(ext)) return "\u{F05C4}"
        return "\u{F0214}"
    }

    function web(raw) {
        return [{ key: "web", kind: "Web", title: "Search the web for “" + raw + "”", glyph: "\u{F059F}", score: 5,
                  run: () => Quickshell.execDetached(["xdg-open", Config.launcher.webSearch.replace("%s", encodeURIComponent(raw))]) }]
    }

    // ---- merged results ------------------------------------------------------------------------

    readonly property var results: {
        const raw = query.trim()
        const q = raw.toLowerCase()
        if (!q) return []
        if (q.startsWith(">")) return command(raw)
        let out = []
        if (calc) out.push({ key: "calc", kind: "Calculator", title: calc, subtitle: raw + " — Enter copies it",
                             glyph: "\u{F00EC}", score: 97, run: () => Quickshell.execDetached(["wl-copy", calc]) })
        out = out.concat(apps(q), settings(q), actions(q, false), fileResults(q), web(raw))
        return out.sort((a, b) => b.score - a.score)
    }

    // Lists for the launcher's browse modes (no query needed)
    function actionList(q) { return actions(q.toLowerCase(), !q).sort((a, b) => b.score - a.score) }

    function activate(r) {
        if (!r) return
        if (r.key !== "web" && r.key !== "calc") remember(r.key)
        r.run()
    }

    // ---- async providers -------------------------------------------------------------------------

    onQueryChanged: { files = []; calc = ""; slow.restart() }
    Timer {
        id: slow
        interval: 120
        onTriggered: {
            const raw = root.query.trim()
            if (raw.startsWith(">") || raw.length === 0) return
            // Calculator: starts like a number or bracket, through qalc (units, %, offline currencies)
            if (/^[\d(.\-√π]/.test(raw) && /\d/.test(raw)) { qalc.command = ["qalc", "-t", "-set", "upxrates 0", "--", raw]; qalc.running = true }
            // Files: "~/x" or "/x" browse a path; otherwise search home once there are 3+ letters
            let cmd = null
            if (raw.startsWith("~") || raw.startsWith("/")) {
                const path = raw.replace(/^~/, root.home)
                const slash = path.lastIndexOf("/")
                const dir = path.slice(0, slash + 1) || "/"
                const part = path.slice(slash + 1)
                cmd = ["fd", "--max-depth", "1", "--max-results", "30", "--ignore-case", "--hidden", "--exclude", ".git",
                       "--", part ? "^" + part.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") : ".", dir]
            } else if (raw.length >= 3 && Config.launcher.showFiles) {
                cmd = ["fd", "--ignore-case", "--max-results", "12", "--exclude", "node_modules", "--exclude", "vendor",
                       "--", raw, root.home]
            }
            // Folders come back with a trailing slash so they can be told apart
            if (cmd) { fd.command = ["sh", "-c", "\"$@\" | while read -r p; do [ -d \"$p\" ] && echo \"${p%/}/\" || echo \"$p\"; done", "fd"].concat(cmd); fd.running = true }
        }
    }
    Process {
        id: fd
        property var buffer: []
        onStarted: buffer = []
        stdout: SplitParser { onRead: line => fd.buffer.push(line) }
        onExited: root.files = buffer
    }
    Process {
        id: qalc
        stdout: StdioCollector {
            onStreamFinished: {
                const a = text.trim()
                const raw = root.query.trim()
                // Ignore echoes, errors and "ans = word" style non-answers
                root.calc = a && a !== raw && !/error|warning|undefined/i.test(a) && /\d/.test(a) ? a.replace(/^≈\s*/, "≈ ") : ""
            }
        }
    }
}
