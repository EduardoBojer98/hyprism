import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Shortcut in the bottom row: icon and label side by side, on a quiet tile
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
    Layout.preferredHeight: Math.max(Theme.ccWell + Theme.spaceXs * 2, Theme.hit)
    radius: Theme.radius
    color: ibArea.pressed ? Theme.fillActive : ibArea.containsMouse ? Theme.fillHover : Theme.fill
    scale: ibArea.pressed ? Theme.pressScale : 1
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
    Row {
        anchors.centerIn: parent
        spacing: Theme.spaceS - 2
        Text { anchors.verticalCenter: parent.verticalCenter; text: ib.glyph; color: Theme.text; font { family: Theme.iconFont; pixelSize: 16 } }
        Text { anchors.verticalCenter: parent.verticalCenter; text: ib.label; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
    }
    MouseArea { id: ibArea; Accessible.role: Accessible.Button; Accessible.name: ib.label; Accessible.onPressAction: ib.clicked(); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: ib.clicked() }
}
