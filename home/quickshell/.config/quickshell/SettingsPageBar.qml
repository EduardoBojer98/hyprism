import QtQuick
import QtQuick.Layouts

// Menu Bar: the clock's format and which items the top bar shows (Config.bar).
ColumnLayout {
    spacing: 20

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
            ConfigChoice { section: "bar"; key: "date"; values: ["full", "short", "none"]; labels: ["Fri 30 Oct", "30 Oct", "None"] }
        }
    }

    SettingGroup {
        title: "Show in the menu bar"
        SettingRow {
            label: "Window title"
            hint: "After the app's name, on the left"
            ConfigToggle { section: "bar"; key: "windowTitle" }
        }
        SettingRow {
            label: "Weather"
            ConfigToggle { section: "bar"; key: "weather" }
        }
        SettingRow {
            label: "Temperatures"
            hint: "CPU and graphics; click them for the system details"
            ConfigToggle { section: "bar"; key: "temperatures" }
        }
        SettingRow {
            label: "Keyboard layout"
            hint: "Only when you have more than one layout"
            ConfigToggle { section: "bar"; key: "keyboard" }
        }
        SettingRow {
            label: "Battery percentage"
            ConfigToggle { section: "bar"; key: "batteryPercent" }
        }
    }

    ResetGroup { sections: ["bar"] }
}
