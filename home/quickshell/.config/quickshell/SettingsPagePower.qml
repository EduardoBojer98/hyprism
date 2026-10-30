import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

// Battery & Power: battery state and health, power mode, charge limit (asusctl).
// Fans, GPU and keyboard lights live in ROG Control Center.
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
        title: "Performance"
        SettingRow {
            label: "Power mode"
            hint: "Quiet saves battery and keeps fans down; Performance for heavy builds and games"
            Choice {
                options: ["Quiet", "Balanced", "Performance"]
                index: PowerProfiles.profile
                onPicked: i => PowerProfiles.profile = i
            }
        }
    }

    SettingGroup {
        title: "ASUS hardware"
        SettingRow {
            label: "Fans, NVIDIA GPU, keyboard lights"
            hint: "ROG Control Center"
            PillButton { text: "Open"; onClicked: Quickshell.execDetached(["rog-control-center"]) }
        }
    }
}
