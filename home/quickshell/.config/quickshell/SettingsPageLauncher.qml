import QtQuick
import QtQuick.Layouts

// Search & Launcher: Spotlight (tap Super) options and your own actions: commands, terminal
// commands, folders/URLs to open, and text snippets to paste.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var kinds: ["command", "terminal", "open", "snippet"]
    readonly property var kindNames: ["Command", "In terminal", "Open", "Snippet"]
    property int newKind: 0
    property bool newConfirm: false
    property string error: ""

    // Commands that delete, wipe or power off always ask before running
    function risky(v) { return /\b(rm\s+-[a-z]*[rf]|dd\s|mkfs|shred|wipefs|shutdown|poweroff|reboot|:\(\)\{|chmod\s+-R|chown\s+-R|>\s*\/dev\/sd|git\s+(push\s+--force|reset\s+--hard|clean\s+-f))/.test(v) }

    function add() {
        const name = nameField.text.trim(), value = valueField.text.trim()
        if (!name || !value) { error = "Give the action a name and a value"; return }
        const list = Array.from(Config.launcher.actions ?? [])
        if (list.some(a => a.name === name)) { error = "An action called “" + name + "” already exists"; return }
        const kind = kinds[newKind]
        const confirm = newConfirm || (kind !== "snippet" && kind !== "open" && risky(value))
        list.push({ name, kind, value, confirm })
        error = Config.set("launcher", "actions", list)
        if (!error) { nameField.text = ""; valueField.text = ""; newConfirm = false }
    }
    // Result groups: move up/down, turn on/off (Config.launcher.order lists the ones that are on)
    readonly property var allGroups: ["apps", "files", "calc", "settings", "actions", "web"]
    readonly property var groupRows: Config.launcher.order.concat(allGroups.filter(g => !Config.launcher.order.includes(g)))
    function moveGroup(g, d) {
        const o = Array.from(Config.launcher.order), i = o.indexOf(g), j = i + d
        if (i < 0 || j < 0 || j >= o.length) return
        o[i] = o[j]; o[j] = g
        Config.set("launcher", "order", o)
    }
    function toggleGroup(g) {
        const o = Array.from(Config.launcher.order)
        Config.set("launcher", "order", o.includes(g) ? o.filter(x => x !== g) : o.concat([g]))
    }

    function remove(i) {
        const list = Array.from(Config.launcher.actions ?? [])
        list.splice(i, 1)
        Config.set("launcher", "actions", list)
    }

    SettingGroup {
        title: "Spotlight"
        SettingRow {
            label: "Opens"
            hint: "Super taps open it on the screen under the pointer"
            ConfigChoice { section: "launcher"; key: "placement"; values: ["center", "cursor"]; labels: ["Centred", "At the pointer"] }
        }
        SettingRow {
            label: "Before you type, show"
            ConfigChoice { section: "launcher"; key: "startView"; values: ["home", "apps", "search"]; labels: ["Suggestions", "All apps", "Just the search field"] }
        }
        SettingRow {
            label: "Clipboard button"
            hint: "Super+V always opens the history at the pointer"
            ConfigChoice { section: "launcher"; key: "clipboardInside"; values: [true, false]; labels: ["History inside Spotlight", "Open the clipboard popup"] }
        }
    }

    SettingGroup {
        title: "Result order"
        Repeater {
            model: page.groupRows
            SettingRow {
                id: groupRow
                required property string modelData
                required property int index
                readonly property bool on: Config.launcher.order.includes(modelData)
                label: (on ? (index + 1) + ".  " : "") + Search.groupNames[modelData]
                hint: on ? "" : "Hidden from results"
                RowLayout {
                    spacing: Theme.spaceXs
                    Chip { icon: "\u{F0143}"; visible: groupRow.on && groupRow.index > 0; onClicked: page.moveGroup(groupRow.modelData, -1) }
                    Chip { icon: "\u{F0140}"; visible: groupRow.on && groupRow.index < Config.launcher.order.length - 1; onClicked: page.moveGroup(groupRow.modelData, 1) }
                    Toggle { checked: groupRow.on; onToggled: page.toggleGroup(groupRow.modelData) }
                }
            }
        }
    }

    SettingGroup {
        title: "Search"
        SettingRow {
            label: "Web search"
            hint: "Used when nothing else matches"
            ConfigChoice {
                section: "launcher"; key: "webSearch"
                values: ["https://duckduckgo.com/?q=%s", "https://www.google.com/search?q=%s", "https://search.brave.com/search?q=%s", "https://www.startpage.com/do/search?q=%s"]
                labels: ["DuckDuckGo", "Google", "Brave", "Startpage"]
            }
        }
        SettingRow {
            label: "Search files in your home folder"
            hint: "Skips node_modules, vendor and hidden folders"
            ConfigToggle { section: "launcher"; key: "showFiles" }
        }
        SettingRow {
            label: "Forget most-used ranking"
            PillButton { text: "Forget"; onClicked: Config.set("launcher", "usage", {}) }
        }
    }

    SettingGroup {
        title: "Your actions"
        SettingRow {
            visible: (Config.launcher.actions ?? []).length === 0
            label: "No actions yet"
            hint: "Add one below; it shows up in Spotlight when you type its name"
        }
        Repeater {
            model: Config.launcher.actions ?? []
            SettingRow {
                required property var modelData
                required property int index
                label: modelData.name + (modelData.confirm ? "  · asks first" : "")
                hint: page.kindNames[page.kinds.indexOf(modelData.kind)] + ": " + modelData.value
                PillButton { text: "Remove"; onClicked: page.remove(index) }
            }
        }
    }

    SettingGroup {
        title: "Add an action"
        SettingRow { label: "Name"; TextField { id: nameField; placeholder: "e.g. Docker containers" } }
        SettingRow { label: "Type"; Choice { options: page.kindNames; index: page.newKind; onPicked: i => page.newKind = i } }
        SettingRow {
            label: page.newKind === 3 ? "Text to paste" : page.newKind === 2 ? "Folder, file or URL" : "Command"
            TextField { id: valueField; width: 320; placeholder: ["docker ps", "php -v", "~/Documents/projects", "Kind regards, Eduardo"][page.newKind]; onAccepted: page.add() }
        }
        SettingRow {
            label: "Ask before running"
            hint: "Always on for commands that delete, wipe or power off"
            Toggle { checked: page.newConfirm; onToggled: on => page.newConfirm = on }
        }
        SettingRow {
            label: page.error
            PillButton { text: "Add"; primary: true; onClicked: page.add() }
        }
    }

    ResetGroup { sections: ["launcher"] }
}
