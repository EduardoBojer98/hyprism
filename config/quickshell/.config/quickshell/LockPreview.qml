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
    property string clock: LockScreen.clock   // any clock style and position, for the pictures of each choice
    property string align: LockScreen.align
    property string field: "idle"       // the password field's state to show: idle | typing | wrong | caps

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

    Repeater {   // the blocks scene's composition, in % of the screen from its bottom-left corner
        model: LockScreen.blocksFor(lp.align)
        Rectangle {
            required property var modelData
            x: modelData.x / 100 * lp.width
            width: modelData.w / 100 * lp.width
            height: modelData.h / 100 * lp.height
            y: lp.height - height - modelData.y / 100 * lp.height
            color: LockScreen.tone(modelData.colour)
        }
    }

    Repeater {
        model: LockScreen.layout(lp.clock, lp.align)
        Item {
            id: el
            required property var modelData
            readonly property var e: modelData
            readonly property bool isText: !["input", "avatar", "shape"].includes(e.role)
            width: isText ? label.implicitWidth : e.w * lp.s
            height: isText ? label.implicitHeight : e.hgt * lp.s
            x: e.h === "left" ? e.x * lp.s : e.h === "right" ? lp.width - width + e.x * lp.s : (lp.width - width) / 2 + e.x * lp.s
            y: e.v === "top" ? -e.y * lp.s : e.v === "bottom" ? lp.height - height - e.y * lp.s : (lp.height - height) / 2 - e.y * lp.s

            Text {
                id: label
                visible: el.isText && (el.e.role !== "caps" || lp.field === "caps")
                text: LockScreen.previewText(el.e.role, lp.now)
                color: LockScreen.inkOf(el.e.colour)
                font {
                    family: el.e.mono ? Theme.monoFont : el.e.display ? Theme.displayFont : Theme.font
                    pixelSize: Math.max(4, Math.round((el.e.size ?? 10) * 1.33 * lp.s))
                    weight: el.e.weight ?? Font.Normal
                    capitalization: el.e.caps ? Font.AllUppercase : Font.MixedCase
                }
                lineHeight: el.e.tight ? 0.92 : 1
                // as hyprlock's label shadow (LockScreen.shadowed)
                layer.enabled: LockScreen.shadowed && el.isText
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.8); shadowBlur: 0.5; shadowVerticalOffset: 0; shadowHorizontalOffset: 0 }
            }
            Rectangle {   // a shape: the soft media pill, the blocks field's hard shadow
                visible: el.e.role === "shape"
                anchors.fill: parent
                radius: el.e.round ? height / 2 : 0
                color: LockScreen.tone(el.e.colour)
            }
            Rectangle {   // the password field, styled as LockScreen.conf styles it per scene
                id: fieldBox
                readonly property string scene: LockScreen.scene
                // hyprlock colours the whole field's outline (or, with none, its fill edge) by state
                readonly property color stateColour: lp.field === "wrong" ? Theme.error : lp.field === "caps" ? Theme.warning : "transparent"
                readonly property bool typed: lp.field === "typing" || lp.field === "caps"
                visible: el.e.role === "input"
                anchors.fill: parent
                radius: scene === "blocks" || scene === "boot" ? 0 : scene === "soft" || Theme.radius >= 12 ? height / 2 : Theme.radius * lp.s
                color: scene === "boot" ? "transparent" : Qt.alpha(Theme.surfaceColor, scene === "blocks" ? 1 : scene === "soft" ? 0.78 : 0.85)
                border { width: (lp.field === "wrong" || lp.field === "caps") && scene !== "boot" ? Math.max(1, 2 * lp.s)
                                : scene === "boot" || scene === "soft" ? 0 : Math.max(1, (scene === "blocks" ? 3 : Theme.line) * lp.s)
                         color: fieldBox.stateColour.a > 0 ? fieldBox.stateColour : scene === "blocks" ? Theme.text : LockScreen.accent }
                Row {
                    visible: fieldBox.scene !== "boot" && fieldBox.typed
                    anchors.centerIn: parent
                    spacing: 7 * lp.s
                    Repeater { model: 6; Rectangle { width: 9 * lp.s; height: width; radius: width / 2; color: Theme.text; opacity: 0.85 } }
                }
                Text {   // the placeholder, or the failure hyprlock writes in
                    visible: fieldBox.scene !== "boot" && !fieldBox.typed
                    anchors.centerIn: parent
                    text: lp.field === "wrong" ? "Authentication failed"
                        : "Enter password" + (Config.lockscreen.widgets.includes("layout") ? "  ·  " + Keyboard.short : "")
                    color: lp.field === "wrong" ? Theme.error : Theme.subtext
                    font { family: Theme.font; pixelSize: Math.max(4, Math.round(11 * 1.33 * lp.s)) }
                }
                Text {   // boot: the stars of a typed password
                    visible: fieldBox.scene === "boot"
                    anchors.verticalCenter: parent.verticalCenter
                    text: lp.field === "wrong" ? "denied (1)" : fieldBox.typed ? "******_" : "_"
                    color: lp.field === "wrong" ? Theme.error : LockScreen.ink
                    font { family: Theme.monoFont; pixelSize: Math.max(4, Math.round(12 * 1.33 * lp.s)) }
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
                Rectangle { anchors.fill: parent; radius: width / 2; color: "transparent"; border { width: Math.max(1, 2 * lp.s); color: LockScreen.accent } }
            }
        }
    }
}
