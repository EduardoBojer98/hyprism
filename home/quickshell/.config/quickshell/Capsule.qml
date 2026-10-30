import QtQuick
import QtQuick.Effects

// One floating glass complication in the top bar. Children are laid out in a row.
// `interactive` makes it a button (status, power); `active` marks its open panel in blue.
Glass {
    id: capsule

    default property alias content: row.data
    property alias spacing: row.spacing
    property int horizontalPadding: 14
    property bool active: false
    property bool interactive: false
    signal clicked()
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: 40
    radius: height / 2
    border.color: active ? Theme.accent : Theme.stroke
    color: active ? Theme.accentWash : area.containsMouse ? Qt.rgba(0.12, 0.13, 0.18, 0.55) : Theme.glass
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    // Soft offset shadow so the capsules float above the wallpaper
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.32)
        shadowVerticalOffset: 4
        shadowBlur: 0.6
    }

    Row {
        id: row
        anchors.centerIn: parent
        height: parent.height
        spacing: 10
    }

    MouseArea {
        id: area
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        enabled: capsule.interactive
        cursorShape: Qt.PointingHandCursor
        onClicked: capsule.clicked()
        onWheel: wheel => capsule.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
    }
}
