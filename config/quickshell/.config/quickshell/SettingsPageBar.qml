import QtQuick
import QtQuick.Layouts

// Menu Bar: how the clock and the focused window read. Where the bar sits, its shape and what it
// holds come from the rice (Settings > Rices); these options apply to every rice's bar.
ColumnLayout {
    id: page
    spacing: 20

    Text {
        Layout.fillWidth: true
        text: "The bar's place, shape and items come from the rice (" + Theme.rice.name + "). Change its size in Rices > Adjust."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontLabel }
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
            hint: "Where the rice's bar shows a date"
            ConfigChoice { section: "bar"; key: "date"; values: ["full", "short", "none"]; labels: ["Fri 30 Oct", "30 Oct", "None"] }
        }
    }

    SettingGroup {
        title: "Details"
        SettingRow {
            label: "Window title"
            hint: "After the app's name, where the rice shows one"
            ConfigToggle { section: "bar"; key: "windowTitle" }
        }
    }

    ResetGroup { sections: ["bar"]; keys: ["clock24", "seconds", "date", "windowTitle"] }
}
