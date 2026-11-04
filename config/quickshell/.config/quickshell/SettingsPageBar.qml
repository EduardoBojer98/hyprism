import Quickshell
import QtQuick
import QtQuick.Layouts

// Menu Bar: where the bar sits, its size and shape, which monitors have one, and which items each of
// its three sections holds. "Theme's" keeps the active theme's own (Themes.qml bar); every option
// works in every theme and on every edge. Changes apply live.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var b: Config.bar

    SettingGroup {
        title: "Place"
        SettingRow {
            label: "Position"
            hint: "The " + Theme.current.name + " theme puts it at the " + Theme.barStyle.edge
            ConfigChoice { section: "bar"; key: "position"; values: ["theme", "top", "bottom", "left", "right"]; labels: ["Theme's", "Top", "Bottom", "Left", "Right"] }
        }
        SettingRow {
            label: "Size"
            hint: Theme.barSize + " px across" + (page.b.size === 0 ? " (the theme's)" : "")
            ConfigChoice { section: "bar"; key: "size"; values: [0, 26, 34, 44, 56]; labels: ["Theme's", "Slim", "Regular", "Tall", "Huge"] }
        }
        SettingRow {
            label: "Shape"
            hint: "Floating keeps a gap to the screen edges"
            ConfigChoice { section: "bar"; key: "floating"; values: ["theme", "floating", "attached"]; labels: ["Theme's", "Floating", "Attached"] }
        }
        SettingRow {
            visible: Theme.barFloating
            label: "Gap"
            hint: "Around the floating bar"
            ConfigSlider { section: "bar"; key: "margin"; from: 0; to: 40; step: 1; format: v => v + " px" }
        }
    }

    SettingGroup {
        title: "Monitors"
        Repeater {
            model: Quickshell.screens
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: modelData.width + " × " + modelData.height + (modelData.model ? " · " + modelData.model : "")
                Toggle {
                    checked: !page.b.hiddenOn.includes(modelData.name)
                    onToggled: on => Config.set("bar", "hiddenOn", on ? page.b.hiddenOn.filter(n => n !== modelData.name)
                                                                        : Array.from(page.b.hiddenOn).concat([modelData.name]))
                }
            }
        }
    }

    // ---- items: a copy of the bar to drag them around on ------------------------------------------------
    SettingGroup {
        title: "Items"
        BarEditor {
            Layout.fillWidth: true
            Layout.margins: 14
            floatOn: page.parent
        }
        SettingRow {
            visible: Config.bar.custom
            label: "Back to the theme's items"
            PillButton { text: "Use the theme's"; onClicked: Config.set("bar", "custom", false) }
        }
    }

    SettingGroup {
        title: "Clock"
        SettingRow {
            label: "24-hour time"
            hint: Config.bar.clock24 ? "14:40" : "2:40 PM"
            ConfigToggle { section: "bar"; key: "clock24" }
        }
        SettingRow {
            label: "Show seconds"
            ConfigToggle { section: "bar"; key: "seconds" }
        }
        SettingRow {
            label: "Date"
            hint: "Beside the time, where there's room"
            ConfigChoice { section: "bar"; key: "date"; values: ["full", "short", "none"]; labels: ["Fri 30 Oct", "30 Oct", "None"] }
        }
        SettingRow {
            label: "Window title"
            hint: "After the app's name in the Active window item"
            ConfigToggle { section: "bar"; key: "windowTitle" }
        }
    }

    // Reset: the theme's place, shape and items again (and the clock's defaults)
    ResetGroup { sections: ["bar"] }
}
