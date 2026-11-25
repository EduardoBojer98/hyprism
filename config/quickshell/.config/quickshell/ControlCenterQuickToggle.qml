import QtQuick
import QtQuick.Layouts

// Control Center building block: a small tile, the icon over its name. On, the tile turns accent (solid themes)
// or takes an accent wash with an accent icon (wash themes). What it is doing (45 min left, Medium) shows in its
// tooltip and accessible description; a large tile shows it inline. With a list, a small chevron in the corner
// opens it (right-click and Enter too).
// The layout shapes it: a wide rounded tile, a round well, the name and its state (cards); the icon over the name with
// a hard shadow it presses into, the big bento tile in the display font (bento); a `[x] name` line (hud).
Rectangle {
    id: qt
    property var host: null   // the panel's PanelState, for the tooltip
    property string glyph
    property string label
    property int labelSize: Theme.fontCaption   // the grid sets one size for all its tiles
    property string status
    property string hint
    property bool active: false
    property bool expandable: false
    property bool isExpanded: false
    property bool big: false   // bento: the 2x2 tile
    signal toggled()
    signal expand()
    readonly property string tip: status !== "" && status !== "On" && status !== "Off" ? label + ": " + status : hint || label
    activeFocusOnTab: true   // keyboard: Space switches it, Enter opens its list
    Keys.onSpacePressed: qt.toggled()
    Keys.onReturnPressed: qt.expandable ? qt.expand() : qt.toggled()
    FocusRing {}

    readonly property bool flat: ControlCenter.style === "borderless"
    readonly property bool hud: ControlCenter.hud
    radius: flat || hud ? Theme.radiusSmall : ControlCenter.cards ? Theme.radiusLarge : Theme.radius
    color: active && !hud ? (qtArea.containsMouse ? Theme.ccTileOnHover : Theme.ccTileOn)
         : qtArea.containsMouse || isExpanded ? Theme.fillHover
         : flat || hud ? "transparent" : Theme.fill
    border { color: hud ? (active ? Theme.accent : qtArea.containsMouse || isExpanded ? Theme.strokeStrong : Theme.stroke)
                  : isExpanded ? Theme.strokeStrong : flat && !active ? Theme.stroke : "transparent"; width: 1 }
    scale: qtArea.pressed && !ControlCenter.bento ? Theme.pressScale : 1
    PressFeel { id: feel; pressed: qtArea.pressed; visible: ControlCenter.bento }
    transform: Translate { x: feel.shift; y: feel.shift + feel.drop }
    Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

    Column {   // the icon over its name (bento, and the classic grid)
        visible: !ControlCenter.cards && !qt.hud
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spaceXs }
        spacing: Theme.spaceXs + 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qt.glyph
            color: qt.active ? Theme.ccIconOn : Theme.text
            font { family: Theme.iconFont; pixelSize: qt.big ? Theme.iconLarge : Theme.glyphL }
            Behavior on color { ColorAnimation { duration: Theme.anim } }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qt.label
            elide: Text.ElideRight
            color: qt.active ? Theme.ccOnText : Theme.text
            font { family: qt.big ? Theme.displayFont : Theme.font; pixelSize: qt.big ? Theme.fontTitle : qt.labelSize; weight: Font.DemiBold
                   capitalization: qt.big ? Font.AllUppercase : Font.MixedCase }
        }
        Text {   // the big bento tile has room for what it is doing
            visible: qt.big && qt.status !== ""
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qt.status
            elide: Text.ElideRight
            color: qt.active ? Theme.ccOnSubtext : Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
    }
    Rectangle {   // cards: a round well, then the name over its state
        id: well
        visible: ControlCenter.cards
        anchors { left: parent.left; leftMargin: Theme.ccInset; verticalCenter: parent.verticalCenter }
        width: Theme.ccWell; height: Theme.ccWell
        radius: Theme.radius > 0 ? height / 2 : 0
        color: qt.active ? Theme.ccWellOn : Theme.fillHover
        Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        Text {
            anchors.centerIn: parent
            text: qt.glyph
            color: qt.active ? Theme.accentText : Theme.text
            font { family: Theme.iconFont; pixelSize: Theme.glyph }
        }
    }
    Column {
        visible: ControlCenter.cards
        anchors { left: well.right; leftMargin: Theme.spaceS; right: parent.right; rightMargin: qt.expandable ? listMark.width + 3 + Theme.spaceXs * 2 + 1 : Theme.spaceXs; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text { width: parent.width; text: qt.label; elide: Text.ElideRight; color: qt.active ? Theme.ccOnText : Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
        Text { width: parent.width; visible: text !== ""; text: qt.status; elide: Text.ElideRight; fontSizeMode: Text.HorizontalFit; minimumPixelSize: Theme.fontCaption - 1; color: qt.active ? Theme.ccOnSubtext : Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
    }
    // hud: a framed cell, the glyph and its `[x]` box on top, the name below; on, the frame and box go lime
    readonly property color hudInk: active || qtArea.containsMouse ? Theme.text : Theme.subtext
    Text {
        id: hudGlyph
        visible: qt.hud
        anchors { left: parent.left; top: parent.top; margins: Theme.spaceS }
        text: qt.glyph; color: qt.active ? Theme.accent : qt.hudInk
        font { family: Theme.iconFont; pixelSize: Theme.glyph }
    }
    Rectangle {   // on: the box in reverse video, like a terminal's selected cell
        id: hudBox
        visible: qt.hud
        anchors { right: parent.right; top: parent.top; margins: Theme.spaceS - 2 }
        width: hudBoxText.implicitWidth; height: hudBoxText.implicitHeight
        color: qt.active ? Theme.accent : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Text { id: hudBoxText; text: qt.status === "" ? "[>]" : qt.active ? "[x]" : "[ ]"; color: qt.active ? Theme.accentText : qt.hudInk
               font { family: Theme.monoFont; pixelSize: Theme.fontCaption; weight: Font.Bold } }
    }
    Text {
        visible: qt.hud
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.spaceS; rightMargin: qt.expandable ? Theme.spaceL + 2 : Theme.spaceS }
        text: qt.label.toLowerCase(); elide: Text.ElideRight; color: qt.hudInk
        font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
    }
    MouseArea {
        id: qtArea
        Accessible.role: Accessible.Button
        Accessible.name: qt.label
        Accessible.description: qt.status || qt.hint
        Accessible.onPressAction: qt.toggled()
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: containsMouse ? qt.host?.hint(qt, qt.tip) : qt.host?.unhint(qt)
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton && qt.expandable ? qt.expand() : qt.toggled()
    }
    // the list it opens, the layout's way: a hairline and a chevron at the tile's right end (cards), a corner block
    // in the second accent once open (bento), `>` turning to `v` (hud). Open is the chevron turned up, never a grey plate.
    Rectangle {
        visible: qt.expandable && ControlCenter.cards
        anchors { right: listMark.left; rightMargin: Theme.spaceXs; verticalCenter: parent.verticalCenter }
        width: 1; height: Math.round(qt.height * 0.42)
        color: qt.active ? Qt.alpha(Theme.ccOnText, 0.22) : Theme.stroke
    }
    Rectangle {
        id: listMark
        readonly property bool block: ControlCenter.bento && qt.isExpanded
        visible: qt.expandable
        anchors { right: parent.right; rightMargin: ControlCenter.bento ? 0 : 3 }
        y: ControlCenter.bento ? 0 : qt.hud ? parent.height - height - 3 : (parent.height - height) / 2
        width: ControlCenter.bento ? 20 : 18; height: width
        radius: ControlCenter.bento ? 0 : height / 2
        color: block ? Theme.accent2 : chevArea.containsMouse ? (qt.active ? Qt.alpha(Theme.ccOnText, 0.16) : Theme.fillHover) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Chevron {
            visible: !qt.hud
            anchors.centerIn: parent
            open: qt.isExpanded
            size: 12
            color: listMark.block ? Theme.accentText : qt.active ? Theme.ccOnSubtext : qt.isExpanded ? Theme.accent
                 : chevArea.containsMouse ? Theme.text : Theme.subtext
        }
        Text {
            visible: qt.hud
            anchors.centerIn: parent
            text: qt.isExpanded ? "v" : ">"
            color: qt.isExpanded ? Theme.accent : chevArea.containsMouse ? Theme.text : Theme.muted
            font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
        }
        MouseArea { id: chevArea; Accessible.role: Accessible.Button; Accessible.name: "Options for " + qt.label; Accessible.onPressAction: qt.expand(); anchors { fill: parent; margins: -4 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: qt.expand() }
    }
}
