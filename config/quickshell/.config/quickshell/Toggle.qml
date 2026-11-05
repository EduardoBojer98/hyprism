import QtQuick

// iOS/macOS-style switch. Keyboard: Tab to it, Space or Enter flips it.
Rectangle {
    id: toggle

    property bool checked: false
    signal toggled(bool checked)

    activeFocusOnTab: true
    Keys.onSpacePressed: toggle.toggled(!toggle.checked)
    Keys.onReturnPressed: toggle.toggled(!toggle.checked)
    FocusRing {}

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
        color: Theme.thumb
        Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
    }

    MouseArea {   // a finger-sized target in tablet mode, the switch itself unchanged
        anchors { fill: parent; margins: -Math.max(0, (Theme.hit - parent.height) / 2) }
        cursorShape: Qt.PointingHandCursor
        onClicked: toggle.toggled(!toggle.checked)
    }
}
