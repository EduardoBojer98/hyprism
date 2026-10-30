import QtQuick

// Text button. primary = filled accent.
Rectangle {
    id: btn

    property string text
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 30
    radius: height / 2
    color: primary ? (area.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
                   : (area.containsMouse ? Theme.fillHover : Theme.fill)
    border { color: primary ? "transparent" : Theme.stroke; width: 1 }
    opacity: enabled ? 1 : 0.45

    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        color: btn.primary ? Theme.accentText : Theme.text
        font { family: Theme.font; pixelSize: 12; weight: Font.DemiBold }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
}
