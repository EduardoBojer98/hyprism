import Quickshell
import QtQuick

// A small drawing of one theme for the Settings > Themes gallery: its wallpaper, its bar in its own
// shape and place, a window in its frame and corners, all in its colours. Click to switch.
Item {
    id: card
    required property var theme
    property bool chosen: false
    property string label: ""          // the caption under the picture (default: the theme's name)
    signal picked()

    readonly property var c: theme.colour
    readonly property var b: theme.bar
    readonly property var d: theme.dock
    function paint(fill) {   // a bar or dock fill (Themes.qml) as a colour
        return ({ glass: Qt.alpha(c.surface, 0.85), surface: c.surface, ground: c.ground, ink: c.text, none: "transparent" })[fill] ?? c.surface
    }
    readonly property real s: width / 200                 // drawing scale
    readonly property string wall: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/hyprism/wallpapers/" + theme.wall + "-v" + Themes.wallVersion + ".png"

    implicitHeight: shot.height + name.implicitHeight + 10

    Rectangle {
        id: shot
        width: parent.width
        height: width * 0.62
        radius: Theme.radiusSmall
        color: card.c.ground
        clip: true
        border { color: card.chosen ? Theme.accent : area.containsMouse ? Theme.strokeStrong : Theme.stroke; width: card.chosen ? 2 : 1 }

        Image { anchors.fill: parent; anchors.margins: 1; source: "file://" + card.wall; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 400 }

        // a window, in the theme's frame and corners, clear of the bar
        Rectangle {
            readonly property real inset: bar.t + bar.gap + 6 * card.s
            x: card.b.edge === "left" ? inset : 10 * card.s
            y: card.b.edge === "top" ? inset : 10 * card.s
            width: parent.width * 0.62
            height: parent.height * 0.52
            radius: Math.min(card.theme.hypr.rounding, 18) * card.s * 0.6
            color: card.c.surface
            border { color: "#" + card.theme.hypr.active[0].slice(0, 6); width: Math.max(1, card.theme.hypr.border * card.s * 0.6) }
            Column {
                x: 8 * card.s; y: 8 * card.s
                spacing: 4 * card.s
                Repeater { model: [0.7, 0.5, 0.6]; Rectangle { required property real modelData; width: 70 * card.s * modelData; height: 3 * card.s; radius: 1; color: card.c.muted; opacity: 0.6 } }
            }
        }

        // the dock on its own edge (a dock on the bar's edge lives inside the bar)
        Rectangle {
            readonly property bool vertical: card.d.edge === "left" || card.d.edge === "right"
            visible: card.d.edge !== card.b.edge
            width: vertical ? 10 * card.s : 60 * card.s
            height: vertical ? 50 * card.s : 10 * card.s
            x: card.d.edge === "left" ? 3 * card.s : card.d.edge === "right" ? parent.width - width - 3 * card.s : (parent.width - width) / 2
            y: card.d.edge === "top" ? 3 * card.s : card.d.edge === "bottom" ? parent.height - height - 3 * card.s : (parent.height - height) / 2
            radius: card.d.shape === "pill" ? Math.min(width, height) / 2 : card.d.shape === "tile" ? 3 * card.s : 0
            color: card.paint(card.d.fill)
        }

        // the bar, in the theme's place, fill and shape: one strip, or a pill per section
        Item {
            id: bar
            readonly property bool vertical: card.b.edge === "left" || card.b.edge === "right"
            readonly property real t: Math.max(6, card.b.size * card.s * 0.32)
            readonly property real gap: card.b.floating ? 4 * card.s : 0
            readonly property real len: (vertical ? shot.height : shot.width) - gap * 2
            x: card.b.edge === "right" ? shot.width - t - gap : gap
            y: card.b.edge === "bottom" ? shot.height - t - gap : gap
            width: vertical ? t : len
            height: vertical ? len : t
            Repeater {   // the whole strip, or a pill per section: start, centre, end
                model: card.b.segmented ? [0, 0.38, 0.76] : [0]
                Rectangle {
                    required property real modelData   // where the piece starts, as a share of the bar
                    readonly property real part: card.b.segmented ? bar.len * 0.24 : bar.len
                    readonly property real at: bar.len * modelData
                    x: bar.vertical ? 0 : at
                    y: bar.vertical ? at : 0
                    width: bar.vertical ? bar.t : part
                    height: bar.vertical ? part : bar.t
                    radius: card.b.floating && card.theme.shape.radius > 0 ? bar.t / 2 : 0
                    color: card.paint(card.b.fill)
                    border { color: card.c.line; width: card.b.line > 0 ? 1 : 0 }
                    Rectangle {   // the current workspace, in the accent
                        visible: parent.modelData === 0
                        width: bar.t * 0.5; height: width
                        radius: card.b.ws === "dots" ? width / 2 : 0
                        x: bar.vertical ? (bar.t - width) / 2 : bar.t * 0.4
                        y: bar.vertical ? bar.t * 0.4 : (bar.t - height) / 2
                        color: card.c.accent
                    }
                }
            }
            Repeater {   // corner brackets
                model: card.b.decor === "brackets" ? [[0, 0], [1, 0], [0, 1], [1, 1]] : []
                Item {
                    required property var modelData
                    width: 4 * card.s; height: width
                    x: modelData[0] ? bar.width - width : 0
                    y: modelData[1] ? bar.height - height : 0
                    Rectangle { width: parent.width; height: 1; color: card.c.accent; y: parent.modelData[1] ? parent.height - 1 : 0 }
                    Rectangle { width: 1; height: parent.height; color: card.c.accent; x: parent.modelData[0] ? parent.width - 1 : 0 }
                }
            }
        }

        Rectangle {   // the one in use: a check in the corner, besides the accent ring
            visible: card.chosen && card.label === ""
            anchors { right: parent.right; top: parent.top; margins: 6 * card.s }
            width: 22; height: 22; radius: Theme.radius === 0 ? 0 : 11
            color: Theme.accent
            Text { anchors.centerIn: parent; text: "\u{F012C}"; color: Theme.accentText; font { family: Theme.iconFont; pixelSize: Theme.iconSmall - 2 } }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.picked() }
    }
    Text {
        id: name
        anchors { top: shot.bottom; topMargin: 6; left: parent.left }
        text: card.label || card.theme.name
        color: card.chosen ? Theme.accent : card.label ? Theme.subtext : Theme.text
        font { family: card.theme.font.ui; pixelSize: Theme.fontSize; weight: card.chosen ? Font.DemiBold : Font.Medium }
    }
}
