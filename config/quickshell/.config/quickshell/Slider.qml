import QtQuick

// Slider, value 0..1. With an icon: a thick track with the icon inside, like macOS Control Center.
// Without one (Settings): a thin track with a thumb. The fill is the accent, like a toggle that is on.
Item {
    id: slider

    property real value: 0
    property string icon
    signal moved(real value)
    signal iconClicked()

    readonly property bool plain: icon === ""
    readonly property real v: Math.max(0, Math.min(1, value))
    readonly property int lead: plain ? 0 : 34   // the icon's room at the start of the track

    implicitHeight: 32

    // keyboard: Tab to it, Left / Right by 5 %, Home / End to the ends
    activeFocusOnTab: true
    Keys.onLeftPressed: slider.moved(Math.max(0, slider.v - 0.05))
    Keys.onRightPressed: slider.moved(Math.min(1, slider.v + 0.05))
    Keys.onPressed: e => { if (e.key === Qt.Key_Home) slider.moved(0); else if (e.key === Qt.Key_End) slider.moved(1) }
    FocusRing { radius: track.radius + 3 }
    property string accessibleName: ""
    Accessible.role: Accessible.Slider
    Accessible.name: slider.accessibleName
    Accessible.description: Math.round(slider.v * 100) + "%"
    Accessible.focusable: true

    Rectangle {
        id: track
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
        height: slider.plain ? 6 : parent.height
        radius: height / 2
        color: Theme.fill
        border { color: slider.plain ? Theme.stroke : "transparent"; width: slider.plain ? 1 : 0 }
        clip: true

        Rectangle {
            width: slider.plain ? thumb.x + thumb.width / 2 : Math.max(track.height, track.width * slider.v)
            height: parent.height
            radius: height / 2
            color: Theme.selected
        }
    }
    Rectangle {   // thumb (plain only)
        id: thumb
        visible: slider.plain
        width: Math.min(slider.height, 18); height: width; radius: width / 2
        x: (slider.width - width) * slider.v
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.thumb
        border { color: Theme.strokeStrong; width: 1 }
    }

    Text {
        visible: !slider.plain
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        text: slider.icon
        color: slider.v > 0.08 ? Theme.onSelected : Theme.text   // on the fill once the fill reaches it
        font { family: Theme.iconFont; pixelSize: 15 }
        MouseArea { anchors { fill: parent; margins: -6 } onClicked: slider.iconClicked() }
    }

    MouseArea {
        anchors { fill: parent; leftMargin: slider.lead }
        cursorShape: Qt.PointingHandCursor
        // plain: the thumb's centre follows the pointer; with an icon: the fill's end does
        function set(x) {
            const v = slider.plain ? (x - thumb.width / 2) / (slider.width - thumb.width) : (x + slider.lead) / slider.width
            slider.moved(Math.max(0, Math.min(1, v)))
        }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x) }
        onWheel: wheel => slider.moved(Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
