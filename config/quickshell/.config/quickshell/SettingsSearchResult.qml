import QtQuick

// Settings search: one result in the sidebar (the page's icon, a title and where it is). Enter, Space or a click opens it.
Rectangle {
    id: result
            property string glyph
    property string title
    property string place
    signal chosen()
    width: parent.width
    height: Math.max(44, Theme.hit)
    radius: Theme.radiusSmall
    color: resArea.containsMouse || activeFocus ? Theme.fillHover : "transparent"
    // keyboard: Tab or Down from the search field, Enter opens
    activeFocusOnTab: true
    Keys.onReturnPressed: chosen()
    Keys.onSpacePressed: chosen()
    Keys.onDownPressed: nextItemInFocusChain(true).forceActiveFocus()
    Keys.onUpPressed: nextItemInFocusChain(false).forceActiveFocus()
    FocusRing {}
    Text {
        id: resGlyph
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        text: result.glyph
        color: Theme.subtext
        font { family: Theme.iconFont; pixelSize: Theme.glyphS }
    }
    Column {
        anchors { left: resGlyph.right; leftMargin: 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        Text { width: parent.width; elide: Text.ElideRight; text: result.title; color: Theme.text
               font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
        Text { width: parent.width; elide: Text.ElideRight; text: result.place; color: Theme.subtext
               font { family: Theme.font; pixelSize: Theme.fontCaption } }
    }
    MouseArea { id: resArea; Accessible.role: Accessible.Button; Accessible.name: result.title + ", " + result.place; Accessible.onPressAction: result.chosen()
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: result.chosen() }
}
