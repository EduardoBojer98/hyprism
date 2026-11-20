import QtQuick

// Control Center building block, the hud layout only (Monolith): accent corner brackets around a section that draw
// in each time the panel opens (full motion; otherwise they are simply there). Put one inside the section.
Item {
    id: br
    anchors { fill: parent; margins: -Theme.spaceXs }
    visible: ControlCenter.hud
    z: 5
    readonly property int full: Math.round(Theme.bracketArm / 2) + 2
    property real arm: full
    readonly property bool shown: ControlCenter.open && visible
    onShownChanged: if (shown && Theme.moves) draw.restart()
    NumberAnimation { id: draw; target: br; property: "arm"; from: 0; to: br.full; duration: Theme.enter * 2; easing.type: Theme.easing }
    Repeater {
        model: [[0, 0], [1, 0], [0, 1], [1, 1]]
        Item {
            id: mark
            required property var modelData
            width: br.full; height: br.full
            x: modelData[0] ? br.width - width : 0
            y: modelData[1] ? br.height - height : 0
            Rectangle { width: br.arm; height: 1; color: Theme.accent2; x: mark.modelData[0] ? parent.width - width : 0; y: mark.modelData[1] ? parent.height - 1 : 0 }
            Rectangle { width: 1; height: br.arm; color: Theme.accent2; x: mark.modelData[0] ? parent.width - 1 : 0; y: mark.modelData[1] ? parent.height - height : 0 }
        }
    }
}
