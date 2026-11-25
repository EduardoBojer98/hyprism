import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Connection tile: an icon well that toggles, then the name and its state; with a list, the rest of the tile
// opens it and a chevron sits behind a hairline at the right. On: the well fills with the accent (wash
// themes) or the whole tile turns accent (solid themes). The layout shapes it: a soft card with a round well (cards),
// a wide block with its name in the display font and a hard shadow (bento), a framed cell, `wifi` and its `[x]` box over the network name (hud).
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
    readonly property bool hud: ControlCenter.hud
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.preferredHeight: hud ? Math.max(Theme.hit, Theme.fontLabel * 4) : ControlCenter.style === "compact" ? Math.max(Theme.ccTile - 8, Theme.hit) : Theme.ccTile
    radius: flat || hud ? Theme.radiusSmall : ControlCenter.cards ? Theme.radiusLarge : Theme.radius
    color: conn.active && !hud ? (rowHover.containsMouse ? Theme.ccTileOnHover : Theme.ccTileOn)
         : rowHover.containsMouse || conn.isExpanded ? Theme.fillHover
         : flat || hud ? "transparent" : Theme.fill
    border { color: hud ? (conn.active ? Theme.accent : rowHover.containsMouse || conn.isExpanded ? Theme.strokeStrong : Theme.stroke)
                    : conn.isExpanded ? Theme.strokeStrong : flat && !conn.active ? Theme.stroke : "transparent"; width: 1 }
    PressFeel { id: feel; pressed: rowHover.pressed || discArea.pressed; visible: ControlCenter.bento }
    transform: Translate { x: feel.shift; y: feel.shift + feel.drop }
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
        // hud: the box sits in the cell's top right corner
        anchors { left: conn.hud ? undefined : parent.left; leftMargin: Theme.ccInset; verticalCenter: conn.hud ? undefined : parent.verticalCenter
                  right: conn.hud ? parent.right : undefined; top: conn.hud ? parent.top : undefined; rightMargin: Theme.spaceS - 2; topMargin: Theme.spaceS - 2 }
        width: conn.hud ? box.implicitWidth : Theme.ccWell; height: conn.hud ? box.implicitHeight : Theme.ccWell
        radius: ControlCenter.cards && Theme.radius > 0 ? height / 2 : Theme.radiusSmall
        color: conn.hud ? (conn.active ? Theme.accent : "transparent") : conn.active ? Theme.ccWellOn
             : discArea.containsMouse ? Theme.fillActive : Theme.fillHover
        scale: discArea.pressed ? Theme.pressScale : 1
        Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
        Text {
            anchors.centerIn: parent
            visible: !conn.hud
            text: conn.glyph
            color: conn.active ? Theme.accentText : Theme.text
            font { family: Theme.iconFont; pixelSize: Theme.glyph }
            Behavior on color { ColorAnimation { duration: Theme.anim } }
        }
        Text {   // hud: the switch as a check box
            id: box
            anchors.verticalCenter: parent.verticalCenter
            visible: conn.hud
            text: conn.active ? "[x]" : "[ ]"
            color: conn.active ? Theme.accentText : discArea.containsMouse ? Theme.text : Theme.subtext
            font { family: Theme.monoFont; pixelSize: Theme.fontLabel; weight: Font.Bold }
        }
        MouseArea { id: discArea; Accessible.role: Accessible.Button; Accessible.name: (conn.active ? "Turn off " : "Turn on ") + conn.title; Accessible.onPressAction: conn.toggled(); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: conn.toggled() }
    }
    Column {
        visible: !conn.hud
        anchors { left: disc.right; leftMargin: Theme.spaceS; right: conn.expandable ? rule.left : parent.right; rightMargin: Theme.spaceXs; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text { width: parent.width; text: conn.title; color: conn.active ? Theme.ccOnText : Theme.text; elide: Text.ElideRight; fontSizeMode: Text.HorizontalFit; minimumPixelSize: Theme.fontCaption
               font { family: ControlCenter.bento ? Theme.displayFont : Theme.font; pixelSize: ControlCenter.bento ? Theme.fontTitle : Theme.fontLabel; weight: Font.DemiBold
                      capitalization: ControlCenter.bento ? Font.AllUppercase : Font.MixedCase } }
        Text { width: parent.width; text: conn.subtitle; color: conn.active ? Theme.ccOnSubtext : Theme.subtext; elide: Text.ElideRight; fontSizeMode: Text.HorizontalFit; minimumPixelSize: Theme.fontCaption - 1; font { family: Theme.font; pixelSize: Theme.fontCaption } }
    }
    Text {   // hud: the glyph and name on top
        id: hudGlyph
        visible: conn.hud
        anchors { left: parent.left; top: parent.top; margins: Theme.spaceS }
        text: conn.glyph
        color: conn.active ? Theme.accent : Theme.subtext
        font { family: Theme.iconFont; pixelSize: Theme.glyph }
    }
    Text {
        visible: conn.hud
        anchors { left: hudGlyph.right; leftMargin: Theme.spaceXs; right: disc.left; rightMargin: Theme.spaceXs; verticalCenter: hudGlyph.verticalCenter }
        text: conn.title.toLowerCase()
        elide: Text.ElideRight
        color: conn.active || rowHover.containsMouse ? Theme.text : Theme.subtext
        font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
    }
    Text {   // hud: what it is on (the network, the device) along the bottom
        visible: conn.hud
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.spaceS; rightMargin: conn.expandable ? Theme.spaceL + 2 : Theme.spaceS }
        text: conn.subtitle
        elide: Text.ElideRight
        color: conn.active ? Theme.accent : Theme.muted
        font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
    }
    Rectangle {   // hairline before the chevron: the tile's right end opens the list
        id: rule
        visible: conn.expandable && !conn.hud
        anchors { right: chev.left; rightMargin: Theme.spaceXs; verticalCenter: parent.verticalCenter }
        width: 1; height: Math.round(conn.height * 0.42)
        color: conn.active ? Qt.alpha(Theme.ccOnText, 0.22) : Theme.stroke
    }
    Chevron { id: chev; visible: conn.expandable && !conn.hud; open: conn.isExpanded; size: 14; color: conn.isExpanded && !conn.active ? Theme.accent : conn.active ? Theme.ccOnText : Theme.subtext
              anchors { right: parent.right; rightMargin: Theme.spaceXs + 2; verticalCenter: parent.verticalCenter } }
    Text {   // hud: the list opens to the right
        visible: conn.expandable && conn.hud
        anchors { right: parent.right; rightMargin: Theme.spaceS; bottom: parent.bottom; bottomMargin: Theme.spaceS - 3 }
        text: conn.isExpanded ? "v" : ">"
        color: conn.isExpanded ? Theme.accent : Theme.muted
        font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
    }
}
