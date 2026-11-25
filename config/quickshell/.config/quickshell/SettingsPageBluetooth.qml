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
    readonly property bool on: adapter?.enabled ?? false

    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    SettingGroup {
        SettingRow {
            label: "Bluetooth"
            hint: !page.adapter ? "No Bluetooth adapter found"
                : page.adapter.enabled ? page.adapter.name : "Off: turn it on to connect headphones, keyboards, mice and more"
            Toggle { checked: page.adapter?.enabled ?? false; onToggled: v => Sys.setBluetooth(v) }
        }
        SettingRow {
            visible: page.on
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
        visible: page.adapter !== null && (page.on || page.devices.some(d => d.paired))
        SettingRow { visible: !page.devices.some(d => d.paired); label: "No paired devices yet"; hint: "Press Scan, then put your device in pairing mode" }
        Repeater {
            model: page.devices.filter(d => d.paired).sort((a, b) => b.connected - a.connected)
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: !page.on ? "Paired; connects when Bluetooth is on" : (modelData.connected ? "Connected" : "Not connected")
                    + (modelData.batteryAvailable ? " · battery " + Math.round(modelData.battery * 100) + "%" : "")
                PillButton { text: "Forget"; onClicked: modelData.forget() }
                PillButton {
                    text: modelData.connected ? "Disconnect" : "Connect"
                    primary: !modelData.connected
                    enabled: page.on
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                }
            }
        }
    }

    SettingGroup {
        title: "Nearby"
        visible: page.on && page.adapter.discovering
        SettingRow { visible: !page.devices.some(d => !d.paired && d.name); label: "Nothing found yet"; hint: "Devices in pairing mode show up here within a few seconds" }
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
