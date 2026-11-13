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

// Control Center part: the media tile, shown while a player is around.
// Used by ControlCenter.qml; reads the panel's state from the ControlCenter singleton.
ColumnLayout {
    Layout.fillWidth: true
    Layout.row: Math.max(0, ControlCenter.shownSections.indexOf("media"))
    visible: ControlCenter.shownSections.includes("media")
    spacing: ControlCenter.gap

    // ---- media, while a player is around ----------------------------------------------------
    ControlCenterTile {
        visible: ControlCenter.player !== null
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        Rectangle {
            id: artBox
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            width: 44; height: 44; radius: Theme.radiusSmall
            color: Theme.fill
            clip: true
            Image {
                anchors.fill: parent
                source: ControlCenter.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize { width: 88; height: 88 }
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !(ControlCenter.player?.trackArtUrl)
                text: "\u{F075A}"
                color: Theme.subtext
                font { family: Theme.iconFont; pixelSize: 20 }
            }
        }
        Column {
            anchors { left: artBox.right; leftMargin: 10; right: controls.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
            Text { width: parent.width; text: ControlCenter.player?.trackTitle || ControlCenter.player?.identity || ""; color: Theme.text; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold } }
            Text { width: parent.width; text: ControlCenter.player?.trackArtist || ControlCenter.player?.identity || ""; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontCaption } }
        }
        Row {
            id: controls
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            Repeater {
                model: [
                    ["\u{F04AE}", () => ControlCenter.player.previous(), ControlCenter.player?.canGoPrevious ?? false, 18],
                    [ControlCenter.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}", () => ControlCenter.player.togglePlaying(), ControlCenter.player?.canTogglePlaying ?? false, 24],
                    ["\u{F04AD}", () => ControlCenter.player.next(), ControlCenter.player?.canGoNext ?? false, 18],
                ]
                Rectangle {
                    required property var modelData
                    width: 32; height: 32; radius: Theme.radius === 0 ? 0 : 16
                    color: mediaArea.containsMouse && modelData[2] ? Theme.fillHover : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData[0]
                        opacity: parent.modelData[2] ? 1 : 0.35
                        color: Theme.text
                        font { family: Theme.iconFont; pixelSize: parent.modelData[3] }
                    }
                    MouseArea { id: mediaArea; Accessible.role: Accessible.Button; Accessible.name: "Media control"; anchors.fill: parent; hoverEnabled: true; enabled: parent.modelData[2]; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData[1]() }
                }
            }
        }
    }
}
