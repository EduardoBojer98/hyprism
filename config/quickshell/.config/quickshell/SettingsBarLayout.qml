import Quickshell
import QtQuick
import QtQuick.Layouts

// Menu Bar > Layout and Screens: the bar is one layout (Config.bar.layout: items, place, size, shape, dock) shared
// by every screen and theme once you change it. "Start from" copies a set of items into it, a screen can have
// a list of its own or no bar, and a layout you like can be kept as a starting point (Config.bar.presets).
ColumnLayout {
    id: lay
    spacing: 20

    required property var editor                       // the BarEditor: what "Save" keeps and what "Start from" fills
    readonly property var b: Config.bar
    readonly property var names: Object.keys(b.presets ?? {})
    readonly property var shipped: Object.keys(fresh.bar.presets)   // the built-in ones, as they ship
    readonly property var mine: names.filter(n => !shipped.includes(n))
    readonly property var screens: Quickshell.screens.filter(s => Machine.realScreen(s.name))
    readonly property var ownScreens: Object.keys(b.monitors ?? {}).filter(n => typeof b.monitors[n] === "object")
    property string message

    ConfigData { id: fresh }

    function clone(o) { return JSON.parse(JSON.stringify(o ?? {})) }
    function lists(p) { return { start: Array.from(p.start ?? []), center: Array.from(p.center ?? []), end: Array.from(p.end ?? []) } }
    function startFrom(name) { editor.save(lists(b.presets[name])) }
    function save(name) {
        if (!/^[A-Za-z0-9-]+$/.test(name)) { message = "Use letters, digits and dashes only."; return }
        if (shipped.includes(name)) { message = "That name is built in."; return }
        const all = clone(b.presets); all[name] = editor.lists()
        message = Config.set("bar", "presets", all)
        if (!message) newName.text = ""
    }
    function remove(name) {
        const all = clone(b.presets)
        delete all[name]
        Config.set("bar", "presets", all)
    }
    function setScreen(name, pick) {
        const hidden = Array.from(b.hiddenOn).filter(n => n !== name), map = clone(b.monitors)
        if (pick === "No bar") { hidden.push(name); delete map[name] }
        else if (pick === "Its own items") map[name] = typeof map[name] === "object" ? map[name] : lists(Theme.barLayout)
        else delete map[name]
        Config.set("bar", "hiddenOn", hidden)
        Config.set("bar", "monitors", map)
        editor.screen = pick === "Its own items" ? name : editor.screen === name ? "" : editor.screen
    }

    SettingGroup {
        title: "Layout"
        SettingRow {
            label: "Start from"
            hint: "Copies a set of items into the bar you are editing; change anything after"
            Flow {
                spacing: 6
                width: 360
                Repeater {
                    model: lay.names
                    PillButton { required property string modelData; text: modelData.charAt(0).toUpperCase() + modelData.slice(1); onClicked: lay.startFrom(modelData) }
                }
            }
        }
        SettingRow {
            visible: Theme.hasLayout
            label: "Use " + Theme.current.name + "'s own bar"
            hint: "Your layout is kept when you switch theme. This puts back the items, place, size and shape " + Theme.current.name + " came with"
            PillButton { text: "Use the theme's"; onClicked: Theme.useThemeLayout() }
        }
        SettingRow {
            label: "Keep this layout as a starting point"
            hint: lay.message || "The three lists above, kept under a name"
            Row {
                spacing: 8
                TextField { id: newName; width: 150; placeholder: "my-layout"; invalid: lay.message !== ""; onAccepted: saveBtn.clicked() }
                PillButton { id: saveBtn; text: "Keep"; primary: true; onClicked: lay.save(newName.text.trim()) }
            }
        }
        Repeater {
            model: lay.mine
            SettingRow {
                id: kept
                required property string modelData
                label: modelData
                hint: "A starting point you kept"
                PillButton { text: "Delete"; Accessible.name: "Delete " + kept.modelData; onClicked: lay.remove(kept.modelData) }
            }
        }
    }

    SettingGroup {
        visible: lay.screens.length > 1
        title: "Screens"
        SettingRow {
            label: "Editing"
            hint: "Which bar the editor below changes"
            Dropdown {
                Accessible.name: "Bar to edit"
                options: ["Every screen"].concat(lay.ownScreens)
                current: lay.editor.onScreen ? lay.editor.screen : "Every screen"
                onPicked: v => lay.editor.screen = v === "Every screen" ? "" : v
            }
        }
        Repeater {
            model: lay.screens
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: modelData.width + " × " + modelData.height + (modelData.model ? " · " + modelData.model : "")
                Dropdown {
                    Accessible.name: "Bar on " + modelData.name
                    options: ["Same as every screen", "Its own items", "No bar"]
                    current: lay.b.hiddenOn.includes(modelData.name) ? "No bar" : typeof lay.b.monitors?.[modelData.name] === "object" ? "Its own items" : "Same as every screen"
                    onPicked: v => lay.setScreen(modelData.name, v)
                }
            }
        }
    }
}
