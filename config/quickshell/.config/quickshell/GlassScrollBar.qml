import QtQuick
import QtQuick.Controls

// Thin macOS-style scrollbar: shown only while the content doesn't fit, widens and brightens under
// the pointer, draggable. Attach with ScrollBar.vertical: GlassScrollBar {} (or .horizontal).
ScrollBar {
    id: bar
    policy: size < 1 ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
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
