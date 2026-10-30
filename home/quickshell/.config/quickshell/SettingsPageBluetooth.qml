import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Bluetooth: on/off, scan, pair, connect, forget.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter ? adapter.devices.values : []

    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    SettingGroup {
        SettingRow {
            label: "Bluetooth"
            hint: page.adapter ? page.adapter.name : "No Bluetooth adapter found"
            Toggle { checked: page.adapter?.enabled ?? false; onToggled: v => { if (page.adapter) page.adapter.enabled = v } }
        }
        SettingRow {
            visible: page.adapter?.enabled ?? false
            label: "Find new devices"
            hint: page.adapter?.discovering ? "Scanning… put your device in pairing mode" : ""
            PillButton {
                text: page.adapter?.discovering ? "Stop" : "Scan"
                onClicked: page.adapter.discovering = !page.adapter.discovering
            }
        }
    }

    SettingGroup {
        title: "My devices"
        visible: page.adapter?.enabled ?? false
        SettingRow { visible: !page.devices.some(d => d.paired); label: "No paired devices yet" }
        Repeater {
            model: page.devices.filter(d => d.paired).sort((a, b) => b.connected - a.connected)
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: (modelData.connected ? "Connected" : "Not connected")
                    + (modelData.batteryAvailable ? " · battery " + Math.round(modelData.battery * 100) + "%" : "")
                PillButton { text: "Forget"; onClicked: modelData.forget() }
                PillButton {
                    text: modelData.connected ? "Disconnect" : "Connect"
                    primary: !modelData.connected
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
        }
    }

    SettingGroup {
        title: "Nearby"
        visible: (page.adapter?.enabled ?? false) && page.adapter.discovering
        Repeater {
            model: page.devices.filter(d => !d.paired && d.name)
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: modelData.pairing ? "Pairing…" : modelData.address
                PillButton { text: "Pair"; primary: true; enabled: !modelData.pairing; onClicked: { modelData.trusted = true; modelData.pair() } }
            }
        }
    }
}
