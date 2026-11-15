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
// A flyout shows one list (host.fixed: "wifi" or "bt") without the tiles (tiles: []).
ColumnLayout {
    id: mod
    Layout.fillWidth: true
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    property var tiles: []   // the Control Center passes its shown tiles; a flyout shows none
    spacing: ControlCenter.gap

    // ---- connections: Wi-Fi, Bluetooth, Focus, Night Light --------------------------------
    GridLayout {
        visible: mod.tiles.length > 0
        Layout.fillWidth: true
        columns: 2
        columnSpacing: ControlCenter.gap
        rowSpacing: ControlCenter.gap
        ControlCenterConnTile {
            visible: mod.tiles.includes("wifi")
            Layout.row: Math.floor(Math.max(0, mod.tiles.indexOf("wifi")) / 2); Layout.column: Math.max(0, mod.tiles.indexOf("wifi")) % 2
            glyph: Networking.wifiEnabled ? "\u{F05A9}" : "\u{F05AA}"
            title: "Wi-Fi"
            subtitle: !Networking.wifiEnabled ? "Off" : (Sys.wifi?.networks.values.find(n => n.connected)?.name ?? "Not connected")
            active: Networking.wifiEnabled
            isExpanded: mod.host.expanded === "wifi"
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            onExpand: mod.host.toggleExpanded("wifi")
        }
        ControlCenterConnTile {
            visible: mod.tiles.includes("bt")
            Layout.row: Math.floor(Math.max(0, mod.tiles.indexOf("bt")) / 2); Layout.column: Math.max(0, mod.tiles.indexOf("bt")) % 2
            glyph: Sys.adapter?.enabled ? "\u{F00AF}" : "\u{F00B2}"
            title: "Bluetooth"
            subtitle: !Sys.adapter ? "Unavailable" : !Sys.adapter.enabled ? "Off"
                    : (Sys.adapter.devices.values.filter(d => d.connected).map(d => d.name).join(", ") || "On")
            active: Sys.adapter?.enabled ?? false
            isExpanded: mod.host.expanded === "bt"
            onToggled: if (Sys.adapter) Sys.adapter.enabled = !Sys.adapter.enabled
            onExpand: mod.host.toggleExpanded("bt")
        }
        ControlCenterConnTile {
            visible: mod.tiles.includes("focus")
            Layout.row: Math.floor(Math.max(0, mod.tiles.indexOf("focus")) / 2); Layout.column: Math.max(0, mod.tiles.indexOf("focus")) % 2
            glyph: "\u{F0594}"
            title: "Focus"
            subtitle: Config.notifications.dnd ? "Do Not Disturb" : "Off"
            active: Config.notifications.dnd
            expandable: false
            onToggled: Config.set("notifications", "dnd", !Config.notifications.dnd)
        }
        ControlCenterConnTile {
            visible: mod.tiles.includes("nightlight")
            Layout.row: Math.floor(Math.max(0, mod.tiles.indexOf("nightlight")) / 2); Layout.column: Math.max(0, mod.tiles.indexOf("nightlight")) % 2
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
        open: mod.host.expanded === "wifi"
        title: "Wi-Fi"
        switchOn: Networking.wifiEnabled
        onSwitched: Networking.wifiEnabled = !Networking.wifiEnabled
        settingsLabel: "Network Settings…"
        settingsPage: "network"

        // one row per name (the strongest access point), known networks first
        readonly property var nets: {
            const best = {}
            for (const n of Sys.wifi?.networks.values ?? []) if (n.name && (!best[n.name] || n.connected || n.signalStrength > best[n.name].signalStrength)) best[n.name] = n
            return Object.values(best).sort((a, b) => b.connected - a.connected || b.signalStrength - a.signalStrength)
        }
        readonly property var known: nets.filter(n => n.known || n.connected)
        readonly property var others: nets.filter(n => !n.known && !n.connected).slice(0, 6)

        ControlCenterSectionLabel { visible: wifiDrop.known.length > 0 && Networking.wifiEnabled; text: "Known networks" }
        Repeater { model: Networking.wifiEnabled ? wifiDrop.known : []; ControlCenterWifiRow { host: mod.host } }
        ControlCenterSectionLabel { visible: wifiDrop.others.length > 0 && Networking.wifiEnabled; text: "Other networks" }
        Repeater { model: Networking.wifiEnabled ? wifiDrop.others : []; ControlCenterWifiRow { host: mod.host } }
        ControlCenterEmpty {
            shown: !Networking.wifiEnabled || wifiDrop.nets.length === 0
            text: !Networking.wifiEnabled ? "Wi-Fi is off." : "Looking for networks…"
        }
    }

    ControlCenterDrop {
        id: btDrop
        open: mod.host.expanded === "bt"
        title: "Bluetooth"
        switchOn: Sys.adapter?.enabled ?? false
        onSwitched: if (Sys.adapter) Sys.adapter.enabled = !Sys.adapter.enabled
        settingsLabel: "Bluetooth Settings…"
        settingsPage: "bluetooth"

        readonly property var devices: (Sys.adapter?.devices.values ?? []).filter(d => d.paired || d.connected)
            .sort((a, b) => b.connected - a.connected || a.name.localeCompare(b.name))

        ControlCenterSectionLabel { visible: btDrop.devices.length > 0 && (Sys.adapter?.enabled ?? false); text: "My devices" }
        Repeater {
            model: Sys.adapter?.enabled ? btDrop.devices : []
            ControlCenterDeviceRow {
                required property var modelData
                readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                glyph: Sys.btGlyph(modelData.icon)
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
            shown: !(Sys.adapter?.enabled ?? false) || btDrop.devices.length === 0
            text: !Sys.adapter ? "No Bluetooth adapter." : !Sys.adapter.enabled ? "Bluetooth is off." : "No paired devices yet. Pair one in Bluetooth Settings."
        }
    }
}
