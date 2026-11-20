import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A hairline, then "X Settings…" that opens that Settings page; `-> x settings` in the hud, caps in bento
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
            text: ControlCenter.hud ? "-> " + link.label.replace("…", "").toLowerCase() : link.label
            color: ControlCenter.hud && linkArea.containsMouse ? Theme.accent : Theme.text
            font { family: ControlCenter.textFont; pixelSize: Theme.fontLabel; weight: ControlCenter.bento ? Font.Bold : Font.Normal
                   capitalization: ControlCenter.bento ? Font.AllUppercase : Font.MixedCase }
        }
        MouseArea { id: linkArea; Accessible.role: Accessible.Button; Accessible.name: link.label; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { Flyouts.hideAll(); SettingsApp.show(link.page) } }
    }
}
