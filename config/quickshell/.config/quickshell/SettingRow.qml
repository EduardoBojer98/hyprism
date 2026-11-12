import QtQuick
import QtQuick.Layouts

// One setting: label and hint on the left, its control on the right. When the window is too
// narrow for both side by side, the control moves under the text.
Item {
    id: row

    property string label
    property string hint
    default property alias control: slot.data
    // under the text when they don't fit side by side, or when a long hint would be squeezed into 3+ lines
    readonly property real textRoom: width - slot.implicitWidth - 48
    readonly property bool stacked: width > 0 && (textRoom < 200 || (hint.length > 60 && textRoom < 300))

    // controls that take an accessibleName and have none are named by this row's label
    Component.onCompleted: { for (const c of slot.children) if (c.accessibleName === "") c.accessibleName = row.label }

    Layout.fillWidth: true
    // tall controls (a wrapped swatch grid, a list) make the row taller, never spill over its border
    implicitHeight: stacked ? texts.implicitHeight + slot.implicitHeight + 34 : Math.max(48, texts.implicitHeight + 20, slot.implicitHeight + 24)

    Column {
        id: texts
        anchors { left: parent.left; leftMargin: 16; right: row.stacked ? parent.right : slot.left; rightMargin: 16 }
        y: row.stacked ? 12 : (row.height - height) / 2
        Text {
            width: parent.width
            text: row.label
            color: Theme.text
            elide: Text.ElideRight
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
        }
        Text {
            visible: row.hint !== ""
            width: parent.width
            text: row.hint
            color: Theme.subtext   // readable copy: secondary text (4.5:1+), not the faint tone
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
    }

    Row {
        id: slot
        x: row.stacked ? 16 : row.width - width - 16
        y: row.stacked ? texts.y + texts.height + 10 : (row.height - height) / 2
        spacing: 8
    }
}
