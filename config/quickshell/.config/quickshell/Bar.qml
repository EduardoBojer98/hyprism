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
    // by name, re-read when monitors change: after a display switch Hyprland makes new monitor objects and monitorFor() stays stale
    readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screen?.name) ?? null
    readonly property var st: Theme.barStyle
    readonly property var layout: Theme.barLayoutFor(screen?.name ?? "")   // this screen's items (a preset or the theme's)
    readonly property string edge: Theme.barEdge
    readonly property bool vertical: Theme.barVertical
    readonly property int size: Theme.barSize
    readonly property int margin: Theme.barMargin
    readonly property bool floating: Theme.barFloating
    readonly property bool segmented: st.segmented && !vertical || st.segmented && floating
    // the bar's ground and the ink on it
    readonly property color ground: ({ glass: Theme.glassStrong, surface: Theme.surfaceColor, ground: Theme.base, ink: Theme.text, none: "transparent" })[st.fill] ?? Theme.surfaceColor
    readonly property color ink: Theme.barInk
    // Settings > Menu Bar > See-through: never | always | notMaximised (until a maximised or fullscreen window
    // covers this screen's workspace) | maximised (only then). Clear drops the ground, edge line and shadow;
    // "fade" leaves a soft shade from the screen edge, and items get a halo so they read over any wallpaper.
    readonly property var ws: monitor?.activeWorkspace ?? null
    readonly property bool covered: ws !== null && (ws.hasFullscreen || ws.toplevels.values.some(t => t.wayland?.maximized ?? false))
    readonly property bool clear: ({ always: true, notMaximised: !covered, maximised: covered })[Config.bar.transparent] ?? false
    readonly property bool fade: clear && Config.bar.clearStyle === "fade"
    property real solid: clear ? 0 : 1   // the ground's share, eased between clear and solid
    Behavior on solid { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    // a floating strip is rounded like the theme's panels (never more than a capsule)
    readonly property real corner: floating || segmented ? Math.min(Theme.radiusLarge, size / 2) : 0
    // items in the mono face for word voices (Monolith, Console)
    readonly property string family: st.mono ? Theme.monoFont : Theme.font

    function menuRows() {
        const act = id => Actions.all.find(a => a.id === id)
        const quick = ["overview", "shot", "keys", "dnd", "caffeine"].map(act).filter(a => a && Actions.available(a)).map(a => ({
            label: a.name, glyph: a.icon, checked: Actions.isOn(a), run: () => Actions.run(a.id) }))
        const mine = Actions.forSurface("barmenu").filter(a => !Actions.builtinIds.includes(a.id)).map(a => ({
            label: a.name, glyph: a.icon ?? "", checked: Actions.isOn(a), run: () => Actions.run(a.id) }))
        const set = (k, v) => () => Config.set(...k, v)
        const settings = [
            { label: "Show seconds", glyph: "\u{F0954}", checked: Config.bar.seconds, run: set(["bar", "seconds"], !Config.bar.seconds) },
            Theme.dockInBar ? null : { label: "Hide the dock automatically", glyph: "\u{F0A1F}", checked: Config.dock.autoHide, run: set(["dock", "autoHide"], !Config.dock.autoHide) },
            { label: "Edit the menu bar…", glyph: "\u{F0E7F}", run: () => SettingsApp.show("bar") },
            { label: "Dock settings…", glyph: "\u{F0A1F}", run: () => SettingsApp.show("dock") },
            { label: "Wallpaper & style…", glyph: "\u{F03D8}", run: () => SettingsApp.show("appearance") },
            { label: "Add your own to this menu…", glyph: "\u{F0415}", run: () => SettingsApp.show("actions") }
        ].filter(x => x)
        if (mine.length) mine[0].sep = true
        settings[0].sep = true
        return quick.concat(mine, settings)
    }

    PanelWindow {
        id: win
        screen: root.screen
        visible: Theme.barShownOn(root.screen)
        WlrLayershell.namespace: "qs-bar"
        // Super+F6 (qs ipc call bar focus): this bar takes the keyboard until Escape or an activation
        readonly property bool hasKeys: BarFocus.active && BarFocus.screen?.name === root.screen?.name
        WlrLayershell.keyboardFocus: hasKeys ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onHasKeysChanged: if (hasKeys) Qt.callLater(() => { const f = body.nextItemInFocusChain(true); if (f && f !== body) f.forceActiveFocus() })
        color: "transparent"
        anchors { top: root.edge !== "bottom"; bottom: root.edge !== "top"; left: root.edge !== "right"; right: root.edge !== "left" }
        exclusiveZone: Theme.barHeight
        implicitHeight: root.vertical ? 0 : Theme.barHeight
        implicitWidth: root.vertical ? Theme.barHeight : 0

        // see-through "fade": the ground as a shade that thins out away from the screen edge
        Rectangle {
            anchors.fill: parent
            visible: root.st.fill !== "none" && opacity > 0
            opacity: root.fade ? 1 - root.solid : 0
            gradient: Gradient {
                orientation: root.vertical ? Gradient.Horizontal : Gradient.Vertical
                GradientStop { position: 0; color: Qt.alpha(root.ground, root.edge === "top" || root.edge === "left" ? 0.55 : 0) }
                GradientStop { position: 1; color: Qt.alpha(root.ground, root.edge === "top" || root.edge === "left" ? 0 : 0.55) }
            }
        }
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
                opacity: root.solid
                anchors.fill: parent
                offset.y: 4; blur: 18; spread: -2
                radius: root.corner
                color: Theme.shadow
            }
            // one ground for the whole strip (segmented themes give each section its own instead)
            Glass {
                anchors.fill: parent
                visible: !root.segmented && root.st.fill !== "none" && root.solid > 0
                opacity: root.solid
                radius: root.corner
                color: root.ground
                border.width: root.floating ? Theme.line : 0
            }
            Rectangle {   // the edge line between an attached bar and the desktop
                visible: !root.segmented && !root.floating && root.st.line > 0
                opacity: root.solid
                color: Theme.stroke
                x: root.edge === "left" ? parent.width - width : 0
                y: root.edge === "top" ? parent.height - height : 0
                width: root.vertical ? root.st.line : parent.width
                height: root.vertical ? parent.height : root.st.line
            }

            // right-click on empty bar: a few quick things, your own actions (Settings > Actions > "Menu bar
            // right-click"), then the settings for what you're looking at; the items above take their own clicks
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                Accessible.role: Accessible.Button
                Accessible.name: "Menu bar options"
                Accessible.onPressAction: { barMenu.at = null; Actions.refreshVisible("barmenu"); barMenu.rows = root.menuRows(); barMenu.open = true }
                onClicked: mouse => { barMenu.at = { x: mouse.x, y: mouse.y }; Actions.refreshVisible("barmenu"); barMenu.rows = root.menuRows(); barMenu.open = true }
            }
            ShellMenu { id: barMenu; anchorItem: body }
            // your own toggles' state arrives a moment after the menu opens: rebuild the rows then, only while open
            Connections { target: Actions; enabled: barMenu.open; function onStatesChanged() { barMenu.rows = root.menuRows() } }

            // blocks and a block clock run flush to the screen's edges, like tmux's status line; a floating bar has
            // rounded ends instead, so they keep the usual inset (flush, the end items sat on the corner)
            readonly property int pad: root.segmented ? 0 : root.vertical ? 10 : (!root.floating && (root.st.ws === "blocks" || ["block", "split"].includes(root.st.clock)) ? 0 : 12)
            readonly property real length: (root.vertical ? height : width) - pad * 2 - 12
            // too many items: the end (status, clock) keeps its room, the start gets the rest, the middle
            // what's between them; whatever doesn't fit is cut off rather than drawn over a neighbour
            readonly property real endLength: Math.min(root.vertical ? endSection.implicitHeight : endSection.implicitWidth, length)
            Section {
                id: startSection
                ids: root.layout.start
                room: body.length - body.endLength - 12
                x: root.vertical ? (parent.width - width) / 2 : body.pad
                y: root.vertical ? body.pad + 6 : (parent.height - height) / 2
            }
            Section {
                id: endSection
                ids: root.layout.end
                room: body.length
                x: root.vertical ? (parent.width - width) / 2 : parent.width - width - body.pad
                y: root.vertical ? parent.height - height - body.pad - 6 : (parent.height - height) / 2
            }
            Section {   // centred, but never over the other two (with very many items it gives way)
                ids: root.layout.center
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

        // see-through: a halo in the ground's colour keeps the items legible over the wallpaper
        layer.enabled: root.clear && Config.bar.clearHalo && !section.empty
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.ground
            blurMax: 6          // a tight, dense halo: an outline more than a glow
            shadowBlur: 1
            shadowScale: 1.04
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }
        RectangularShadow {
            visible: section.pill && Theme.depth === "soft"
            opacity: root.solid
            anchors.fill: parent
            offset.y: 4; blur: 16; spread: -2
            radius: root.corner
            color: Theme.shadow
        }
        Glass {
            anchors.fill: parent
            visible: section.pill && root.solid > 0
            opacity: root.solid
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
