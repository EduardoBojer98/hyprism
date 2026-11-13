import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A column that slides open and shut (the sound and microphone device lists)
Item {
    id: rv
    property bool open: false
    property alias spacing: rvCol.spacing
    default property alias content: rvCol.data
    property real shown: open ? rvCol.implicitHeight : 0
    Behavior on shown { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    Layout.fillWidth: true
    Layout.preferredHeight: shown
    visible: shown > 0
    clip: true
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    ColumnLayout {
        id: rvCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 2
    }
}
