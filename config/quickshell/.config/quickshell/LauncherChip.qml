import QtQuick

// Launcher part: one quick action on the home view, as a chip with its whole name (and a toggle's state);
// `at` is its keyboard index. The sheet (Poster) draws it ruled in ink, room left for the hard shadow.
Rectangle {
    id: chip
    property var item
    property int at
    readonly property bool current: Launcher.homeIndex === at
    readonly property bool sheet: Launcher.layout === "sheet"
    width: chipRow.implicitWidth + Theme.spaceM * 2 + (sheet ? Theme.shadowOffset : 0)
    height: Math.max(Theme.hit, Theme.rowHeight)
    radius: Launcher.corner === 0 ? 0 : Launcher.look.corners === "round" ? height / 2 : Theme.radiusSmall
    color: "transparent"
    // the chip's own ground and hairline; under the selection, which draws its block over it
    Rectangle {
        anchors { fill: parent; rightMargin: chip.sheet ? Theme.shadowOffset : 0 }
        radius: parent.radius
        color: chipArea.containsMouse && !chip.current ? Theme.fillHover : chip.sheet ? "transparent" : Theme.fill
        border { width: 1; color: chip.sheet ? Theme.text : Theme.stroke }
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }
    LauncherSelection { on: chip.current; radius: chip.radius }
    Row {
        id: chipRow
        x: Theme.spaceM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spaceS
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.item.glyph ?? ""
            color: chip.current ? Launcher.selText : Theme.accent
            font { family: Theme.iconFont; pixelSize: Theme.glyph }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.item.title
            color: chip.current ? Launcher.selText : Theme.text
            font { family: Launcher.rowFont; pixelSize: Theme.fontLabel; weight: chip.sheet ? Font.Bold : Font.Medium }
        }
        Text {   // a toggle's state (Caffeine: Off)
            visible: text !== "" && text.length <= 12
            anchors.verticalCenter: parent.verticalCenter
            text: chip.item.subtitle ?? ""
            color: chip.current ? Launcher.selSub : Theme.muted
            font { family: Launcher.rowFont; pixelSize: Theme.fontCaption }
        }
    }
    MouseArea { id: chipArea; Accessible.role: Accessible.Button; Accessible.name: chip.item.title; Accessible.onPressAction: Launcher.activate(chip.item); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: Launcher.homeIndex = chip.at; onClicked: Launcher.activate(chip.item) }
}
