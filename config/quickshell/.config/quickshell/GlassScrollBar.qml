import QtQuick
import QtQuick.Controls

// Thin macOS-style scrollbar: shown only while the content doesn't fit, widens and brightens under
// the pointer, draggable. Attach with ScrollBar.vertical: GlassScrollBar {} (or .horizontal).
ScrollBar {
    id: bar
    // pixels that don't fit: fractional scales (1.2, 1.25) leave content a pixel or so taller than its box,
    // which mustn't show a full-length bar on a popup that does fit
    readonly property real hidden: size > 0 && parent ? (orientation === Qt.Vertical ? parent.height : parent.width) * (1 / size - 1) : 0
    policy: hidden > 2 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    minimumSize: 0.08
    padding: 2
    implicitWidth: hovered || pressed ? 10 : 7
    implicitHeight: hovered || pressed ? 10 : 7
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast } }
    Behavior on implicitHeight { NumberAnimation { duration: Theme.animFast } }

    contentItem: Rectangle {
        radius: Math.min(width, height) / 2
        color: bar.pressed ? Theme.subtext : bar.hovered ? Theme.subtext : Theme.muted   // visible at rest: it is the only cue that a page scrolls
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
    }
    background: Item {}
}
