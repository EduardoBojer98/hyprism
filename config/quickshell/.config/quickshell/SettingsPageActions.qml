import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Actions: your own buttons and toggles (Config.actions.list), run from Spotlight, a bar click, a hot corner or a
// keyboard shortcut (Actions.qml). Make, edit, test and delete them here; the built-in ones are listed below,
// read-only. A command is a list of words run without a shell; "Shell script" is the one type that goes through sh.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var mine: Array.from(Config.actions.list ?? [])
    readonly property var types: ["command", "terminal", "shell", "open", "snippet", "app", "sequence"]
    readonly property var typeNames: ["Command", "In terminal", "Shell script", "Open", "Paste text", "App", "Sequence"]
    readonly property var valueLabels: ["Command", "Command", "Script (sh -c)", "Folder, file or URL", "Text to paste", "App id (its .desktop file name)", "Steps"]
    readonly property var valueHints: ["docker compose up -d", "htop", "cd ~/proj && make", "~/Documents/projects", "Kind regards, Eduardo",
                                       "org.gnome.Nautilus", "start-db, 2000, open-editor  (a number waits that many ms)"]
    readonly property var stateTypes: ["process", "unit", "unit-system", "command"]
    readonly property var stateNames: ["A program runs", "A service runs", "A system service runs", "A command succeeds"]
    readonly property var limits: [30, 120, 600, 0]
    readonly property var places: [["launcher", "Spotlight"], ["bar", "Bar clicks"], ["corner", "Hot corners"], ["controlcenter", "Control Center"], ["barmenu", "Menu bar right-click"]]

    property int editing: -2          // index in `mine` being edited; -1 = a new one; -2 = the editor is closed
    property var draft: ({})          // the form's choices that aren't text fields
    property string error: ""
    property string result: ""        // the Test button's report
    property bool showBuiltins: false

    // ---- does the program exist? Checked as you type, so a typo shows here and not later as exit code 127 ----
    // the first word of each command the form would run (a shell script's too, when it starts with a plain word)
    function firstWord(line, shell) {
        const w = shell ? (/^\s*([\w.\/+-]+)(\s|$)/.exec(line)?.[1] ?? "") : split(line)[0] ?? ""
        return w.includes("=") ? "" : w   // VAR=value: an assignment, not a program
    }
    readonly property bool runsProgram: ["command", "terminal", "shell"].includes(draft.type)
    readonly property string valueProgram: runsProgram ? firstWord(valueText, draft.type === "shell") : ""
    readonly property string offProgram: runsProgram && draft.kind === "toggle" ? firstWord(offText, draft.type === "shell") : ""
    readonly property string stateProgram: draft.kind === "toggle" && draft.stateType === "command" ? firstWord(stateText, false) : ""
    readonly property var programs: [...new Set([valueProgram, offProgram, stateProgram].filter(w => w))]
    function note(word) { return word ? missing.find(m => m.word === word)?.hint ?? "" : "" }
    property string valueText: ""; property string offText: ""; property string stateText: ""; property string cwdText: ""
    property var missing: []          // [{ word, hint }] for programs not found
    property bool insist: false       // Save pressed once with a missing program: the next press saves anyway
    onProgramsChanged: { insist = false; error = ""; checkLater.restart() }
    onCwdTextChanged: checkLater.restart()
    Timer { id: checkLater; interval: 350; onTriggered: { checker.running = false; if (page.programs.length) checker.running = true; else page.missing = [] } }
    Process {
        id: checker
        // each missing word, then the commands on PATH that start with its letter (for "did you mean")
        command: ["bash", "-c", 'c="${1/#\~/$HOME}"; shift; [ -n "$c" ] && cd -- "$c" 2>/dev/null; for w; do command -v -- "$w" >/dev/null 2>&1 && continue; printf "\\036%s\\n" "$w"; case $w in */*) ;; *) compgen -c -- "${w:0:1}" | sort -u ;; esac; done',
                  "check", page.cwdText.trim()].concat(page.programs)
        stdout: StdioCollector {
            onStreamFinished: page.missing = text.split("\x1e").slice(1).map(part => {
                const [word, ...names] = part.trim().split("\n")
                const near = names.filter(n => n.length > 1).map(n => ({ n: n, d: page.distance(word, n) })).filter(x => x.d <= (word.length >= 8 ? 2 : 1)).sort((a, b) => a.d - b.d)[0]
                const q = "\u201c" + word + "\u201d"
                return { word: word,
                         hint: word.includes("/") ? q + ": nothing to run there. Check the path, and that the file is executable"
                             : near ? q + " isn't a command here. Did you mean \u201c" + near.n + "\u201d?"
                             : q + " isn't installed, or isn't on your PATH. Install it (the package often has the same name) or check the name" }
            })
        }
    }
    // edits between two words, a swap of two neighbours counting as one (dokcer -> docker), for the closest command
    function distance(a, b) {
        const d = Array.from({ length: a.length + 1 }, (_, i) => [i])
        for (let j = 1; j <= b.length; j++) d[0][j] = j
        for (let i = 1; i <= a.length; i++)
            for (let j = 1; j <= b.length; j++) {
                d[i][j] = Math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1))
                if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) d[i][j] = Math.min(d[i][j], d[i - 2][j - 2] + 1)
            }
        return d[a.length][b.length]
    }
    // a program that isn't there: said right under its field, with what to do about it
    component Note: RowLayout {
        property string word
        readonly property string hint: page.note(word)
        visible: hint !== "" && page.editing !== -2
        Layout.fillWidth: true
        Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.bottomMargin: 10
        spacing: Theme.spaceS
        Text { Layout.alignment: Qt.AlignTop; text: "\u{F0028}"; color: Theme.red; font { family: Theme.iconFont; pixelSize: Theme.fontSize } }
        Text { Layout.fillWidth: true; text: parent.hint; textFormat: Text.PlainText; wrapMode: Text.Wrap; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel } }
    }

    Component.onCompleted: Actions.watch("all", true)
    Component.onDestruction: Actions.watch("all", false)

    // "a 'b c' d" -> ["a", "b c", "d"]: quotes keep spaces, a backslash keeps the next character
    function split(line) {
        const out = []
        let cur = "", quote = "", started = false
        for (let i = 0; i < line.length; i++) {
            const ch = line[i]
            if (ch === "\\" && i + 1 < line.length && quote !== "'") { cur += line[++i]; started = true }
            else if (quote) { if (ch === quote) quote = ""; else cur += ch }
            else if (ch === "'" || ch === '"') { quote = ch; started = true }
            else if (/\s/.test(ch)) { if (started) out.push(cur); cur = ""; started = false }
            else { cur += ch; started = true }
        }
        if (started) out.push(cur)
        return out
    }
    function join(argv) { return (argv ?? []).map(s => s === "" || /[\s'"\\]/.test(s) ? "'" + s.replace(/'/g, "'\\''") + "'" : s).join(" ") }
    function lineOf(r) {
        if (!r) return ""
        if (r.type === "command" || r.type === "terminal") return join(r.argv)
        if (r.type === "sequence") return (r.steps ?? []).map(s => typeof s === "object" ? String(s.wait) : s).join(", ")
        return r.value ?? ""
    }
    function runOf(type, line, cwd) {
        const r = { type: type }
        if (type === "command" || type === "terminal") r.argv = split(line)
        else if (type === "sequence") r.steps = line.split(",").map(s => s.trim()).filter(s => s).map(s => /^\d+$/.test(s) ? { wait: Number(s) } : s)
        else r.value = line.trim()
        if (cwd.trim() && ["command", "terminal", "shell"].includes(type)) r.cwd = cwd.trim()
        return r
    }
    // Commands that delete, wipe or power off always ask before running
    function risky(v) { return /\b(rm\s+-[a-z]*[rf]|dd\s|mkfs|shred|wipefs|shutdown|poweroff|reboot|:\(\)\{|chmod\s+-R|chown\s+-R|>\s*\/dev\/sd|git\s+(push\s+--force|reset\s+--hard|clean\s+-f))/.test(v) }

    function edit(i) {
        const a = i >= 0 ? mine[i] : { kind: "button", run: { type: "command" }, showIn: ["launcher"] }
        const s = a.state ?? { type: "process" }
        draft = { kind: a.kind ?? "button", type: a.run?.type ?? "command", confirm: a.confirm === true, timeoutSec: a.timeoutSec ?? 30,
                  showIn: Array.from(a.showIn ?? ["launcher"]), stateType: s.type === "unit" && s.system ? "unit-system" : s.type }
        nameField.text = a.name ?? ""; iconField.text = a.icon ?? ""; descField.text = a.description ?? ""
        valueField.text = lineOf(a.run); cwdField.text = a.run?.cwd ?? ""; offField.text = lineOf(a.off)
        stateField.text = s.type === "unit" ? s.unit ?? "" : s.type === "process" ? s.name ?? "" : join(s.argv)
        error = ""; result = ""; insist = false; missing = []; editing = i
    }
    function set(key, value) { const d = Object.assign({}, draft); d[key] = value; draft = d }
    // the form as an action; `id` stays what it was (shortcuts and the launcher's history use it)
    function build() {
        const name = nameField.text.trim()
        let id = editing >= 0 ? mine[editing].id : name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 40) || "action"
        if (editing < 0) while (Actions.get(id) || Actions.builtinIds.includes(id)) id += "-2"
        const a = { id: id, name: name, kind: draft.kind, run: runOf(draft.type, valueField.text, cwdField.text), showIn: draft.showIn }
        if (iconField.text.trim()) a.icon = iconField.text.trim()
        if (descField.text.trim()) a.description = descField.text.trim()
        if (draft.timeoutSec !== 30) a.timeoutSec = draft.timeoutSec
        a.confirm = draft.confirm || (["command", "terminal", "shell"].includes(draft.type) && risky(valueField.text))
        if (draft.kind === "toggle") {
            if (offField.text.trim()) a.off = runOf(draft.type, offField.text, cwdField.text)
            const st = draft.stateType, v = stateField.text.trim()
            if (v) a.state = st === "process" ? { type: "process", name: v } : st === "command" ? { type: "command", argv: split(v) }
                                                : { type: "unit", unit: v, system: st === "unit-system" }
        }
        return a
    }
    function save() {
        const a = build()
        error = Actions.problem(a)
        if (error) return
        if (missing.length && !insist) {   // kept possible (a program installed later, a PATH only a login sets), but never by accident
            error = missing.map(m => "\u201c" + m.word + "\u201d").join(" and ") + (missing.length > 1 ? " aren't" : " isn't") + " found. Save anyway keeps the action as it is"
            insist = true
            return
        }
        const list = JSON.parse(JSON.stringify(mine))
        if (editing >= 0) list[editing] = a; else list.push(a)
        error = Config.set("actions", "list", list)
        if (!error) editing = -2
    }
    function remove(i) {
        const list = JSON.parse(JSON.stringify(mine))
        list.splice(i, 1)
        Config.set("actions", "list", list)
        if (editing === i) editing = -2
    }
    function test() {
        const a = build()
        error = Actions.problem(a)
        if (error) return
        result = "Running…"
        Actions.test(a, (code, lines) => page.result = (code === 0 ? "Exit code 0" : code === 124 ? "Stopped at the time limit" : "Exit code " + code)
                                                       + (lines.length ? "\n" + lines.join("\n") : ""))
    }
    function badges(a) {
        return [a.kind === "toggle" ? (Actions.isOn(a.id) ? "toggle · on" : "toggle · off") : "", a.run?.type === "shell" ? "shell" : "",
                a.confirm ? "asks first" : "", Actions.needsAdmin(a) ? "asks for admin password" : ""].filter(b => b).join(" · ")
    }

    Text {
        Layout.fillWidth: true
        text: "Your own buttons and toggles. Show them in Spotlight, on a bar click, a hot corner or the Control Center, or give them a key in Keyboard Shortcuts."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontLabel }
    }

    // while one is being edited the form takes the list's place, so it opens where you clicked
    SettingGroup {
        visible: page.editing === -2
        title: "Your actions"
        SettingRow {
            visible: page.mine.length === 0
            label: "No actions yet"
            hint: "Add one: a command, a folder to open, text to paste, or a toggle that knows when it is on"
        }
        Repeater {
            model: page.mine
            SettingRow {
                required property var modelData
                required property int index
                label: modelData.name
                hint: [Actions.summary(modelData), page.badges(modelData)].filter(t => t).join("\n")
                RowLayout {
                    spacing: Theme.spaceXs
                    PillButton { text: "Edit"; onClicked: page.edit(index) }
                    Chip { icon: "\u{F01B4}"; accessibleName: "Delete " + modelData.name; onClicked: page.remove(index); ToolTipText { shown: parent.hovered; text: "Delete" } }
                }
            }
        }
        SettingRow {
            label: ""
            PillButton { text: "New action"; primary: true; onClicked: page.edit(-1) }
        }
    }

    SettingGroup {
        visible: page.editing !== -2
        title: page.editing === -1 ? "New action" : "Edit “" + (page.mine[page.editing]?.name ?? "") + "”"
        SettingRow { label: "Name"; TextField { id: nameField; placeholder: "e.g. Start the database" } }
        SettingRow {
            label: "Icon"
            hint: "A Nerd Font glyph, pasted in (nerdfonts.com/cheat-sheet)"
            RowLayout {
                spacing: Theme.spaceS
                Text { text: iconField.text || "\u{F018D}"; color: Theme.text; font { family: Theme.iconFont; pixelSize: 20 } }
                TextField { id: iconField; width: 80; placeholder: "glyph" }
            }
        }
        SettingRow { label: "Description"; hint: "Shown under the name in Spotlight"; TextField { id: descField; width: 320; placeholder: "optional" } }
        SettingRow {
            label: "Kind"
            hint: page.draft.kind === "toggle" ? "On or off, read from the system, not remembered" : "Runs once each time"
            Choice { options: ["Button", "Toggle"]; index: page.draft.kind === "toggle" ? 1 : 0; onPicked: i => page.set("kind", i ? "toggle" : "button") }
        }
        SettingRow {
            label: "Runs"
            hint: page.draft.type === "shell" ? "Goes through sh: pipes and && work, and so does anything else you type"
                : page.draft.type === "command" ? "Words split at spaces; quote a word with spaces in it. No shell, so no pipes or ~"
                : page.draft.type === "sequence" ? "Other actions by id, one after another" : ""
            Dropdown {
                width: 200
                options: page.typeNames
                current: page.typeNames[page.types.indexOf(page.draft.type)] ?? "Command"
                onPicked: v => page.set("type", page.types[page.typeNames.indexOf(v)])
            }
        }
        SettingRow {
            label: page.valueLabels[page.types.indexOf(page.draft.type)] ?? "Command"
            TextField { id: valueField; width: 360; placeholder: page.valueHints[page.types.indexOf(page.draft.type)] ?? ""; onTextChanged: page.valueText = text; invalid: page.note(page.valueProgram) !== "" }
        }
        Note { word: page.valueProgram }
        SettingRow {
            visible: ["command", "terminal", "shell"].includes(page.draft.type)
            label: "Run in folder"
            hint: "Optional; ~ means your home folder"
            TextField { id: cwdField; width: 320; placeholder: "~"; onTextChanged: page.cwdText = text }
        }
        SettingRow {
            visible: page.draft.kind === "toggle"
            label: "Turn off with"
            hint: "Runs instead while it is on; empty runs the same as turning on"
            TextField { id: offField; width: 360; placeholder: page.valueHints[page.types.indexOf(page.draft.type)] ?? ""; onTextChanged: page.offText = text; invalid: page.note(page.offProgram) !== "" }
        }
        Note { word: page.offProgram }
        SettingRow {
            visible: page.draft.kind === "toggle"
            label: "It is on when"
            hint: "Checked when a list showing it opens and after it runs, never in the background"
            RowLayout {
                spacing: Theme.spaceS
                Dropdown {
                    width: 190
                    options: page.stateNames
                    current: page.stateNames[page.stateTypes.indexOf(page.draft.stateType)] ?? page.stateNames[0]
                    onPicked: v => page.set("stateType", page.stateTypes[page.stateNames.indexOf(v)])
                }
                TextField { id: stateField; width: 180; placeholder: ({ process: "program name", unit: "name.service", "unit-system": "name.service", command: "command" })[page.draft.stateType] ?? ""; onTextChanged: page.stateText = text; invalid: page.note(page.stateProgram) !== "" }
            }
        }
        Note { word: page.stateProgram }
        SettingRow {
            label: "Ask before running"
            hint: "Always on for commands that delete, wipe or power off"
            Toggle { checked: page.draft.confirm === true; onToggled: on => page.set("confirm", on) }
        }
        SettingRow {
            visible: ["command", "shell", "open"].includes(page.draft.type)
            label: "Time limit"
            hint: "Stopped after this; a failure or a stop shows a notification"
            Choice { options: ["30 s", "2 min", "10 min", "None"]; index: Math.max(0, page.limits.indexOf(page.draft.timeoutSec)); onPicked: i => page.set("timeoutSec", page.limits[i]) }
        }
        SettingRow {
            label: "Show in"
            RowLayout {
                spacing: Theme.spaceXs
                Repeater {
                    model: page.places
                    Chip {
                        required property var modelData
                        readonly property bool on: (page.draft.showIn ?? []).includes(modelData[0])
                        icon: on ? "\u{F012C}" : "\u{F0415}"
                        label: modelData[1]
                        active: on
                        onClicked: page.set("showIn", on ? page.draft.showIn.filter(s => s !== modelData[0]) : (page.draft.showIn ?? []).concat([modelData[0]]))
                    }
                }
            }
        }
        Text {
            visible: page.result !== ""
            Layout.fillWidth: true
            Layout.margins: 16
            text: page.result
            color: Theme.text
            wrapMode: Text.WrapAnywhere
            font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
        }
        SettingRow {
            label: page.error
            RowLayout {
                spacing: Theme.spaceXs
                PillButton { text: "Cancel"; onClicked: page.editing = -2 }
                PillButton { text: "Test"; onClicked: page.test() }
                PillButton { text: page.insist ? "Save anyway" : "Save"; primary: true; onClicked: page.save() }
            }
        }
    }

    SettingGroup {
        visible: page.editing === -2
        title: "Built in"
        SettingRow {
            label: "The desktop's own actions"
            hint: "Can be given a shortcut or a hot corner; not changed here"
            PillButton { text: page.showBuiltins ? "Hide" : "Show " + BuiltinActions.list.length; onClicked: page.showBuiltins = !page.showBuiltins }
        }
        Repeater {
            model: page.showBuiltins ? BuiltinActions.list.filter(a => Actions.available(a)) : []
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: modelData.id + (modelData.kind === "toggle" ? " · toggle" : "")
            }
        }
    }
}
