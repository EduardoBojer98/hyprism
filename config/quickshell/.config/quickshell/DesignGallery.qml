import QtQuick
import QtQuick.Layouts

// A grid of ready-made designs for the menu bar, the dock or Spotlight (Settings). A design is a set
// of look options (`set`, Config[section] keys); picking it writes them all and nothing else, so the
// bar's items and the dock's apps stay as they are. The card of the design that matches the current
// options is outlined; none outlined means the options were mixed by hand ("Custom").
//   DesignGallery { section: "bar"; designs: [{ id, name, about, set: { style: "strip", ... } }, ...] }
GridLayout {
    id: gallery

    property string section: "bar"     // "bar", "dock" or "launcher"
    property var designs: []
    readonly property var current: Config[section]
    readonly property var match: designs.find(d => Object.keys(d.set).every(k => current[k] === d.set[k])) ?? null

    function apply(set) { for (const k in set) Config.set(section, k, set[k]) }

    Layout.fillWidth: true
    Layout.margins: 14
    columns: width > 640 ? 4 : 2
    columnSpacing: 12
    rowSpacing: 14

    Repeater {
        model: gallery.designs
        ColumnLayout {
            id: card
            required property var modelData
            readonly property bool on: gallery.match?.id === modelData.id
            Layout.fillWidth: true
            Layout.preferredWidth: 1      // equal columns, whatever the text under each card
            Layout.alignment: Qt.AlignTop
            spacing: 5
            Rectangle {
                id: shot
                Layout.fillWidth: true
                Layout.preferredHeight: width * 10 / 16
                radius: Theme.radiusSmall
                color: "#1c1c1e"
                border { color: card.on ? Theme.accent : area.containsMouse ? Theme.text : Theme.stroke; width: card.on ? 2 : 1 }
                clip: true
                Image {
                    anchors { fill: parent; margins: card.on ? 2 : 1 }
                    source: Wallpapers.current ? "file://" + Wallpapers.current : ""
                    sourceSize.width: 320
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Loader {
                    anchors { fill: parent; margins: card.on ? 2 : 1 }
                    sourceComponent: ({ bar: barMock, dock: dockMock, launcher: launcherMock })[gallery.section]
                    Component { id: barMock; BarMock { look: card.modelData.set } }
                    Component { id: dockMock; DockMock { look: card.modelData.set } }
                    Component { id: launcherMock; LauncherMock { look: card.modelData.set } }
                }
                MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: gallery.apply(card.modelData.set) }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: card.modelData.name
                color: card.on ? Theme.text : Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: card.on ? Font.DemiBold : Font.Normal }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: card.modelData.about
                wrapMode: Text.Wrap
                color: Theme.muted
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
        }
    }

    // A small desktop (240 wide) with a bar in the given look: three groups of items, left, centre and right
    component BarMock: Item {
        id: bm
        property var look: ({})
        readonly property real s: width / 240
        readonly property string style: look.style ?? "strip"
        readonly property bool atBottom: look.position === "bottom"
        readonly property real margin: ["floating", "islands", "compact"].includes(style) ? 4 * s : 0
        readonly property real h: (look.size ?? 30) * 0.4 * s
        readonly property real pad: (({ islands: 5, tabs: 6, compact: 6 })[style] ?? 0) * s
        readonly property real side: (({ floating: 12, islands: 9, tabs: 10 })[style] ?? 6) * s
        readonly property color tone: look.tint === "solid" ? Theme.menu : look.tint === "accent"
            ? Qt.tint(Theme.tinted(0.75, 0.6), Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35))
            : Theme.light ? Qt.rgba(1, 1, 1, 0.6) : Theme.tinted(0.75, 0.55)
        readonly property real barY: atBottom ? height - h - margin : margin
        readonly property var parts: [{ n: 3 }, { n: 2 }, { n: 4 }]
        readonly property real spacer: 8 * s + pad * 2
        function partWidth(n) { return n * 9 * s + (n - 1) * 3 * s }
        readonly property real span: partWidth(3) + partWidth(2) + partWidth(4) + spacer * 2

        Rectangle {   // the strip / floating / compact surface, or the clear shade
            visible: ["strip", "floating", "compact", "clear"].includes(bm.style)
            x: bm.style === "floating" ? bm.margin : bm.style === "compact" ? (bm.width - bm.span) / 2 - bm.pad : 0
            y: bm.barY
            width: bm.style === "compact" ? bm.span + bm.pad * 2 : bm.width - x * 2
            height: bm.h
            radius: bm.style === "floating" || bm.style === "compact" ? height / 2 : 0
            color: bm.style === "clear" ? "transparent" : bm.tone
            border { color: Theme.stroke; width: bm.style === "floating" || bm.style === "compact" ? 1 : 0 }
            gradient: bm.style === "clear" ? shade : null
            Gradient {
                id: shade
                GradientStop { position: bm.atBottom ? 1 : 0; color: Qt.rgba(0, 0, 0, 0.4) }
                GradientStop { position: bm.atBottom ? 0 : 1; color: "transparent" }
            }
        }
        Repeater {
            model: bm.parts
            Item {
                id: group
                required property var modelData
                required property int index
                width: dots.width + bm.pad * 2
                height: bm.h
                y: bm.barY
                x: bm.style === "compact"
                    ? (bm.width - bm.span) / 2 - bm.pad + [0, bm.partWidth(3) + bm.spacer, bm.span - bm.partWidth(4)][index]
                    : index === 0 ? bm.side - bm.pad : index === 2 ? bm.width - width - bm.side + bm.pad : (bm.width - width) / 2
                Rectangle {   // islands and tabs
                    readonly property bool tab: bm.style === "tabs"
                    visible: bm.style === "islands" || tab
                    anchors.fill: parent
                    radius: tab ? 0 : height / 2
                    topLeftRadius: tab && !bm.atBottom ? 0 : tab ? 4 * bm.s : radius
                    topRightRadius: topLeftRadius
                    bottomLeftRadius: tab && bm.atBottom ? 0 : tab ? 4 * bm.s : radius
                    bottomRightRadius: bottomLeftRadius
                    color: bm.tone
                    border { color: Theme.stroke; width: 1 }
                }
                Row {
                    id: dots
                    anchors.centerIn: parent
                    spacing: 3 * bm.s
                    Repeater {
                        model: group.modelData.n
                        Rectangle {
                            width: 9 * bm.s; height: bm.look.items === "chips" ? bm.h * 0.62 : 3 * bm.s
                            anchors.verticalCenter: parent.verticalCenter
                            radius: Math.min(height / 2, 2 * bm.s)
                            color: bm.look.items === "chips" ? Theme.fillActive : Theme.text
                            opacity: 0.85
                            Rectangle {   // the item's text on its chip
                                visible: bm.look.items === "chips"
                                anchors.centerIn: parent
                                width: parent.width * 0.6; height: 2 * bm.s; radius: height / 2
                                color: Theme.text
                            }
                        }
                    }
                }
            }
        }
    }

    // A small desktop with a dock in the given look: the launcher, four pinned apps and two windows
    component DockMock: Item {
        id: dm
        property var look: ({})
        readonly property real s: width / 240
        readonly property string style: look.style ?? "glass"
        readonly property bool panel: style === "panel"
        readonly property bool bare: style === "clear" || style === "shelf"
        readonly property color tone: look.tint === "solid" ? Theme.menu : look.tint === "accent"
            ? Qt.tint(Theme.tinted(0.75, 0.6), Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35))
            : Theme.light ? Qt.rgba(1, 1, 1, 0.6) : Theme.tinted(0.75, panel ? 0.7 : 0.55)
        readonly property int hovered: 2     // which icon the mock shows as hovered

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: dm.height - height - (dm.panel ? 0 : 6 * dm.s)
            width: dm.panel ? dm.width : icons.width + (dm.style === "pill" ? 14 : 10) * dm.s
            height: 24 * dm.s
            radius: dm.panel ? 0 : dm.style === "pill" ? height / 2 : 7 * dm.s
            color: dm.bare ? "transparent" : dm.tone
            border { color: Theme.stroke; width: dm.bare ? 0 : 1 }
            Rectangle {   // shelf slab
                visible: dm.style === "shelf"
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: -4 * dm.s; rightMargin: -4 * dm.s }
                height: parent.height * 0.42
                radius: 2 * dm.s
                color: dm.look.tint === "accent" ? dm.tone : Theme.menu
                border { color: Theme.strokeStrong; width: 1 }
            }
            Row {
                id: icons
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 3 * dm.s }
                spacing: 4 * dm.s
                Repeater {
                    model: 7
                    Item {
                        id: slot
                        required property int index
                        readonly property bool win: index > 4
                        readonly property bool hot: index === dm.hovered
                        width: (win ? 22 : 14) * dm.s
                        height: 18 * dm.s
                        Rectangle {   // hover plate
                            visible: slot.hot && (dm.look.hover ?? "plate") === "plate"
                            anchors { fill: parent; margins: -1.5 * dm.s }
                            radius: 4 * dm.s
                            color: Theme.fillActive
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: slot.hot && dm.look.hover === "lift" ? -3 * dm.s : 0
                            width: parent.width; height: 14 * dm.s
                            radius: 4 * dm.s
                            transformOrigin: Item.Bottom
                            scale: slot.hot && dm.look.hover === "grow" ? 1.3 : 1
                            color: slot.index === 0 ? Theme.fill : slot.win ? Qt.rgba(1, 1, 1, 0.25) : Theme.accent
                            opacity: slot.index === 0 || slot.win ? 1 : 1 - slot.index * 0.15
                            border { color: Theme.stroke; width: slot.index === 0 ? 1 : 0 }
                        }
                        Rectangle {   // open-app mark
                            visible: (dm.look.indicator ?? "dot") !== "none" && (slot.index === 1 || slot.index === 3 || slot.win)
                            readonly property bool line: dm.look.indicator === "line"
                            readonly property bool on: slot.index === 5
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                            width: line ? (on ? 7 : 4) * dm.s : 1.6 * dm.s
                            height: line ? 1.3 * dm.s : 1.6 * dm.s
                            radius: height / 2
                            color: on ? Theme.accent : Theme.text
                        }
                    }
                }
            }
        }
    }

    // A small desktop with Spotlight open in the given look: the search field, the round mode
    // buttons (split) and a few results, one of them selected
    component LauncherMock: Item {
        id: lm
        property var look: ({})
        readonly property real s: width / 240
        readonly property bool unified: look.style === "unified"
        readonly property real w: (look.width ?? 720) / 960 * 200 * s
        readonly property real fh: (look.field ?? 48) * 0.3 * s
        readonly property real r: look.corners === "round" ? 9 * s : look.corners === "sharp" ? 2.5 * s : 5 * s
        readonly property color tone: look.tint === "solid" ? Theme.menu : look.tint === "accent"
            ? Qt.tint(Theme.tinted(0.75, 0.75), Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35))
            : Theme.light ? Qt.rgba(1, 1, 1, 0.7) : Theme.tinted(0.75, 0.72)
        readonly property real gap: unified ? 0 : 3 * s
        readonly property real listH: 4 * 9 * s + 6 * s

        Rectangle { anchors.fill: parent; color: "black"; opacity: lm.look.dim ?? 0 }
        Item {
            id: box
            x: (lm.width - lm.w) / 2
            y: lm.height * 0.16
            width: lm.w
            height: lm.fh + lm.gap + lm.listH
            Rectangle {   // unified card
                visible: lm.unified
                anchors.fill: parent
                radius: lm.r
                color: lm.tone
                border { color: Theme.stroke; width: 1 }
                Rectangle { y: lm.fh; width: parent.width; height: 1; color: Theme.stroke }
            }
            Rectangle {   // search field
                width: parent.width - (lm.unified ? 0 : buttons.width + 3 * lm.s)
                height: lm.fh
                radius: lm.look.corners === "round" ? height / 2 : lm.r
                color: lm.unified ? "transparent" : lm.tone
                border { color: Theme.stroke; width: lm.unified ? 0 : 1 }
                Rectangle { x: 6 * lm.s; anchors.verticalCenter: parent.verticalCenter; width: 4 * lm.s; height: width; radius: width / 2; color: "transparent"; border { color: Theme.subtext; width: 1 } }
                Rectangle { x: 14 * lm.s; anchors.verticalCenter: parent.verticalCenter; width: parent.width * 0.4; height: 2.5 * lm.s; radius: height / 2; color: Theme.muted }
            }
            Rectangle {   // mode buttons
                id: buttons
                anchors.right: parent.right
                width: 4 * 7 * lm.s + 4 * lm.s
                height: lm.fh
                radius: height / 2
                color: lm.unified ? "transparent" : lm.tone
                border { color: Theme.stroke; width: lm.unified ? 0 : 1 }
                Row {
                    anchors.centerIn: parent
                    spacing: 2 * lm.s
                    Repeater { model: 4; Rectangle { width: 5 * lm.s; height: width; radius: width / 2; color: index === 0 ? Theme.accent : Theme.subtext; opacity: 0.8 } }
                }
            }
            Rectangle {   // results
                y: lm.fh + lm.gap
                width: parent.width
                height: lm.listH
                radius: lm.r
                color: lm.unified ? "transparent" : lm.tone
                border { color: Theme.stroke; width: lm.unified ? 0 : 1 }
                Column {
                    anchors { fill: parent; margins: 3 * lm.s }
                    spacing: 0
                    Repeater {
                        model: 4
                        Rectangle {
                            width: parent.width; height: 9 * lm.s
                            radius: Math.min(lm.r, 3 * lm.s)
                            color: index === 0 ? (lm.look.selection === "accent" ? Theme.accentWash : Theme.fillActive) : "transparent"
                            Rectangle { x: 3 * lm.s; anchors.verticalCenter: parent.verticalCenter; width: 5 * lm.s; height: width; radius: 1.5 * lm.s; color: Theme.accent; opacity: 1 - index * 0.2 }
                            Rectangle { x: 11 * lm.s; anchors.verticalCenter: parent.verticalCenter; width: parent.width * (0.5 - index * 0.06); height: 2 * lm.s; radius: height / 2; color: Theme.text; opacity: 0.75 }
                        }
                    }
                }
            }
        }
    }
}
