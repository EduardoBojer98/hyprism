import Quickshell
import QtQuick
import QtQuick.Layouts

// Menu Bar > Layout and Screens: which preset of items the bar uses (Config.bar.preset; "Theme's own" follows
// the theme), saving the editor's layout as a preset of your own, and a preset (or no bar) for each screen.
ColumnLayout {
    id: lay
    spacing: 20

    required property var editor                       // the BarEditor: its lists are what "Save current layout" stores
    readonly property var b: Config.bar
    readonly property string own: "Theme's own"
    readonly property var names: Object.keys(b.presets ?? {})
    readonly property var shipped: Object.keys(fresh.bar.presets)   // the built-in presets, as they ship
    readonly property bool builtIn: shipped.includes(b.preset)
    property string message

    ConfigData { id: fresh }

    function clone(o) { return JSON.parse(JSON.stringify(o ?? {})) }
    function save(name) {
        if (!/^[A-Za-z0-9-]+$/.test(name) || name === "theme") { message = "Use letters, digits and dashes only, and not “theme”."; return }
        const all = clone(b.presets); all[name] = editor.lists()
        message = Config.set("bar", "presets", all)
        if (!message) { Config.set("bar", "preset", name); newName.text = "" }
    }
    function remove(name) {   // a user-made preset goes; a built-in goes back to how it ships
        const all = clone(b.presets), map = clone(b.monitors)
        if (shipped.includes(name)) all[name] = clone(fresh.bar.presets[name])
        else {
            delete all[name]
            for (const s of Object.keys(map)) if (map[s] === name) delete map[s]
            Config.set("bar", "monitors", map)
            Config.set("bar", "preset", "theme")
        }
        Config.set("bar", "presets", all)
    }
    function setScreen(name, pick) {
        const hidden = Array.from(b.hiddenOn).filter(n => n !== name), map = clone(b.monitors)
        if (pick === "No bar") hidden.push(name)
        else if (pick === "Same as above") delete map[name]
        else map[name] = pick
        Config.set("bar", "hiddenOn", hidden)
        Config.set("bar", "monitors", map)
    }

    SettingGroup {
        title: "Layout"
        SettingRow {
            label: "Preset"
            hint: lay.b.preset === "theme" ? "“Theme's own” follows the theme: " + Theme.current.name + "'s items, with your changes"
                                           : "Every screen without its own choice uses “" + lay.b.preset + "”"
            Dropdown {
                Accessible.name: "Bar preset"
                options: [lay.own].concat(lay.names)
                current: lay.b.presets?.[lay.b.preset] === undefined ? lay.own : lay.b.preset
                onPicked: v => Config.set("bar", "preset", v === lay.own ? "theme" : v)
            }
        }
        SettingRow {
            label: "Save current layout as…"
            hint: lay.message || "The three lists shown below, kept under a name"
            Row {
                spacing: 8
                TextField { id: newName; width: 150; placeholder: "my-layout"; invalid: lay.message !== ""; onAccepted: saveBtn.clicked() }
                PillButton { id: saveBtn; text: "Save"; primary: true; onClicked: lay.save(newName.text.trim()) }
            }
        }
        SettingRow {
            visible: lay.b.presets?.[lay.b.preset] !== undefined
            label: lay.builtIn ? "Reset “" + lay.b.preset + "”" : "Delete “" + lay.b.preset + "”"
            hint: lay.builtIn ? "Built-in presets can be reset, not deleted" : "Screens that used it follow the theme again"
            PillButton { text: lay.builtIn ? "Reset" : "Delete"; Accessible.name: text + " preset"; onClicked: lay.remove(lay.b.preset) }
        }
    }

    SettingGroup {
        visible: Quickshell.screens.length > 1
        title: "Screens"
        Repeater {
            model: Quickshell.screens
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: modelData.width + " × " + modelData.height + (modelData.model ? " · " + modelData.model : "")
                Dropdown {
                    Accessible.name: "Bar on " + modelData.name
                    options: ["Same as above"].concat(lay.names, ["No bar"])
                    current: lay.b.hiddenOn.includes(modelData.name) ? "No bar"
                           : lay.b.presets?.[lay.b.monitors?.[modelData.name]] !== undefined ? lay.b.monitors[modelData.name] : "Same as above"
                    onPicked: v => lay.setScreen(modelData.name, v)
                }
            }
        }
    }
}
