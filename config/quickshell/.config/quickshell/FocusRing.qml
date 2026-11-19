import QtQuick

// The keyboard focus mark for a control, shown only while it has focus (Tab moves between controls): an accent ring
// just outside it, or with Theme.focusStyle "reticle" (Monolith) four corner marks that close in on it.
// Put one inside any focusable control: FocusRing {}
Rectangle {
    id: ring
    readonly property bool reticle: Theme.focusStyle === "reticle"
    readonly property bool on: parent.activeFocus
    anchors { fill: parent; margins: reticle && !on ? -9 : -3 }
    Behavior on anchors.margins { enabled: Theme.moves; NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
    visible: on
    radius: !reticle && (parent.radius ?? 0) > 0 ? parent.radius + 3 : 0
    color: "transparent"
    border { color: Theme.accent; width: reticle ? 0 : 2 }

    Repeater {
        model: ring.reticle ? [[0, 0], [1, 0], [0, 1], [1, 1]] : []
        Item {
            id: corner
            required property var modelData
            width: Theme.bracketArm / 2; height: Theme.bracketArm / 2
            x: modelData[0] ? ring.width - width : 0
            y: modelData[1] ? ring.height - height : 0
            Rectangle { width: parent.width; height: 2; color: Theme.accent; y: corner.modelData[1] ? parent.height - 2 : 0 }
            Rectangle { width: 2; height: parent.height; color: Theme.accent; x: corner.modelData[0] ? parent.width - 2 : 0 }
        }
    }
}
