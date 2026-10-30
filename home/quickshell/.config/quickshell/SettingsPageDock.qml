import QtQuick
import QtQuick.Layouts

// Desktop & Dock: the dock at the bottom of each screen.
ColumnLayout {
    spacing: 20

    SettingGroup {
        title: "Dock"
        SettingRow {
            label: "Icon size"
            ConfigChoice { section: "dock"; key: "iconSize"; values: [36, 44, 52, 60]; labels: ["Small", "Medium", "Large", "Huge"] }
        }
        SettingRow {
            label: "Hide automatically"
            hint: "Slides away until the pointer touches the bottom edge"
            ConfigToggle { section: "dock"; key: "autoHide" }
        }
        SettingRow {
            label: "Show open apps that aren't pinned"
            ConfigToggle { section: "dock"; key: "showRunning" }
        }
        SettingRow {
            label: "Pinned apps"
            hint: "Drag an icon sideways to reorder; right-click it for its windows, pin, minimise or quit"
        }
    }

    ResetGroup { sections: ["dock"] }
}
