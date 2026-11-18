import QtQuick

// A drawing of a Control Center layout (a ControlCenter.resolve() snapshot) for the gallery in Settings >
// Control Center: its sections in order, folded cards as one line, its tiles and buttons counted from this
// computer, in its style and width. Drawn at the panel's real size and scaled to fit the box.
Item {
    id: thumb
    required property var snap

    readonly property string style: snap.style
    readonly property bool compact: style === "compact"
    readonly property bool flat: style === "borderless"
    readonly property int pad: compact ? 10 : 16
    readonly property int gap: compact ? 5 : 8
    readonly property int groupGap: compact ? gap : 16
    readonly property int blockRadius: Theme.radius === 0 ? 0 : flat ? Math.max(4, Theme.radius - 4) : Theme.radius + 2
    readonly property var hidden: Array.from(snap.hidden)
    function shown(group) { return ControlCenter.order(group, snap).filter(id => !hidden.includes(id) && (group === "sections" || ControlCenter.available(id))) }
    readonly property var sections: shown("sections")
    readonly property real s: Math.min(width / panel.width, height / panel.height)

    Rectangle {
        id: panel
        width: thumb.snap.width
        height: col.implicitHeight + thumb.pad * 2
        scale: thumb.s
        transformOrigin: Item.TopLeft
        x: (thumb.width - width * thumb.s) / 2
        y: Math.max(0, (thumb.height - height * thumb.s) / 2)
        radius: Theme.radius === 0 ? 0 : thumb.compact ? Theme.radiusLarge : thumb.flat ? Theme.radius : Theme.radiusPanel
        color: Theme.glassStrong
        border { color: Theme.strokeStrong; width: thumb.flat ? 0 : 2 }

        Column {
            id: col
            x: thumb.pad; y: thumb.pad
            width: parent.width - thumb.pad * 2
            spacing: thumb.groupGap

            Repeater {
                model: thumb.sections
                Loader {
                    required property string modelData
                    width: col.width
                    sourceComponent: ({ connections: tilesC, screen: sliderC, audio: sliderC, toggles: gridC, media: mediaC, power: lineC })[modelData]
                    property string section: modelData
                }
            }
            Row {   // the footer: battery, then the panel's own buttons
                width: col.width
                height: 26
                layoutDirection: Qt.RightToLeft
                spacing: 10
                Repeater { model: 4; Rectangle { width: 18; height: 18; radius: 9; y: 4; color: Qt.alpha(Theme.text, 0.16) } }
            }
        }
    }

    component Block: Rectangle {
        radius: thumb.blockRadius
        color: Qt.alpha(Theme.text, Theme.light ? 0.08 : 0.10)
        border { color: Theme.stroke; width: thumb.flat ? 1 : 0 }
    }
    component Bar: Rectangle { height: 8; radius: 4; color: Qt.alpha(Theme.text, 0.22) }

    Component {   // large tiles, two to a row
        id: tilesC
        Flow {
            readonly property var ids: thumb.shown("tiles")
            spacing: thumb.gap
            Repeater {
                model: parent.ids
                Block {
                    width: (col.width - thumb.gap) / 2; height: thumb.compact ? 52 : 62
                    color: Qt.alpha(Theme.accent, 0.22)
                    Rectangle { x: 12; anchors.verticalCenter: parent.verticalCenter; width: 30; height: 30; radius: Theme.radius === 0 ? 0 : 15; color: Qt.alpha(Theme.accent, 0.55) }
                    Bar { x: 52; y: parent.height / 2 - 10; width: parent.width * 0.38 }
                    Bar { x: 52; y: parent.height / 2 + 4; width: parent.width * 0.24; opacity: 0.6 }
                }
            }
        }
    }
    Component {   // the Screen and Sound cards: a title row, then a slider per row unless folded
        id: sliderC
        Block {
            readonly property bool folded: Array.from(thumb.snap.folded).includes(parent.section === "audio" ? "sound" : parent.section)
            readonly property int rows: folded ? 0 : parent.section === "audio" ? thumb.shown("sliders").length : 1
            height: 40 + rows * 34
            Bar { x: 14; y: 16; width: 70; color: Theme.strokeStrong }
            Bar { x: parent.width - 64; y: 16; width: 50; opacity: 0.6 }
            Repeater {
                model: parent.rows
                Item {
                    required property int index
                    x: 14; y: 44 + index * 34; width: parent.width - 28; height: 12
                    Rectangle { anchors.fill: parent; radius: 6; color: Qt.alpha(Theme.text, 0.16) }
                    Rectangle { width: parent.width * (0.7 - index * 0.25); height: parent.height; radius: 6; color: Theme.accent }
                }
            }
        }
    }
    Component {   // the small buttons: four to a row, a few of them on
        id: gridC
        Flow {
            readonly property var ids: thumb.shown("toggles")
            readonly property int cols: thumb.snap.width >= 370 ? 5 : 4
            readonly property real side: (col.width - thumb.gap * (cols - 1)) / cols
            spacing: thumb.gap
            Repeater {
                model: parent.ids
                Block {
                    required property int index
                    width: parent.side; height: thumb.compact ? parent.side * 0.8 : parent.side * 0.92
                    color: index % 5 === 1 || index === 3 ? Qt.alpha(Theme.accent, 0.35) : Qt.alpha(Theme.text, Theme.light ? 0.08 : 0.10)
                    Rectangle { anchors.centerIn: parent; anchors.verticalCenterOffset: -6; width: 16; height: 16; radius: 8; color: Theme.subtext; opacity: 0.7 }
                    Bar { anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - 18; width: parent.width * 0.5; height: 6 }
                }
            }
        }
    }
    Component {
        id: mediaC
        Block {
            height: 84
            Rectangle { x: 12; y: 12; width: 60; height: 60; radius: Math.min(8, thumb.blockRadius); color: Qt.alpha(Theme.accent, 0.4) }
            Bar { x: 86; y: 22; width: parent.width * 0.4; color: Theme.strokeStrong }
            Bar { x: 86; y: 38; width: parent.width * 0.26 }
            Bar { x: 86; y: 58; width: parent.width - 100; height: 6 }
        }
    }
    Component {
        id: lineC
        Block {
            height: Array.from(thumb.snap.folded).includes("power") ? 40 : 74
            Bar { x: 14; y: 16; width: 80; color: Theme.strokeStrong }
            Bar { x: parent.width - 64; y: 16; width: 50; opacity: 0.6 }
        }
    }
}
