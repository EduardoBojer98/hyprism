import QtQuick
import QtQuick.Layouts

// Clipboard: history kept by ~/.local/bin/clipstore (Super+V). Limits apply on the next copy.
ColumnLayout {
    spacing: 20

    SettingGroup {
        title: "History"
        SettingRow {
            label: "Pause history"
            hint: "Nothing new is saved while paused"
            ConfigToggle { section: "clipboard"; key: "paused" }
        }
        SettingRow {
            label: "Keep up to"
            ConfigChoice { section: "clipboard"; key: "maxItems"; values: [50, 300, 1000]; labels: ["50", "300", "1000"] }
        }
        SettingRow {
            label: "Forget entries after"
            hint: "Pinned entries are always kept"
            ConfigChoice { section: "clipboard"; key: "maxAgeDays"; values: [1, 7, 30, 90, 0]; labels: ["1 day", "1 week", "1 month", "3 months", "Never"] }
        }
        SettingRow {
            label: "Save images"
            ConfigToggle { section: "clipboard"; key: "images" }
        }
        SettingRow {
            label: "Skip passwords"
            hint: "Copies that password managers mark as secret are never saved"
            ConfigToggle { section: "clipboard"; key: "skipSensitive" }
        }
    }

    SettingGroup {
        title: "Pasting"
        SettingRow {
            label: "Paste automatically"
            hint: "Choosing an entry pastes it into the app you were in. Off: it's copied, press Ctrl+V yourself"
            ConfigToggle { section: "clipboard"; key: "autoPaste" }
        }
        SettingRow {
            label: "Clear history"
            hint: "Removes everything except pinned entries"
            PillButton { text: "Clear"; onClicked: Clipboard.run(["clear"]) }
        }
    }

    ResetGroup { sections: ["clipboard"] }
}
