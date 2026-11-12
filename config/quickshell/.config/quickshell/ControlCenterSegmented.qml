import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Segmented choice (current -1 = none picked)
Rectangle {
    id: seg
    property var options: []
    property int current: -1
    signal picked(int index)
    Layout.fillWidth: true
    Layout.leftMargin: 4
    Layout.rightMargin: 4
    implicitHeight: Theme.controlHeight + 2
    radius: Theme.radiusSmall + 1
    color: Theme.fill
    Rectangle {
        visible: seg.current >= 0
        width: (parent.width - 6) / Math.max(1, seg.options.length)
        height: parent.height - 6
        y: 3
        x: 3 + Math.max(0, seg.current) * width
        radius: Theme.radiusSmall - 1
        color: Theme.thumb
        Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    }
    Row {
        anchors { fill: parent; margins: 3 }
        Repeater {
            model: seg.options
            Item {
                required property string modelData
                required property int index
                width: parent.width / seg.options.length
                height: parent.height
                Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: seg.current === index ? Theme.thumbText : Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: seg.picked(index) }
            }
        }
    }
}
