import QtQuick

// Launcher part: the accent tick at the left of the selected row, so a soft tint selection (wash) still reads
// at a glance; a solid accent selection (inverse) needs none.
Rectangle {
    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
    width: 3
    height: Math.round(parent.height * 0.46)
    radius: 1.5
    color: Theme.accent
    opacity: Launcher.inverse ? 0 : 1
}
