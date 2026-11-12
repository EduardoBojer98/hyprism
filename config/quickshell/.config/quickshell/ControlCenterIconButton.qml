import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Shortcut in the bottom row: icon over a small label, on a quiet tile
Rectangle {
    id: ib
    property string glyph
    property string label
    signal clicked()
    activeFocusOnTab: true
    Keys.onSpacePressed: ib.clicked()
    Keys.onReturnPressed: ib.clicked()
    FocusRing {}
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.preferredHeight: 50
    radius: Theme.radius
    color: ibArea.containsMouse ? Theme.fillHover : Theme.fill
    scale: ibArea.pressed ? 0.96 : 1
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
    Column {
        anchors.centerIn: parent
        spacing: 2
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: ib.glyph; color: Theme.text; font { family: Theme.iconFont; pixelSize: 16 } }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: ib.label; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium } }
    }
    MouseArea { id: ibArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
}
