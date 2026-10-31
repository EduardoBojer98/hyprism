import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Battery & Power: battery state and health, power mode, charge limit (asusctl).
// Fans and power limits live on the ASUS Hardware page (asusd); not in ROG Control Center, which
// changes the same settings behind this setup's back.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var bat: UPower.displayDevice
    readonly property var laptopBattery: UPower.devices.values.find(d => d.isLaptopBattery) ?? null
    property int limit: 0

    Process {
        running: true
        command: ["cat", "/sys/class/power_supply/BAT0/charge_control_end_threshold"]
        stdout: StdioCollector { onStreamFinished: page.limit = parseInt(text) }
    }

    SettingGroup {
        title: "Battery"
        SettingRow {
            label: Math.round((page.bat?.percentage ?? 0) * 100) + "%  ·  " + UPowerDeviceState.toString(page.bat?.state ?? 0)
            hint: {
                const s = page.bat?.state === UPowerDeviceState.Charging ? page.bat.timeToFull : page.bat?.timeToEmpty ?? 0
                return s > 0 && s < 86400 ? Math.floor(s / 3600) + " h " + Math.round(s % 3600 / 60) + " min " + (page.bat.state === UPowerDeviceState.Charging ? "until full" : "left") : ""
            }
        }
        SettingRow {
            visible: page.laptopBattery?.healthSupported ?? false
            label: "Battery health"
            hint: "Capacity compared to when it was new"
            Text {
                text: Math.round(page.laptopBattery?.healthPercentage ?? 0) + "%"
                color: Theme.text
                font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold }
            }
        }
        SettingRow {
            visible: Machine.asus
            label: "Charge limit"
            hint: "Stopping at 80 % keeps the battery healthy when the laptop is mostly plugged in"
            Choice {
                readonly property var values: [60, 80, 100]
                options: values.map(v => v + "%")
                index: values.indexOf(page.limit)
                onPicked: i => {
                    page.limit = values[i]
                    Quickshell.execDetached(["asusctl", "battery", "limit", String(values[i])])
                }
            }
        }
    }

    SettingGroup {
        title: "Low battery warning"
        SettingRow {
            label: "Warn me"
            hint: "A notification while on battery; the critical one stays until you dismiss it"
            ConfigToggle { section: "battery"; key: "warn" }
        }
        SettingRow {
            visible: Config.battery.warn
            label: "Low at"
            ConfigChoice { section: "battery"; key: "warnAt"; values: [10, 15, 20, 30]; labels: ["10%", "15%", "20%", "30%"] }
        }
        SettingRow {
            visible: Config.battery.warn
            label: "Critical at"
            ConfigChoice { section: "battery"; key: "criticalAt"; values: [3, 5, 8]; labels: ["3%", "5%", "8%"] }
        }
    }

    SettingGroup {
        title: "Performance"
        SettingRow {
            label: "Power mode"
            hint: "Quiet: browsing, documents, battery. Balanced: daily work and builds. Performance: short heavy jobs on AC. Plugging in switches to Balanced, battery to Quiet."
            Choice {
                options: ["Quiet", "Balanced", "Performance"]
                index: PowerMode.profile
                onPicked: i => PowerMode.set(i)
            }
        }
    }

    // Lid: read only. logind's file is a system file (system/02-desktop.sh writes it)
    readonly property var lidWords: ({ "suspend": "Sleep", "suspend-then-hibernate": "Sleep, then hibernate", "hibernate": "Hibernate",
                                       "ignore": "Nothing", "lock": "Lock", "poweroff": "Shut down" })
    property var lid: ({})
    Process {
        running: true
        command: ["sh", "-c", "systemd-analyze cat-config systemd/logind.conf 2>/dev/null | grep -E '^HandleLidSwitch'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const l of text.trim().split("\n")) { const i = l.indexOf("="); if (i > 0) o[l.slice(0, i)] = l.slice(i + 1).trim() }
                page.lid = o
            }
        }
    }
    SettingGroup {
        title: "When the lid closes"
        SettingRow {
            label: "On battery"
            hint: "Set by the install script (system/02-desktop.sh)"
            LidValue { text: page.lidWords[page.lid.HandleLidSwitch ?? "suspend"] ?? page.lid.HandleLidSwitch }
        }
        SettingRow {
            label: "Plugged in"
            LidValue { text: page.lidWords[page.lid.HandleLidSwitchExternalPower ?? page.lid.HandleLidSwitch ?? "suspend"] ?? "" }
        }
        SettingRow {
            label: "With an external screen"
            LidValue { text: page.lidWords[page.lid.HandleLidSwitchDocked ?? "ignore"] ?? "" }
        }
    }

    SettingGroup {
        visible: Machine.asus
        title: "ASUS hardware"
        SettingRow {
            label: "Temperatures, fans and power limits"
            PillButton { text: "Open"; onClicked: SettingsApp.show("asus") }
        }
    }

    component LidValue: Text {
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 13 }
    }
}
