import Quickshell
import QtQuick
import QtQuick.Layouts

// Phone: KDE Connect on/off, pairing, and what the phone shares with this computer (Phone.qml).
ColumnLayout {
    id: page
    spacing: 20

    Component.onCompleted: Phone.watch(true)
    Component.onDestruction: Phone.watch(false)
    readonly property var d: Phone.phone

    SettingGroup {
        SettingRow {
            label: "Phone link"
            hint: ({ off: "Off: KDE Connect is stopped",
                     missing: "Needs KDE Connect on this computer and the KDE Connect app on your phone (Android, or iPhone from the App Store)",
                     starting: "Starting KDE Connect…",
                     none: "Looking for your phone…",
                     unpaired: "Pair your phone below",
                     away: (page.d?.name ?? "") + " isn't nearby",
                     ready: "Connected to " + (page.d?.name ?? "") })[Phone.state]
            Toggle { checked: Phone.enabled; onToggled: on => Phone.setEnabled(on) }
        }
        SettingRow {
            visible: Phone.state === "missing"
            label: "Install KDE Connect"
            hint: "Opens a terminal that installs the missing packages (asks for your password)"
            PillButton { text: "Install"; primary: true; onClicked: Phone.install() }
        }
        SettingRow {
            visible: Phone.state === "starting" && Phone.read
            label: "KDE Connect isn't answering"
            hint: "Start it by hand; it starts by itself at the next login"
            PillButton { text: "Start"; primary: true; onClicked: Phone.start() }
        }
        SettingRow {
            visible: Phone.state === "none" || Phone.state === "unpaired" || Phone.state === "away"
            label: "Can't find your phone?"
            hint: "Open KDE Connect on the phone, on the same Wi-Fi. A firewall must let ports 1714–1764 (TCP and UDP) through; the user guide has the commands."
            PillButton { text: "Look again"; onClicked: { Quickshell.execDetached(["kdeconnect-cli", "--refresh"]); Phone.refresh() } }
        }
    }

    SettingGroup {
        title: "My phone"
        visible: Phone.enabled && Phone.paired.length > 0
        Repeater {
            model: Phone.paired
            SettingRow {
                id: prow
                required property var modelData
                readonly property bool chosen: modelData.id === page.d?.id
                label: modelData.name + (chosen && Phone.paired.length > 1 ? "  ·  in use" : "")
                hint: (modelData.reachable ? "Connected" : "Not nearby")
                    + (modelData.reachable && modelData.charge >= 0 ? " · battery " + modelData.charge + "%" + (modelData.charging ? ", charging" : "") : "")
                PillButton { visible: !prow.chosen; text: "Use this one"; onClicked: Config.set("phone", "device", modelData.id) }
                PillButton { text: "Unpair"; onClicked: Phone.unpair(modelData.id) }
            }
        }
    }

    SettingGroup {
        title: "Nearby"
        visible: Phone.enabled && Phone.nearby.length > 0
        Repeater {
            model: Phone.nearby
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: modelData.requested ? "Accept the request on the phone" : "Not paired: both screens show the same key to compare"
                PillButton { text: modelData.requested ? "Waiting…" : "Pair"; primary: !modelData.requested; enabled: !modelData.requested; onClicked: Phone.pair(modelData.id) }
            }
        }
    }

    SettingGroup {
        title: "Shared with this computer"
        visible: Phone.enabled && page.d !== null
        SettingRow {
            label: "Notifications"
            hint: "The phone's notifications show up here, with Do Not Disturb and Focus applied"
            Toggle { checked: page.d?.notifications ?? false; enabled: Phone.ready; onToggled: on => Phone.setPlugin("notifications", on) }
        }
        SettingRow {
            label: "Clipboard"
            hint: "Copy on one, paste on the other"
            Toggle { checked: page.d?.clipboard ?? false; enabled: Phone.ready; onToggled: on => Phone.setPlugin("clipboard", on) }
        }
        SettingRow {
            label: "Remote"
            hint: "The phone plays, pauses and skips music and video on this computer. The phone's own player shows in the Control Center."
            Toggle { checked: page.d?.remote ?? false; enabled: Phone.ready; onToggled: on => Phone.setPlugin("remote", on) }
        }
        SettingRow {
            label: "Find my phone"
            hint: Phone.ready ? "Rings it, even on silent" : "When the phone is nearby"
            PillButton { text: "Ring"; enabled: Phone.ready; onClicked: Phone.ring() }
        }
        SettingRow {
            label: "Send files"
            hint: "Also from the Control Center and the launcher (Send files to my phone)"
            PillButton { text: "Choose…"; enabled: Phone.ready; onClicked: Phone.pick() }
        }
    }
}
