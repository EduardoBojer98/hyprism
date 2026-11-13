import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: the shared tooltip, beside the island at the hovered icon.
// Used by Dock.qml, which passes itself in as `dock`.
// the tooltip, beside the island at the hovered icon; hover-to-hover it moves without waiting
Rectangle {
    required property var dock
    id: tip
    readonly property bool on: dock.tipReady && dock.tipItem !== null && dock.menuBox.entry === null && dock.dragId === "" && !dock.previewOn
    readonly property point at: dock.tipItem ? dock.beside(width, height, dock.middleOf(dock.tipItem), 8) : Qt.point(0, 0)
    x: at.x; y: at.y
    width: tipLabel.implicitWidth + 16
    height: 24
    radius: Theme.radiusSmall
    color: Theme.menu
    border { color: Theme.stroke; width: Theme.line }
    opacity: on ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    Text {
        id: tipLabel
        anchors.centerIn: parent
        text: dock.tipText
        color: Theme.text
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
