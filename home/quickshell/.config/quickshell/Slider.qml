import QtQuick

// Glass slider with an icon inside the track, like macOS Control Center. value is 0..1.
Item {
    id: slider

    property real value: 0
    property string icon
    signal moved(real value)
    signal iconClicked()

    implicitHeight: 32

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.fill
        clip: true

        Rectangle {
            width: Math.max(track.height, track.width * Math.max(0, Math.min(1, slider.value)))
            height: parent.height
            radius: height / 2
            color: Theme.text
            opacity: 0.92
        }
    }

    Text {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        text: slider.icon
        color: Theme.accentText
        font { family: Theme.iconFont; pixelSize: 15 }
        MouseArea { anchors { fill: parent; margins: -6 } onClicked: slider.iconClicked() }
    }

    MouseArea {
        anchors { fill: parent; leftMargin: 34 }
        cursorShape: Qt.PointingHandCursor
        function set(x) { slider.moved(Math.max(0, Math.min(1, (x + 34) / slider.width))) }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x) }
        onWheel: wheel => slider.moved(Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
