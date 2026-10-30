import QtQuick
import QtQuick.Layouts

// One row in a Settings group: label (+ optional hint) on the left, a control on the right.
Item {
    id: row

    property string label
    property string hint
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: Math.max(48, texts.implicitHeight + 20)

    Column {
        id: texts
        anchors { left: parent.left; leftMargin: 16; right: slot.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
        Text {
            width: parent.width
            text: row.label
            color: Theme.text
            elide: Text.ElideRight
            font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
        }
        Text {
            visible: row.hint !== ""
            width: parent.width
            text: row.hint
            color: Theme.muted
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: 11 }
        }
    }

    Row {
        id: slot
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 8
    }
}
