import QtQuick

// The on-screen display's card: a glyph, then the level (or a word: "Mic muted", "US"). Osd.qml shows it on
// screen; Settings > Notifications draws it as the style and size samples. Sized by `size` from the Theme tokens.
//   look  bar (a thin level bar and the number) | numeral (a big number over ten blocks) | ascii (a mono [████░░] meter)
//   size  compact | regular | large
Glass {
    id: card

    property string icon
    property real level                  // 0..1
    property string label                // a word instead of the level
    property string look: "bar"
    property string size: "regular"
    readonly property int step: size === "compact" ? 0 : size === "large" ? 2 : 1
    readonly property int row: [Theme.iconMedium + Theme.spaceS * 2, Theme.iconMedium + Theme.spaceM * 2, Theme.iconLarge + Theme.spaceL * 2][step]
    readonly property int edge: [Theme.spaceM, Theme.spaceL, Theme.spaceXl][step]
    readonly property int textSize: [Theme.fontCaption, Theme.fontLabel, Theme.fontTitle][step]

    implicitWidth: Math.round(row * (look === "numeral" ? 6.3 : look === "ascii" ? 6 : 5.5))
    implicitHeight: look === "numeral" && label === "" ? row + Theme.spaceXl + Theme.spaceXs : row
    radius: Math.min(height / 2, Theme.radiusLarge)
    strong: true

    Text {
        id: glyph
        anchors { left: parent.left; leftMargin: card.edge; verticalCenter: parent.verticalCenter }
        text: card.icon
        color: Theme.text
        font { family: Theme.iconFont; pixelSize: [Theme.glyph, Theme.glyphL, Theme.iconMedium + Theme.spaceXs][card.step] }
    }

    Text {   // a word or value ("Mic muted", "US") where there is no level to draw
        visible: card.label !== ""
        anchors { left: glyph.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: card.edge; verticalCenter: parent.verticalCenter }
        text: card.label
        elide: Text.ElideRight
        color: Theme.text
        font { family: Theme.font; pixelSize: card.textSize; weight: Font.Medium }
    }

    Text {   // the level as a number: a bar alone can't say 0 % from muted, or 45 from 50
        id: number
        visible: card.label === "" && card.look === "bar"
        anchors { right: parent.right; rightMargin: card.edge; verticalCenter: parent.verticalCenter }
        width: card.textSize * 2.4
        horizontalAlignment: Text.AlignRight
        text: Math.round(card.level * 100)
        color: Theme.subtext
        font { family: Theme.font; pixelSize: card.textSize; weight: Font.Medium; features: { "tnum": 1 } }
    }
    Rectangle {
        visible: card.label === "" && card.look === "bar"
        anchors { left: glyph.right; leftMargin: Theme.spaceM; right: number.left; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
        height: Math.max(4, Math.round(card.row / 8))
        radius: Math.min(height / 2, Theme.radiusSmall)
        color: Theme.fill

        Rectangle {   // the level: a scale from the left, not a width change (no layout per frame)
            width: parent.width
            height: parent.height
            radius: parent.radius
            color: Theme.accent
            transform: Scale { xScale: card.level; Behavior on xScale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } } }
        }
    }

    // numeral: the level as a poster number, ten blocks under it that snap (no tween: a stamp, not a glide)
    Column {
        visible: card.label === "" && card.look === "numeral"
        anchors { left: glyph.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: card.edge; verticalCenter: parent.verticalCenter }
        spacing: Theme.spaceXs
        Text {
            anchors.right: parent.right
            text: Math.round(card.level * 100)
            color: Theme.text
            font { family: Theme.displayFont; pixelSize: [Theme.fontTitle, Theme.fontHeading, Math.round(Theme.fontHeading * 1.4)][card.step]
                   weight: Theme.displayWeight; features: { "tnum": 1 } }
        }
        Row {
            width: parent.width
            spacing: 3
            Repeater {
                model: 10
                Rectangle {
                    required property int index
                    width: (parent.width - 9 * 3) / 10
                    height: Math.round(card.row / 5)
                    radius: Math.min(2, Theme.radiusSmall)
                    color: index < Math.round(card.level * 10) ? Theme.accent : Theme.fill
                }
            }
        }
    }

    // ascii: a terminal meter in the mono face, the number after it
    Text {
        visible: card.label === "" && card.look === "ascii"
        anchors { left: glyph.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: card.edge; verticalCenter: parent.verticalCenter }
        readonly property int cells: 16
        readonly property int on: Math.round(card.level * cells)
        textFormat: Text.StyledText
        elide: Text.ElideRight
        text: "<font color='" + Theme.subtext + "'>[</font><font color='" + Theme.accent + "'>" + "█".repeat(on) + "</font><font color='" + Theme.muted + "'>"
              + "░".repeat(cells - on) + "]</font> " + String(Math.round(card.level * 100)).padStart(3, " ")
        color: Theme.text
        font { family: Theme.monoFont; pixelSize: card.textSize; features: { "tnum": 1 } }
    }
}
