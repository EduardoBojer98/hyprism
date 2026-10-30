import QtQuick
import QtQuick.Layouts

// Control Center: which optional sections the quick-settings panel shows.
ColumnLayout {
    spacing: 20
    SettingGroup {
        SettingRow { label: "Media controls"; hint: "Shown while something is playing"; ConfigToggle { section: "controlCenter"; key: "showMedia" } }
        SettingRow { label: "Hardware summary"; hint: "Power mode, temperatures and fan speed"; ConfigToggle { section: "controlCenter"; key: "showHardware" } }
    }
    ResetGroup { sections: ["controlCenter"] }
}
