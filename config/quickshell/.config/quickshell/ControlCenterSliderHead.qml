import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Label over a slider; with a detail (device name) it is a button that opens the device list
Item {
    id: sh
    property string title
    property string detail
    property bool isExpanded: false
    signal clicked()
    Layout.fillWidth: true
    Layout.preferredHeight: 16
    Layout.bottomMargin: -4
    Text {
        id: shTitle
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: sh.title
        color: Theme.text
        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
    }
    Row {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        visible: sh.detail !== ""
        spacing: 2
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, sh.width - shTitle.implicitWidth - 30)
            text: sh.detail
            elide: Text.ElideRight
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
        Chevron { open: sh.isExpanded; size: 13; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea {
        anchors.fill: parent
        enabled: sh.detail !== ""
        cursorShape: Qt.PointingHandCursor
        onClicked: sh.clicked()
    }
}
