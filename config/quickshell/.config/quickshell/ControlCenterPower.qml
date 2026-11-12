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

// Control Center part: the power mode choice.
// Used by ControlCenter.qml; reads the panel's state from the ControlCenter singleton.
ColumnLayout {
    Layout.fillWidth: true
    Layout.row: Math.max(0, ControlCenter.shownSections.indexOf("power"))
    visible: ControlCenter.shownSections.includes("power")
    spacing: ControlCenter.gap

    // ---- power mode ---------------------------------------------------------------------
    ControlCenterModule {
        title: "Power mode"
        detail: Config.controlCenter.showHardware ? `CPU ${Math.round(Sensors.cpu)}°` : ""
        warn: Sensors.cpu >= 90
        onDetailClicked: { ControlCenter.hide(); SettingsApp.show(Machine.asus ? "asus" : "power") }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.controlHeight
            radius: Theme.radiusSmall + 1
            color: Theme.fill

            Rectangle {
                width: (parent.width - 6) / 3
                height: parent.height - 6
                y: 3
                x: 3 + PowerMode.profile * width
                radius: Theme.radiusSmall - 1
                color: Theme.thumb
                Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
            }
            Row {
                anchors { fill: parent; margins: 3 }
                Repeater {
                    model: ["Quiet", "Balanced", "Performance"]
                    Item {
                        required property string modelData
                        required property int index
                        readonly property bool on: PowerMode.profile === index
                        width: parent.width / 3
                        height: parent.height
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: parent.on ? Theme.thumbText : Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: PowerMode.set(index) }
                    }
                }
            }
        }
    }
}
