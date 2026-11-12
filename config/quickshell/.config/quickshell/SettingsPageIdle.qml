import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Lock & Sleep: when to dim, lock, turn the screens off and sleep. Edits settings.json (idle); SettingsSync.qml
// writes hypr/settings/hypridle.conf from it and restarts hypridle.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var lockOptions: [2, 5, 10, 15, 0]     // minutes, 0 = never
    readonly property var sleepOptions: [10, 20, 30, 60, 0]
    readonly property int lockMin: Config.idle.lockMin
    readonly property int sleepMin: Config.idle.sleepMin
    readonly property int powerMin: Config.idle.sleepOnPowerMin
    function label(m) { return m === 0 ? "Never" : m + " min" }

    SettingGroup {
        SettingRow {
            label: "Lock the screen after"
            hint: "The screen dims 30 seconds before; screens turn off 30 seconds after"
            Choice {
                options: page.lockOptions.map(page.label)
                index: page.lockOptions.indexOf(page.lockMin)
                extra: index < 0 ? page.lockMin + " min (custom)" : ""
                onPicked: i => Config.set("idle", "lockMin", page.lockOptions[i])
            }
        }
        SettingRow {
            visible: Sys.hasBattery
            label: "Sleep on battery after"
            hint: Machine.canHibernate ? "Sleeping laptops hibernate after another hour to save the battery" : "Turns the screens off and sleeps"
            Choice {
                options: page.sleepOptions.map(page.label)
                index: page.sleepOptions.indexOf(page.sleepMin)
                extra: index < 0 ? page.sleepMin + " min (custom)" : ""
                onPicked: i => Config.set("idle", "sleepMin", page.sleepOptions[i])
            }
        }
        SettingRow {
            label: "Sleep when plugged in after"
            hint: Sys.hasBattery ? "Never by default: a plugged-in computer keeps running" : "Never by default: a desktop keeps running until you choose a time"
            Choice {
                options: page.sleepOptions.map(page.label)
                index: page.sleepOptions.indexOf(page.powerMin)
                extra: index < 0 ? page.powerMin + " min (custom)" : ""
                onPicked: i => Config.set("idle", "sleepOnPowerMin", page.sleepOptions[i])
            }
        }
        SettingRow {
            label: "Lock now"
            PillButton { text: "Lock"; onClicked: Quickshell.execDetached(["loginctl", "lock-session"]) }
        }
    }

    SettingGroup {
        title: "Caffeine"
        SettingRow {
            label: "Keep awake for"
            hint: "Used by the Caffeine button and Spotlight. Stays on across restarts until you turn it off or the time runs out."
            ConfigChoice { section: "caffeine"; key: "defaultMinutes"; values: Caffeine.choices; labels: Caffeine.choices.map(Caffeine.label) }
        }
        SettingRow {
            label: Caffeine.active ? "Caffeine is on" : "Caffeine is off"
            PillButton { text: Caffeine.active ? "Turn off" : "Turn on"; onClicked: Caffeine.toggle() }
        }
    }
}
