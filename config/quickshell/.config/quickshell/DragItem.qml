import QtQuick

// A piece of a Settings editor that can be picked up with the mouse and dropped on a DropSpot with
// the same key. While dragged it floats above the page (on `floatOn`) and leaves an empty slot behind.
// Clicks still work: `clicked` fires for a press and release without a drag. Controls inside the
// content (toggles, buttons) keep their own clicks; the drag starts anywhere else on the item.
//   DragItem { key: "bar"; payload: id; floatOn: page.parent; width: 120; height: 32
//              Rectangle { anchors.fill: parent; ... } }
Item {
    id: slot

    property string key: "item"
    property var payload
    property Item floatOn                  // an item above the whole editor that isn't a layout (page.parent)
    property bool draggable: true
    property real radius: Theme.radiusSmall + 2
    default property alias content: body.data
    readonly property bool dragging: area.drag.active
    readonly property bool hovered: area.containsMouse
    signal clicked()

    // the place it came from, while it's away
    Rectangle {
        visible: slot.dragging
        anchors.fill: parent
        radius: slot.radius
        color: Theme.fill
        border { color: Theme.stroke; width: 1 }
    }

    Item {
        id: body
        width: slot.width
        height: slot.height

        Drag.active: slot.dragging
        Drag.keys: [slot.key]
        Drag.source: slot
        Drag.hotSpot.x: area.pressX
        Drag.hotSpot.y: area.pressY

        Rectangle {   // a card under the floating copy, so rows without a background stay readable
            visible: slot.dragging
            anchors.fill: parent
            radius: slot.radius
            color: Theme.menu
            border { color: Theme.accent; width: 1 }
        }
        MouseArea {   // under the content, so its own controls keep their clicks
            id: area
            property real pressX: 0
            property real pressY: 0
            anchors.fill: parent
            hoverEnabled: true
            enabled: slot.enabled
            cursorShape: slot.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            drag.target: slot.draggable ? body : null
            drag.threshold: 6
            onPressed: mouse => { pressX = mouse.x; pressY = mouse.y }
            onReleased: if (body.Drag.active) body.Drag.drop()
            onClicked: slot.clicked()
        }

        states: State {
            when: slot.dragging && slot.floatOn !== null
            ParentChange { target: body; parent: slot.floatOn }
            PropertyChanges { target: body; z: 1000; opacity: 0.95; scale: 1.03 }
        }
    }
    // back into its slot once dropped (the state change has handed it back by then)
    onDraggingChanged: if (!dragging) Qt.callLater(() => { body.x = 0; body.y = 0 })
}
