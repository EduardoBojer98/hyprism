import QtQuick

// Launcher part: the selected row or cell's mark, the theme's way (Launcher.layout): grid a soft wash that springs
// in, sheet an inverse block on a hard offset shadow, otherwise the plain tint or block. The first child of a row,
// so the row's text draws over it; `inset` leaves room on the left (the sheet's letter index).
Item {
    id: sel
    property bool on: false
    property real radius: 0
    property real inset: 0
    readonly property bool sheet: Launcher.layout === "sheet"
    anchors.fill: parent
    Rectangle {   // the hard shadow, in ink, offset down and right
        visible: sel.sheet
        x: sel.inset + Theme.shadowOffset; y: Theme.shadowOffset
        width: block.width; height: block.height
        color: Theme.text
        opacity: block.opacity
    }
    Rectangle {
        id: block
        x: sel.inset
        width: parent.width - sel.inset - (sel.sheet ? Theme.shadowOffset : 0)
        height: parent.height
        radius: sel.radius
        color: Launcher.selection
        opacity: sel.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        // grid: springs in from a little smaller, only in full motion (reduced motion: the fade alone)
        scale: sel.on || Launcher.layout !== "grid" || !Theme.moves ? 1 : 0.9
        Behavior on scale {
            enabled: Launcher.layout === "grid" && Theme.moves
            NumberAnimation { duration: Theme.anim; easing.type: Easing.OutBack; easing.overshoot: Theme.popOvershoot }
        }
    }
}
