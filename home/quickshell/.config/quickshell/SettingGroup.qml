import QtQuick
import QtQuick.Layouts

// A titled, rounded group of SettingRows with hairline separators, like macOS System Settings.
ColumnLayout {
    id: group

    property string title
    default property alias rows: box.data

    Layout.fillWidth: true
    spacing: 8

    Text {
        visible: group.title !== ""
        text: group.title
        leftPadding: 4
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: box.implicitHeight
        radius: 14
        color: Theme.fill
        border { color: Theme.stroke; width: 1 }

        ColumnLayout {
            id: box
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 0
        }
    }
}
