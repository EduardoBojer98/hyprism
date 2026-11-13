import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A square tile in the quick-toggle row: icon, name, and what it's doing; white when on.
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

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.preferredHeight: ControlCenter.style === "compact" ? 54 : 66
    radius: ControlCenter.style === "borderless" ? Theme.radiusSmall : Theme.radius
    color: active ? Theme.tileOn
         : qtArea.containsMouse ? Theme.fillHover
         : ControlCenter.style === "borderless" ? "transparent" : Theme.fill
    border { color: isExpanded ? Theme.accent : active ? Theme.tileOnBorder : ControlCenter.style === "borderless" ? Theme.stroke : "transparent"; width: 1 }
    scale: qtArea.pressed ? 0.96 : 1
    Behavior on color { ColorAnimation { duration: Theme.anim } }
    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

    Column {
        anchors.centerIn: parent
        width: parent.width - 8
        spacing: 1
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qt.glyph
            color: qt.active ? Theme.tileOnIcon : Theme.text
            font { family: Theme.iconFont; pixelSize: 18 }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qt.label
            elide: Text.ElideRight
            fontSizeMode: Text.HorizontalFit   // wide faces (mono) shrink a little before they cut a word
            minimumPixelSize: Theme.fontCaption - 2
            color: qt.active ? Theme.tileOnText : Theme.text
            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: qt.status
            elide: Text.ElideRight
            fontSizeMode: Text.HorizontalFit
            minimumPixelSize: Theme.fontCaption - 2
            color: qt.active ? Theme.tileOnText : Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
        }
    }
    MouseArea {
        id: qtArea
        Accessible.role: Accessible.Button
        Accessible.name: qt.label
        Accessible.onPressAction: qt.toggled()
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: containsMouse && qt.hint !== "" ? ControlCenter.hint(qt, qt.hint) : ControlCenter.unhint(qt)
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton && qt.expandable ? qt.expand() : qt.toggled()
    }
    Rectangle {   // dropdown button: a small round badge that reads on both the light (on) and dark (off) tile
        visible: qt.expandable
        anchors { right: parent.right; top: parent.top; margins: 5 }
        width: 20; height: 20; radius: Theme.radius === 0 ? 0 : 10
        color: qt.active ? Qt.alpha(Theme.tileOnText, chevArea.containsMouse || qt.isExpanded ? 0.16 : 0.09)
                         : chevArea.containsMouse || qt.isExpanded ? Theme.fillActive : Theme.fillHover
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Chevron {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: qt.isExpanded ? -1 : 1
            open: qt.isExpanded
            size: 13
            color: qt.active ? Theme.tileOnText : Theme.text
        }
        MouseArea { id: chevArea; Accessible.role: Accessible.Button; Accessible.name: "Options for " + qt.label; Accessible.onPressAction: qt.expand(); anchors { fill: parent; margins: -4 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: qt.expand() }
    }

}
