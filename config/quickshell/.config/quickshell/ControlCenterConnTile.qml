import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Connection tile: an icon well that toggles, then the name and its state; with a list, the rest of the tile
// opens it and a chevron sits behind a hairline at the right. On: the well fills with the accent (wash
// themes) or the whole tile turns accent (solid themes).
Rectangle {
    id: conn
    property string glyph
    property string title
    property string subtitle
    property bool active: false
    property bool expandable: true
    property bool isExpanded: false
    signal toggled()
    signal expand()

    // keyboard: Tab to it, Space switches it, Enter opens its list
    activeFocusOnTab: true
    Keys.onSpacePressed: conn.toggled()
    Keys.onReturnPressed: if (conn.expandable) conn.expand()
    FocusRing {}

    readonly property bool flat: ControlCenter.style === "borderless"
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.preferredHeight: ControlCenter.style === "compact" ? Math.max(Theme.ccTile - 8, Theme.hit) : Theme.ccTile
    radius: flat ? Theme.radiusSmall : Theme.radius
    color: conn.active ? (rowHover.containsMouse ? Theme.ccTileOnHover : Theme.ccTileOn)
         : rowHover.containsMouse || conn.isExpanded ? Theme.fillHover
         : flat ? "transparent" : Theme.fill
    border { color: conn.isExpanded ? Theme.strokeStrong : flat && !conn.active ? Theme.stroke : "transparent"; width: 1 }
    Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Theme.easing } }

    MouseArea {
        id: rowHover
        Accessible.role: Accessible.Button
        Accessible.name: conn.title
        Accessible.description: conn.subtitle
        Accessible.onPressAction: conn.expandable ? conn.expand() : conn.toggled()
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: conn.expandable ? conn.expand() : conn.toggled()
    }
    Rectangle {   // the icon well: toggles (inline: components declared in this file can't nest)
        id: disc
        anchors { left: parent.left; leftMargin: Theme.ccInset; verticalCenter: parent.verticalCenter }
        width: Theme.ccWell; height: Theme.ccWell; radius: Theme.radiusSmall
        color: conn.active ? Theme.ccWellOn
             : discArea.containsMouse ? Theme.fillActive : Theme.fillHover
        scale: discArea.pressed ? Theme.pressScale : 1
        Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
        Text {
            anchors.centerIn: parent
            text: conn.glyph
            color: conn.active ? Theme.accentText : Theme.text
            font { family: Theme.iconFont; pixelSize: 17 }
            Behavior on color { ColorAnimation { duration: Theme.anim } }
        }
        MouseArea { id: discArea; Accessible.role: Accessible.Button; Accessible.name: (conn.active ? "Turn off " : "Turn on ") + conn.title; Accessible.onPressAction: conn.toggled(); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: conn.toggled() }
    }
    Column {
        anchors { left: disc.right; leftMargin: Theme.spaceS; right: conn.expandable ? rule.left : parent.right; rightMargin: Theme.spaceXs; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text { width: parent.width; text: conn.title; color: conn.active ? Theme.ccOnText : Theme.text; elide: Text.ElideRight; fontSizeMode: Text.HorizontalFit; minimumPixelSize: Theme.fontCaption; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
        Text { width: parent.width; text: conn.subtitle; color: conn.active ? Theme.ccOnSubtext : Theme.subtext; elide: Text.ElideRight; fontSizeMode: Text.HorizontalFit; minimumPixelSize: Theme.fontCaption - 1; font { family: Theme.font; pixelSize: Theme.fontCaption } }
    }
    Rectangle {   // hairline before the chevron: the tile's right end opens the list
        id: rule
        visible: conn.expandable
        anchors { right: chev.left; rightMargin: Theme.spaceXs; verticalCenter: parent.verticalCenter }
        width: 1; height: Math.round(conn.height * 0.42)
        color: conn.active ? Qt.alpha(Theme.ccOnText, 0.22) : Theme.stroke
    }
    Chevron { id: chev; visible: conn.expandable; open: conn.isExpanded; size: 14; color: conn.isExpanded && !conn.active ? Theme.accent : conn.active ? Theme.ccOnText : Theme.subtext
              anchors { right: parent.right; rightMargin: Theme.spaceXs + 2; verticalCenter: parent.verticalCenter } }
}
