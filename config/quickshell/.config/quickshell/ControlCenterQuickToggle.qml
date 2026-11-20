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
    border { color: isExpanded && !hud ? Theme.strokeStrong : flat && !active && !hud ? Theme.stroke : "transparent"; width: 1 }
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
        anchors { left: well.right; leftMargin: Theme.spaceS; right: parent.right; rightMargin: qt.expandable ? Theme.spaceL : Theme.spaceXs; verticalCenter: parent.verticalCenter }
        spacing: 1
        Text { width: parent.width; text: qt.label; elide: Text.ElideRight; color: qt.active ? Theme.ccOnText : Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold } }
        Text { width: parent.width; visible: text !== ""; text: qt.status; elide: Text.ElideRight; color: qt.active ? Theme.ccOnSubtext : Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
    }
    Row {   // hud: `[x]  night light`, a mono glyph between; an action that only runs reads `[>]`
        id: hudRow
        visible: qt.hud
        readonly property color ink: qt.active ? Theme.accent : qtArea.containsMouse ? Theme.text : Theme.subtext
        anchors { left: parent.left; leftMargin: Theme.spaceXs; right: parent.right; rightMargin: qt.expandable ? Theme.spaceL : Theme.spaceXs; verticalCenter: parent.verticalCenter }
        spacing: Theme.spaceXs
        Text { id: hudBox; anchors.verticalCenter: parent.verticalCenter; text: qt.status === "" ? "[>]" : qt.active ? "[x]" : "[ ]"; color: hudRow.ink; font { family: Theme.monoFont; pixelSize: Theme.fontLabel } }
        Text { id: hudGlyph; anchors.verticalCenter: parent.verticalCenter; text: qt.glyph; color: hudRow.ink; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, hudRow.width - hudBox.width - hudGlyph.width - 2 * hudRow.spacing)
            text: qt.label.toLowerCase(); elide: Text.ElideRight; color: hudRow.ink
            font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
        }
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
    Rectangle {   // the list: a small badge in the corner that reads on the on and off tile alike
        visible: qt.expandable
        anchors { right: parent.right; rightMargin: 3 }
        y: ControlCenter.cards || qt.hud ? (parent.height - height) / 2 : 3
        width: 18; height: 18; radius: Math.min(Theme.radiusSmall, 5)
        color: qt.active ? Qt.alpha(Theme.ccOnText, chevArea.containsMouse || qt.isExpanded ? 0.16 : 0)
                         : chevArea.containsMouse || qt.isExpanded ? Theme.fillActive : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Chevron {
            anchors.centerIn: parent
            open: qt.isExpanded
            size: 12
            color: qt.isExpanded && !qt.active ? Theme.accent : qt.active ? Theme.ccOnSubtext : Theme.subtext
        }
        MouseArea { id: chevArea; Accessible.role: Accessible.Button; Accessible.name: "Options for " + qt.label; Accessible.onPressAction: qt.expand(); anchors { fill: parent; margins: -4 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: qt.expand() }
    }
}
