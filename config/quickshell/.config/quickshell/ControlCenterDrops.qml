import Quickshell
import Quickshell.Networking
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

// Control Center part: the lists a tile opens underneath it (Wi-Fi networks, Bluetooth devices, Caffeine's
// durations). Large tiles (ControlCenterConnections) and small ones (ControlCenterToggles) each put one under
// their grid, for the tiles they hold (`ids`); a flyout shows its one list (host.fixed).
ColumnLayout {
    id: drops
    Layout.fillWidth: true
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    property var ids: []      // the tiles above it: only their lists open here
    spacing: ControlCenter.gap
    // from the lists' heights, not their `visible` (that reads false while this is hidden)
    visible: ids.includes("wifi") && wifiDrop.shown > 0 || ids.includes("bt") && btDrop.shown > 0 || ids.includes("caffeine") && cafDrop.shown > 0
             || ids.includes("phone") && phoneDrop.shown > 0
             || ids.includes("focus") && focusDrop.shown > 0

    // ---- Wi-Fi and Bluetooth dropdowns, under their tiles ----------------------------------
    ControlCenterDrop {
        id: wifiDrop
        visible: drops.ids.includes("wifi") && shown > 0
        open: drops.host.expanded === "wifi"
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
        Repeater { model: Networking.wifiEnabled ? wifiDrop.known : []; ControlCenterWifiRow { host: drops.host } }
        ControlCenterSectionLabel { visible: wifiDrop.others.length > 0 && Networking.wifiEnabled; text: "Other networks" }
        Repeater { model: Networking.wifiEnabled ? wifiDrop.others : []; ControlCenterWifiRow { host: drops.host } }
        ControlCenterEmpty {
            shown: !Networking.wifiEnabled || wifiDrop.nets.length === 0
            text: !Networking.wifiEnabled ? "Wi-Fi is off." : "Looking for networks…"
        }
    }

    ControlCenterDrop {
        id: btDrop
        visible: drops.ids.includes("bt") && shown > 0
        open: drops.host.expanded === "bt"
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

    ControlCenterDrop {
        id: cafDrop
        visible: drops.ids.includes("caffeine") && shown > 0
        open: drops.host.expanded === "caffeine"
        title: "Caffeine"
        switchOn: Caffeine.active
        onSwitched: Caffeine.toggle()
        settingsLabel: "Lock & Sleep Settings…"
        settingsPage: "idle"

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 2
            wrapMode: Text.Wrap
            text: !Caffeine.active ? "Keeps the screen on and stops sleep. Stays on after a restart until you turn it off."
                : Caffeine.endsAt === 0 ? "Keeping the screen on until you turn it off."
                : "Keeping the screen on until " + Qt.formatTime(new Date(Caffeine.endsAt), "HH:mm") + "  ·  " + Caffeine.remaining(ControlCenter.now.getTime())
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
        ControlCenterSectionLabel { text: Caffeine.active ? "Change to" : "Turn on for" }
        ControlCenterSegmented {
            options: Caffeine.choices.map(m => m === 0 ? "Always" : Caffeine.label(m))
            current: Caffeine.active ? Caffeine.choices.indexOf(Caffeine.minutes) : -1
            onPicked: i => { Caffeine.start(Caffeine.choices[i]); ControlCenter.now = new Date() }
        }
    }

    // ---- Focus: plain Do Not Disturb and each mode; a click switches, the switch turns all of it off ----
    ControlCenterDrop {
        id: focusDrop
        visible: drops.ids.includes("focus") && shown > 0
        open: drops.host.expanded === "focus"
        title: "Focus"
        switchOn: Focus.mode !== null || Notifications.dnd
        onSwitched: Focus.toggle()
        settingsLabel: "Focus Settings…"
        settingsPage: "focus"

        ControlCenterDeviceRow {
            readonly property bool on: Notifications.dnd && !Focus.mode
            glyph: "\u{F009B}"
            title: "Do Not Disturb"
            subtitle: on ? Notifications.dndStatus === "On" ? "On until you turn it off" : Notifications.dndStatus : "Only critical notifications pop up"
            selected: on
            action: on ? "Turn off" : "Turn on"
            onClicked: { if (Focus.mode) Focus.off(); Notifications.toggleDnd() }
        }
        Repeater {
            model: Focus.modes
            ControlCenterDeviceRow {
                required property var modelData
                readonly property bool on: Config.focus.active === modelData.id
                glyph: modelData.icon || "\u{F0594}"
                title: modelData.name
                subtitle: on && Config.focus.auto ? "On until " + modelData.schedule.to : Focus.about(modelData) || Focus.summary(modelData)
                selected: on
                action: on ? "Turn off" : "Turn on"
                onClicked: Focus.set(on ? "" : modelData.id)
            }
        }
    }

    // ---- the phone (KDE Connect, Phone.qml): battery, ring, send, and what it may do; an empty state says how to fix it
    ControlCenterDrop {
        id: phoneDrop
        visible: drops.ids.includes("phone") && shown > 0
        open: drops.host.expanded === "phone"
        title: "Phone"
        switchOn: Phone.enabled
        onSwitched: Phone.setEnabled(!Phone.enabled)
        settingsLabel: "Phone Settings…"
        settingsPage: "phone"

        readonly property var d: Phone.phone
        ControlCenterDeviceRow {
            visible: Phone.state === "ready" || Phone.state === "away"
            glyph: Phone.battGlyph(phoneDrop.d) || Phone.glyph
            title: phoneDrop.d?.name ?? ""
            subtitle: Phone.state === "away" ? "Not nearby: same Wi-Fi as this computer?" : Phone.status
            selected: Phone.state === "ready"
            warn: Phone.state === "away"
            onClicked: Phone.refresh()
        }
        ControlCenterDeviceRow {
            visible: Phone.ready
            glyph: "\u{F009E}"
            title: "Find my phone"
            subtitle: "Rings it, even on silent"
            action: "Ring"
            onClicked: Phone.ring()
        }
        ControlCenterDeviceRow {
            visible: Phone.ready
            glyph: "\u{F048A}"
            title: "Send files…"
            action: "Choose"
            onClicked: { ControlCenter.hide(); Phone.pick() }
        }
        ControlCenterSectionLabel { visible: Phone.ready; text: "Shared with this computer" }
        Repeater {
            model: Phone.ready ? [["clipboard", "Clipboard", "Copy on one, paste on the other"],
                                  ["notifications", "Notifications", "The phone's show up here"],
                                  ["remote", "Remote", "The phone controls music and video here"]] : []
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Layout.leftMargin: 6
                Layout.rightMargin: 4
                Column {
                    Layout.fillWidth: true
                    Text { text: modelData[1]; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize } }
                    Text { text: modelData[2]; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                }
                Toggle { checked: phoneDrop.d?.[modelData[0]] ?? false; onToggled: on => Phone.setPlugin(modelData[0], on) }
            }
        }
        // not paired yet: the phones KDE Connect sees, a click pairs
        ControlCenterSectionLabel { visible: Phone.state === "unpaired"; text: "Nearby" }
        Repeater {
            model: Phone.enabled && !Phone.phone ? Phone.nearby : []
            ControlCenterDeviceRow {
                required property var modelData
                glyph: Phone.glyph
                title: modelData.name
                subtitle: modelData.requested ? "Accept on the phone…" : "Not paired"
                action: modelData.requested ? "" : "Pair"
                onClicked: if (!modelData.requested) Phone.pair(modelData.id)
            }
        }
        ControlCenterEmpty {
            shown: ["off", "missing", "starting", "none"].includes(Phone.state)
            text: ({ off: "Phone link is off.",
                     missing: "Phone link needs KDE Connect on this computer and the KDE Connect app on your phone.",
                     starting: "KDE Connect isn't answering yet.",
                     none: "No phone found. Open KDE Connect on your phone, on the same Wi-Fi as this computer." })[Phone.state] ?? ""
        }
        ControlCenterDeviceRow {
            visible: Phone.state === "missing" || Phone.state === "starting"
            glyph: Phone.state === "missing" ? "\u{F01DA}" : "\u{F040A}"
            title: Phone.state === "missing" ? "Install KDE Connect" : "Start KDE Connect"
            subtitle: Phone.state === "missing" ? "Opens a terminal with the installer" : ""
            action: Phone.state === "missing" ? "Install" : "Start"
            onClicked: { if (Phone.state === "missing") { ControlCenter.hide(); Phone.install() } else Phone.start() }
        }
    }
}
