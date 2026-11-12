import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).

Text {
    property bool shown: false
    visible: shown
    Layout.fillWidth: true
    padding: 8
    wrapMode: Text.Wrap
    color: Theme.muted
    font { family: Theme.font; pixelSize: Theme.fontLabel }
}
