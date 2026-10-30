import QtQuick

// Small glass tooltip that sits under its parent while `shown`.
Rectangle {
    property bool shown: false
    property alias text: label.text

    anchors { top: parent.bottom; topMargin: Theme.spaceXs + 2; horizontalCenter: parent.horizontalCenter }
    width: label.implicitWidth + Theme.spaceM * 2
    height: label.implicitHeight + Theme.spaceS
    radius: Theme.radiusSmall / 1.5
    color: Theme.glassStrong
    border { color: Theme.stroke; width: 1 }
    opacity: shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

    Text {
        id: label
        anchors.centerIn: parent
        color: Theme.text
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
