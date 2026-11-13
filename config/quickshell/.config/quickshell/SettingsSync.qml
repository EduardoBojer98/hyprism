import Quickshell
import Quickshell.Io
import QtQuick

// The Hyprland-side settings, from settings.json to the files their programs read. settings.json (Config) is the
// one source of truth; the Settings pages only edit it. This writes, and applies live, whatever changed:
//   Config.idle          -> hypr/settings/hypridle.conf (lock, dim, screens off, sleep), hypridle restarted
//   Config.input         -> hypr/settings/input.lua (layouts, repeat, touchpad), applied with hyprctl eval
//   Config.displays      -> hypr/settings/displays.lua (arrangement, modes, scale…), applied with hyprctl eval
//   Config.monitorShare  -> ~/.config/monswitch.conf (or .off when switched off), its watcher restarted
// Before a section has `imported` set, its values are read once from the file written before (by an older
// Settings, or by hand), so nothing is lost. A file is only written when its text differs from what is on disk.
Scope {
    id: sync

    readonly property string screensOn: "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'"
    readonly property var shortcuts: ["grp:alt_shift_toggle", "grp:ctrl_shift_toggle", "grp:caps_toggle", ""]

    // ---- the files, as text from Config --------------------------------------------------------------
    function idleText(lockMin, sleepMin, powerMin) {
        const blocks = []
        if (lockMin > 0) {
            if (lockMin * 60 > 60)   // a dim first: half a minute's warning before the lock (any input brings it back)
                blocks.push("# 30 s before the lock: dim\nlistener {\n    timeout    = " + (lockMin * 60 - 30) + "\n    on-timeout = brightnessctl -s set 30%\n    on-resume  = brightnessctl -r\n}")
            blocks.push("# " + lockMin + " min: lock\nlistener {\n    timeout    = " + lockMin * 60 + "\n    on-timeout = loginctl lock-session\n}")
            blocks.push("# 30 s later: screens off\nlistener {\n    timeout    = " + (lockMin * 60 + 30) + "\n    on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'\n    on-resume  = " + screensOn + "\n}")
        }
        // one sleep listener per distinct non-zero time; idle-sleep decides at that moment which one applies (battery or mains)
        for (const m of [...new Set([sleepMin, powerMin])].filter(m => m > 0).sort((a, b) => a - b))
            blocks.push("# " + m + " min: idle-sleep sleeps if this is the time for the power source in use (then hibernate after 60 more min where hibernation is set up)\nlistener {\n    timeout    = " + m * 60
                        + "\n    on-timeout = idle-sleep " + sleepMin + " " + powerMin + " " + m + "\n}")
        return "# Written by Quickshell from Settings > Lock & Sleep (settings.json idle). hypridle uses hyprlang.\n"
            + "general {\n    lock_cmd         = pidof hyprlock || hyprlock\n    before_sleep_cmd = loginctl lock-session; " + screensOn + "\n"
            + "    after_sleep_cmd  = " + screensOn + "\n}\n\n" + blocks.join("\n\n") + "\n"
    }
    function inputTable(i) {
        const list = Array.from(i.layouts), many = list.length > 1
        return SettingsApp.lua({
            kb_layout: list.map(l => l.code).join(","),
            kb_variant: many || list[0]?.variant ? list.map(l => l.variant ?? "").join(",") : "",
            kb_options: many ? shortcuts[i.shortcut] ?? "" : "",
            repeat_rate: i.repeatRate, repeat_delay: i.repeatDelay, sensitivity: i.sensitivity,
            natural_scroll: i.naturalScroll, tap_to_click: i.tapToClick,
            disable_while_typing: i.disableWhileTyping, clickfinger: i.clickMethod === "clickfinger",
            scroll_factor: i.scrollFactor, middle_emulation: i.middleEmulation, drag_lock: i.dragLock,
        })
    }
    // the layout, plus the Advanced options under "_options" (monitors.lua skips names that start with _)
    function displaysTable(d) {
        return SettingsApp.lua(Object.assign({}, d.layout, { _options: {
            autoHdr: d.autoHdr, sendContentType: d.sendContentType, xwaylandNativeScale: d.xwaylandNativeScale,
            vrr: d.vrr, preferHighRefresh: d.preferHighRefresh } }))
    }
    function shareText(s) {
        return "# Written by Quickshell from Settings > Shared Monitor (settings.json monitorShare). Read by ~/.local/bin/monswitch.\n"
            + `OUT=${s.output}\nLAPTOP=${s.thisInput}\nPC=${s.otherInput}\n`
            + (s.mirror ? `MIRROR=${s.mirror}\n` : "")           // left out = monswitch uses this computer's own screen
            + (s.mirrorMode ? `MIRROR_MODE=${s.mirrorMode}\n` : "")
    }

    readonly property string idle: idleText(Config.idle.lockMin, Config.idle.sleepMin, Config.idle.sleepOnPowerMin)
    readonly property string inputLua: inputTable(Config.input)
    readonly property string displaysLua: displaysTable(Config.displays)
    readonly property string appsLua: SettingsApp.lua({ terminal: Config.apps.terminal })   // read by modules/binds.lua at load
    readonly property string share: shareText(Config.monitorShare) + (Config.monitorShare.enabled ? "" : "#off\n")

    // ---- writing: each section once its old file has been read, and only when the text changed ----------
    property var disk: ({})   // file -> its text as last read or written
    function put(file, text, then) {
        if (disk[file] === text) return
        const d = Object.assign({}, disk); d[file] = text; disk = d
        SettingsApp.writeConfigFile(file, text, then)
    }
    function writeIdle() {
        if (!Config.idle.imported) return
        put("hypr/settings/hypridle.conf", idle,
            ["sh", "-c", "sleep 0.3; pkill -x hypridle; hyprctl dispatch 'hl.dsp.exec_cmd(\"hypridle -c ~/.config/hypr/settings/hypridle.conf\")'"])
    }
    function writeInput() {
        if (!Config.input.imported) return
        const body = "-- Written by Quickshell from Settings > Keyboard & Touchpad (settings.json input).\nreturn " + inputLua
        put("hypr/settings/input.lua", body, ["hyprctl", "eval", "INPUT = " + inputLua.replace(/\n/g, " ") + "; apply_input()"])
    }
    function writeDisplays() {
        if (!Config.displays.imported) return
        const body = "-- Written by Quickshell from Settings > Displays (settings.json displays). Positions are logical pixels.\nreturn " + displaysLua
        put("hypr/settings/displays.lua", body, ["hyprctl", "eval", "DISPLAYS = " + displaysLua.replace(/\n/g, " ") + "; apply_displays()"])
    }
    function writeApps() {
        put("hypr/settings/apps.lua", "-- Written by Quickshell from settings.json (apps). The terminal key uses it after the next Hyprland reload.\nreturn " + appsLua)
    }
    function writeShare() {
        const s = Config.monitorShare
        if (!s.imported || !s.output) return
        const on = s.enabled
        // off keeps the values in monswitch.conf.off; the watcher restarts with them ([h]: not this shell's line)
        put(on ? "monswitch.conf" : "monswitch.conf.off", shareText(s),
            ["sh", "-c", 'rm -f "$HOME/.config/$1"; pkill -f "bin/monswitch watc[h]"; [ "$2" = on ] && (setsid monswitch watch >/dev/null 2>&1 &); true',
             "sh", on ? "monswitch.conf.off" : "monswitch.conf", on ? "on" : "off"])
        Machine.refresh()
    }
    Timer { id: later; interval: 300; onTriggered: { sync.writeIdle(); sync.writeInput(); sync.writeDisplays(); sync.writeApps(); sync.writeShare() } }
    onAppsLuaChanged: if (Config.loaded) later.restart()
    onIdleChanged: if (Config.loaded) later.restart()
    onInputLuaChanged: if (Config.loaded) later.restart()
    onDisplaysLuaChanged: if (Config.loaded) later.restart()
    onShareChanged: if (Config.loaded) later.restart()

    // ---- once, at load: what is on disk now, and the old files' values for sections not imported yet --------
    Connections { target: Config; function onLoadedChanged() { if (Config.loaded) reader.running = true } }
    Component.onCompleted: if (Config.loaded) reader.running = true
    readonly property var files: ["hypr/settings/hypridle.conf", "hypr/settings/input.lua", "hypr/settings/displays.lua", "hypr/settings/apps.lua", "monswitch.conf", "monswitch.conf.off"]
    Process {
        id: reader
        command: ["sh", "-c", 'for f; do printf "\\036%s\\n" "$f"; cat "$HOME/.config/$f" 2>/dev/null; done', "sh"].concat(sync.files)
        stdout: StdioCollector {
            onStreamFinished: {
                const d = {}
                for (const part of text.split("\x1e").slice(1)) {
                    const nl = part.indexOf("\n")
                    d[part.slice(0, nl)] = part.slice(nl + 1)
                }
                sync.disk = d
                sync.importOld(d)
                later.restart()   // anything missing or out of date on disk gets written now
            }
        }
    }

    // values from a file written before settings.json held them (each section once)
    // every match of a global regex (this JS engine has no String.matchAll)
    function all(re, text) { const out = []; let m; while ((m = re.exec(text)) !== null) out.push(m); return out }
    function luaFields(block) {
        const o = {}
        for (const m of all(/\["(\w+)"\] = ("((?:[^"\\]|\\.)*)"|-?[\d.]+|true|false)/g, block))
            o[m[1]] = m[3] !== undefined ? m[3] : m[2] === "true" ? true : m[2] === "false" ? false : Number(m[2])
        return o
    }
    function importOld(d) {
        if (!Config.idle.imported) {
            const t = d["hypr/settings/hypridle.conf"] ?? ""
            if (t.includes("listener")) {
                const blocks = t.split("listener").slice(1)
                const min = b => { const m = b?.match(/timeout\s*=\s*(\d+)/); return m ? Math.round(parseInt(m[1]) / 60) : 0 }
                Config.set("idle", "lockMin", min(blocks.find(b => b.includes("lock-session"))))
                const sleep = blocks.find(b => b.includes("on-timeout = idle-sleep"))?.match(/on-timeout = idle-sleep (\d+) (\d+)/)
                if (sleep) { Config.set("idle", "sleepMin", parseInt(sleep[1])); Config.set("idle", "sleepOnPowerMin", parseInt(sleep[2])) }
                else Config.set("idle", "sleepMin", min(blocks.find(b => b.includes("systemctl suspend"))))
            }
            Config.set("idle", "imported", true)
        }
        if (!Config.input.imported) {
            const o = luaFields(d["hypr/settings/input.lua"] ?? "")
            if (o.kb_layout) {
                const variants = String(o.kb_variant ?? "").split(",")
                Config.set("input", "layouts", String(o.kb_layout).split(",").filter(c => c).map((c, i) => ({ code: c, variant: variants[i] ?? "" })))
                Config.set("input", "shortcut", Math.max(0, shortcuts.indexOf(o.kb_options ?? "")))
                for (const [k, f] of [["repeatRate", "repeat_rate"], ["repeatDelay", "repeat_delay"], ["sensitivity", "sensitivity"],
                                      ["naturalScroll", "natural_scroll"], ["tapToClick", "tap_to_click"]])
                    if (o[f] !== undefined) Config.set("input", k, o[f])
            }
            Config.set("input", "imported", true)
        }
        if (!Config.displays.imported) {
            const layout = {}
            for (const m of all(/\["([A-Za-z0-9._-]+)"\] = \{([^{}]*)\}/g, d["hypr/settings/displays.lua"] ?? ""))
                if (m[1] !== "_options") layout[m[1]] = luaFields(m[2])
            Config.set("displays", "layout", layout)
            Config.set("displays", "imported", true)
        }
        if (!Config.monitorShare.imported) {
            const on = (d["monswitch.conf"] ?? "") !== "", t = on ? d["monswitch.conf"] : d["monswitch.conf.off"] ?? ""
            const v = k => t.match(new RegExp("^\\s*" + k + "=([^#\\s]*)", "m"))?.[1]
            if (v("OUT")) {
                for (const [key, name] of [["output", "OUT"], ["thisInput", "LAPTOP"], ["otherInput", "PC"], ["mirror", "MIRROR"], ["mirrorMode", "MIRROR_MODE"]])
                    if (v(name) !== undefined) Config.set("monitorShare", key, v(name))
                Config.set("monitorShare", "enabled", on)
            }
            Config.set("monitorShare", "imported", true)
        }
    }
}
