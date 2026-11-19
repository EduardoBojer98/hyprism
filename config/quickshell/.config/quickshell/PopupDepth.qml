import QtQuick
import QtQuick.Effects

// A popup's depth and decor, the theme's way (Theme.depth, Theme.current.popup.decor): a soft shadow, an
// accent glow or a hard offset block behind it; an accent top line or corner brackets over its frame.
// Shared by CursorPopup, TrayMenu and Dropdown. Two in each box, one under the content, one over it:
//   PopupDepth { anchors.fill: parent; z: -1 }   PopupDepth { anchors.fill: parent; z: 10; over: true }
// A PopupWindow leaves PopupDepth.room around the box so the shadow isn't cut off.
Item {
    id: depth
    property real radius: Theme.radiusLarge
    property bool over: false   // true: the decor over the frame; false: the depth under it
    // room a shadow needs outside the box, for windows sized to their box
    // popup.decorColour: the topline and brackets in the accent or the second accent (Monolith's neon pair)
    readonly property color mark: Theme.current.popup.decorColour === "accent2" ? Theme.accent2 : Theme.accent
    readonly property int room: Theme.depth === "soft" || Theme.depth === "glow" ? 36 : Theme.depth === "hard" ? 8 : 2

    RectangularShadow {
        visible: !depth.over && Theme.depth === "soft"
        anchors.fill: parent
        offset.y: 10
        blur: 28
        spread: -4
        radius: depth.radius
        color: Theme.shadow
    }
    RectangularShadow {   // glow: a haze in the accent around the panel
        visible: !depth.over && Theme.depth === "glow"
        anchors.fill: parent
        blur: 34
        spread: 2
        radius: depth.radius
        color: Qt.alpha(Theme.accent, 0.22)
    }
    Rectangle {   // hard: an offset block in the second accent (Poster's cobalt): ink would vanish on its charcoal ground
        visible: !depth.over && Theme.depth === "hard"
        anchors { fill: parent; leftMargin: 7; topMargin: 7; rightMargin: -7; bottomMargin: -7 }
        color: Theme.accent2
    }
    Rectangle {   // topline: the accent along the top edge, like a focused terminal pane (Monolith)
        visible: depth.over && Theme.current.popup.decor === "topline"
        width: parent.width; height: 2
        color: depth.mark
    }
    // brackets draw in from each corner as the popup opens (full motion only)
    readonly property bool shown: visible && (parent?.opacity ?? 1) > 0.01
    property real arm: Theme.bracketArm
    onShownChanged: if (shown && over && Theme.moves) draw.restart()
    NumberAnimation { id: draw; target: depth; property: "arm"; from: 0; to: Theme.bracketArm; duration: Theme.enter; easing.type: Theme.easing }
    Repeater {   // brackets: accent corner marks over the frame
        model: depth.over && Theme.current.popup.decor === "brackets" ? [[0, 0], [1, 0], [0, 1], [1, 1]] : []
        Item {
            id: mark
            required property var modelData
            width: Theme.bracketArm; height: Theme.bracketArm
            x: modelData[0] ? depth.width - width + 2 : -2
            y: modelData[1] ? depth.height - height + 2 : -2
            Rectangle { width: depth.arm; height: 2; color: depth.mark; x: mark.modelData[0] ? parent.width - width : 0; y: mark.modelData[1] ? parent.height - 2 : 0 }
            Rectangle { width: 2; height: depth.arm; color: depth.mark; x: mark.modelData[0] ? parent.width - 2 : 0; y: mark.modelData[1] ? parent.height - height : 0 }
        }
    }
}
