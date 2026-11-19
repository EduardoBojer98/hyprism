import QtQuick
import QtQuick.Layouts

// Control Center building block: a small tile, the icon over its name. On, the tile turns accent (solid themes)
// or takes an accent wash with an accent icon (wash themes). What it is doing (45 min left, Medium) shows in its
// tooltip and accessible description; a large tile shows it inline. With a list, a small chevron in the corner
// opens it (right-click and Enter too).
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
    signal toggled()
    signal expand()
    readonly property string tip: status !== "" && status !== "On" && status !== "Off" ? label + ": " + status : hint || label
    activeFocusOnTab: true   // keyboard: Space switches it, Enter opens its list
    Keys.onSpacePressed: qt.toggled()
    Keys.onReturnPressed: qt.expandable ? qt.expand() : qt.toggled()
    FocusRing {}

    readonly property bool flat: ControlCenter.style === "borderless"
    radius: flat ? Theme.radiusSmall : Theme.radius
    color: active ? (qtArea.containsMouse ? Theme.ccTileOnHover : Theme.ccTileOn)
         : qtArea.containsMouse || isExpanded ? Theme.fillHover
         : flat ? "transparent" : Theme.fill
    border { color: isExpanded ? Theme.strokeStrong : flat && !active ? Theme.stroke : "transparent"; width: 1 }
    scale: qtArea.pressed ? Theme.pressScale : 1
    Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

    Column {
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.spaceXs }
        spacing: Theme.spaceXs + 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qt.glyph
            color: qt.active ? Theme.ccIconOn : Theme.text
            font { family: Theme.iconFont; pixelSize: Theme.glyphL }
            Behavior on color { ColorAnimation { duration: Theme.anim } }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qt.label
            elide: Text.ElideRight
            color: qt.active ? Theme.ccOnText : Theme.text
            font { family: Theme.font; pixelSize: qt.labelSize; weight: Font.DemiBold }
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
        anchors { right: parent.right; top: parent.top; margins: 3 }
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
