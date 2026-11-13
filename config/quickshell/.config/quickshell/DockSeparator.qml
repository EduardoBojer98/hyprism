import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: the hairline between the launcher, the pinned apps and the open windows.
// Used by Dock.qml, which passes itself in as `dock`.
Rectangle {
    required property var dock
    width: dock.vertical ? dock.iconSize * 0.7 : 1
    height: dock.vertical ? 1 : dock.iconSize * 0.7
    color: Qt.alpha(dock.ink, 0.2)
}
