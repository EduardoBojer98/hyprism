import QtQuick

// Launcher part: a small section heading on the home view and over result groups. A theme with
// launcher.labels "rule" (Monolith) sets it as a pane title: the name in the second accent, a hairline to the edge.
Item {
    id: label
    property alias text: name.text
    property real leftPad: Theme.spaceXs
    property real topPad: Theme.spaceXs
    property real bottomPad: 0
    width: parent ? parent.width : 0
    implicitHeight: name.implicitHeight + topPad + bottomPad
    height: implicitHeight

    Text {
        id: name
        x: label.leftPad
        y: label.topPad
        color: Launcher.ruled ? Theme.accent2 : Theme.subtext
        font { family: Launcher.rowFont; pixelSize: Theme.fontCaption; weight: Font.DemiBold; letterSpacing: Launcher.ruled ? 0.6 : 0 }
    }
    Rectangle {
        visible: Launcher.ruled
        anchors { left: name.right; leftMargin: Theme.spaceS; right: parent.right; rightMargin: Theme.spaceXs; verticalCenter: name.verticalCenter }
        height: 1
        color: Qt.alpha(Theme.accent2, 0.35)
    }
}
