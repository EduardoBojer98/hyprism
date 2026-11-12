import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: the open-app mark on the edge side of an icon (theme dock.mark): a dot, a short line or a square bar; longer and in the accent when focused.
// Used by Dock.qml, which passes itself in as `dock`.
Rectangle {
    required property var dock
    property bool on: false
    property bool urgent: false
    readonly property real len: dock.indicator === "line" ? (on ? 16 : 8) : dock.indicator === "bar" ? (on ? 22 : 10) : 4
    readonly property real thick: dock.indicator === "dot" ? 4 : 3
    x: dock.vertical ? (dock.sign > 0 ? parent.width - thick - 1 : 1) : (parent.width - width) / 2
    y: dock.vertical ? (parent.height - height) / 2 : (dock.sign > 0 ? parent.height - thick - 1 : 1)
    width: dock.vertical ? thick : len
    height: dock.vertical ? len : thick
    radius: dock.indicator === "bar" ? 0 : thick / 2
    color: urgent ? Theme.warning : on ? Theme.accent : dock.ink
    Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
}
