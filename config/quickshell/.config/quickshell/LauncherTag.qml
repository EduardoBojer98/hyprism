import QtQuick

// Launcher part: the sheet's category tag at a row's right end (APP, FILE, SETTING…), a ruled caps label that
// turns with the inverse selection. Only in the sheet layout (Poster).
Rectangle {
    id: tag
    property var item
    property bool current: false
    readonly property string kind: (Search.groupOf[item?.kind] ?? item?.kind ?? "").replace(/s$/, "")
    visible: Launcher.layout === "sheet" && kind !== ""
    width: visible ? label.implicitWidth + Theme.spaceS * 2 : 0
    height: label.implicitHeight + Theme.spaceXs
    color: "transparent"
    border { width: 1; color: current ? Launcher.selText : Theme.text }
    Text {
        id: label
        anchors.centerIn: parent
        text: tag.kind.toUpperCase()
        color: tag.current ? Launcher.selText : Theme.text
        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Bold; letterSpacing: 1 }
    }
}
