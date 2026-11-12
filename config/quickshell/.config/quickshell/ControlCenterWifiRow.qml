import Quickshell.Networking
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A Wi-Fi network row; a secured network you haven't joined asks for its password right under it
ColumnLayout {
    id: wr
    required property var modelData
    readonly property bool secured: modelData.security !== WifiSecurityType.Open
    readonly property bool failed: ControlCenter.wifiFailed === modelData.name
    Layout.fillWidth: true
    spacing: 2

    ControlCenterDeviceRow {
        glyph: wr.modelData.signalStrength > 0.66 ? "\u{F0928}" : wr.modelData.signalStrength > 0.33 ? "\u{F0925}" : "\u{F091F}"
        title: wr.modelData.name
        subtitle: wr.modelData.stateChanging ? (wr.modelData.connected ? "Disconnecting…" : "Connecting…")
                : wr.modelData.connected ? "Connected"
                : wr.failed ? "Couldn't connect" + (wr.secured ? ". Check the password." : "")
                : wr.modelData.known ? "Saved" : wr.secured ? "Secured" : "Open"
        warn: wr.failed && !wr.modelData.connected
        trailingGlyph: wr.secured ? "\u{F033E}" : ""
        selected: wr.modelData.connected
        action: wr.modelData.connected ? "Disconnect" : "Join"
        onClicked: {
            ControlCenter.wifiFailed = ""
            if (wr.modelData.connected) wr.modelData.disconnect()
            else if (wr.modelData.known || !wr.secured) wr.modelData.connect()
            else ControlCenter.passwordFor = wr.modelData
        }
    }
    Connections {
        target: wr.modelData
        function onConnectionFailed() { ControlCenter.wifiFailed = wr.modelData.name; if (wr.secured) ControlCenter.passwordFor = wr.modelData }
    }
    RowLayout {   // password, under the network it's for
        visible: ControlCenter.passwordFor === wr.modelData
        Layout.fillWidth: true
        Layout.leftMargin: 44
        Layout.rightMargin: 6
        Layout.bottomMargin: 6
        spacing: 6
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 30
            radius: Theme.radiusSmall
            color: Theme.fill
            border { color: psk.activeFocus ? Theme.accent : Theme.stroke; width: 1 }
            TextInput {
                id: psk
                anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontSize }
                focus: parent.parent.visible
                onAccepted: join()
                Keys.onEscapePressed: ControlCenter.passwordFor = null
                function join() { if (!text) return; ControlCenter.wifiFailed = ""; wr.modelData.connectWithPsk(text); text = ""; ControlCenter.passwordFor = null }
                Text { visible: !psk.text; anchors.verticalCenter: parent.verticalCenter; text: "Password"; color: Theme.muted; font: psk.font }
            }
        }
        Chip { label: "Join"; active: psk.text !== ""; onClicked: psk.join() }
    }
}
