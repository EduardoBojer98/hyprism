import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A device or network: round icon (accent when in use), name, status line, and on hover what a
// click does ("Connect", "Disconnect"); a check mark marks the one in use
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

    Layout.fillWidth: true
    implicitHeight: subtitle !== "" ? 44 : 36
    radius: Theme.radiusSmall
    color: drArea.containsMouse ? Theme.fillHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Rectangle {
        id: badge
        anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
        width: 28; height: 28; radius: 14
        color: dr.selected ? Theme.accent : Theme.fillHover
        Behavior on color { ColorAnimation { duration: Theme.anim } }
        Text {
            anchors.centerIn: parent
            text: dr.glyph
            color: dr.selected ? Theme.accentText : Theme.text
            font { family: Theme.iconFont; pixelSize: 14 }
        }
    }
    Column {
        anchors { left: badge.right; leftMargin: 10; right: tail.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text {
            width: parent.width
            text: dr.title
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize; weight: dr.selected ? Font.DemiBold : Font.Normal }
        }
        Text {
            visible: dr.subtitle !== ""
            width: parent.width
            text: dr.subtitle
            elide: Text.ElideRight
            color: dr.warn ? Theme.warning : Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
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
            width: actionText.implicitWidth + 16; height: 22; radius: 11
            color: Theme.fillActive
            Text { id: actionText; anchors.centerIn: parent; text: dr.action; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
        }
        Text {
            id: tailGlyph
            visible: !actionPill.visible && text !== ""
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: dr.selected ? "\u{F012C}" : dr.trailingGlyph
            color: dr.selected ? Theme.accent : Theme.muted
            font { family: Theme.iconFont; pixelSize: 14 }
        }
    }
    MouseArea { id: drArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dr.clicked() }
}
