import QtQuick

// A drawing of a Control Center layout (a ControlCenter.resolve() snapshot) for the gallery in Settings >
// Control Center: its sections in order, folded cards as one line, its tiles and buttons counted from this
// computer, in its style and width, and in the theme's structure (ControlCenter.layout): soft cards with pill sliders
// (cards), a bento of tiles with hard shadows and heavy labels (bento), or bracketed lines and meters (hud).
// Drawn at the panel's real size and scaled to fit the box.
Item {
    id: thumb
    required property var snap

    readonly property string style: snap.style
    readonly property bool compact: style === "compact"
    readonly property bool flat: style === "borderless"
    readonly property int pad: compact ? 10 : 16
    readonly property int gap: compact ? 5 : 8
    readonly property int groupGap: compact ? gap : 16
    readonly property int blockRadius: Theme.radius === 0 ? 0 : flat ? Math.max(4, Theme.radius - 4) : Theme.radius + (cards ? 6 : 2)
    readonly property bool cards: ControlCenter.cards
    readonly property bool bento: ControlCenter.bento
    readonly property bool hud: ControlCenter.hud
    readonly property color on: Qt.alpha(Theme.accent, cards ? 0.35 : 1)   // a tile that is on: a wash, or solid
    readonly property int lineH: 22   // hud: one text line
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
                Column {
                    required property string modelData
                    width: col.width
                    spacing: thumb.gap
                    Rectangle {   // bento: a heavy label in ink; hud: a `// name` line in the second accent
                        visible: (thumb.bento || thumb.hud) && (modelData === "connections" || modelData === "toggles" || modelData === "media")
                        width: thumb.bento ? 90 : 70; height: thumb.bento ? 12 : 6
                        color: thumb.bento ? Theme.text : Theme.accent2
                        opacity: thumb.hud ? 0.8 : 1
                    }
                    Loader {
                        width: parent.width
                        sourceComponent: ({ connections: tilesC, screen: sliderC, audio: sliderC, toggles: gridC, media: mediaC, power: lineC })[parent.modelData]
                        property string section: parent.modelData
                    }
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
        property bool section: true   // hud: only a whole section gets brackets, never a single tile
        radius: thumb.blockRadius
        color: thumb.hud ? "transparent" : Qt.alpha(Theme.text, Theme.light ? 0.08 : 0.10)
        border { color: Theme.stroke; width: thumb.flat && !thumb.hud ? 1 : 0 }
        Rectangle {   // bento: the hard shadow
            visible: thumb.bento && !thumb.flat
            z: -1; x: 5; y: 5; width: parent.width; height: parent.height
            color: Theme.accent2
            Rectangle { x: -5; y: -5; width: parent.width; height: parent.height; color: Theme.surfaceColor }
        }
        Repeater {   // hud: corner brackets
            model: thumb.hud && parent.section ? [[0, 0], [1, 0], [0, 1], [1, 1]] : []
            Item {
                required property var modelData
                width: 12; height: 12
                x: modelData[0] ? parent.width - width : 0
                y: modelData[1] ? parent.height - height : 0
                Rectangle { width: 12; height: 2; color: Theme.accent2; y: parent.modelData[1] ? 10 : 0 }
                Rectangle { width: 2; height: 12; color: Theme.accent2; x: parent.modelData[0] ? 10 : 0 }
            }
        }
    }
    component Bar: Rectangle { height: 8; radius: thumb.hud ? 0 : 4; color: Qt.alpha(Theme.text, 0.22) }
    component Well: Rectangle {   // an icon well: round in cards, square elsewhere; hud: a [x] box
        width: thumb.hud ? 16 : 30; height: width
        radius: thumb.cards && Theme.radius > 0 ? width / 2 : Math.min(6, thumb.blockRadius)
        property bool lit: false
        color: thumb.hud ? "transparent" : lit ? Qt.alpha(Theme.accent, 0.8) : Qt.alpha(Theme.text, 0.16)
        border { color: lit ? Theme.accent : Theme.subtext; width: thumb.hud ? 2 : 0 }
        Rectangle { visible: thumb.hud && parent.lit; anchors { fill: parent; margins: 5 } color: Theme.accent }
    }
    Component {   // large tiles: two to a row (cards), one wide block each (bento), a `[x] wifi` line each (hud)
        id: tilesC
        Flow {
            readonly property var ids: thumb.shown("tiles")
            spacing: thumb.gap
            Repeater {
                model: parent.ids
                Block {
                    required property int index
                    readonly property bool lit: index === 0
                    section: false
                    width: thumb.cards ? (col.width - thumb.gap) / 2 : col.width
                    height: thumb.hud ? thumb.lineH : thumb.compact ? 52 : 62
                    color: thumb.hud ? "transparent" : lit ? thumb.on : Qt.alpha(Theme.text, Theme.light ? 0.08 : 0.10)
                    Well { x: thumb.hud ? 4 : 12; anchors.verticalCenter: parent.verticalCenter; lit: parent.lit }
                    Bar { x: thumb.hud ? 30 : 52; y: thumb.hud ? 7 : parent.height / 2 - 10; width: parent.width * (thumb.bento ? 0.3 : 0.38); height: thumb.bento ? 12 : 8
                          color: thumb.bento ? Theme.text : Qt.alpha(Theme.text, 0.22) }
                    Bar { visible: !thumb.hud; x: 52; y: parent.height / 2 + (thumb.bento ? 8 : 4); width: parent.width * 0.24; opacity: 0.6 }
                    Bar { visible: thumb.hud; x: parent.width - width - 6; y: 7; width: parent.width * 0.3; color: Qt.alpha(Theme.accent, 0.7) }
                }
            }
        }
    }
    Component {   // the Screen and Sound cards: a title row, then a slider per row unless folded
        id: sliderC
        Block {
            readonly property bool folded: Array.from(thumb.snap.folded).includes(parent.section === "audio" ? "sound" : parent.section)
            readonly property int rows: folded ? 0 : parent.section === "audio" ? thumb.shown("sliders").length : 1
            readonly property int rowH: thumb.cards ? 40 : 34
            height: 40 + rows * rowH
            Bar { x: 14; y: 16; width: 70; color: thumb.hud ? Theme.accent2 : thumb.bento ? Theme.text : Theme.strokeStrong; height: thumb.bento ? 12 : 8 }
            Bar { x: parent.width - 64; y: 16; width: 50; opacity: 0.6 }
            Repeater {
                model: parent.rows
                Item {
                    required property int index
                    readonly property real level: 0.7 - index * 0.25
                    x: 14; y: 44 + index * parent.rowH; width: parent.width - 28; height: thumb.cards ? 26 : 12
                    Rectangle {   // the track (cards: a fat pill; bento: ink-edged)
                        visible: !thumb.hud
                        anchors.fill: parent; radius: thumb.cards ? height / 2 : Theme.radius > 0 ? 6 : 0
                        color: Qt.alpha(Theme.text, 0.16)
                        border { color: Theme.text; width: thumb.bento ? 2 : 0 }
                    }
                    Rectangle {
                        visible: !thumb.hud
                        width: Math.max(height, parent.width * parent.level); height: parent.height
                        radius: thumb.cards ? height / 2 : Theme.radius > 0 ? 6 : 0
                        color: Theme.accent
                        Rectangle { visible: thumb.cards; x: 6; anchors.verticalCenter: parent.verticalCenter; width: 14; height: 14; radius: 7; color: Theme.accentText; opacity: 0.8 }
                    }
                    Row {   // hud: a tag, then thin VU cells
                        visible: thumb.hud
                        spacing: (col.width - 28 - 30 - 14 * 3) / 14
                        Rectangle { width: 22; height: 12; color: Qt.alpha(Theme.text, 0.5) }
                        Item { width: 6; height: 1 }
                        Repeater {
                            model: 14
                            Rectangle { required property int index; width: 3; height: 12
                                        color: index < 14 * parent.parent.level ? Theme.accent : Qt.alpha(Theme.text, 0.18) }
                        }
                    }
                }
            }
        }
    }
    Component {   // the small buttons: four to a row; two wide ones (cards); three framed cells (hud); a 2x2 block first (bento)
        id: gridC
        Item {
            id: g
            readonly property var ids: thumb.shown("toggles")
            readonly property int count: ids.length
            readonly property bool big: thumb.bento && count >= 5
            readonly property int cols: thumb.hud ? 3 : thumb.cards ? 2 : big ? 4 : thumb.snap.width >= 370 ? 5 : 4
            readonly property real side: (width - thumb.gap * (cols - 1)) / cols
            readonly property real cellH: thumb.hud ? 52 : thumb.cards ? 46 : thumb.compact ? side * 0.8 : side * 0.92
            function cell(i) {   // [column, row, wide, tall], as ControlCenterToggles lays them out
                if (!big) return [i % cols, Math.floor(i / cols), 1, 1]
                if (i === 0) return [0, 0, 2, 2]
                if (i <= 4) return [2 + (i - 1) % 2, Math.floor((i - 1) / 2), 1, 1]
                const c = (i - 5) % 4
                return [c, 2 + Math.floor((i - 5) / 4), i === count - 1 ? 4 - c : 1, 1]
            }
            readonly property int rows: big ? 2 + Math.ceil((count - 5) / 4) : Math.ceil(count / cols)
            width: col.width
            height: rows * cellH + Math.max(0, rows - 1) * thumb.gap
            Repeater {
                model: g.ids
                Block {
                    required property int index
                    readonly property var c: g.cell(index)
                    readonly property bool lit: index % 5 === 1 || index === 3
                    section: false
                    x: c[0] * (g.side + thumb.gap); y: c[1] * (g.cellH + thumb.gap)
                    width: c[2] * g.side + (c[2] - 1) * thumb.gap; height: c[3] * g.cellH + (c[3] - 1) * thumb.gap
                    color: thumb.hud ? "transparent" : lit ? thumb.on : Qt.alpha(Theme.text, Theme.light ? 0.08 : 0.10)
                    border { color: thumb.hud ? (lit ? Theme.accent : Theme.strokeStrong) : Theme.stroke; width: thumb.hud ? 2 : thumb.flat ? 1 : 0 }
                    // cards: a well beside a name; hud: an icon and its box over the name; bento and the classic grid: an icon over its name
                    Well { visible: thumb.cards; x: 8; anchors.verticalCenter: parent.verticalCenter; lit: parent.lit; width: 26 }
                    Bar { visible: thumb.cards; x: 42; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.42; height: 6 }
                    Rectangle { visible: thumb.hud; x: 8; y: 8; width: 12; height: 12; color: parent.lit ? Theme.accent : Qt.alpha(Theme.text, 0.4) }
                    Well { visible: thumb.hud; x: parent.width - width - 8; y: 7; lit: parent.lit; width: 14 }
                    Bar { visible: thumb.hud; x: 8; y: parent.height - 14; width: parent.width * 0.55; height: 6 }
                    Rectangle { visible: !thumb.cards && !thumb.hud; anchors.centerIn: parent; anchors.verticalCenterOffset: -6
                                width: parent.c[3] > 1 ? 30 : 16; height: width; radius: width / 2; color: Theme.subtext; opacity: 0.7 }
                    Bar { visible: !thumb.cards && !thumb.hud; anchors.horizontalCenter: parent.horizontalCenter; y: parent.height - (parent.c[3] > 1 ? 30 : 18)
                          width: parent.width * 0.5; height: parent.c[3] > 1 ? 12 : 6; color: parent.c[3] > 1 ? Theme.text : Qt.alpha(Theme.text, 0.22) }
                }
            }
        }
    }
    Component {
        id: mediaC
        Block {
            height: thumb.hud ? 40 : thumb.bento ? 104 : 84
            color: thumb.cards ? Qt.alpha(Theme.accent2, 0.22) : thumb.hud ? "transparent" : Qt.alpha(Theme.text, Theme.light ? 0.08 : 0.10)   // cards: tinted by the art
            Rectangle { visible: !thumb.hud; x: 12; y: 12; width: parent.height - 24; height: width; radius: Math.min(8, thumb.blockRadius); color: Qt.alpha(Theme.accent, 0.4) }
            Bar { x: thumb.hud ? 12 : parent.height + 2; y: thumb.hud ? 16 : 22; width: parent.width * 0.4; height: thumb.bento ? 12 : 8; color: thumb.bento ? Theme.text : Theme.strokeStrong }
            Bar { visible: !thumb.hud; x: parent.height + 2; y: thumb.bento ? 42 : 38; width: parent.width * 0.26 }
            Row {
                visible: thumb.hud
                x: parent.width - width - 12; y: 14; spacing: 6
                Repeater { model: 3; Rectangle { required property int index; width: 18; height: 10; color: index === 1 ? Theme.accent : Qt.alpha(Theme.text, 0.4) } }
            }
            Bar { visible: thumb.cards; x: parent.height + 2; y: 58; width: parent.width - parent.height - 16; height: 6 }
        }
    }
    Component {
        id: lineC
        Block {
            readonly property bool folded: Array.from(thumb.snap.folded).includes("power")
            height: folded ? 40 : 74
            Bar { x: 14; y: 16; width: 80; color: thumb.hud ? Theme.accent2 : thumb.bento ? Theme.text : Theme.strokeStrong; height: thumb.bento ? 12 : 8 }
            Bar { x: parent.width - 64; y: 16; width: 50; opacity: 0.6 }
            Rectangle {   // the mode: a segmented control, or `mode: <balanced>`
                visible: !parent.folded
                x: 14; y: 42; width: thumb.hud ? parent.width * 0.5 : parent.width - 28; height: thumb.hud ? 10 : 22
                radius: thumb.hud ? 0 : Math.min(6, thumb.blockRadius)
                color: thumb.hud ? "transparent" : Qt.alpha(Theme.text, 0.12)
                border { color: Theme.text; width: thumb.bento ? 2 : 0 }
                Rectangle { x: thumb.hud ? parent.width * 0.4 : parent.width / 3; y: thumb.hud ? 0 : 3; width: thumb.hud ? parent.width * 0.6 : parent.width / 3; height: thumb.hud ? parent.height : parent.height - 6
                            radius: parent.radius; color: thumb.hud ? Theme.accent : Theme.selectInverse ? Theme.segOn : Theme.thumb }
                Rectangle { visible: thumb.hud; width: parent.width * 0.32; height: parent.height; color: Qt.alpha(Theme.text, 0.4) }
            }
        }
    }
}
