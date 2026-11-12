import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Small heading inside a dropdown ("Known networks", "Apps")
Text {
    Layout.fillWidth: true
    Layout.leftMargin: 6
    Layout.topMargin: 6
    Layout.bottomMargin: 2
    color: Theme.muted
    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
}
