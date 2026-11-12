import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A hairline, then "X Settings…" that opens that Settings page
ColumnLayout {
    id: link
    property string label
    property string page
    Layout.fillWidth: true
    Layout.topMargin: 4
    spacing: 4
    Rectangle { Layout.fillWidth: true; Layout.leftMargin: 6; Layout.rightMargin: 6; implicitHeight: 1; color: Theme.stroke }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 30
        radius: Theme.radiusSmall
        color: linkArea.containsMouse ? Theme.fillHover : "transparent"
        Text {
            anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
            text: link.label
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        MouseArea { id: linkArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { ControlCenter.hide(); SettingsApp.show(link.page) } }
    }
}
