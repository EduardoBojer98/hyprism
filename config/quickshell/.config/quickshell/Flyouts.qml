pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The bar items' flyouts: each opens beside its item and shows that topic's Control Center section, so
// there is one implementation per topic. Volume, network, Bluetooth, brightness, media, battery + power
// mode. Bar items call toggle(<name>); the status item opens the one for the icon clicked.
Singleton {
    id: root

    readonly property var all: ({ volume: volume, network: network, bluetooth: bluetooth, brightness: brightness, media: media, battery: battery })
    function toggle(name) { all[name]?.toggle() }
    function isOpen(name) { return all[name]?.open ?? false }
    // a Settings link inside any of them (or the Control Center) closes whichever is open
    function hideAll() { ControlCenter.hide(); for (const k in all) all[k].hide() }

    IpcHandler {   // qs ipc call flyout toggle volume   (opens beside its bar item on the pointer's screen)
        target: "flyout"
        function toggle(name: string): void { root.toggle(name) }
    }

    Flyout {
        id: volume
        name: "volume"
        ControlCenterSliders { host: volume.host; parts: ["sound", "mic"] }
    }
    Flyout {
        id: brightness
        name: "brightness"
        onOpened: Sys.readBrightness()
        ControlCenterSliders { host: brightness.host; parts: ["display"] }
    }
    Flyout {
        id: network
        name: "network"
        fixed: "wifi"
        // look for networks only while a list of them is on screen
        onOpened: if (Sys.wifi) Sys.wifi.scannerEnabled = true
        onClosed: if (Sys.wifi && !ControlCenter.open) Sys.wifi.scannerEnabled = false
        ControlCenterConnections { host: network.host; tiles: [] }
    }
    Flyout {
        id: bluetooth
        name: "bluetooth"
        fixed: "bt"
        ControlCenterConnections { host: bluetooth.host; tiles: [] }
    }
    Flyout {
        id: media
        name: "media"
        ControlCenterMedia { host: media.host }
        ControlCenterEmpty { shown: Sys.player === null; text: "Nothing is playing. Start music or a video and its controls show up here." }
    }
    Flyout {
        id: battery
        name: "battery"
        readonly property var readings: ["battery", "battery_power", "battery_time", "cpu_temp", "fans"]
        onOpened: Metrics.want(readings, 2)
        onClosed: Metrics.unwant(readings)
        ControlCenterBattery { host: battery.host }
    }
}
