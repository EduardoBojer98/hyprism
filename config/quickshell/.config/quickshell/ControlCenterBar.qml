import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Slider row: the icon (click it to mute when there is a hint), a thick track whose accent fill carries the
// handle at its end, the value, and (expandable) a chevron that opens its device list. The whole row height
// grabs the track; the wheel and Left / Right (Tab to it) step by 5 %.
Item {
    id: bar
    property real value: 0
    property string icon
    property string hint
    property bool expandable: false
    property bool isExpanded: false
    property string expandHint: ""   // what the chevron opens, for its tooltip ("Built-in speakers")
    property var host: null          // the panel's PanelState, for tooltips (only the Control Center draws them)
    signal moved(real value)
    signal iconClicked()
    signal expand()
    readonly property real v: Math.max(0, Math.min(1, value))
    readonly property bool round: Theme.radius > 0

    Layout.fillWidth: true
    Layout.preferredHeight: Theme.ccSlider
    implicitHeight: Theme.ccSlider

    activeFocusOnTab: true
    Keys.onLeftPressed: bar.moved(Math.max(0, bar.v - 0.05))
    Keys.onRightPressed: bar.moved(Math.min(1, bar.v + 0.05))
    Accessible.role: Accessible.Slider
    Accessible.name: bar.hint || "Level"
    Accessible.description: Math.round(bar.v * 100) + "%"
    Accessible.focusable: true

    Rectangle {   // the icon well: mutes when the slider has a hint, otherwise just names the slider
        id: well
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: Theme.ccWell; height: Theme.ccWell; radius: Theme.radiusSmall
        color: wellArea.pressed ? Theme.fillActive : wellArea.containsMouse ? Theme.fillHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Text {
            anchors.centerIn: parent
            text: bar.icon
            color: bar.v > 0 ? Theme.text : Theme.subtext
            font { family: Theme.iconFont; pixelSize: Theme.glyph }
        }
        MouseArea {
            id: wellArea
            anchors.fill: parent
            enabled: bar.hint !== ""
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: bar.hint
            Accessible.onPressAction: bar.iconClicked()
            onContainsMouseChanged: containsMouse ? bar.host?.hint(well, bar.hint) : bar.host?.unhint(well)
            onClicked: bar.iconClicked()
        }
    }

    Item {   // the track, with the handle riding at the end of its fill; the hit area is the whole row height
        id: slide
        anchors { left: well.right; leftMargin: Theme.spaceXs + bar.pad; right: valueText.left; rightMargin: Theme.spaceS + bar.pad; top: parent.top; bottom: parent.bottom }
        Rectangle {
            id: track
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: -bar.pad; rightMargin: -bar.pad }
            height: Theme.ccTrack
            radius: bar.round ? height / 2 : 0
            color: Theme.fillActive
            Rectangle {   // the fill: from the left edge to the handle, with room for the handle at 0 %
                width: slide.width * bar.v + bar.pad * 2
                height: parent.height
                radius: parent.radius
                color: Theme.selected
            }
        }
        Rectangle {
            id: knob
            x: slide.width * bar.v - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: bar.knob; height: bar.knob
            radius: bar.round ? width / 2 : 0
            color: Theme.accentText   // reads on the fill it rides on, in every theme
            scale: dragArea.pressed ? 1.15 : dragArea.containsMouse || bar.activeFocus ? 1.08 : 1
            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
        }
        MouseArea {
            id: dragArea
            anchors { fill: parent; leftMargin: -bar.pad; rightMargin: -bar.pad }
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            preventStealing: true
            Accessible.ignored: true
            function set(x) { bar.moved(Math.max(0, Math.min(1, (x - bar.pad) / slide.width))) }
            onPressed: mouse => set(mouse.x)
            onPositionChanged: mouse => { if (pressed) set(mouse.x) }
            onWheel: wheel => bar.moved(Math.max(0, Math.min(1, bar.v + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
    readonly property real pad: Theme.ccTrack / 2   // the track's rounded end: the handle's centre stops this far in
    readonly property int knob: Theme.ccKnob

    Text {
        id: valueText
        anchors { right: chev.visible ? chev.left : parent.right; rightMargin: chev.visible ? Theme.spaceXs : 2; verticalCenter: parent.verticalCenter }
        width: Math.ceil(fm.advanceWidth("100%")) + 1
        horizontalAlignment: Text.AlignRight
        text: Math.round(bar.v * 100) + "%"
        color: Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium; features: { "tnum": 1 } }
        FontMetrics { id: fm; font: valueText.font }
    }

    Rectangle {   // the device list
        id: chev
        visible: bar.expandable
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: Theme.ccWell - 6; height: Theme.ccWell; radius: Theme.radiusSmall
        color: chevArea.containsMouse || bar.isExpanded ? Theme.fillHover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Chevron { anchors.centerIn: parent; open: bar.isExpanded; size: 14 }
        MouseArea {
            id: chevArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Accessible.role: Accessible.Button
            Accessible.name: "Choose device" + (bar.expandHint ? ": " + bar.expandHint : "")
            Accessible.onPressAction: bar.expand()
            onContainsMouseChanged: containsMouse && bar.expandHint ? bar.host?.hint(chev, bar.expandHint) : bar.host?.unhint(chev)
            onClicked: bar.expand()
        }
    }

    FocusRing { radius: Theme.radiusSmall + 3 }
}
