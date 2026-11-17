pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The action registry: every button and toggle the desktop can run, the built-in ones (BuiltinActions.qml) and
// yours (Config.actions.list, Settings > Actions). The launcher, bar clicks, hot corners, the Control Center and
// keyboard shortcuts all run actions by id through here (docs/decisions/0002-action-registry.md).
//   { id, name, icon (a Nerd Font glyph), description, kind: "button" | "toggle",
//     run: { type, argv, value, cwd, steps }, off (a toggle's "turn off", same shape), state (how a toggle reads
//     its real state), confirm, timeoutSec (0 = no limit), when (Conditions.qml), showIn: ["launcher", "bar", "corner"] }
// run.type: app (value: desktop id, gtk-launch) · command (argv, no shell) · terminal (argv in a Ghostty window) ·
//   open (value: path or URL, xdg-open) · snippet (value: text to paste) · shell (value: sh -c, labelled as such) ·
//   sequence (steps: action ids and { wait: ms }) · preset (value: a display preset, run by Displays) · internal (built-ins)
// state.type: internal (built-ins) · unit (unit, system: bool; systemctl is-active) · process (name; pgrep -x) ·
//   command (argv; exit 0 = on). Checked after a run and when a surface showing it opens; never polled in the
//   background (state.interval, seconds, only while one is shown).
// Commands run tracked with a time limit; a failure shows a notification, every tracked run writes a line to
// ~/.local/state/hyprism/actions.log. sudo, su and doas are refused (no terminal to ask in); pkexec asks in a window.
//   qs ipc call actions run <id> | toggle <id> | list
Singleton {
    id: root

    // old ids that still work: hot corners saved before the registry, and Control Center tiles that share a launcher action
    readonly property var aliases: ({ mission: "overview", launcher: "panel-launcher", controlcenter: "panel-controlcenter",
                                      notifications: "panel-notifications", focus: "dnd", screenshot: "shot", colorpicker: "picker" })
    readonly property var surfaces: ["launcher", "bar", "corner", "controlcenter"]
    readonly property var userTypes: ["app", "command", "terminal", "open", "snippet", "shell", "sequence", "preset"]
    readonly property var refused: ["sudo", "su", "doas"]

    readonly property var user: Array.from(Config.actions.list ?? []).map(a => Object.assign({ kind: "button", showIn: ["launcher"], user: true }, a))
    readonly property var builtinIds: BuiltinActions.list.map(a => a.id)
    // a built-in wins over one of yours with the same id (Settings refuses that, a hand edit may not)
    readonly property var all: BuiltinActions.list.concat(user.filter(a => !builtinIds.includes(a.id)))

    function get(id) { const want = aliases[id] ?? id; return all.find(a => a.id === want) ?? null }
    function available(a) { return !!a && Conditions.holds(a.when) }
    function forSurface(s) { return all.filter(a => (s === "all" || (a.showIn ?? []).includes(s)) && available(a)) }
    function needsAdmin(a) { return [a?.run, a?.off].some(r => r?.argv?.[0] === "pkexec" || /(^|[;&|]\s*)pkexec\b/.test(r?.value ?? "")) }
    // a short line saying what it does, for lists
    function summary(a) {
        const r = a?.run ?? {}
        const argv = (r.argv ?? []).map(s => /\s/.test(s) ? JSON.stringify(s) : s).join(" ")
        return ({ app: "App: " + r.value, command: argv, terminal: "In terminal: " + argv, open: "Open: " + r.value, snippet: "Paste: " + r.value,
                  shell: "Shell: " + r.value, sequence: "Runs " + (r.steps ?? []).filter(s => typeof s === "string").join(", "),
                  preset: "Display preset: " + r.value, internal: "Built in" })[r.type] ?? ""
    }

    // ---- toggle state ---------------------------------------------------------------------------
    property var states: ({})   // id -> on, for unit / process / command states
    function isOn(id) {
        const a = typeof id === "string" ? get(id) : id
        if (a?.kind !== "toggle" || !a.state) return false
        if (a.state.type === "internal") return !!a.state.on?.()
        return states[a.id] === true
    }
    function refresh(id) {
        const a = get(id), s = a?.state
        if (!s || s.type === "internal" || checking[a.id]) return
        const argv = s.type === "unit" ? ["systemctl", s.system ? "--system" : "--user", "is-active", "--quiet", "--", s.unit]
                   : s.type === "process" ? ["pgrep", "-x", "--", s.name] : s.argv
        if (!argv?.length || refused.includes(argv[0])) return
        checking[a.id] = true
        start(argv, "", 10, (code) => { delete checking[a.id]; const st = Object.assign({}, states); st[a.id] = code === 0; states = st })
    }
    property var checking: ({})
    function refreshVisible(surface) { for (const a of forSurface(surface)) if (a.kind === "toggle") refresh(a.id) }
    // a surface tells when it is shown, so state is read then (and on its interval, only while shown)
    property var watching: []
    function watch(surface, shown) {
        watching = watching.filter(s => s !== surface).concat(shown ? [surface] : [])
        if (shown) refreshVisible(surface)
    }
    readonly property int pollMs: {
        let shown = []
        for (const s of watching) shown = shown.concat(forSurface(s))
        const secs = shown.map(a => Number(a.state?.interval) || 0).filter(n => n >= 2)
        return secs.length ? Math.min(...secs) * 1000 : 0
    }
    Timer { interval: Math.max(2000, root.pollMs); running: root.pollMs > 0; repeat: true; onTriggered: { for (const s of root.watching) root.refreshVisible(s) } }

    // ---- running --------------------------------------------------------------------------------
    // By id. A toggle that is on runs its `off` (when it has one). An action that asks first opens the
    // launcher's confirmation unless `confirmed`. Returns "" or why it couldn't start.
    function run(id, confirmed, chain) {
        const a = get(id)
        if (!a) return "No action " + id
        if (!available(a)) return a.name + " isn't available here"
        if (a.confirm && !confirmed) { Launcher.ask({ key: "action:" + a.id, title: a.name, run: () => root.run(a.id, true) }); return "" }
        const r = a.kind === "toggle" && a.off && isOn(a) ? a.off : a.run
        const why = exec(a, r, chain ?? [], null)
        if (why) { log(a, why, false); fail(a, why, []) }
        return why
    }
    // Runs one run/off object for `a`. done(code, lines) is called for tracked commands (the Settings test button).
    function exec(a, r, chain, done) {
        const home = Quickshell.env("HOME")
        const cwd = (r.cwd ?? "").replace(/^~(?=\/|$)/, home)
        switch (r?.type) {
        case "internal": r.fn?.(); afterRun(a); return ""
        case "app": Quickshell.execDetached(["gtk-launch", r.value]); return ""
        case "snippet": Clipboard.pasteText(r.value); return ""
        case "open": return spawn(a, ["xdg-open", String(r.value).replace(/^~(?=\/|$)/, home)], cwd, false, done)
        case "shell": return spawn(a, ["sh", "-c", r.value], cwd, r.detach, done)
        case "command": return spawn(a, r.argv ?? [], cwd, r.detach, done)
        // the window shows what happened; Ghostty may keep running as its own instance, so it isn't timed
        case "terminal": return spawn(a, ["ghostty", "+new-window", "-e", "sh", "-c", '"$@"; echo; read -p "Press Enter to close" _', "sh"].concat(r.argv ?? []), cwd, true, done)
        case "preset": return Displays.run(r.value) || ""   // a preset's id or name; same keep-or-revert countdown as Settings
        case "sequence": return sequence(a, r.steps ?? [], 0, chain.concat([a.id]))
        default: return "Unknown run type " + r?.type
        }
    }
    function toggle(id) { return run(id) }

    // Steps one after another; a { wait } holds the next ones back. No loops: an action already in the chain stops it.
    function sequence(a, steps, i, chain) {
        for (; i < steps.length; i++) {
            const s = steps[i]
            if (typeof s === "object" && s !== null) {
                const rest = i + 1
                waiter.createObject(root, { interval: Math.max(0, Number(s.wait) || 0), then: () => {
                    const why = root.sequence(a, steps, rest, chain)
                    if (why) { root.log(a, why, false); root.fail(a, why, []) }
                } })
                return ""
            }
            const id = aliases[s] ?? s
            if (chain.includes(id) || chain.length > 8) return "“" + a.name + "” runs itself again (" + chain.concat([id]).join(" → ") + ")"
            const why = run(id, true, chain)
            if (why) return why
        }
        return ""
    }
    Component { id: waiter; Timer { property var then; running: true; onTriggered: { then(); destroy() } } }

    function spawn(a, argv, cwd, detach, done) {
        if (!argv.length || typeof argv[0] !== "string" || argv[0] === "") return "Nothing to run"
        if (refused.includes(argv[0].split("/").pop())) return argv[0] + " can't ask for a password here: use pkexec instead"
        // env runs it without a shell, gives exit code 127 when the program is missing, and -C reports a bad folder
        const full = ["env"].concat(cwd ? ["-C", cwd] : [], ["--"], argv)
        if (detach) { Quickshell.execDetached(full); afterRun(a); return "" }
        return start(full, a, a.timeoutSec ?? 30, done)
    }
    // A tracked process. `a` is the action (or "" for a state check: no log, no notification).
    function start(argv, a, timeoutSec, done) {
        job.createObject(root, { action: a || null, done: done ?? null, limit: Number(timeoutSec) || 0, command: argv })
        return ""
    }
    Component {
        id: job
        Scope {
            id: j
            property var action
            property var done
            property int limit
            property alias command: proc.command
            property bool timedOut: false
            property var err: []
            property var out: []
            Process {
                id: proc
                running: true
                stdout: SplitParser { onRead: line => { j.out.push(line); if (j.out.length > 20) j.out.shift() } }
                stderr: SplitParser { onRead: line => { j.err.push(line); if (j.err.length > 20) j.err.shift() } }
                onExited: code => j.finish(j.timedOut ? 124 : code)
            }
            // at the time limit: ask it to stop, then (3 s later) make it
            Timer { interval: j.limit * 1000; running: j.limit > 0; onTriggered: { proc.signal(j.timedOut ? 9 : 15); j.timedOut = true; interval = 3000; restart() } }
            Timer { running: !proc.running && !j.timedOut; interval: 3000; onTriggered: j.finish(-1) }   // never started
            property bool over: false
            function finish(code) {
                if (over) return
                over = true
                root.finished(j.action, code, j.timedOut, j.err, !!j.done)
                j.done?.(code, j.out.concat(j.err))
                j.destroy()
            }
        }
    }
    // tested from Settings: the page shows the result itself, so no notification
    function finished(a, code, timedOut, err, tested) {
        if (!a) return
        log(a, code, timedOut)
        afterRun(a)
        if (code !== 0 && !tested) fail(a, timedOut ? `Stopped after ${a.timeoutSec ?? 30} s` : `Exit code ${code}`, err)
    }
    function afterRun(a) { if (a?.kind === "toggle") recheck.restart(); lastRun = a?.id ?? "" }
    property string lastRun: ""
    Timer { id: recheck; interval: 600; onTriggered: root.refresh(root.lastRun) }

    function fail(a, why, err) {
        console.warn("actions: " + a.id + ": " + why)
        Notifications.post("“" + a.name + "” failed", [why].concat(err.slice(-4)).join("\n"), "normal", "dialog-error")
    }

    readonly property string logFile: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/hyprism/actions.log"
    // one line per run; at 256 KB the log moves to actions.log.1 (the one before is dropped)
    function log(a, result, timedOut) {
        const line = `${new Date().toISOString()} ${a.id} ${timedOut ? "timeout" : result}`
        Quickshell.execDetached(["sh", "-c", 'mkdir -p "${1%/*}" && { [ "$(stat -c %s "$1" 2>/dev/null || echo 0)" -lt 262144 ] || mv -f "$1" "$1.1"; } && printf "%s\\n" "$2" >> "$1"',
                                 "sh", logFile, line])
    }

    // Settings > Actions: run an unsaved action and hand back its exit code and last lines of output
    function test(a, done) {
        if (a.kind === "toggle" && a.state && a.state.type !== "internal") Qt.callLater(() => refresh(a.id))
        const r = a.run ?? {}
        if (!["command", "shell", "open"].includes(r.type)) { const why = exec(a, r, [], null); done(why ? 1 : 0, [why || "Started"]); return }
        const why = exec(a, Object.assign({}, r, { detach: false }), [], (code, lines) => done(code, lines))
        if (why) done(1, [why])
    }

    // ---- checking yours (Config.qml's "actions" rule) -------------------------------------------
    function argvProblem(argv, what) {
        if (!argv || typeof argv.length !== "number" || argv.length === 0 || argv.length > 64) return what + ": a list of words"
        if (!Array.from(argv).every(s => typeof s === "string")) return what + ": only text"
        if (argv[0] === "") return what + ": the program is missing"
        if (refused.includes(String(argv[0]).split("/").pop())) return what + ": " + argv[0] + " isn't allowed (use pkexec)"
        return ""
    }
    function runProblem(r, what) {
        if (!r || typeof r !== "object" || !userTypes.includes(r.type)) return what + ": type must be one of " + userTypes.join(", ")
        if (r.cwd !== undefined && typeof r.cwd !== "string") return what + ": cwd must be text"
        if (r.type === "command" || r.type === "terminal") return argvProblem(r.argv, what)
        if (r.type === "sequence") {
            const steps = r.steps
            if (!steps || typeof steps.length !== "number" || steps.length === 0 || steps.length > 20) return what + ": 1-20 steps"
            const ok = Array.from(steps).every(s => typeof s === "string" ? /^[a-z0-9][a-z0-9-]*$/.test(s)
                : s !== null && typeof s === "object" && typeof s.wait === "number" && s.wait >= 0 && s.wait <= 60000)
            return ok ? "" : what + ": steps are action ids or { wait: ms } up to 60000"
        }
        if (typeof r.value !== "string" || r.value.trim() === "") return what + ": value is missing"
        if (r.type === "shell" && /(^|[;&|]\s*)(sudo|su|doas)\b/.test(r.value)) return what + ": sudo, su and doas aren't allowed (use pkexec)"
        return ""
    }
    // why one of your actions can't be used, or ""
    function problem(a) {
        if (!a || typeof a !== "object") return "not an object"
        if (typeof a.id !== "string" || !/^[a-z0-9][a-z0-9-]{0,47}$/.test(a.id)) return "id: lower-case letters, digits and -"
        if (typeof a.name !== "string" || a.name.trim() === "" || a.name.length > 60) return "name: 1-60 characters"
        if (a.icon !== undefined && (typeof a.icon !== "string" || a.icon.length > 8)) return "icon: one glyph"
        if (a.description !== undefined && typeof a.description !== "string") return "description must be text"
        if (a.kind !== undefined && !["button", "toggle"].includes(a.kind)) return "kind: button or toggle"
        const rp = runProblem(a.run, "run")
        if (rp) return rp
        if (a.off !== undefined && (a.kind !== "toggle" || runProblem(a.off, "off"))) return runProblem(a.off, "off") || "off: only for toggles"
        const s = a.state
        if (s !== undefined) {
            if (a.kind !== "toggle" || !s || typeof s !== "object") return "state: only for toggles"
            if (s.type === "unit") { if (typeof s.unit !== "string" || !/^[A-Za-z0-9@._:\\-]{1,100}$/.test(s.unit)) return "state: a unit name" }
            else if (s.type === "process") { if (typeof s.name !== "string" || !/^[A-Za-z0-9._+-]{1,15}$/.test(s.name)) return "state: a process name (15 characters at most)" }
            else if (s.type === "command") { const p = argvProblem(s.argv, "state"); if (p) return p }
            else return "state: type must be unit, process or command"
            if (s.interval !== undefined && !(typeof s.interval === "number" && s.interval >= 2 && s.interval <= 3600)) return "state: interval 2-3600 s"
        }
        if (a.confirm !== undefined && typeof a.confirm !== "boolean") return "confirm: true or false"
        if (a.timeoutSec !== undefined && !(typeof a.timeoutSec === "number" && a.timeoutSec >= 0 && a.timeoutSec <= 86400)) return "timeoutSec: 0-86400"
        const wp = Conditions.problem(a.when)
        if (wp) return wp
        if (a.showIn !== undefined && !(a.showIn && typeof a.showIn.length === "number" && Array.from(a.showIn).every(s => surfaces.includes(s))))
            return "showIn: " + surfaces.join(", ")
        return ""
    }

    IpcHandler {
        target: "actions"
        function run(id: string): string { return root.run(id) || "ok" }
        function toggle(id: string): string { return root.toggle(id) || "ok" }
        function list(): string { return JSON.stringify(root.all.filter(a => root.available(a)).map(a => a.kind === "toggle" ? { id: a.id, name: a.name, kind: a.kind, on: root.isOn(a) } : { id: a.id, name: a.name, kind: a.kind })) }
    }
}
