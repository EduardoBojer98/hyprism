import QtQuick
import QtQuick.Layouts

// Notifications: popups, Do Not Disturb and the notification centre's history.
ColumnLayout {
    spacing: 20
    SettingGroup {
        SettingRow {
            label: "Do Not Disturb"
            hint: "Popups stay silent; everything still lands in the notification centre"
            ConfigToggle { section: "notifications"; key: "dnd" }
        }
        SettingRow {
            label: "Popups stay for"
            hint: "Critical notifications stay until dismissed"
            ConfigChoice { section: "notifications"; key: "timeoutSec"; values: [4, 6, 10, 15]; labels: ["4 s", "6 s", "10 s", "15 s"] }
        }
        SettingRow {
            label: "Keep in history"
            ConfigChoice { section: "notifications"; key: "historyMax"; values: [50, 100, 300]; labels: ["50", "100", "300"] }
        }
    }
    ResetGroup { sections: ["notifications"] }
}
