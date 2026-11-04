import QtQuick

// Compact segmented choice: options is a list of labels, index the selected one.
Rectangle {
    id: choice

    property var options: []
    property int index: 0
    property string extra: ""   // value outside options, shown as a selected extra entry
    readonly property var shown: extra ? options.concat([extra]) : options
    readonly property int current: extra ? options.length : index
    signal picked(int index)

    implicitWidth: row.implicitWidth + 6
    implicitHeight: 28
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
                width: label.implicitWidth + 22
                height: 22
                radius: 11
                color: index === choice.current ? Theme.fillActive : area.containsMouse ? Theme.fillHover : "transparent"
                border { color: index === choice.current ? Theme.stroke : "transparent"; width: 1 }
                Text {
                    id: label
                    anchors.centerIn: parent
                    text: modelData
                    color: index === choice.current ? Theme.text : Theme.subtext
                    font { family: Theme.font; pixelSize: 12; weight: Font.Medium }
                }
                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (index < choice.options.length) choice.picked(index) }
            }
        }
    }
}
