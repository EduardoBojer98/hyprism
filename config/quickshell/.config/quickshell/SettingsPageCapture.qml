import QtQuick
import QtQuick.Layouts

// Screenshots and recordings: ~/.local/bin/screenshot and record read Config.capture. Print opens the capture bar.
ColumnLayout {
    spacing: 20

    SettingGroup {
        title: "Screenshots"
        SettingRow {
            label: "After taking one"
            hint: "Annotate opens the editor (arrows, text, highlight, blur); Enter copies, Ctrl+S saves"
            ConfigChoice { section: "capture"; key: "after"; values: ["edit", "copy", "save"]; labels: ["Annotate", "Copy", "Save and copy"] }
        }
        SettingRow {
            label: "Save to"
            ConfigChoice {
                section: "capture"; key: "folder"
                values: ["~/Pictures/Screenshots", "~/Pictures", "~/Desktop"]
                labels: ["Pictures › Screenshots", "Pictures", "Desktop"]
            }
        }
        SettingRow {
            label: "Wait before a full-screen picture"
            hint: "Time to open a menu first"
            ConfigChoice { section: "capture"; key: "delay"; values: [0, 3, 5, 10]; labels: ["No wait", "3 s", "5 s", "10 s"] }
        }
        SettingRow {
            label: "Show a notification"
            hint: "With the picture; click it to open the folder"
            ConfigToggle { section: "capture"; key: "notify" }
        }
    }

    SettingGroup {
        title: "Recordings"
        SettingRow {
            label: "Sound"
            ConfigChoice { section: "capture"; key: "audio"; values: ["none", "desktop", "mic"]; labels: ["None", "Computer sound", "Microphone"] }
        }
        SettingRow {
            label: "Save to"
            ConfigChoice { section: "capture"; key: "recordFolder"; values: ["~/Videos/Recordings", "~/Videos"]; labels: ["Videos › Recordings", "Videos"] }
        }
    }

    ResetGroup { sections: ["capture"] }
}
