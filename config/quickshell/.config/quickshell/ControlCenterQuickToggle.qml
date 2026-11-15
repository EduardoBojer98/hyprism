import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A quick-toggle tile: an icon well, the name, and what it's doing. On reads like a connection tile: the
// well fills with the accent (wash themes) or the whole tile turns accent (solid themes).
// With a list, a small chevron in the corner opens it (right-click works too).
Rectangle {
    id: qt
    property string glyph
    property string label
    property string status
    property string hint
    property bool active: false
    property bool expandable: false
    property bool isExpanded: false
    signal toggled()
    signal expand()
    activeFocusOnTab: true   // keyboard: Space switches it, Enter opens its list
    Keys.onSpacePressed: qt.toggled()
    Keys.onReturnPressed: if (qt.expandable) qt.expand()
    FocusRing {}

    readonly property bool flat: ControlCenter.style === "borderless"
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.preferredHeight: ControlCenter.style === "compact" ? Theme.ccToggle - 14 : Theme.ccToggle
    radius: flat ? Theme.radiusSmall : Theme.radius
    color: active ? (qtArea.containsMouse ? Theme.ccTileOnHover : Theme.ccTileOn)
         : qtArea.containsMouse || isExpanded ? Theme.fillHover
         : flat ? "transparent" : Theme.fill
    border { color: isExpanded ? Theme.strokeStrong : flat && !active ? Theme.stroke : "transparent"; width: 1 }
    scale: qtArea.pressed ? Theme.pressScale : 1
    Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

    Column {
        anchors.centerIn: parent
        width: parent.width - Theme.spaceS
        spacing: 2
        Rectangle {   // the icon well
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.ccWell - 2; height: Theme.ccWell - 2; radius: Theme.radiusSmall
            color: qt.active ? Theme.ccWellOn : Theme.fillHover
            Behavior on color { ColorAnimation { duration: Theme.anim; easing.type: Theme.easing } }
            Text {
                anchors.centerIn: parent
                text: qt.glyph
                color: qt.active ? Theme.accentText : Theme.text
                font { family: Theme.iconFont; pixelSize: 16 }
            }
        }
        Item { width: 1; height: Theme.spaceXs - 2 }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qt.label
            elide: Text.ElideRight
            fontSizeMode: Text.HorizontalFit   // wide faces (mono) shrink a little before they cut a word
            minimumPixelSize: Theme.fontCaption - 2
            color: qt.active ? Theme.ccOnText : Theme.text
            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qt.status
            elide: Text.ElideRight
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Theme.fontCaption - 2
            color: qt.active ? Theme.ccOnSubtext : Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
        }
    }
    MouseArea {
        id: qtArea
        Accessible.role: Accessible.Button
        Accessible.name: qt.label
        Accessible.description: qt.status
        Accessible.onPressAction: qt.toggled()
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: containsMouse && qt.hint !== "" ? ControlCenter.hint(qt, qt.hint) : ControlCenter.unhint(qt)
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton && qt.expandable ? qt.expand() : qt.toggled()
    }
    Rectangle {   // dropdown button: a small badge in the corner that reads on the on and off tile alike
        visible: qt.expandable
        anchors { right: parent.right; top: parent.top; margins: Theme.spaceXs }
        width: 20; height: 20; radius: Math.min(Theme.radiusSmall, 6)
        color: qt.active ? Qt.alpha(Theme.ccOnText, chevArea.containsMouse || qt.isExpanded ? 0.16 : 0.08)
                         : chevArea.containsMouse || qt.isExpanded ? Theme.fillActive : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Chevron {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: qt.isExpanded ? -1 : 1
            open: qt.isExpanded
            size: 13
            color: qt.isExpanded && !qt.active ? Theme.accent : qt.active ? Theme.ccOnText : Theme.subtext
        }
        MouseArea { id: chevArea; Accessible.role: Accessible.Button; Accessible.name: "Options for " + qt.label; Accessible.onPressAction: qt.expand(); anchors { fill: parent; margins: -4 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: qt.expand() }
    }
}
