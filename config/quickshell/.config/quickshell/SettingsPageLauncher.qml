import QtQuick
import QtQuick.Layouts

// Search & Launcher: Spotlight (tap Super): its design (a set of look options, or each one on its own),
// how it opens, result order, and your own actions: commands, terminal
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
    // Result groups: drag to reorder, turn on/off (Config.launcher.order lists the ones that are on)
    readonly property var allGroups: ["apps", "files", "calc", "settings", "actions", "web"]
    readonly property var groupRows: Config.launcher.order.concat(allGroups.filter(g => !Config.launcher.order.includes(g)))
    // dragging `g` before or after `target`; onto a hidden group it is hidden too, and a hidden one
    // dropped among the shown ones comes back there
    function placeGroup(g, target, after) {
        if (g === target) return
        const o = Config.launcher.order.filter(x => x !== g), i = o.indexOf(target)
        if (i >= 0) o.splice(i + (after ? 1 : 0), 0, g)
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

    readonly property var designs: [
        { id: "tahoe",   name: "Tahoe",   about: "A search pill, round buttons and results as separate glass",
          set: { style: "split", width: 720, field: 48, tint: "glass", corners: "soft", selection: "soft", dim: 0 } },
        { id: "card",    name: "Card",    about: "Search and results in one solid card",
          set: { style: "unified", width: 720, field: 48, tint: "solid", corners: "soft", selection: "accent", dim: 0 } },
        { id: "command", name: "Command", about: "A compact command bar over a dimmed screen",
          set: { style: "unified", width: 640, field: 44, tint: "solid", corners: "sharp", selection: "accent", dim: 0.35 } },
        { id: "pill",    name: "Pill",    about: "Round, airy glass pieces",
          set: { style: "split", width: 660, field: 52, tint: "glass", corners: "round", selection: "soft", dim: 0 } },
        { id: "focus",   name: "Focus",   about: "Wide and large, the screen dimmed behind it",
          set: { style: "unified", width: 880, field: 58, tint: "glass", corners: "round", selection: "accent", dim: 0.45 } },
        { id: "accent",  name: "Accent",  about: "Split glass washed with the accent colour",
          set: { style: "split", width: 720, field: 48, tint: "accent", corners: "soft", selection: "accent", dim: 0 } },
    ]

    SettingGroup {
        title: "Design"
        DesignGallery { id: gallery; section: "launcher"; designs: page.designs }
    }

    SettingGroup {
        title: gallery.match ? "Customise" : "Customise · your own mix"
        SettingRow {
            label: "Layout"
            hint: Config.launcher.style === "unified" ? "Search and results in one card" : "Search field, buttons and results as separate pieces"
            ConfigChoice { section: "launcher"; key: "style"; values: ["split", "unified"]; labels: ["Split", "One card"] }
        }
        SettingRow {
            label: "Width"
            ConfigChoice { section: "launcher"; key: "width"; values: [600, 720, 880]; labels: ["Narrow", "Normal", "Wide"] }
        }
        SettingRow {
            label: "Search size"
            ConfigChoice { section: "launcher"; key: "field"; values: [42, 48, 56]; labels: ["Small", "Normal", "Large"] }
        }
        SettingRow {
            label: "Colour"
            ConfigChoice { section: "launcher"; key: "tint"; values: ["glass", "solid", "accent"]; labels: ["Glass", "Solid", "Accent"] }
        }
        SettingRow {
            label: "Corners"
            ConfigChoice { section: "launcher"; key: "corners"; values: ["round", "soft", "sharp"]; labels: ["Round", "Soft", "Sharp"] }
        }
        SettingRow {
            label: "Selected result"
            ConfigChoice { section: "launcher"; key: "selection"; values: ["soft", "accent"]; labels: ["Grey", "Accent"] }
        }
        SettingRow {
            label: "Dim the screen behind it"
            ConfigSlider { section: "launcher"; key: "dim"; from: 0; to: 0.6; step: 0.05; format: v => v === 0 ? "Off" : Math.round(v * 100) + "%" }
        }
        SettingRow {
            label: "Apps per row"
            hint: "In the apps grid"
            ConfigChoice { section: "launcher"; key: "columns"; values: [5, 6, 7, 8]; labels: ["5", "6", "7", "8"] }
        }
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
            DragItem {
                id: groupRow
                required property string modelData
                required property int index
                readonly property bool on: Config.launcher.order.includes(modelData)
                Layout.fillWidth: true
                implicitHeight: rowContent.implicitHeight
                key: "launcherGroups"
                payload: modelData
                floatOn: page.parent
                radius: Theme.radius
                SettingRow {
                    id: rowContent
                    anchors.fill: parent
                    label: "\u{2807}  " + (groupRow.on ? (groupRow.index + 1) + ".  " : "") + Search.groupNames[groupRow.modelData]
                    hint: groupRow.on ? "" : "Hidden from results · drag it among the others or switch it on"
                    Toggle { checked: groupRow.on; onToggled: page.toggleGroup(groupRow.modelData) }
                }
                DropSpot { anchors.fill: parent; key: "launcherGroups"; vertical: true; owner: groupRow; onPlaced: (g, after) => page.placeGroup(g, groupRow.modelData, after) }
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
