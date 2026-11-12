import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Pill slider: the fill carries the icon (click it to mute), the value sits at the right end
Item {
    id: bar
    property real value: 0
    property string icon
    property string hint
    signal moved(real value)
    signal iconClicked()
    readonly property real v: Math.max(0, Math.min(1, value))

    Layout.fillWidth: true
    Layout.preferredHeight: 26

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.fill
        Rectangle {
            width: Math.max(track.height, track.width * bar.v)
            height: parent.height
            radius: parent.radius
            color: Theme.selected
        }
    }
    Text {
        id: barIcon
        anchors { left: parent.left; leftMargin: 7; verticalCenter: parent.verticalCenter }
        text: bar.icon
        color: Theme.onSelected
        font { family: Theme.iconFont; pixelSize: 14 }
    }
    Text {
        anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
        text: Math.round(bar.v * 100) + "%"
        // over the fill near the top, on the track otherwise
        color: track.width * bar.v >= track.width - anchors.rightMargin - width - 2 ? Theme.onSelected : Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold; features: { "tnum": 1 } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        property bool onIcon: false
        Accessible.role: Accessible.Slider
        Accessible.name: bar.hint || "Level"
        function set(x) { bar.moved(Math.max(0, Math.min(1, x / width))) }
        onPressed: mouse => { onIcon = bar.hint !== "" && mouse.x < track.height; if (!onIcon) set(mouse.x) }
        onPositionChanged: mouse => { if (pressed && !onIcon) set(mouse.x) }
        onReleased: mouse => { if (onIcon && mouse.x < track.height) bar.iconClicked() }
        onWheel: wheel => bar.moved(Math.max(0, Math.min(1, bar.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
