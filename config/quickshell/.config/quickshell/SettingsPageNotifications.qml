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
            label: "Popups stay for"
            hint: "Critical notifications stay until dismissed"
            ConfigChoice { section: "notifications"; key: "timeoutSec"; values: [4, 6, 10, 15]; labels: ["4 s", "6 s", "10 s", "15 s"] }
        }
    }

    SettingGroup {
        title: "On-screen display"
        SettingRow { label: "Volume"; hint: "A pop-up when the volume or mute changes"; ConfigToggle { section: "osd"; key: "volume" } }
        SettingRow { label: "Brightness"; ConfigToggle { section: "osd"; key: "brightness" } }
        SettingRow { label: "Microphone mute"; ConfigToggle { section: "osd"; key: "micMute" } }
        SettingRow { label: "Keyboard layout"; ConfigToggle { section: "osd"; key: "layout" } }
        SettingRow {
            label: "Caps Lock"
            hint: "Checks the keyboard's light twice a second while on"
            ConfigToggle { section: "osd"; key: "capsLock" }
        }
        SettingRow {
            label: "Position"
            ConfigChoice { section: "osd"; key: "position"; values: ["bottom", "top", "center"]; labels: ["Bottom", "Top", "Center"] }
        }
        SettingRow {
            label: "Stays for"
            ConfigSlider { section: "osd"; key: "timeoutMs"; from: 600; to: 5000; step: 100; format: v => (v / 1000).toFixed(1) + " s" }
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
