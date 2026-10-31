import Quickshell
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

// Wi-Fi & Network: radio on/off, join networks (with password), disconnect, forget; wired status.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.filter(d => d.type === DeviceType.Wired)
    property var askFor: null

    Component.onCompleted: if (wifi) wifi.scannerEnabled = true
    Component.onDestruction: if (wifi) wifi.scannerEnabled = false

    SettingGroup {
        SettingRow {
            label: "Wi-Fi"
            hint: Networking.wifiHardwareEnabled ? "" : "Turned off by the hardware switch / airplane mode"
            Toggle { checked: Networking.wifiEnabled; onToggled: v => Networking.wifiEnabled = v }
        }
    }

    SettingGroup {
        title: "Networks"
        visible: Networking.wifiEnabled
        Repeater {
            model: (page.wifi?.networks.values ?? []).filter(n => n.name)
                .sort((a, b) => b.connected - a.connected || b.known - a.known || b.signalStrength - a.signalStrength)
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: (modelData.connected ? "Connected · " : modelData.known ? "Saved · " : "")
                    + Math.round(modelData.signalStrength * 100) + "% signal"
                    + (modelData.security === WifiSecurityType.Open ? " · open network" : "")
                PillButton {
                    visible: modelData.known && !modelData.connected
                    text: "Forget"
                    onClicked: modelData.forget()
                }
                PillButton {
                    text: modelData.connected ? "Disconnect" : "Join"
                    primary: !modelData.connected
                    onClicked: {
                        if (modelData.connected) modelData.disconnect()
                        else if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect()
                        else page.askFor = modelData
                    }
                }
            }
        }
    }

    SettingGroup {
        title: "Join " + (page.askFor?.name ?? "")
        visible: page.askFor !== null
        SettingRow {
            label: "Password"
            Rectangle {
                width: 260; height: 30; radius: 10
                color: Theme.fill
                border { color: Theme.accent; width: 1 }
                TextInput {
                    id: psk
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 13 }
                    focus: page.askFor !== null
                    onAccepted: joinButton.clicked()
                }
            }
            PillButton { text: "Cancel"; onClicked: { psk.text = ""; page.askFor = null } }
            PillButton {
                id: joinButton
                text: "Join"
                primary: true
                onClicked: { page.askFor.connectWithPsk(psk.text); psk.text = ""; page.askFor = null }
            }
        }
    }

    SettingGroup {
        title: "Wired"
        visible: page.wired.length > 0
        Repeater {
            model: page.wired
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: modelData.connected ? "Connected" : "Cable unplugged"
            }
        }
    }

    SettingGroup {
        title: "Advanced"
        SettingRow {
            label: "VPN, static IP, DNS, hotspot"
            hint: "Opens NetworkManager's connection editor"
            PillButton { text: "Open"; onClicked: Quickshell.execDetached(["nm-connection-editor"]) }
        }
    }
}
