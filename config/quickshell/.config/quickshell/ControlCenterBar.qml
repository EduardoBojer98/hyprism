import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Slider row: the icon (click it to mute when there is a hint), a thick track whose accent fill carries the
// handle at its end, the value, and (expandable) a chevron that opens its device list. The whole row height
// grabs the track; the wheel and Left / Right (Tab to it) step by 5 %.
// The layout shapes it: a fat pill with the icon inside the track (cards), an ink-edged block (bento), or an ascii
// meter `vol [████████░░] 80` whose short name mutes (hud). Every one still drags, scrolls and steps.
Item {
    id: bar
    property real value: 0
    property string icon
    property string hint
    property bool expandable: false
    property bool isExpanded: false
    property string expandHint: ""   // what the chevron opens, for its tooltip ("Built-in speakers")
    property var host: null          // the panel's PanelState, for tooltips (only the Control Center draws them)
    property string tag: "lvl"       // hud: its short name in the meter (vol, mic, bri)
    signal moved(real value)
    signal iconClicked()
    signal expand()
    readonly property real v: Math.max(0, Math.min(1, value))
    readonly property bool round: Theme.radius > 0
    readonly property bool pill: ControlCenter.cards   // the icon rides inside the track
    readonly property bool hud: ControlCenter.hud
    readonly property int trackH: pill ? Theme.ccWell : Theme.ccTrack

    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    implicitHeight: Math.max(Theme.ccSlider, trackH)

    activeFocusOnTab: true
    Keys.onLeftPressed: bar.moved(Math.max(0, bar.v - 0.05))
    Keys.onRightPressed: bar.moved(Math.min(1, bar.v + 0.05))
    Accessible.role: Accessible.Slider
    Accessible.name: bar.hint || "Level"
    Accessible.description: Math.round(bar.v * 100) + "%"
    Accessible.focusable: true

    Rectangle {   // the icon well: mutes when the slider has a hint, otherwise just names the slider
        id: well
        anchors { left: parent.left; leftMargin: bar.hud ? Theme.spaceS : 0; verticalCenter: parent.verticalCenter }
        z: 2   // pill: over the track it sits in
        width: bar.hud ? tagText.implicitWidth + Theme.spaceXs : Theme.ccWell; height: Theme.ccWell
        radius: bar.pill && bar.round ? height / 2 : Theme.radiusSmall
        color: wellArea.pressed && !bar.hud ? (bar.pill ? Qt.alpha(Theme.accentText, 0.24) : Theme.fillActive)
             : wellArea.containsMouse && !bar.hud ? (bar.pill ? Qt.alpha(Theme.accentText, 0.14) : Theme.fillHover) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Text {
            anchors.centerIn: parent
            visible: !bar.hud
            text: bar.icon
            color: bar.pill ? Theme.accentText : bar.v > 0 ? Theme.text : Theme.subtext
            font { family: Theme.iconFont; pixelSize: Theme.glyph }
        }
        Text {   // hud: the meter's name; muted, it dims
            id: tagText
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            visible: bar.hud
            text: bar.tag
            color: wellArea.containsMouse ? Theme.accent : bar.v > 0 ? Theme.text : Theme.subtext
            font { family: Theme.monoFont; pixelSize: Theme.fontLabel; strikeout: bar.v === 0 && bar.hint !== "" }
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
        anchors { left: bar.pill ? parent.left : well.right; leftMargin: (bar.pill ? 0 : Theme.spaceXs) + bar.pad; right: valueText.left; rightMargin: Theme.spaceS + bar.pad; top: parent.top; bottom: parent.bottom }
        Rectangle {
            id: track
            visible: !bar.hud
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: -bar.pad; rightMargin: -bar.pad }
            height: bar.trackH
            radius: bar.round ? height / 2 : 0
            color: Theme.fillActive
            border { color: Theme.text; width: ControlCenter.bento ? Math.max(1, Theme.line) : 0 }
            Rectangle {   // the fill: from the left edge to the handle, with room for the handle at 0 %
                width: slide.width * bar.v + bar.pad * 2
                height: parent.height
                radius: parent.radius
                color: Theme.selected
            }
        }
        Row {   // hud: [████████░░], as many cells as fit; the empty ones dimmed
            id: meter
            visible: bar.hud
            anchors.verticalCenter: parent.verticalCenter
            readonly property int cells: Math.max(4, Math.floor(slide.width / Math.max(1, mfm.advanceWidth("\u2503"))) - 2)
            readonly property int on: Math.round(bar.v * cells)
            Repeater {
                model: [["[", Theme.muted], ["\u2503".repeat(meter.on), Theme.accent], ["\u00b7".repeat(meter.cells - meter.on), Theme.muted], ["]", Theme.muted]]
                Text { required property var modelData; text: modelData[0]; color: modelData[1]; font: mfm.font }
            }
            FontMetrics { id: mfm; font { family: Theme.monoFont; pixelSize: Theme.fontLabel } }
        }
        Rectangle {
            id: knob
            visible: !bar.hud
            x: slide.width * bar.v - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: bar.pill ? 3 : bar.knob; height: bar.pill ? Math.round(bar.trackH / 2) : bar.knob
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
    readonly property real pad: hud ? 0 : trackH / 2   // the track's rounded end: the handle's centre stops this far in
    readonly property int knob: Theme.ccKnob

    Text {
        id: valueText
        anchors { right: chev.visible ? chev.left : parent.right; rightMargin: chev.visible ? Theme.spaceXs : 2; verticalCenter: parent.verticalCenter }
        width: Math.ceil(fm.advanceWidth("100%")) + 1
        horizontalAlignment: Text.AlignRight
        text: Math.round(bar.v * 100) + (bar.hud ? "" : "%")
        color: bar.hud ? Theme.text : Theme.subtext
        font { family: bar.hud ? Theme.monoFont : ControlCenter.bento ? Theme.displayFont : Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium; features: { "tnum": 1 } }
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
