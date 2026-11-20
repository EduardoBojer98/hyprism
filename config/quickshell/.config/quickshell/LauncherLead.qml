import QtQuick

// Launcher part: a row's lead at its left edge, the theme's way (Launcher.layout). sheet: the first-letter index
// in the display face (a letter only where it changes); prompt: a > on the selected row and a dim 01 index.
// Nothing (no width) otherwise.
Item {
    id: lead
    property bool current: false
    property int number: 0
    property string letter: ""
    readonly property string layout: Launcher.layout
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
    implicitWidth: layout === "sheet" ? Theme.spaceXl + Theme.spaceM : layout === "prompt" ? marks.implicitWidth + Theme.spaceS : 0
    width: implicitWidth
    visible: width > 0
    Text {
        visible: lead.layout === "sheet"
        anchors.centerIn: parent
        text: lead.letter
        color: lead.current ? Theme.accent : Theme.text
        font { family: Theme.displayFont; pixelSize: Theme.fontHeading; weight: Theme.displayWeight }
    }
    Row {
        id: marks
        visible: lead.layout === "prompt"
        x: Theme.spaceS
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spaceXs
        Text { text: lead.current ? ">" : " "; color: Theme.accent; font { family: Theme.monoFont; pixelSize: Theme.fontSize; weight: Font.Bold } }
        Text { anchors.baseline: parent.children[0].baseline; text: String(lead.number).padStart(2, "0"); color: lead.current ? Theme.subtext : Theme.muted; font { family: Theme.monoFont; pixelSize: Theme.fontCaption } }
    }
}
