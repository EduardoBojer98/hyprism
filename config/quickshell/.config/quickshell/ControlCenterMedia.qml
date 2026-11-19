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
// Used by ControlCenter.qml and Flyouts.qml; the panel's own state comes from `host`.
ColumnLayout {
    Layout.fillWidth: true
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    spacing: ControlCenter.gap

    // ---- media, while a player is around ----------------------------------------------------
    ControlCenterTile {
        visible: Sys.player !== null
        Layout.fillWidth: true
        Layout.preferredHeight: artBox.height + Theme.ccInset * 2
        Rectangle {
            id: artBox
            anchors { left: parent.left; leftMargin: Theme.ccInset; verticalCenter: parent.verticalCenter }
            width: Theme.ccWell + 12; height: width; radius: Theme.radiusSmall
            color: Theme.fillHover
            clip: true
            Image {
                anchors.fill: parent
                source: Sys.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize { width: 88; height: 88 }
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !(Sys.player?.trackArtUrl)
                text: "\u{F075A}"
                color: Theme.subtext
                font { family: Theme.iconFont; pixelSize: Theme.glyphL }
            }
        }
        Column {
            anchors { left: artBox.right; leftMargin: Theme.spaceS; right: controls.left; rightMargin: Theme.spaceXs; verticalCenter: parent.verticalCenter }
            Text { width: parent.width; text: Sys.player?.trackTitle || Sys.player?.identity || ""; color: Theme.text; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold } }
            Text { width: parent.width; text: Sys.player?.trackArtist || Sys.player?.identity || ""; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontCaption } }
        }
        Row {
            id: controls
            anchors { right: parent.right; rightMargin: Theme.ccInset - 4; verticalCenter: parent.verticalCenter }
            spacing: 2
            Repeater {
                model: [
                    ["\u{F04AE}", () => Sys.player.previous(), Sys.player?.canGoPrevious ?? false, 18, "Previous"],
                    [Sys.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}", () => Sys.player.togglePlaying(), Sys.player?.canTogglePlaying ?? false, 22, Sys.player?.isPlaying ? "Pause" : "Play"],
                    ["\u{F04AD}", () => Sys.player.next(), Sys.player?.canGoNext ?? false, 18, "Next"],
                ]
                Rectangle {
                    required property var modelData
                    readonly property bool main: index === 1   // play / pause: the one in a well
                    required property int index
                    width: Theme.ccWell; height: Theme.ccWell; radius: Theme.radiusSmall
                    color: mediaArea.containsMouse && modelData[2] ? Theme.fillActive : main ? Theme.fillHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData[0]
                        opacity: parent.modelData[2] ? 1 : 0.35
                        color: Theme.text
                        font { family: Theme.iconFont; pixelSize: parent.modelData[3] }
                    }
                    MouseArea { id: mediaArea; Accessible.role: Accessible.Button; Accessible.name: parent.modelData[4]; Accessible.onPressAction: parent.modelData[1](); anchors.fill: parent; hoverEnabled: true; enabled: parent.modelData[2]; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData[1]() }
                }
            }
        }
    }
}
