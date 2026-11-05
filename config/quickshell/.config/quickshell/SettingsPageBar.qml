import Quickshell
import QtQuick
import QtQuick.Layouts

// Menu Bar: where the bar sits, its size and shape, which monitors have one, and which items each of
// its three sections holds. Place, shape and items are saved for the active theme only (each theme keeps
// its own; "Default" puts the theme's own back); every option works in every theme and on every edge.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var b: Config.bar

    SettingGroup {
        title: "Place"
        SettingRow {
            label: "Position"
            hint: "The " + Theme.current.name + " theme puts it at the " + Themes.get(Config.appearance.theme).bar.edge
            ThemeChoice { key: "barEdge"; values: ["theme", "top", "bottom", "left", "right"]; labels: ["Default", "Top", "Bottom", "Left", "Right"] }
        }
        SettingRow {
            label: "Size"
            hint: Theme.barSize + " px across"
            ThemeChoice { key: "barSize"; values: [0, 26, 34, 44, 56]; labels: ["Default", "Slim", "Regular", "Tall", "Huge"] }
        }
        SettingRow {
            label: "Shape"
            hint: "Floating keeps a gap to the screen edges"
            ThemeChoice { key: "barFloating"; values: ["theme", true, false]; labels: ["Default", "Floating", "Attached"] }
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
            visible: ((Config.appearance.custom ?? {})[Config.appearance.theme] ?? {}).barItems !== undefined
            label: "Back to the theme's items"
            PillButton { text: "Use the theme's"; onClicked: Themes.adjust("barItems", undefined) }
        }
        SaveTheme {}
    }

    SettingGroup {
        title: "Battery"
        SettingRow {
            label: "Battery percentage"
            hint: "In every theme: in the battery icon, beside it, or not shown"
            ConfigChoice { section: "bar"; key: "batteryPercent"; values: ["inside", "beside", "off"]; labels: ["Inside", "Beside", "Off"] }
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
