import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Lock & Sleep: when to lock, turn the screens off and sleep. Writes hypr/settings/hypridle.conf and
// restarts hypridle.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var lockOptions: [2, 5, 10, 15, 0]     // minutes, 0 = never
    readonly property var sleepOptions: [10, 20, 30, 60, 0]
    property int lockMin: 5
    property int sleepMin: 20

    Process {
        running: true
        command: ["sh", "-c", "cat \"$HOME/.config/hypr/settings/hypridle.conf\""]
        stdout: StdioCollector {
            onStreamFinished: {
                // each listener block: its timeout and what it runs
                const blocks = text.split("listener").slice(1)
                const lock = blocks.find(b => b.includes("lock-session"))
                const sleep = blocks.find(b => b.includes("systemctl suspend"))
                const minutes = b => b ? Math.round(parseInt(b.match(/timeout\s*=\s*(\d+)/)[1]) / 60) : 0
                page.lockMin = minutes(lock)
                page.sleepMin = minutes(sleep)
            }
        }
    }

    readonly property string screensOn: "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'"

    function label(m) { return m === 0 ? "Never" : m + " min" }

    function save() {
        const blocks = []
        if (lockMin > 0) {
            blocks.push("# " + lockMin + " min: lock\nlistener {\n    timeout    = " + lockMin * 60 + "\n    on-timeout = loginctl lock-session\n}")
            blocks.push("# 30 s later: screens off\nlistener {\n    timeout    = " + (lockMin * 60 + 30) + "\n    on-timeout = hyprctl dispatch 'hl.dsp.dpms({ action = \"disable\" })'\n    on-resume  = hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'\n}")
        }
        if (sleepMin > 0)
            // screens on first: an output that sleeps while off loses its CRTC and wakes black
            blocks.push("# " + sleepMin + " min: sleep, then hibernate after 60 more min\nlistener {\n    timeout    = " + sleepMin * 60 + "\n    on-timeout = " + page.screensOn + "; systemctl suspend-then-hibernate\n}")
        const text = "# Written by the Settings app (Lock & Sleep). hypridle still uses hyprlang.\n"
            + "general {\n    lock_cmd         = pidof hyprlock || hyprlock\n    before_sleep_cmd = loginctl lock-session; " + page.screensOn + "\n"
            + "    after_sleep_cmd  = hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'\n}\n\n" + blocks.join("\n\n")
        SettingsApp.writeHyprFile("settings/hypridle.conf", text)
        Quickshell.execDetached(["sh", "-c", "sleep 0.3; pkill -x hypridle; hyprctl dispatch 'hl.dsp.exec_cmd(\"hypridle -c ~/.config/hypr/settings/hypridle.conf\")'"])
    }

    SettingGroup {
        SettingRow {
            label: "Lock the screen after"
            hint: "Screens turn off 30 seconds later"
            Choice {
                options: page.lockOptions.map(page.label)
                index: page.lockOptions.indexOf(page.lockMin)
                onPicked: i => { page.lockMin = page.lockOptions[i]; page.save() }
            }
        }
        SettingRow {
            label: "Sleep after"
            hint: "Sleeping laptops hibernate after another hour to save the battery"
            Choice {
                options: page.sleepOptions.map(page.label)
                index: page.sleepOptions.indexOf(page.sleepMin)
                onPicked: i => { page.sleepMin = page.sleepOptions[i]; page.save() }
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
