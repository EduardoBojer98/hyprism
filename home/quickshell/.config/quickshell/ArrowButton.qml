import QtQuick

// A small round button with one icon and a tooltip (Settings editors: move up, down, earlier, later)
Rectangle {
    id: ab
    property string glyph
    property string tip
    property bool small: false
    readonly property bool hovered: abArea.containsMouse
    signal clicked()
    width: small ? 18 : 24; height: width; radius: width / 2
    color: abArea.containsMouse && enabled ? Theme.fillActive : small ? "transparent" : Theme.fill
    opacity: enabled ? 1 : 0.3
    Text { anchors.centerIn: parent; text: ab.glyph; color: Theme.text; font { family: Theme.iconFont; pixelSize: ab.small ? 13 : 15 } }
    MouseArea { id: abArea; anchors.fill: parent; hoverEnabled: true; enabled: ab.enabled; cursorShape: Qt.PointingHandCursor; onClicked: ab.clicked() }
    ToolTipText { shown: abArea.containsMouse; text: ab.tip }
}
