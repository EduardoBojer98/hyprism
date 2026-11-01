import QtQuick

// Where a DragItem with the same key can land. "side": on another item, an accent line shows whether
// the dropped one goes before or after it (left/right, or above/below when `vertical`). "fill": a
// whole area (a zone, a list) that takes it at its end, shown with an accent outline.
// `placed(payload, after)` fires once the drag is over, so the editor can rebuild its items safely.
DropArea {
    id: spot

    property string key: "item"
    property string mode: "side"           // "side" or "fill"
    property bool vertical: false
    property real radius: Theme.radiusSmall + 2
    property Item owner: null              // the DragItem this spot sits on: off while that one is carried
    readonly property bool active: containsDrag
    readonly property bool after: vertical ? drag.y > height / 2 : drag.x > width / 2
    signal placed(var payload, bool after)

    keys: [key]
    enabled: !(owner?.dragging ?? false)
    onDropped: drop => {
        const payload = drop.source.payload, after = spot.after
        drop.accept()
        Qt.callLater(() => spot.placed(payload, after))   // after the drag's own handlers have returned
    }

    Rectangle {   // before / after marker
        visible: spot.mode === "side" && spot.active
        x: spot.vertical ? 0 : spot.after ? spot.width - 1 : -2
        y: spot.vertical ? (spot.after ? spot.height - 1 : -2) : 0
        width: spot.vertical ? spot.width : 3
        height: spot.vertical ? 3 : spot.height
        radius: 1.5
        color: Theme.accent
    }
    Rectangle {   // the whole area
        visible: spot.mode === "fill" && spot.containsDrag
        anchors.fill: parent
        radius: spot.radius
        color: Theme.accentWash
        border { color: Theme.accent; width: 1 }
    }
}
