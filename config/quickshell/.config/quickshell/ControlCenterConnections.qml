import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center part: the Wi-Fi, Bluetooth, Focus and Night Light tiles, with the Wi-Fi and Bluetooth dropdowns under them.
// Used by ControlCenter.qml; reads the panel's state from the ControlCenter singleton.
ColumnLayout {
    Layout.fillWidth: true
    Layout.row: Math.max(0, ControlCenter.shownSections.indexOf("connections"))
    visible: ControlCenter.shownSections.includes("connections")
    spacing: ControlCenter.gap

    // ---- connections: Wi-Fi, Bluetooth, Focus, Night Light --------------------------------
    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: ControlCenter.gap
        rowSpacing: ControlCenter.gap
        ControlCenterConnTile {
            visible: ControlCenter.shownTiles.includes("wifi")
            Layout.row: Math.floor(Math.max(0, ControlCenter.shownTiles.indexOf("wifi")) / 2); Layout.column: Math.max(0, ControlCenter.shownTiles.indexOf("wifi")) % 2
            glyph: Networking.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
            title: "Wi-Fi"
            subtitle: !Networking.wifiEnabled ? "Off" : (ControlCenter.wifi?.networks.values.find(n => n.connected)?.name ?? "Not connected")
            active: Networking.wifiEnabled
            isExpanded: ControlCenter.expanded === "wifi"
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            onExpand: ControlCenter.toggleExpanded("wifi")
        }
        ControlCenterConnTile {
            visible: ControlCenter.shownTiles.includes("bt")
            Layout.row: Math.floor(Math.max(0, ControlCenter.shownTiles.indexOf("bt")) / 2); Layout.column: Math.max(0, ControlCenter.shownTiles.indexOf("bt")) % 2
            glyph: ControlCenter.adapter?.enabled ? "\u{F00AF}" : "\u{F00B2}"
            title: "Bluetooth"
            subtitle: !ControlCenter.adapter ? "Unavailable" : !ControlCenter.adapter.enabled ? "Off"
                    : (ControlCenter.adapter.devices.values.filter(d => d.connected).map(d => d.name).join(", ") || "On")
            active: ControlCenter.adapter?.enabled ?? false
            isExpanded: ControlCenter.expanded === "bt"
            onToggled: if (ControlCenter.adapter) ControlCenter.adapter.enabled = !ControlCenter.adapter.enabled
            onExpand: ControlCenter.toggleExpanded("bt")
        }
        ControlCenterConnTile {
            visible: ControlCenter.shownTiles.includes("focus")
            Layout.row: Math.floor(Math.max(0, ControlCenter.shownTiles.indexOf("focus")) / 2); Layout.column: Math.max(0, ControlCenter.shownTiles.indexOf("focus")) % 2
            glyph: "\u{F0594}"
            title: "Focus"
            subtitle: Config.notifications.dnd ? "Do Not Disturb" : "Off"
            active: Config.notifications.dnd
            expandable: false
            onToggled: Config.set("notifications", "dnd", !Config.notifications.dnd)
        }
        ControlCenterConnTile {
            visible: ControlCenter.shownTiles.includes("nightlight")
            Layout.row: Math.floor(Math.max(0, ControlCenter.shownTiles.indexOf("nightlight")) / 2); Layout.column: Math.max(0, ControlCenter.shownTiles.indexOf("nightlight")) % 2
            glyph: "\u{F0599}"
            title: "Night Light"
            subtitle: ({ off: "Off", on: "On", sun: "Sunset to sunrise", schedule: `${Config.nightLight.from}–${Config.nightLight.to}` })[Config.nightLight.mode]
            active: NightLight.active
            expandable: false
            onToggled: NightLight.toggle()
        }
    }

    // ---- Wi-Fi and Bluetooth dropdowns, under their tiles ----------------------------------
    ControlCenterDrop {
        id: wifiDrop
        open: ControlCenter.expanded === "wifi"
        title: "Wi-Fi"
        switchOn: Networking.wifiEnabled
        onSwitched: Networking.wifiEnabled = !Networking.wifiEnabled
        settingsLabel: "Network Settings…"
        settingsPage: "network"

        // one row per name (the strongest access point), known networks first
        readonly property var nets: {
            const best = {}
            for (const n of ControlCenter.wifi?.networks.values ?? []) if (n.name && (!best[n.name] || n.connected || n.signalStrength > best[n.name].signalStrength)) best[n.name] = n
            return Object.values(best).sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength)
        }
        readonly property var known: nets.filter(n => n.known || n.connected)
        readonly property var others: nets.filter(n => !n.known && !n.connected).slice(0, 6)

        ControlCenterSectionLabel { visible: wifiDrop.known.length > 0 && Networking.wifiEnabled; text: "Known networks" }
        Repeater { model: Networking.wifiEnabled ? wifiDrop.known : []; ControlCenterWifiRow {} }
        ControlCenterSectionLabel { visible: wifiDrop.others.length > 0 && Networking.wifiEnabled; text: "Other networks" }
        Repeater { model: Networking.wifiEnabled ? wifiDrop.others : []; ControlCenterWifiRow {} }
        ControlCenterEmpty {
            shown: !Networking.wifiEnabled || wifiDrop.nets.length === 0
            text: !Networking.wifiEnabled ? "Wi-Fi is off." : "Looking for networks…"
        }
    }

    ControlCenterDrop {
        id: btDrop
        open: ControlCenter.expanded === "bt"
        title: "Bluetooth"
        switchOn: ControlCenter.adapter?.enabled ?? false
        onSwitched: if (ControlCenter.adapter) ControlCenter.adapter.enabled = !ControlCenter.adapter.enabled
        settingsLabel: "Bluetooth Settings…"
        settingsPage: "bluetooth"

        readonly property var devices: (ControlCenter.adapter?.devices.values ?? []).filter(d => d.paired || d.connected)
            .sort((a, b) => b.connected - a.connected || a.name.localeCompare(b.name))

        ControlCenterSectionLabel { visible: btDrop.devices.length > 0 && (ControlCenter.adapter?.enabled ?? false); text: "My devices" }
        Repeater {
            model: ControlCenter.adapter?.enabled ? btDrop.devices : []
            ControlCenterDeviceRow {
                required property var modelData
                readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                glyph: ControlCenter.btGlyph(modelData.icon)
                title: modelData.name
                subtitle: modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                        : modelData.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                        : modelData.connected ? "Connected" + (modelData.batteryAvailable ? `  ·  ${Math.round(modelData.battery * 100)}% battery` : "")
                        : "Not connected"
                selected: modelData.connected
                action: busy ? "" : modelData.connected ? "Disconnect" : "Connect"
                onClicked: if (!busy) modelData.connected ? modelData.disconnect() : modelData.connect()
            }
        }
        ControlCenterEmpty {
            shown: !(ControlCenter.adapter?.enabled ?? false) || btDrop.devices.length === 0
            text: !ControlCenter.adapter ? "No Bluetooth adapter." : !ControlCenter.adapter.enabled ? "Bluetooth is off." : "No paired devices yet. Pair one in Bluetooth Settings."
        }
    }
}
