import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Connection tile: round icon that toggles, then name and status that open its list (chevron)
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

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.preferredHeight: Math.max(ControlCenter.style === "compact" ? 44 : 52, Theme.hit)
    radius: ControlCenter.style === "borderless" ? Theme.radiusSmall : Theme.radius
    color: conn.isExpanded || rowHover.containsMouse ? Theme.fillHover
         : ControlCenter.style === "borderless" ? "transparent" : Theme.fill
    border { color: conn.isExpanded ? Theme.strokeStrong : ControlCenter.style === "borderless" ? Theme.stroke : "transparent"; width: 1 }
    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    MouseArea {
        id: rowHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: conn.expandable ? conn.expand() : conn.toggled()
    }
    Rectangle {   // round toggle (inline: components declared in this file can't nest)
        id: disc
        anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
        width: 32; height: 32; radius: 16
        color: conn.active ? Theme.tileOn : discArea.containsMouse ? Theme.fillActive : Theme.fillHover
        border { width: conn.active && Theme.washTiles ? 1 : 0; color: Theme.tileOnBorder }
        scale: discArea.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation { duration: Theme.anim } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
        Text {
            anchors.centerIn: parent
            text: conn.glyph
            color: conn.active ? Theme.tileOnIcon : Theme.text
            font { family: Theme.iconFont; pixelSize: 16 }
        }
        MouseArea { id: discArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: conn.toggled() }
    }
    Column {
        anchors { left: disc.right; leftMargin: 9; right: chev.visible ? chev.left : parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
        Text { width: parent.width; text: conn.title; color: Theme.text; elide: Text.ElideRight; fontSizeMode: Text.HorizontalFit; minimumPixelSize: Theme.fontCaption; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
        Text { width: parent.width; text: conn.subtitle; color: Theme.subtext; elide: Text.ElideRight; font { family: Theme.font; pixelSize: Theme.fontCaption } }
    }
    Chevron { id: chev; visible: conn.expandable; open: conn.isExpanded; size: 12; anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter } }
}
