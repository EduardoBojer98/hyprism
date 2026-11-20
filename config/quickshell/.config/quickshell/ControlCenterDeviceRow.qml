import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A device or network: round icon (accent when in use), name, status line, and on hover what a
// click does ("Connect", "Disconnect"); a check mark marks the one in use. The hud drops the badge: a `>` cursor and
// accent text mark the one in use, the action reads `[connect]`; bento's action is a solid accent block.
Rectangle {
    id: dr
    property string glyph
    property string title
    property string subtitle
    property string trailingGlyph       // e.g. a lock on secured networks
    property string action              // shown on hover
    property bool selected: false
    property bool warn: false
    signal clicked()
    readonly property bool hud: ControlCenter.hud

    Layout.fillWidth: true
    implicitHeight: subtitle !== "" ? 44 : 36
    radius: Theme.radiusSmall
    color: drArea.containsMouse ? Theme.fillHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Text {
        visible: dr.hud && dr.selected
        anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
        text: ">"
        color: Theme.accent
        font { family: Theme.monoFont; pixelSize: Theme.fontLabel; weight: Font.Bold }
    }
    Rectangle {
        id: badge
        anchors { left: parent.left; leftMargin: dr.hud ? Theme.spaceL : 6; verticalCenter: parent.verticalCenter }
        width: dr.hud ? Theme.glyphS + 2 : 28; height: 28; radius: Theme.radius === 0 ? 0 : 14
        color: dr.hud ? "transparent" : dr.selected ? Theme.accent : Theme.fillHover
        Behavior on color { ColorAnimation { duration: Theme.anim } }
        Text {
            anchors.centerIn: parent
            text: dr.glyph
            color: dr.hud ? (dr.selected ? Theme.accent : Theme.subtext) : dr.selected ? Theme.accentText : Theme.text
            font { family: Theme.iconFont; pixelSize: Theme.glyphS }
        }
    }
    Column {
        anchors { left: badge.right; leftMargin: dr.hud ? Theme.spaceS : 10; right: tail.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text {
            width: parent.width
            text: dr.title
            elide: Text.ElideRight
            color: dr.hud && dr.selected ? Theme.accent : Theme.text
            font { family: ControlCenter.textFont; pixelSize: Theme.fontSize; weight: dr.selected ? (ControlCenter.bento ? Font.Bold : Font.DemiBold) : Font.Normal }
        }
        Text {
            visible: dr.subtitle !== ""
            width: parent.width
            text: dr.subtitle
            elide: Text.ElideRight
            color: dr.warn ? Theme.warning : Theme.subtext
            font { family: ControlCenter.textFont; pixelSize: Theme.fontCaption }
        }
    }
    Item {
        id: tail
        anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        width: Math.max(actionPill.visible ? actionPill.width : 0, tailGlyph.visible ? tailGlyph.implicitWidth : 0)
        height: 22
        Rectangle {
            id: actionPill
            visible: drArea.containsMouse && dr.action !== ""
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: actionText.implicitWidth + (dr.hud ? 0 : 16); height: 22; radius: Theme.radius === 0 ? 0 : 11
            color: dr.hud ? "transparent" : ControlCenter.bento ? Theme.accent : Theme.fillActive
            Text { id: actionText; anchors.centerIn: parent; text: dr.hud ? "[" + dr.action.toLowerCase() + "]" : dr.action
                   color: dr.hud ? Theme.accent : ControlCenter.bento ? Theme.accentText : Theme.text
                   font { family: ControlCenter.textFont; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
        }
        Text {
            id: tailGlyph
            visible: !actionPill.visible && text !== ""
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: dr.selected && !dr.hud ? "\u{F012C}" : dr.trailingGlyph
            color: dr.selected ? Theme.accent : Theme.muted
            font { family: Theme.iconFont; pixelSize: Theme.glyphS }
        }
    }
    MouseArea { id: drArea; Accessible.role: Accessible.Button; Accessible.name: dr.title; Accessible.onPressAction: dr.clicked(); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dr.clicked() }
}
