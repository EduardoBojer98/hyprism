import QtQuick
import QtQuick.Effects

// A live picture of the lock screen for Settings > Lock Screen: the same layout hyprlock gets
// (LockScreen.elements: position from an edge, y up, sizes in points on a 1600x1000 screen) over the
// chosen background with its blur and brightness, scaled to this item.
Item {
    id: lp

    property string source: ""          // background image path
    property int blur: 3                // hyprlock blur passes (0..6)
    property real brightness: 0.72
    property bool live: true            // false: a still clock

    readonly property real s: width / 1600
    property date now: new Date()
    Timer { running: lp.live && lp.visible; interval: 1000; repeat: true; onTriggered: lp.now = new Date() }

    clip: true

    Rectangle { anchors.fill: parent; color: Theme.base }
    Image {
        id: bg
        anchors.fill: parent
        source: lp.source ? "file://" + lp.source : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: 640
        asynchronous: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: bg
        visible: bg.status === Image.Ready
        blurEnabled: lp.blur > 0
        blur: Math.min(1, lp.blur / 6)
        blurMax: 48
        brightness: lp.brightness - 1
    }

    Repeater {
        model: LockScreen.elements
        Item {
            id: el
            required property var modelData
            readonly property var e: modelData
            readonly property bool isText: !["input", "avatar"].includes(e.role)
            width: isText ? label.implicitWidth : e.w * lp.s
            height: isText ? label.implicitHeight : e.hgt * lp.s
            x: e.h === "left" ? e.x * lp.s : e.h === "right" ? lp.width - width - e.x * lp.s : (lp.width - width) / 2 + e.x * lp.s
            y: e.v === "top" ? -e.y * lp.s : e.v === "bottom" ? lp.height - height - e.y * lp.s : (lp.height - height) / 2 - e.y * lp.s

            Text {
                id: label
                visible: el.isText
                text: LockScreen.previewText(el.e.role, lp.now)
                color: el.e.colour === "accent" ? Theme.accent : el.e.colour === "muted" ? LockScreen.inkMuted : LockScreen.ink
                font {
                    family: el.e.mono ? Theme.monoFont : el.e.display ? Theme.displayFont : Theme.font
                    pixelSize: Math.max(4, Math.round((el.e.size ?? 10) * 1.33 * lp.s))
                    weight: el.e.weight ?? Font.Normal
                    capitalization: el.e.caps ? Font.AllUppercase : Font.MixedCase
                }
                lineHeight: el.e.tight ? 0.92 : 1
            }
            Rectangle {   // the password field
                visible: el.e.role === "input"
                anchors.fill: parent
                radius: Theme.radius >= 12 ? height / 2 : Theme.radius * lp.s
                color: Qt.alpha(Theme.surfaceColor, 0.85)
                border { width: Math.max(1, Theme.line * lp.s); color: Theme.accent }
                Row {
                    anchors.centerIn: parent
                    spacing: 6 * lp.s
                    Repeater { model: 4; Rectangle { width: 7 * lp.s; height: width; radius: width / 2; color: Theme.text; opacity: 0.8 } }
                }
            }
            Item {   // the avatar: a round picture with an accent ring
                visible: el.e.role === "avatar"
                anchors.fill: parent
                Image {
                    id: face
                    anchors.fill: parent
                    source: el.e.role === "avatar" && LockScreen.avatarPath ? "file://" + LockScreen.avatarPath : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }
                Rectangle { id: round; anchors.fill: parent; radius: width / 2; visible: false; layer.enabled: true }
                MultiEffect { anchors.fill: parent; source: face; maskEnabled: true; maskSource: round }
                Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border { width: Math.max(1, 2 * lp.s); color: Theme.accent } }
            }
        }
    }
}
