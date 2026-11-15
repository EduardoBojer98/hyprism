import Quickshell
import QtQuick
import QtQuick.Layouts

// Menu Bar: one bar for every screen and theme: its items, where it sits, its size and shape (all saved in
// Config.bar.layout by the first change; "Use the theme's" puts the theme's own back), a list of its own or no
// bar per screen, and each item's own settings.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var b: Config.bar

    SettingsBarLayout { id: layoutPane; Layout.fillWidth: true; editor: barEditor }

    SettingGroup {
        title: "Place"
        SettingRow {
            label: "Position"
            hint: "For every screen and theme"
            Choice {
                readonly property var values: ["top", "bottom", "left", "right"]
                options: ["Top", "Bottom", "Left", "Right"]
                index: values.indexOf(Theme.barEdge)
                onPicked: i => Theme.setLayout({ edge: values[i] })
            }
        }
        SettingRow {
            label: "Size"
            hint: Theme.barSize + " px across"
            Choice {
                readonly property var values: [26, 34, 44, 56]
                options: ["Slim", "Regular", "Tall", "Huge"]
                index: values.indexOf(Theme.barSize)
                extra: index < 0 ? Theme.barSize + " px" : ""
                onPicked: i => Theme.setLayout({ size: values[i] })
            }
        }
        SettingRow {
            label: "Shape"
            hint: "Floating keeps a gap to the screen edges"
            Choice {
                options: ["Floating", "Attached"]
                index: Theme.barFloating ? 0 : 1
                onPicked: i => Theme.setLayout({ floating: i === 0 })
            }
        }
        SettingRow {
            visible: Theme.barFloating
            label: "Gap"
            hint: "Around the floating bar"
            ConfigSlider { section: "bar"; key: "margin"; from: 0; to: 40; step: 1; format: v => v + " px" }
        }
    }

    // ---- items: a copy of the bar to drag them around on ------------------------------------------------
    SettingGroup {
        title: "Items"
        BarEditor {
            id: barEditor
            Layout.fillWidth: true
            Layout.margins: 14
            floatOn: page.parent
        }
        SettingRow {
            visible: barEditor.onScreen
            label: "Same items as every screen"
            hint: barEditor.screen + " has a list of its own"
            PillButton { text: "Use the shared list"; onClicked: layoutPane.setScreen(barEditor.screen, "Same as every screen") }
        }
        SaveTheme {}
    }

    SettingsBarItem { editor: barEditor }

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

    // Reset: the clock's and the bar's defaults; the layout goes back to the theme's own
    ResetGroup { sections: ["bar"] }
}
