import QtQuick

// A small drawing of one Spotlight style for Settings > Search & Launcher: the screen with its bar, and the launcher
// in that style's place and shape (split pill or one card, grid or list, how the selection is marked), in the
// active theme's colours. Click to pick it.
Item {
    id: card
    required property var spec          // a Launcher.styles entry, or the theme's launcher block
    property string label
    property string about
    property bool chosen: false
    signal picked()

    readonly property real s: width / 200                  // drawing scale
    readonly property real barT: 7 * s
    readonly property bool sideBar: Theme.barEdge === "left" || Theme.barEdge === "right"
    readonly property bool split: spec.split ?? (Theme.glassy && spec.placement === "center")
    readonly property string corners: spec.corners && spec.corners !== "theme" ? spec.corners : Theme.radius === 0 ? "sharp" : "round"
    readonly property real r: corners === "sharp" ? 0 : 4 * s
    readonly property bool grid: spec.view === "grid" || spec.view === "start"
    readonly property bool inverse: (spec.select ?? "wash") === "inverse"

    implicitHeight: shot.height + text.implicitHeight + Theme.spaceS

    Rectangle {
        id: shot
        width: parent.width
        height: Math.round(width * 0.62)
        radius: Theme.radiusSmall
        color: Theme.base
        clip: true
        border { color: card.chosen ? Theme.accent : area.containsMouse ? Theme.strokeStrong : Theme.stroke; width: card.chosen ? 2 : 1 }

        Rectangle {   // the bar, on the theme's edge
            x: Theme.barEdge === "right" ? parent.width - width : 0
            y: Theme.barEdge === "bottom" ? parent.height - height : 0
            width: card.sideBar ? card.barT : parent.width
            height: card.sideBar ? parent.height : card.barT
            color: Theme.glass
        }
        Rectangle {   // the dimmed screen behind it
            anchors.fill: parent
            color: Theme.shadow
            opacity: Math.min(0.8, (card.spec.dim ?? 0.18) * 1.6)
        }

        // the launcher: [x, y, w, h] in the drawing, per placement (as CursorPopup.place() puts it)
        Item {
            id: box
            readonly property real sw: shot.width
            readonly property real sh: shot.height
            readonly property real t0: Theme.barEdge === "top" ? card.barT : 0
            readonly property var at: ({
                strip: [0, t0, sw, sh * 0.5],
                half: [sw / 2, t0, sw / 2, sh - t0],
                column: [0, t0, sw * 0.34, sh - t0],
                fullscreen: [sw * 0.08, sh * 0.12, sw * 0.84, sh * 0.76],
                island: [sw * 0.24, sh * 0.4, sw * 0.52, sh * 0.54],
                corner: [sw * 0.03, sh * 0.38, sw * 0.4, sh * 0.56],
            })[card.spec.placement] ?? [sw * 0.24, sh * 0.2, sw * 0.52, sh * 0.56]
            x: at[0]; y: at[1]; width: at[2]; height: at[3]
            readonly property real fh: Math.max(10 * card.s, height * (card.spec.placement === "fullscreen" ? 0.17 : 0.2))
            readonly property real gap: card.split ? 3 * card.s : 0

            Rectangle {   // one card behind everything (unified)
                visible: !card.split
                anchors.fill: parent
                radius: card.r
                color: Theme.glassStrong
                border { width: 1; color: Theme.stroke }
            }
            Rectangle {   // the search field (a pill on its own when split)
                id: fieldShape
                width: card.split ? parent.width * 0.74 : parent.width
                height: box.fh
                radius: card.split && card.corners === "round" ? height / 2 : card.r
                color: card.split ? Theme.glassStrong : "transparent"
                border { width: card.split ? 1 : 0; color: Theme.stroke }
                Text {
                    visible: (card.spec.prompt ?? "") !== ""
                    anchors { left: parent.left; leftMargin: 5 * card.s; verticalCenter: parent.verticalCenter }
                    text: card.spec.prompt ?? ""
                    color: Theme.accent
                    font { family: Theme.monoFont; pixelSize: Math.max(8, box.fh * 0.5); weight: Font.Bold }
                }
                Rectangle {   // the lens
                    visible: (card.spec.prompt ?? "") === ""
                    anchors { left: parent.left; leftMargin: 5 * card.s; verticalCenter: parent.verticalCenter }
                    width: box.fh * 0.36; height: width; radius: width / 2
                    color: "transparent"
                    border { width: Math.max(1, card.s); color: Theme.subtext }
                }
                Rectangle {   // typed text
                    x: 5 * card.s + box.fh * 0.6
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * (card.spec.header === "query" ? 0.3 : 0.22)
                    height: Math.max(2, box.fh * (card.spec.header === "query" ? 0.3 : 0.18))
                    radius: height / 2
                    color: Theme.muted
                }
            }
            Rectangle {   // the round mode buttons (beside the pill when split)
                visible: card.split
                anchors { right: parent.right; top: parent.top }
                width: parent.width * 0.26 - box.gap; height: box.fh
                radius: card.corners === "round" ? height / 2 : card.r
                color: Theme.glassStrong
                border { width: 1; color: Theme.stroke }
            }
            Rectangle {   // the hairline between field and results (unified)
                visible: !card.split
                y: box.fh
                width: parent.width; height: 1
                color: Theme.stroke
            }

            Rectangle {   // the results panel
                id: body
                y: box.fh + box.gap
                width: parent.width
                height: parent.height - y
                radius: card.r
                color: card.split ? Theme.glassStrong : "transparent"
                border { width: card.split ? 1 : 0; color: Theme.stroke }
                readonly property real pad: 4 * card.s

                Grid {   // apps first: a grid of icons, the first one selected
                    visible: card.grid
                    x: body.pad; y: body.pad
                    readonly property int cols: Math.max(3, Math.round(body.width / (16 * card.s)))
                    readonly property real cell: (body.width - body.pad * 2) / cols
                    columns: cols
                    Repeater {
                        model: Math.max(0, parent.cols * Math.floor((body.height - body.pad * 2) / parent.cell))
                        Item {
                            required property int index
                            width: parent.cell; height: parent.cell
                            Rectangle {
                                anchors { fill: parent; margins: 1 }
                                visible: parent.index === 0
                                radius: card.r / 2
                                color: card.inverse ? Theme.accent : Theme.accentWash
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.5; height: width
                                radius: card.corners === "sharp" ? 0 : width * 0.3
                                color: parent.index === 0 && card.inverse ? Theme.accentText : Theme.subtext
                                opacity: 0.55
                            }
                        }
                    }
                }
                Column {   // a list: the selected row, then a few more
                    visible: !card.grid
                    x: body.pad; y: body.pad
                    width: body.width - body.pad * 2
                    spacing: 2 * card.s
                    Repeater {
                        model: Math.max(0, Math.min(6, Math.floor((body.height - body.pad * 2) / (9 * card.s))))
                        Rectangle {
                            required property int index
                            width: parent.width; height: 7 * card.s
                            radius: card.r / 2
                            color: index === 0 ? (card.inverse ? Theme.accent : Theme.accentWash) : "transparent"
                            Rectangle {   // the accent tick of a soft selection
                                visible: parent.index === 0 && !card.inverse
                                x: 1; anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(1, card.s); height: parent.height * 0.5
                                color: Theme.accent
                            }
                            Rectangle {
                                x: 3 * card.s; anchors.verticalCenter: parent.verticalCenter
                                width: 4 * card.s; height: width; radius: card.corners === "sharp" ? 0 : width / 2
                                color: parent.index === 0 && card.inverse ? Theme.accentText : Theme.subtext
                                opacity: 0.6
                            }
                            Rectangle {
                                x: 10 * card.s; anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * [0.42, 0.3, 0.36, 0.26, 0.34, 0.28][parent.index]; height: Math.max(2, 1.6 * card.s)
                                radius: height / 2
                                color: parent.index === 0 && card.inverse ? Theme.accentText : Theme.muted
                            }
                        }
                    }
                }
            }
        }
    }

    Column {
        id: text
        anchors { top: shot.bottom; topMargin: Theme.spaceS; left: parent.left; right: parent.right }
        spacing: 2
        Text {
            width: parent.width
            text: (card.chosen ? "\u{F012C}  " : "") + card.label
            elide: Text.ElideRight
            color: card.chosen ? Theme.accent : Theme.text
            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
        }
        Text {
            width: parent.width
            text: card.about
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
    }

    MouseArea {
        id: area
        Accessible.role: Accessible.RadioButton
        Accessible.name: "Spotlight style " + card.label
        Accessible.checkable: true
        Accessible.checked: card.chosen
        Accessible.onPressAction: card.picked()
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.picked()
    }
}
