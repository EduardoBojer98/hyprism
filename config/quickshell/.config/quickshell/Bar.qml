import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects

// The bar of one screen. One bar for every theme: the theme gives its look (Theme.barStyle: fill,
// edge line, voice, workspace and clock style, segmented pills) and its own item layout; Settings >
// Menu Bar can move it to any edge, resize it, float it, hide it per monitor and choose the items
// of each section (start, center, end). Items come from BarWidget.qml and work on every edge.
Scope {
    id: root
    required property ShellScreen screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var st: Theme.barStyle
    readonly property string edge: Theme.barEdge
    readonly property bool vertical: Theme.barVertical
    readonly property int size: Theme.barSize
    readonly property int margin: Theme.barMargin
    readonly property bool floating: Theme.barFloating
    readonly property bool segmented: st.segmented && !vertical || st.segmented && floating
    // the bar's ground and the ink on it
    readonly property color ground: ({ glass: Theme.glassStrong, surface: Theme.surfaceColor, ground: Theme.base, ink: Theme.text, none: "transparent" })[st.fill] ?? Theme.surfaceColor
    readonly property color ink: Theme.barInk
    // a floating strip is rounded like the theme's panels (never more than a capsule)
    readonly property real corner: floating || segmented ? Math.min(Theme.radiusLarge, size / 2) : 0
    // items in the mono face for word voices (Monolith, Console)
    readonly property string family: st.mono ? Theme.monoFont : Theme.font

    PanelWindow {
        id: win
        screen: root.screen
        visible: Theme.barShownOn(root.screen)
        WlrLayershell.namespace: "qs-bar"
        color: "transparent"
        anchors { top: root.edge !== "bottom"; bottom: root.edge !== "top"; left: root.edge !== "right"; right: root.edge !== "left" }
        exclusiveZone: Theme.barHeight
        implicitHeight: root.vertical ? 0 : Theme.barHeight
        implicitWidth: root.vertical ? Theme.barHeight : 0

        // the bar itself: inset from the screen edge and along it when floating
        Item {
            id: body
            anchors {
                fill: parent
                topMargin: root.edge === "bottom" ? 0 : root.margin
                bottomMargin: root.edge === "top" ? 0 : root.margin
                leftMargin: root.edge === "right" ? 0 : root.margin
                rightMargin: root.edge === "left" ? 0 : root.margin
            }

            // the theme's depth under a floating strip (segmented pills carry their own)
            RectangularShadow {
                visible: Theme.depth === "soft" && root.floating && !root.segmented && root.st.fill !== "none"
                anchors.fill: parent
                offset.y: 4; blur: 18; spread: -2
                radius: root.corner
                color: Theme.shadow
            }
            // one ground for the whole strip (segmented themes give each section its own instead)
            Glass {
                anchors.fill: parent
                visible: !root.segmented && root.st.fill !== "none"
                radius: root.corner
                color: root.ground
                border.width: root.floating ? Theme.line : 0
            }
            Rectangle {   // the edge line between an attached bar and the desktop
                visible: !root.segmented && !root.floating && root.st.line > 0
                color: Theme.stroke
                x: root.edge === "left" ? parent.width - width : 0
                y: root.edge === "top" ? parent.height - height : 0
                width: root.vertical ? root.st.line : parent.width
                height: root.vertical ? parent.height : root.st.line
            }

            readonly property int pad: root.segmented ? 0 : root.vertical ? 10 : (root.st.ws === "blocks" ? 0 : 12)
            readonly property real length: (root.vertical ? height : width) - pad * 2 - 12
            // too many items: the end (status, clock) keeps its room, the start gets the rest, the middle
            // what's between them; whatever doesn't fit is cut off rather than drawn over a neighbour
            readonly property real endLength: Math.min(root.vertical ? endSection.implicitHeight : endSection.implicitWidth, length)
            Section {
                id: startSection
                ids: Theme.barLayout.start
                room: body.length - body.endLength - 12
                x: root.vertical ? (parent.width - width) / 2 : body.pad
                y: root.vertical ? body.pad + 6 : (parent.height - height) / 2
            }
            Section {
                id: endSection
                ids: Theme.barLayout.end
                room: body.length
                x: root.vertical ? (parent.width - width) / 2 : parent.width - width - body.pad
                y: root.vertical ? parent.height - height - body.pad - 6 : (parent.height - height) / 2
            }
            Section {   // centred, but never over the other two (with very many items it gives way)
                ids: Theme.barLayout.center
                readonly property real lo: root.vertical ? startSection.y + startSection.height + 12 : startSection.x + startSection.width + 12
                readonly property real hi: root.vertical ? endSection.y - 12 : endSection.x - 12
                readonly property real mid: ((root.vertical ? parent.height : parent.width) - (root.vertical ? height : width)) / 2
                readonly property real at: Math.max(lo, Math.min(mid, hi - (root.vertical ? height : width)))
                room: hi - lo
                x: root.vertical ? (parent.width - width) / 2 : at
                y: root.vertical ? at : (parent.height - height) / 2
            }
        }
    }

    // Console's corner brackets: decoration only, click-through, clear of the bar
    PanelWindow {
        screen: root.screen
        visible: root.st.decor === "brackets" && win.visible
        WlrLayershell.namespace: "qs-brackets"
        WlrLayershell.layer: WlrLayer.Bottom
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        mask: Region {}
        Repeater {
            model: [[0, 0], [1, 0], [0, 1], [1, 1]]
            Item {
                id: bracket
                required property var modelData
                readonly property int arm: 40
                x: modelData[0] ? parent.width - arm - 14 - Theme.reserveRight : 14 + Theme.reserveLeft
                y: modelData[1] ? parent.height - arm - 14 - Theme.reserveBottom : 14 + Theme.reserveTop
                width: arm; height: arm
                Rectangle { width: parent.width; height: 2; color: Theme.accent; y: bracket.modelData[1] ? parent.height - 2 : 0 }
                Rectangle { width: 2; height: parent.height; color: Theme.accent; x: bracket.modelData[0] ? parent.width - 2 : 0 }
            }
        }
    }

    // One section of items; in a segmented theme it is its own floating pill
    component Section: Item {
        id: section
        property var ids: []
        // an empty section (no items, or all of them have nothing to show) takes no room and no pill
        readonly property bool empty: grid.implicitWidth <= 0
        readonly property bool pill: root.segmented && !empty
        readonly property int inset: pill ? 10 : 0
        implicitWidth: empty ? 0 : root.vertical ? (pill ? root.size : grid.implicitWidth) : grid.implicitWidth + inset * 2
        implicitHeight: empty ? 0 : root.vertical ? grid.implicitHeight + inset * 2 : (pill ? root.size : grid.implicitHeight)
        property real room: 100000          // the most this section may take along the bar
        width: root.vertical ? implicitWidth : Math.max(0, Math.min(implicitWidth, room))
        height: root.vertical ? Math.max(0, Math.min(implicitHeight, room)) : implicitHeight
        clip: root.vertical ? implicitHeight > room : implicitWidth > room

        RectangularShadow {
            visible: section.pill && Theme.depth === "soft"
            anchors.fill: parent
            offset.y: 4; blur: 16; spread: -2
            radius: root.corner
            color: Theme.shadow
        }
        Glass {
            anchors.fill: parent
            visible: section.pill
            strong: true
            radius: root.corner
            color: root.ground
        }
        Grid {
            id: grid
            anchors.centerIn: parent
            // one row or one column: only `columns` is set (setting rows too adds spacing for empty rows)
            columns: root.vertical ? 1 : Math.max(1, visibleChildren.filter(c => c.width > 0).length)
            spacing: root.st.voice === "icons" ? (root.st.ws === "blocks" ? 12 : 10) : 16
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
            Repeater {
                id: list
                model: section.ids
                BarWidget {
                    required property string modelData
                    required property int index
                    // a thin rule before every item but the first (themes with sep: Monolith, Console)
                    separated: root.st.sep && index > 0
                    kind: modelData
                    monitor: root.monitor
                    vertical: root.vertical
                    tone: root.ink
                    dim: Theme.barDim
                    voice: root.st.voice
                    family: root.family
                    thickness: root.size
                }
            }
        }
    }
}
