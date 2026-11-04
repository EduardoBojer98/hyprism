import QtQuick
import QtQuick.Layouts

// Notifications: popups, sound, Do Not Disturb, apps kept quiet and the notification centre's history.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var c: Config.notifications
    readonly property var soundIds: [""].concat(Object.keys(Notifications.sounds))
    // apps that have sent something (still in the history), plus any muted earlier
    readonly property var apps: [...new Set(Notifications.history.map(n => n.appName || "Other").concat(c.mutedApps))].sort((a, b) => a.localeCompare(b))

    SettingGroup {
        title: "Popups"
        SettingRow {
            label: "Do Not Disturb"
            hint: "No popups or sound; everything still lands in the notification centre"
            ConfigToggle { section: "notifications"; key: "dnd" }
        }
        SettingRow {
            label: "Style"
            hint: ({ card: "Standard card with icon and summary", pill: "Compact one-line pill", minimal: "Clean minimal card with no border" })[Config.notifications.style] ?? ""
            ConfigChoice { section: "notifications"; key: "style"; values: ["card", "pill", "minimal", "neon"]; labels: ["Card", "Pill", "Minimal", "Neon"] }
        }
        SettingRow {
            label: "Position"
            ConfigChoice { section: "notifications"; key: "position"; values: ["top-left", "top-center", "top-right"]; labels: ["Top left", "Top centre", "Top right"] }
        }
        SettingRow {
            label: "Popups stay for"
            hint: "Critical notifications stay until dismissed"
            ConfigChoice { section: "notifications"; key: "timeoutSec"; values: [4, 6, 10, 15]; labels: ["4 s", "6 s", "10 s", "15 s"] }
        }
    }

    SettingGroup {
        title: "Sound"
        SettingRow {
            label: "Sound"
            hint: "Plays with each popup; not during Do Not Disturb"
            Dropdown {
                width: 160
                options: page.soundIds.map(id => id ? Notifications.sounds[id] : "None")
                current: page.c.sound ? (Notifications.sounds[page.c.sound] ?? page.c.sound) : "None"
                onPicked: v => {
                    const id = page.soundIds[options.indexOf(v)]
                    Config.set("notifications", "sound", id)
                    Notifications.playSound(id)
                }
            }
        }
        SettingRow {
            visible: page.c.sound !== ""
            label: "Volume"
            hint: "Relative to the system volume"
            ConfigSlider { section: "notifications"; key: "volume"; from: 0; to: 100; step: 5; format: v => v + "%" }
        }
        SettingRow {
            visible: page.c.sound !== ""
            label: "Try it"
            PillButton { text: "Play sound"; onClicked: { Notifications.lastSound = 0; Notifications.playSound(page.c.sound) } }
        }
    }

    SettingGroup {
        title: "Apps"
        Text {
            visible: page.apps.length === 0
            Layout.fillWidth: true
            Layout.margins: 16
            text: "Apps show up here once they've sent a notification."
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Repeater {
            model: page.apps
            SettingRow {
                id: appRow
                required property string modelData
                readonly property bool muted: page.c.mutedApps.includes(modelData)
                label: modelData
                hint: muted ? "Only in the notification centre: no popup or sound" : "Popups and sound"
                Toggle {
                    checked: !appRow.muted
                    onToggled: on => Config.set("notifications", "mutedApps",
                        on ? page.c.mutedApps.filter(a => a !== modelData) : page.c.mutedApps.concat([modelData]))
                }
            }
        }
    }

    SettingGroup {
        title: "Notification centre"
        SettingRow {
            label: "Keep in history"
            ConfigChoice { section: "notifications"; key: "historyMax"; values: [50, 100, 300]; labels: ["50", "100", "300"] }
        }
        SettingRow {
            label: "Clear history"
            hint: Notifications.history.length + " notifications"
            PillButton { text: "Clear all"; enabled: Notifications.history.length > 0; onClicked: Notifications.clearAll() }
        }
    }

    ResetGroup { sections: ["notifications"] }
}
