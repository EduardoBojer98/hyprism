import QtQuick

// Compact segmented choice: options is a list of labels, index the selected one.
// Keyboard: Tab to it, Left / Right picks the one beside.
Rectangle {
    id: choice

    activeFocusOnTab: true
    function step(d) { const i = Math.max(0, Math.min(choice.options.length - 1, (choice.current >= choice.options.length ? 0 : choice.current) + d)); if (i !== choice.current) choice.picked(i) }
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    FocusRing {}

    property string accessibleName: ""
    Accessible.role: Accessible.RadioButton
    Accessible.name: choice.accessibleName !== "" ? choice.accessibleName : String(choice.shown[choice.current] ?? "")
    Accessible.description: choice.accessibleName !== "" ? String(choice.shown[choice.current] ?? "") : ""
    Accessible.focusable: true

    property var options: []
    property int index: 0
    property string extra: ""   // value outside options, shown as a selected extra entry
    readonly property var shown: extra ? options.concat([extra]) : options
    readonly property int current: extra ? options.length : index
    signal picked(int index)

    implicitWidth: row.implicitWidth + 6
    implicitHeight: Math.max(28, Theme.hit)
    radius: height / 2
    color: Theme.fill
    border { color: Theme.stroke; width: 1 }

    Row {
        id: row
        anchors.centerIn: parent
        Repeater {
            model: choice.shown
            Rectangle {
                required property var modelData
                required property int index
                width: label.implicitWidth + (Theme.hit ? 32 : 22)
                height: choice.height - 6
                radius: height / 2
                Accessible.role: Accessible.RadioButton
                Accessible.name: String(modelData)
                Accessible.checkable: true
                Accessible.checked: index === choice.current
                Accessible.focusable: true
                Accessible.onPressAction: if (index < choice.options.length) choice.picked(index)
                color: index === choice.current ? Theme.fillActive : area.containsMouse ? Theme.fillHover : "transparent"
                border { color: index === choice.current ? Theme.stroke : "transparent"; width: 1 }
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: modelData
                    color: index === choice.current ? Theme.text : Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
                }
                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (index < choice.options.length) choice.picked(index) }
            }
        }
    }
}
