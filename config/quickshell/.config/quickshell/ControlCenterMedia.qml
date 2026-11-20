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
import QtQuick.Effects

// Control Center part: the media tile, shown while a player is around.
// Used by ControlCenter.qml and Flyouts.qml; the panel's own state comes from `host`.
// The layout shapes it: a card washed in the album art's colours (cards), a big square cover and the title in the
// display font (bento), `> title — artist` with `[|<] [>] [>|]` (hud).
ColumnLayout {
    Layout.fillWidth: true
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    spacing: ControlCenter.gap

    ControlCenterSliderHead { visible: !ControlCenter.cards && Sys.player !== null; title: "Now playing" }

    // ---- media, while a player is around ----------------------------------------------------
    ControlCenterTile {
        id: card
        visible: Sys.player !== null
        Layout.fillWidth: true
        Layout.preferredHeight: (ControlCenter.hud ? Theme.ccWell : artBox.height) + Theme.ccInset * 2
        clip: ControlCenter.cards
        Image {   // cards: the cover, blurred, washes the card in its colours
            id: tintArt
            anchors.fill: parent
            visible: false
            source: ControlCenter.cards ? (Sys.player?.trackArtUrl ?? "") : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize { width: 64; height: 64 }
        }
        Rectangle { id: tintMask; anchors.fill: parent; radius: card.radius; visible: false; layer.enabled: true }
        MultiEffect {
            anchors.fill: parent
            visible: ControlCenter.cards && tintArt.status === Image.Ready
            source: tintArt
            blurEnabled: true; blur: 1; blurMax: 48
            saturation: 0.2
            opacity: Theme.light ? 0.45 : 0.4
            maskEnabled: true; maskSource: tintMask
        }
        Rectangle {
            id: artBox
            visible: !ControlCenter.hud
            anchors { left: parent.left; leftMargin: ControlCenter.inset; verticalCenter: parent.verticalCenter }
            width: ControlCenter.bento ? Theme.ccTile + Theme.ccWell : Theme.ccWell + 12; height: width; radius: Theme.radiusSmall
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
            visible: !ControlCenter.hud
            anchors { left: artBox.right; leftMargin: Theme.spaceS; right: ControlCenter.bento ? parent.right : controls.left; rightMargin: Theme.spaceXs }
            y: ControlCenter.bento ? artBox.y : (parent.height - height) / 2   // not anchors: switching anchors live leaves a conflict
            Text { width: parent.width; text: Sys.player?.trackTitle || Sys.player?.identity || ""; color: Theme.text; elide: Text.ElideRight; maximumLineCount: 2; wrapMode: ControlCenter.bento ? Text.Wrap : Text.NoWrap
                   font { family: ControlCenter.bento ? Theme.displayFont : Theme.font; pixelSize: ControlCenter.bento ? Theme.fontTitle : Theme.fontSize; weight: Font.DemiBold } }
            Text { width: parent.width; text: Sys.player?.trackArtist || Sys.player?.identity || ""; color: Theme.subtext; elide: Text.ElideRight; font { family: ControlCenter.textFont; pixelSize: Theme.fontCaption } }
        }
        Text {   // hud: `> title — artist`
            visible: ControlCenter.hud
            anchors { left: parent.left; leftMargin: ControlCenter.inset; right: controls.left; rightMargin: Theme.spaceS; verticalCenter: parent.verticalCenter }
            elide: Text.ElideRight
            textFormat: Text.PlainText
            text: "> " + (Sys.player?.trackTitle || Sys.player?.identity || "") + (Sys.player?.trackArtist ? " \u2014 " + Sys.player.trackArtist : "")
            color: Theme.text
            font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
        }
        Row {
            id: controls
            anchors { right: parent.right; rightMargin: Math.max(0, ControlCenter.inset - 4) }
            y: ControlCenter.bento ? artBox.y + artBox.height - height : (parent.height - height) / 2
            spacing: 2
            Repeater {
                model: [
                    ["\u{F04AE}", () => Sys.player.previous(), Sys.player?.canGoPrevious ?? false, 18, "Previous", "[|<]"],
                    [Sys.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}", () => Sys.player.togglePlaying(), Sys.player?.canTogglePlaying ?? false, 22, Sys.player?.isPlaying ? "Pause" : "Play", Sys.player?.isPlaying ? "[||]" : "[> ]"],
                    ["\u{F04AD}", () => Sys.player.next(), Sys.player?.canGoNext ?? false, 18, "Next", "[>|]"],
                ]
                Rectangle {
                    required property var modelData
                    readonly property bool main: index === 1   // play / pause: the one in a well
                    required property int index
                    width: ControlCenter.hud ? hudKey.implicitWidth + Theme.spaceXs : Theme.ccWell; height: Theme.ccWell
                    radius: ControlCenter.cards && Theme.radius > 0 ? height / 2 : Theme.radiusSmall
                    color: mediaArea.containsMouse && modelData[2] ? Theme.fillActive : main && !ControlCenter.hud ? Theme.fillHover : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Text {
                        id: hudKey
                        anchors.centerIn: parent
                        visible: ControlCenter.hud
                        text: parent.modelData[5]
                        opacity: parent.modelData[2] ? 1 : 0.35
                        color: parent.main ? Theme.accent : Theme.text
                        font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !ControlCenter.hud
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
