import QtQuick
import QtQuick.Layouts

// Control Center building block: the power mode picker, all modes in view with their speedometer, one click picks.
// Each layout draws it its own way: soft tiles with an accent wash (cards), solid blocks on a hard shadow with the
// name in caps display type (bento), `[󰾅 balanced]` with the pick as an inverse block (hud).
// Keyboard: Tab to it, Left / Right picks the one beside.
Item {
    id: modes
    property var options: []   // [{ glyph, name }]
    property int current: -1
    property string accessibleName: ""
    signal picked(int index)
    readonly property bool hud: ControlCenter.hud
    readonly property bool bento: ControlCenter.bento

    Layout.fillWidth: true
    implicitHeight: hud ? Theme.hit : Theme.ccTile
    activeFocusOnTab: true
    function step(d) { const i = Math.max(0, Math.min(options.length - 1, Math.max(0, current) + d)); if (i !== current) picked(i) }
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    FocusRing {}
    Accessible.role: Accessible.RadioButton
    Accessible.name: accessibleName
    Accessible.description: options[current]?.name ?? ""
    Accessible.focusable: true

    Row {
        id: row
        anchors.fill: parent
        spacing: modes.hud ? Theme.spaceS : Theme.spaceXs + (modes.bento ? 2 : 0)
        Repeater {
            model: modes.options
            Rectangle {
                id: opt
                required property var modelData
                required property int index
                readonly property bool on: modes.current === index
                readonly property color ink: modes.hud ? (on ? Theme.accentText : optArea.containsMouse ? Theme.text : Theme.subtext)
                                                       : on ? Theme.ccOnText : optArea.containsMouse ? Theme.text : Theme.subtext
                width: modes.hud ? hudText.implicitWidth + Theme.spaceS * 2
                                 : (row.width - row.spacing * (modes.options.length - 1)) / Math.max(1, modes.options.length)
                height: modes.hud ? Math.round(Theme.fontLabel * 1.7) : row.height
                anchors.verticalCenter: parent.verticalCenter
                radius: modes.hud || modes.bento ? Theme.radiusSmall : ControlCenter.cards ? Theme.radiusLarge : Theme.radius
                color: on ? (modes.hud ? Theme.accent : optArea.containsMouse ? Theme.ccTileOnHover : Theme.ccTileOn)
                          : modes.hud ? "transparent" : optArea.containsMouse ? Theme.fillHover : Theme.fill
                scale: optArea.pressed && !feel.shadow ? Theme.pressScale : 1
                Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
                PressFeel { id: feel; pressed: optArea.pressed; visible: modes.bento }
                transform: Translate { x: feel.shift; y: feel.shift + feel.drop }

                Column {   // the speedometer over its name (cards, bento)
                    visible: !modes.hud
                    anchors.centerIn: parent
                    width: parent.width - Theme.spaceXs * 2
                    spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: opt.modelData.glyph
                        color: opt.on ? Theme.ccIconOn : opt.ink
                        font { family: Theme.iconFont; pixelSize: Theme.glyphL }
                        Behavior on color { ColorAnimation { duration: Theme.anim } }
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        fontSizeMode: Text.HorizontalFit; minimumPixelSize: Theme.fontCaption - 3   // Poster's caps run wide
                        text: opt.modelData.name
                        color: opt.ink
                        font { family: modes.bento ? Theme.displayFont : Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold
                               capitalization: modes.bento ? Font.AllUppercase : Font.MixedCase }
                        Behavior on color { ColorAnimation { duration: Theme.anim } }
                    }
                }
                Text {   // hud: `󰾅 balanced`, the brackets drawn round the unpicked ones
                    id: hudText
                    visible: modes.hud
                    anchors.centerIn: parent
                    textFormat: Text.PlainText
                    text: (opt.on ? " " : "[") + opt.modelData.glyph + " " + opt.modelData.name.toLowerCase() + (opt.on ? " " : "]")
                    color: opt.ink
                    font { family: Theme.monoFont; pixelSize: Theme.fontLabel; weight: opt.on ? Font.Bold : Font.Normal }
                }
                MouseArea {
                    id: optArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modes.picked(opt.index)
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: opt.modelData.name
                    Accessible.checkable: true
                    Accessible.checked: opt.on
                    Accessible.onPressAction: modes.picked(opt.index)
                }
            }
        }
    }
}
