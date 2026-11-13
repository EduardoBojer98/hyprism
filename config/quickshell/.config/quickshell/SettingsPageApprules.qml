import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// App Rules: how particular apps open: floating, floating on top, maximised or fullscreen, and on
// which desktop (Config.windows.apps; hypr/modules/windows.lua makes a Hyprland window rule for
// each). Rules apply to windows opened after the change. Below them, the rules the setup itself
// makes (hypr/modules/rules.lua, host.lua), read from Hyprland's WINDOW_RULES (hyprland.lua).
ColumnLayout {
    id: page
    spacing: 20

    readonly property var opens: [
        { value: "normal", name: "Normally" }, { value: "float", name: "Floating" },
        { value: "pin", name: "Floating, on top" }, { value: "maximize", name: "Maximised" },
        { value: "fullscreen", name: "Fullscreen" },
    ]
    readonly property var desktops: ["Any desktop"].concat([1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(n => "Desktop " + n))
    readonly property var rules: Config.windows.apps ?? []

    property string query: ""
    readonly property var matches: {
        const q = query.trim().toLowerCase()
        if (!q) return []
        const have = rules.map(r => r.id)
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !have.includes(e.id) && (e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q)))
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 8)
    }

    // Window classes an app may use: its desktop id (and its last part), StartupWMClass and the
    // program's name (com.microsoft.VSCode opens windows of class "code"); matched in any case
    function classFor(e) {
        const exe = (e.command?.[0] ?? "").split("/").pop()
        const names = [e.id, e.id.split(".").pop(), e.startupClass ?? "", exe].filter((n, i, a) => n && a.indexOf(n) === i)
        return "(?i)^(" + names.map(n => n.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|") + ")$"
    }
    // ---- the setup's own rules, one row per app they name ---------------------------------------
    property var setupRules: []
    Process {
        running: true
        command: ["hyprctl", "repl", "return window_rules_json()"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { page.setupRules = JSON.parse(text).filter(r => !String(r.name).startsWith("settings-app-")) } catch (e) { page.setupRules = [] }
            }
        }
    }
    // "^(a|b\\.c)$" -> ["a", "b.c"]; anything fancier names no app
    function classNames(re) {
        const m = /^\^\(?([A-Za-z0-9_.\\|-]+)\)?\$$/.exec(re ?? "")
        return m ? m[1].split("|").map(n => n.replace(/\\\./g, ".")).filter(n => n) : []
    }
    function plain(re) { return String(re ?? "").replace(/^\^\(?|\)?\$$/g, "") }
    readonly property var effectNames: ({
        float: "Floating", pin: "Always on top", center: "Centred", maximize: "Maximised", fullscreen: "Fullscreen",
        no_anim: "No animation", no_focus: "Doesn't take focus", stay_focused: "Keeps focus", no_shadow: "No shadow",
        no_blur: "No blur", no_border: "No border",
    })
    function effects(r) {
        return Object.keys(r).filter(k => k !== "name" && k !== "match" && r[k] !== false).map(k => {
            const v = r[k]
            if (k === "size") return "Opens at " + String(v).replace(" ", " × ")
            if (k === "workspace") return "Opens on desktop " + v
            if (k === "suppress_event") return "Can't " + String(v).replace("maximize", "maximise") + " itself"
            if (k === "border_size" && Number(v) === 0) return "No border"
            if (k === "rounding" && Number(v) === 0) return "Square corners"
            if (k === "opacity") return "Opacity " + v
            return effectNames[k] ?? (k.charAt(0).toUpperCase() + k.slice(1).replace(/_/g, " ") + (v === true ? "" : ": " + v))
        }).join(" · ")
    }
    readonly property var setupRows: {
        const rows = []
        for (const r of setupRules) {
            const what = effects(r)
            const title = plain(r.match?.title)
            const names = classNames(r.match?.class)
            const entries = names.map(n => DesktopEntries.heuristicLookup(n))
            // one window of an app (class and title), like this Settings window: its title says more
            if (names.length === 1 && title && title.toLowerCase() !== names[0].toLowerCase())
                rows.push({ icon: entries[0]?.icon ?? "", name: title + " window", what })
            else if (names.length && entries.some(e => e))
                names.forEach((n, i) => rows.push({ icon: entries[i]?.icon ?? "", name: entries[i]?.name ?? n + " (not installed)", what }))
            else rows.push({ icon: "", what,
                name: r.match?.class === ".*" ? "Every app" : title ? title + " windows"
                    : r.match?.xwayland ? "Untitled pop-ups of older (X11) apps"
                    : String(r.name).charAt(0).toUpperCase() + String(r.name).slice(1).replace(/-/g, " ") })
        }
        return rows.sort((a, b) => a.name.localeCompare(b.name))
    }

    function save(list) { Config.set("windows", "apps", list) }
    function change(i, k, v) { save(rules.map((r, j) => j === i ? Object.assign({}, r, { [k]: v }) : r)) }
    function add(e) {
        save(rules.concat([{ id: e.id, name: e.name, class: classFor(e), open: "float", workspace: 0 }]))
        query = ""; search.text = ""
    }

    SettingGroup {
        title: "Your rules"
        Text {
            visible: page.rules.length === 0
            Layout.fillWidth: true
            Layout.margins: 16
            text: "No rules yet: every app opens the normal way. Search below to add one."
            color: Theme.subtext
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Repeater {
            model: page.rules
            SettingRow {
                required property var modelData
                required property int index
                label: modelData.name || modelData.id
                Dropdown {
                    width: 150
                    options: page.opens.map(o => o.name)
                    current: (page.opens.find(o => o.value === modelData.open) ?? page.opens[0]).name
                    onPicked: v => page.change(index, "open", page.opens.find(o => o.name === v).value)
                }
                Dropdown {
                    width: 130
                    options: page.desktops
                    current: page.desktops[modelData.workspace ?? 0] ?? page.desktops[0]
                    onPicked: v => page.change(index, "workspace", page.desktops.indexOf(v))
                }
                PillButton { text: "Remove"; onClicked: page.save(page.rules.filter((_, j) => j !== index)) }
            }
        }
    }

    SettingGroup {
        title: "Add an app"
        SettingRow {
            label: "Search"
            hint: "Type part of the app's name"
            TextField {
                id: search
                width: 220
                placeholder: "e.g. Calculator"
                onTextChanged: page.query = text
                onAccepted: if (page.matches.length) page.add(page.matches[0])
            }
        }
        Repeater {
            model: page.matches
            AppRow {
                required property var modelData
                entry: modelData
                action: "Add"
                onTriggered: page.add(modelData)
            }
        }
    }

    SettingGroup {
        visible: page.setupRows.length > 0
        title: "Built into this setup"
        Repeater {
            model: page.setupRows
            Item {
                id: setupRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: Math.max(52, texts.implicitHeight + 20)
                Rectangle { visible: setupRow.index > 0; anchors { left: parent.left; right: parent.right; leftMargin: 16 } height: 1; color: Theme.stroke }
                IconImage {
                    id: icon
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    implicitSize: 26
                    source: Quickshell.iconPath(setupRow.modelData.icon, "preferences-system-windows")
                }
                Column {
                    id: texts
                    anchors { left: icon.right; leftMargin: 12; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                    Text {
                        width: parent.width
                        text: setupRow.modelData.name
                        elide: Text.ElideRight
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium }
                    }
                    Text {
                        width: parent.width
                        text: setupRow.modelData.what
                        wrapMode: Text.Wrap
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                    }
                }
            }
        }
        SettingRow {
            label: "These come with the desktop"
            hint: "They live in a file that updates replace: to change how an app opens, add a rule above"
            PillButton { text: "Built-in rules (read-only file)"; onClicked: Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") + "/.config/hypr/modules/rules.lua"]) }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Rules apply to windows opened after you change them; close and reopen an app to see it. "
            + "Super+T still floats or tiles any window by hand."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
