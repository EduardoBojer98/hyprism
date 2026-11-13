import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: the open-app mark on the edge side of an icon (theme dock.mark, Settings > Dock > Active window
// mark): a dot, a short line, a square bar, a hollow ring or a diamond; bigger and in the accent when focused.
// Pass a `dock` (Dock.qml's root: vertical, sign, ink, indicator) in the floating dock, or the four props
// directly (vertical, sign, ink, style) from anywhere else, such as the dock item inside the bar.
Rectangle {
    id: mark
    property var dock: null
    property bool vertical: dock ? dock.vertical : false
    property int sign: dock ? dock.sign : -1          // +1: mark sits toward the bottom/right of the icon
    property color ink: dock ? dock.ink : Theme.text
    property string style: dock ? dock.indicator : "dot"
    property bool on: false
    property bool urgent: false
    readonly property bool round: style === "dot" || style === "ring"
    readonly property real len: style === "line" ? (on ? 16 : 8) : style === "bar" ? (on ? 22 : 10)
                               : round || style === "diamond" ? (on ? 9 : 7) : 4
    readonly property real thick: style === "dot" ? 4 : style === "ring" ? len : style === "diamond" ? len : 3
    readonly property color tone: urgent ? Theme.warning : on ? Theme.accent : ink
    x: vertical ? (sign > 0 ? parent.width - thick - 1 : 1) : (parent.width - width) / 2
    y: vertical ? (parent.height - height) / 2 : (sign > 0 ? parent.height - thick - 1 : 1)
    width: vertical ? thick : len
    height: vertical ? len : thick
    radius: style === "bar" || style === "diamond" ? 0 : thick / 2
    rotation: style === "diamond" ? 45 : 0
    color: style === "ring" ? "transparent" : tone
    border.width: style === "ring" ? Math.max(1.5, thick * 0.3) : 0
    border.color: tone
    Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
}
