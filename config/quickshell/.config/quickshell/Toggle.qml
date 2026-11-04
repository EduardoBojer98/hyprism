import QtQuick

// iOS/macOS-style switch.
Rectangle {
    id: toggle

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 42
    implicitHeight: 24
    radius: height / 2
    color: checked ? Theme.accent : Theme.fillActive
    border { color: Theme.stroke; width: 1 }
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    Rectangle {
        width: 18; height: 18; radius: 9
        anchors.verticalCenter: parent.verticalCenter
        x: toggle.checked ? parent.width - width - 3 : 3
        color: "white"
        Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled(!toggle.checked)
    }
}
