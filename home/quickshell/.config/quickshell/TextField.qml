import QtQuick

// One-line text input in the Settings style.
Rectangle {
    property alias text: input.text
    property string placeholder
    property bool invalid: false
    signal accepted()

    width: 240; height: Theme.controlHeight
    radius: Theme.radiusSmall
    color: Theme.fill
    border { color: invalid ? Theme.error : input.activeFocus ? Theme.accent : Theme.stroke; width: 1 }
    TextInput {
        id: input
        anchors { fill: parent; leftMargin: Theme.spaceS + 2; rightMargin: Theme.spaceS + 2 }
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Theme.text
        selectionColor: Theme.accent
        font { family: Theme.font; pixelSize: Theme.fontSize }
        onAccepted: parent.accepted()
        Text { visible: !input.text; text: parent.parent.placeholder; color: Theme.muted; font: input.font; anchors.verticalCenter: parent.verticalCenter }
    }
}
