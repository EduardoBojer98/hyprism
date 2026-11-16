import Quickshell
import QtQuick
import QtQuick.Layouts

// Menu Bar: the items are one layout for every theme; place, size and shape belong to each theme. First its items and the picked item's own settings, then where it
// sits, its size and shape (all saved in Config.bar.layout by the first change; "Use the theme's" puts the theme's
// own back), starting points, and a list of its own or no bar per screen.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var b: Config.bar

    // ---- items: a copy of the bar to drag them around on ------------------------------------------------
    SettingGroup {
        title: "Items"
        BarEditor {
            id: barEditor
            Layout.fillWidth: true
            Layout.margins: 12
            floatOn: page.parent
        }
        SettingRow {
            visible: barEditor.onScreen
            label: "Same items as every screen"
            hint: barEditor.screen + " has a list of its own"
            PillButton { text: "Use the shared list"; onClicked: layoutPane.setScreen(barEditor.screen, "Same as every screen") }
        }
    }

    SettingsBarItem { editor: barEditor }

    SettingGroup {
        title: "Place"
        SettingRow {
            label: "Position"
            hint: "For " + Theme.current.name + " on every screen: each theme keeps its own place, size and shape"
            Choice {
                readonly property var values: ["top", "bottom", "left", "right"]
                options: ["Top", "Bottom", "Left", "Right"]
                index: values.indexOf(Theme.barEdge)
                onPicked: i => Theme.setLayout({ edge: values[i] })
            }
        }
        SettingRow {   // the sizes that ship, over a slider for any size between: a size of your own lights no chip
            label: "Size"
            hint: Theme.barSize + " px across" + ([26, 34, 44, 56].includes(Theme.barSize) ? "" : ", your own size")
            PresetSlider {
                values: [26, 34, 44, 56]
                options: ["Slim", "Regular", "Tall", "Huge"]
                from: 24; to: 56                  // below 24 px an item (24 px at least) no longer fits the bar
                value: Theme.barSize
                unit: "px"
                accessibleName: "Size"
                onPicked: v => Theme.setLayout({ size: v })
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

    SettingsBarLayout { id: layoutPane; Layout.fillWidth: true; editor: barEditor }

    // Reset: the clock's and the bar's defaults; the layout goes back to the theme's own
    ResetGroup { sections: ["bar"] }
}
