import QtQuick

// Text button. primary = filled accent.
Rectangle {
    id: btn

    property string text
    property bool primary: false
    signal clicked()

    activeFocusOnTab: enabled
    Keys.onSpacePressed: btn.clicked()
    Keys.onReturnPressed: btn.clicked()
    FocusRing {}

    implicitWidth: label.implicitWidth + 28
    implicitHeight: Math.max(30, Theme.hit)
    radius: height / 2
    // disabled: a plain, quiet button (a faded accent pill reads as a broken one)
    readonly property bool filled: primary && enabled
    color: filled ? (area.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
                  : (area.containsMouse ? Theme.fillHover : Theme.fill)
    border { color: filled ? "transparent" : Theme.stroke; width: 1 }
    scale: area.pressed ? Theme.pressScale : 1
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        color: btn.filled ? Theme.accentText : btn.enabled ? Theme.text : Theme.muted
        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
}
