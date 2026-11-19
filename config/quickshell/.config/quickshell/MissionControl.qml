pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Mission Control (Super+W, Spotlight "Mission Control", `qs ipc call overview toggle`): on the
// focused screen, the windows of the current desktop spread out with live previews, and every
// desktop of this screen in a strip along the top.
//   Click a window to go to it · drag it onto a desktop to move it there (drop on + for a new one)
//   · click a desktop (or press 1-9) to switch · arrows/Tab + Enter pick a window · Esc closes.
//   A click on empty space does nothing: it stays open until you pick something or press Esc.
// Minimised windows (special:minimized) stay in the dock and aren't shown here.
// Opening freezes a copy of the screen and blurs it behind everything (works in every theme, even
// those with Hyprland's blur off); the windows then lift off their real places into the grid, and
// fly back on close, so the overview always reads as the same desktop seen from further away.
Singleton {
    id: root

    property bool open: false
    property var mon: null           // { name, id, x, y, w, h, ws }
    readonly property var mc: Config.missionControl
    property var clients: []         // hyprctl clients on the normal workspaces of every screen
    property var groups: []          // { name, here, spaces }: one per screen shown, left to right
    property var spaces: []          // { id, x, y, w, h }: every workspace shown, with its screen's place and size
    property int nextSpace: 1        // lowest workspace id no screen is using
    property int viewing: 0          // the workspace whose windows are laid out (browse: the one picked above)
    property int selected: -1
    property var dragging: null      // client being dragged
    property string wallpaper: ""    // shown behind the desktop thumbnails
    property bool snapping: false    // the overlay is up but see-through, taking the screen copy
    // 0 = the desktop as it is, 1 = the overview: drives the blur, the dim, the windows' flight
    // from their real places and the desktop strip's drop-in, so all of it moves as one
    property real t: open ? 1 : 0
    Behavior on t { NumberAnimation { duration: root.open ? Theme.enter + Theme.exit : Theme.enter
                                      easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
    readonly property bool flies: Theme.travel > 0   // themes with no travel (and reduced motion) only fade

    // most recently used first, like macOS
    readonly property var current: clients.filter(c => c.workspace.id === viewing).sort((a, b) => a.focusHistoryID - b.focusHistoryID)

    function toggle() { if (open) hide(); else show() }
    function show() { reader.running = true }
    function hide() { open = false; snapping = false; dragging = null }
    function dispatch(lua) { Quickshell.execDetached(["hyprctl", "dispatch", lua]) }
    function toplevel(c) { return Hyprland.toplevels.values.find(t => "0x" + t.address === c.address)?.wayland ?? null }
    function focusWindow(c) { hide(); dispatch(`hl.dsp.focus({ window = "address:${c.address}" })`) }
    // after the overlay lets go of the keyboard: Hyprland then refocuses the last window, which would
    // pull an empty desktop's switch straight back to that window's desktop
    function goTo(id) { hide(); switchTo.space = id; switchTo.restart() }
    // a workspace clicked above: go there, or (Settings > Mission Control > Click) show its windows first
    function pick(id) {
        if (mc.click !== "browse" || id === viewing) { goTo(id); return }
        viewing = id
        selected = 0
    }
    function moveTo(c, id) {
        if (c.workspace.id === id) return
        dispatch(`hl.dsp.window.move({ workspace = ${id}, follow = false, window = "address:${c.address}" })`)
        reread.restart()
    }

    // Window boxes for the current desktop: one shared scale (so sizes stay comparable) in the
    // grid that allows the largest one; the last row is centred.
    function layout(list, W, H) {
        const n = list.length, gap = 40, label = 34
        if (n === 0) return []
        let best = null
        for (let cols = 1; cols <= n; cols++) {
            const rows = Math.ceil(n / cols), cw = W / cols, ch = H / rows
            let s = 0.7
            for (const c of list) s = Math.min(s, (cw - gap) / c.size[0], (ch - gap - label) / c.size[1])
            if (!best || s > best.s) best = { cols: cols, rows: rows, s: s, cw: cw, ch: ch }
        }
        return list.map((c, i) => {
            const row = Math.floor(i / best.cols), col = i % best.cols
            const inRow = row === best.rows - 1 ? n - row * best.cols : best.cols
            const w = c.size[0] * best.s, h = c.size[1] * best.s
            return { client: c, w: w, h: h,
                     x: (W - inRow * best.cw) / 2 + col * best.cw + (best.cw - w) / 2,
                     y: (H - best.rows * best.ch) / 2 + row * best.ch + (best.ch - h - label) / 2 }
        })
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.toggle() }
    }

    Timer { id: switchTo; property int space; interval: 120; onTriggered: root.dispatch(`hl.dsp.focus({ workspace = ${space} })`) }
    Timer { id: reread; interval: 150; onTriggered: reader.running = true }
    // never wait on the screen copy for long: open over a plain dim if it doesn't come
    Timer { id: snapGuard; interval: 250; onTriggered: if (root.snapping) { root.snapping = false; root.open = true } }

    Process {
        id: reader
        command: ["sh", "-c", "readlink -f \"$HOME/.config/hypr/settings/wallpaper\"; printf '{\"m\":%s,\"c\":%s,\"w\":%s}' \"$(hyprctl -j monitors)\" \"$(hyprctl -j clients)\" \"$(hyprctl -j workspaces)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const nl = text.indexOf("\n")
                    root.wallpaper = text.slice(0, nl).trim()
                    const d = JSON.parse(text.slice(nl + 1))
                    const m = d.m.find(x => x.focused) ?? d.m[0]
                    const geo = x => { const r = x.transform % 2 === 1
                        return { x: x.x, y: x.y, w: (r ? x.height : x.width) / x.scale, h: (r ? x.width : x.height) / x.scale } }
                    root.mon = Object.assign({ name: m.name, id: m.id, ws: m.activeWorkspace.id }, geo(m))
                    root.clients = d.c.filter(c => c.workspace.id > 0 && c.mapped && !c.hidden)
                    root.viewing = m.activeWorkspace.id
                    // each screen's workspaces, drawn at its shape, screens left to right (or just this one)
                    const all = root.mc.screens !== "this"
                    root.groups = d.m.filter(x => x.id === m.id || all && Machine.realScreen(x.name))
                        .sort((a, b) => a.x - b.x || a.y - b.y).map(x => {
                            const g = geo(x)
                            const spaces = d.w.filter(w => w.id > 0 && w.monitorID === x.id).map(w => Object.assign({ id: w.id }, g))
                            if (x.id === m.id && !spaces.some(w => w.id === x.activeWorkspace.id)) spaces.push(Object.assign({ id: x.activeWorkspace.id }, g))
                            return { name: x.name.startsWith("eDP") ? "Built-in screen" : (x.model || x.description || x.name),
                                     here: x.id === m.id, spaces: spaces.sort((a, b) => a.id - b.id) }
                        }).filter(gr => gr.spaces.length)
                    root.spaces = root.groups.reduce((a, gr) => a.concat(gr.spaces), [])
                    const used = new Set(d.w.map(w => w.id))
                    let n = 1; while (used.has(n)) n++
                    root.nextSpace = n
                    root.selected = root.current.length > 1 ? 1 : 0   // the previous window, like Alt+Tab
                    if (desk.hasContent) root.open = true   // reopened mid-close: the copy is still good
                    else { root.snapping = true; snapGuard.restart() }
                } catch (e) { console.warn("overview:", e) }
            }
        }
    }

    PanelWindow {
        id: win
        screen: Quickshell.screens.find(s => s.name === root.mon?.name) ?? Quickshell.screens[0]
        visible: root.open || root.snapping || root.t > 0
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-overview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onVisibleChanged: if (visible) stage.forceActiveFocus()

        Item {
            id: stage
            anchors.fill: parent
            // in: at once (the first frame is the screen copy, unblurred: nothing changes yet); out:
            // a fade back to the real desktop that lags the windows' flight home (sqrt holds it up),
            // so they're seen landing before it goes
            opacity: root.open ? 1 : Math.sqrt(root.t)
            focus: root.open

            Keys.onPressed: event => {
                const n = root.current.length
                if (event.key === Qt.Key_Escape) root.hide()
                else if ((event.key === Qt.Key_Right || event.key === Qt.Key_Tab || event.key === Qt.Key_Down) && n) root.selected = (root.selected + 1) % n
                else if ((event.key === Qt.Key_Left || event.key === Qt.Key_Backtab || event.key === Qt.Key_Up) && n) root.selected = (root.selected - 1 + n) % n
                else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.current[root.selected]) root.focusWindow(root.current[root.selected])
                else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) root.goTo(event.key - Qt.Key_0)
                else return
                event.accepted = true
            }

            // the screen as it was a moment before opening, frozen, blurred and dimmed with t
            ScreencopyView {
                id: desk
                anchors.fill: parent
                captureSource: win.visible ? win.screen : null   // dropped on close, so each opening copies anew
                live: false
                visible: false
                onHasContentChanged: if (hasContent && root.snapping) { root.snapping = false; root.open = true }
            }
            MultiEffect {
                anchors.fill: parent
                source: desk
                visible: desk.hasContent
                autoPaddingEnabled: false
                blurEnabled: true
                blurMax: 64
                blurMultiplier: 1.5   // past blurMax: no shapes left to read, only colour and light
                blur: root.t
                saturation: 0.15 * root.t   // a little richer, as frosted glass reads
            }
            Rectangle { anchors.fill: parent; color: Theme.backdrop; opacity: root.t }
            // a click on empty space closes, like every other sheet (a window or a desktop closes it too)
            MouseArea { anchors.fill: parent; Accessible.ignored: true; onClicked: root.hide() }

            // ---- workspaces: a row along the top, one group per screen (Settings > Mission Control) ----
            Row {
                id: strip
                readonly property real groupGap: Theme.spaceXl * 2
                // the size picked in Settings, smaller when that many don't fit across the screen
                readonly property real thumbH: Math.min(({ small: 80, medium: 112, large: 148 })[root.mc.size] ?? 112,
                    (win.width - 160 - Theme.spaceL * root.spaces.length - groupGap * (root.groups.length - 1)) /
                    (root.spaces.reduce((a, s) => a + s.w / s.h, 0) + (root.mc.newTile ? (root.mon?.w ?? 16) / (root.mon?.h ?? 10) : 0)))
                anchors { top: parent.top; topMargin: Theme.spaceXl + Theme.spaceS - (root.flies ? (1 - root.t) * (height + Theme.spaceXl) : 0)
                          horizontalCenter: parent.horizontalCenter }
                opacity: root.t
                spacing: groupGap

                Repeater {
                    model: root.groups
                    Column {
                        id: group
                        required property var modelData
                        required property int index
                        spacing: Theme.spaceS

                        Text {   // the screen's name, once there is more than one
                            visible: root.groups.length > 1
                            text: group.modelData.name
                            color: group.modelData.here ? Theme.text : Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold; capitalization: Font.AllUppercase; letterSpacing: 0.6 }
                        }
                        Row {
                            spacing: Theme.spaceL
                            Rectangle {   // a hairline between screens
                                visible: group.index > 0
                                x: -strip.groupGap / 2
                                width: 1; height: strip.thumbH
                                color: Theme.stroke
                            }

                            Repeater {
                                model: group.modelData.spaces
                                Column {
                                    id: space
                                    required property var modelData
                                    readonly property int num: modelData.id
                                    readonly property real s: strip.thumbH / modelData.h
                                    readonly property bool shown: num === root.viewing
                                    readonly property bool hot: spaceArea.containsMouse || drop.containsDrag
                                    spacing: Theme.spaceS

                                    Item {
                                        width: space.modelData.w * space.s
                                        height: strip.thumbH
                                        scale: spaceArea.pressed ? 0.97 : space.hot ? 1.04 : 1
                                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

                                        Rectangle {   // ring outside a small gap: accent on the workspace shown below and under a dragged window
                                            anchors { fill: parent; margins: -4 }
                                            radius: Theme.radius + 4
                                            color: "transparent"
                                            border { width: 2; color: space.shown || drop.containsDrag ? Theme.accent : Theme.strokeStrong }
                                            opacity: space.shown || space.hot ? 1 : 0
                                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                        }
                                        ClippingRectangle {
                                            anchors.fill: parent
                                            radius: Theme.radius
                                            color: Theme.glassStrong
                                            Image {
                                                anchors.fill: parent
                                                source: root.wallpaper ? "file://" + root.wallpaper : ""
                                                sourceSize.width: 400
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                            }
                                            Repeater {
                                                model: root.clients.filter(c => c.workspace.num === space.num)
                                                ScreencopyView {
                                                    required property var modelData
                                                    x: (modelData.at[0] - space.modelData.x) * space.s
                                                    y: (modelData.at[1] - space.modelData.y) * space.s
                                                    width: modelData.size[0] * space.s
                                                    height: modelData.size[1] * space.s
                                                    captureSource: win.visible ? root.toplevel(modelData) : null
                                                    live: false
                                                }
                                            }
                                        }
                                        Rectangle { anchors.fill: parent; radius: Theme.radius; color: "transparent"; border { width: 1; color: Theme.stroke } }
                                        MouseArea { id: spaceArea; Accessible.role: Accessible.Button; Accessible.name: "Workspace " + space.num; Accessible.onPressAction: root.pick(space.num); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.pick(space.num) }
                                        DropArea { id: drop; anchors.fill: parent; onDropped: if (root.dragging) root.moveTo(root.dragging, space.num) }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Workspace " + space.num
                                        color: space.shown ? Theme.text : Theme.subtext
                                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: space.shown ? Font.DemiBold : Font.Medium }
                                    }
                                }
                            }

                            // the empty workspace at the end of this screen's row: a click opens it and goes there,
                            // a dropped window moves to it
                            Column {
                                visible: group.modelData.here && root.mc.newTile
                                spacing: Theme.spaceS
                                Item {
                                    id: add
                                    readonly property bool hot: addArea.containsMouse || addDrop.containsDrag
                                    width: (root.mon?.w ?? 16) / (root.mon?.h ?? 10) * strip.thumbH
                                    height: strip.thumbH
                                    scale: addArea.pressed ? 0.97 : add.hot ? 1.04 : 1
                                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

                                    Rectangle {
                                        anchors { fill: parent; margins: -4 }
                                        radius: Theme.radius + 4
                                        color: "transparent"
                                        border { width: 2; color: addDrop.containsDrag ? Theme.accent : Theme.strokeStrong }
                                        opacity: add.hot ? 1 : 0
                                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                    }
                                    ClippingRectangle {   // the bare wallpaper, dimmed: an empty workspace waiting
                                        anchors.fill: parent
                                        radius: Theme.radius
                                        color: Theme.glassStrong
                                        Image {
                                            anchors.fill: parent
                                            source: root.wallpaper ? "file://" + root.wallpaper : ""
                                            sourceSize.width: 400
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            opacity: add.hot ? 0.6 : 0.3
                                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                        }
                                    }
                                    Rectangle { anchors.fill: parent; radius: Theme.radius; color: "transparent"; border { width: 1; color: Theme.stroke } }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 40; height: 40; radius: 20
                                        color: add.hot ? Theme.fillActive : Theme.glass
                                        border { width: 1; color: Theme.strokeStrong }
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                        Text { anchors.centerIn: parent; text: "\u{F0415}"; color: Theme.text; font { family: Theme.iconFont; pixelSize: Theme.glyphL } }
                                    }
                                    MouseArea { id: addArea; Accessible.role: Accessible.Button; Accessible.name: "New workspace"; Accessible.onPressAction: root.goTo(root.nextSpace); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goTo(root.nextSpace) }
                                    DropArea { id: addDrop; anchors.fill: parent; onDropped: if (root.dragging) root.moveTo(root.dragging, root.nextSpace) }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "New workspace"
                                    color: Theme.subtext
                                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium }
                                }
                            }
                        }
                    }
                }
            }

            // ---- windows of this desktop ----
            Item {
                id: field
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom
                          leftMargin: 72; rightMargin: 72; topMargin: 200; bottomMargin: 110 }   // under the desktops, clear of the dock

                // an empty desktop: a quiet card, readable over any wallpaper, rising in with the rest
                Glass {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: root.flies ? (1 - root.t) * Theme.travel * 2 : 0
                    visible: root.current.length === 0
                    opacity: root.t
                    strong: true
                    radius: Theme.radiusLarge
                    width: empty.implicitWidth + Theme.spaceL * 2
                    height: empty.implicitHeight + Theme.spaceL * 2
                    Accessible.role: Accessible.StaticText
                    Accessible.name: "No windows on this workspace"
                    Column {
                        id: empty
                        anchors.centerIn: parent
                        spacing: Theme.spaceS
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\u{F0570}"
                            color: Theme.subtext
                            font { family: Theme.iconFont; pixelSize: Theme.iconLarge }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No windows on this workspace"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Pick another workspace above, or press 1–9"
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontLabel }
                        }
                    }
                }

                Repeater {
                    model: win.visible ? root.layout(root.current, field.width, field.height) : []
                    Item {
                        id: slot
                        required property var modelData
                        required property int index
                        readonly property bool lit: (area.containsMouse || root.selected === index) && !area.drag.active && root.t === 1   // rings and labels wait for the windows to land
                        readonly property var entry: DesktopEntries.heuristicLookup(modelData.client.class)
                        // f: 0 where the window really is on screen, 1 in its place in the grid
                        readonly property real f: root.flies ? root.t : 1
                        readonly property var c: modelData.client
                        x: (c.at[0] - (root.mon?.x ?? 0) - field.x) * (1 - f) + modelData.x * f
                        y: (c.at[1] - (root.mon?.y ?? 0) - field.y) * (1 - f) + modelData.y * f
                        width: modelData.w; height: modelData.h
                        transformOrigin: Item.TopLeft
                        scale: c.size[0] / modelData.w * (1 - f) + f
                        z: area.drag.active ? 10 : root.selected === index ? 1 : 0

                        // selection ring in the theme's selection colour, lifted with the window (kept
                        // outside the tile: its shadow layer would clip anything past its edges)
                        Rectangle {
                            x: tile.x - 4; y: tile.y - 4
                            width: tile.width + 8; height: tile.height + 8
                            scale: tile.scale
                            radius: Theme.radius + 4
                            color: "transparent"
                            border { width: 3; color: Theme.selected }
                            opacity: slot.lit ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        }

                        Item {
                            id: tile
                            width: slot.width; height: slot.height
                            // hover lifts it a touch; a drag shrinks it to about a desktop thumbnail
                            scale: area.drag.active ? 0.3 : area.containsMouse && root.t === 1 ? 1.025 : 1
                            opacity: area.drag.active ? 0.85 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            // a drop that missed glides back into place instead of jumping
                            Behavior on x { enabled: !area.drag.active; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                            Behavior on y { enabled: !area.drag.active; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                            Drag.active: area.drag.active
                            Drag.hotSpot { x: width / 2; y: height / 2 }
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: Theme.shadow
                                shadowBlur: 1.0
                                shadowVerticalOffset: 10
                            }

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: Theme.radius
                                color: Theme.glassStrong
                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: win.visible ? root.toplevel(slot.modelData.client) : null
                                    live: true
                                }
                            }
                            Rectangle {   // a hairline edge, so a dark window still separates from a dark desktop
                                anchors.fill: parent
                                radius: Theme.radius
                                color: "transparent"
                                border { width: 1; color: Theme.strokeStrong }
                            }
                            MouseArea {
                                id: area
                                Accessible.role: Accessible.Button
                                Accessible.name: slot.entry?.name ?? slot.modelData.client.title
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                drag.target: tile
                                drag.threshold: 12
                                onEntered: root.selected = slot.index
                                onPressed: root.dragging = slot.modelData.client
                                onReleased: {
                                    // dropped on a desktop: gone from here until the list is read again
                                    if (drag.active) { if (tile.Drag.drop() !== Qt.IgnoreAction) tile.visible = false }
                                    else root.focusWindow(slot.modelData.client)
                                    tile.x = 0; tile.y = 0
                                }
                            }
                        }

                        // app icon and title under the window, for the one under the pointer or keys
                        Glass {
                            anchors { top: tile.bottom; topMargin: Theme.spaceM; horizontalCenter: tile.horizontalCenter }
                            width: label.implicitWidth + Theme.spaceM * 2
                            height: 30
                            radius: Theme.radiusSmall
                            strong: true
                            opacity: slot.lit && !area.drag.active ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            Row {
                                id: label
                                anchors.centerIn: parent
                                spacing: Theme.spaceS
                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    implicitSize: 18
                                    source: Quickshell.iconPath(slot.entry?.icon ?? "", "application-x-executable")
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.min(implicitWidth, Math.max(slot.width, 260) - 60)
                                    text: slot.entry?.name ? `${slot.entry.name} — ${slot.modelData.client.title}` : slot.modelData.client.title || slot.modelData.client.class
                                    elide: Text.ElideRight
                                    color: Theme.text
                                    font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // a click on another screen closes it too
    HyprlandFocusGrab {
        windows: [win]
        active: root.open
        onCleared: root.hide()
    }
}
