import QtQuick

// Control Center building block: an on/off switch in the layout's voice. The shared Toggle, or in the hud the words
// `[x] on` / `[ ] off`, the on state in accent. Keyboard: Tab to it, Space or Enter flips it.
Item {
    id: sw
    property bool checked: false
    property string accessibleName: ""
    signal toggled(bool checked)
    readonly property bool hud: ControlCenter.hud
    implicitWidth: hud ? hudText.implicitWidth + Theme.spaceS * 2 : toggle.implicitWidth
    implicitHeight: toggle.implicitHeight

    Toggle { id: toggle; visible: !sw.hud; checked: sw.checked; accessibleName: sw.accessibleName; onToggled: on => sw.toggled(on) }
    Rectangle {
        visible: sw.hud
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: hudArea.containsMouse ? Theme.fillHover : "transparent"
        activeFocusOnTab: visible
        Keys.onSpacePressed: sw.toggled(!sw.checked)
        Keys.onReturnPressed: sw.toggled(!sw.checked)
        FocusRing {}
        Text {
            id: hudText
            anchors.centerIn: parent
            text: sw.checked ? "[x] on" : "[ ] off"
            color: sw.checked ? Theme.accent : hudArea.containsMouse ? Theme.text : Theme.subtext
            font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
        }
        MouseArea {
            id: hudArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.CheckBox
            Accessible.name: sw.accessibleName
            Accessible.checkable: true
            Accessible.checked: sw.checked
            Accessible.onPressAction: sw.toggled(!sw.checked)
            onClicked: sw.toggled(!sw.checked)
        }
    }
}
