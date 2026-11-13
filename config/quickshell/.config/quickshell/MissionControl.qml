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
    property var clients: []         // hyprctl clients on this screen's normal desktops
    property var spaces: []          // desktop ids on this screen
    property int nextSpace: 1        // lowest desktop id no screen is using
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
    readonly property var current: clients.filter(c => c.workspace.id === mon?.ws).sort((a, b) => a.focusHistoryID - b.focusHistoryID)

    function toggle() { if (open) hide(); else show() }
    function show() { reader.running = true }
    function hide() { open = false; snapping = false; dragging = null }
    function dispatch(lua) { Quickshell.execDetached(["hyprctl", "dispatch", lua]) }
    function toplevel(c) { return Hyprland.toplevels.values.find(t => "0x" + t.address === c.address)?.wayland ?? null }
    function focusWindow(c) { hide(); dispatch(`hl.dsp.focus({ window = "address:${c.address}" })`) }
    function goTo(id) { hide(); dispatch(`hl.dsp.focus({ workspace = ${id} })`) }
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
                    const rotated = m.transform % 2 === 1
                    root.mon = { name: m.name, id: m.id, x: m.x, y: m.y, ws: m.activeWorkspace.id,
                                 w: (rotated ? m.height : m.width) / m.scale, h: (rotated ? m.width : m.height) / m.scale }
                    root.clients = d.c.filter(c => c.monitor === m.id && c.workspace.id > 0 && c.mapped && !c.hidden)
                    const ids = new Set(d.w.filter(w => w.monitorID === m.id && w.id > 0).map(w => w.id))
                    ids.add(m.activeWorkspace.id)
                    root.spaces = [...ids].sort((a, b) => a - b)
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
            // empty space does nothing on its own: Esc, a window or a desktop are what close this
            MouseArea { anchors.fill: parent; Accessible.ignored: true }

            // ---- desktops: a glass bar along the top ----
            Glass {
                // drops in from above the screen's edge as the windows lift off
                anchors { top: parent.top; topMargin: Theme.spaceL - (root.flies ? (1 - root.t) * (height + Theme.spaceL) : 0)
                          horizontalCenter: parent.horizontalCenter }
                opacity: root.t
                width: strip.implicitWidth + Theme.spaceL * 2
                height: strip.implicitHeight + Theme.spaceM * 2
                radius: Theme.radiusLarge
                MouseArea { anchors.fill: parent }   // clicks between the desktops don't close

                Row {
                    id: strip
                    readonly property real thumbH: 84
                    readonly property real s: thumbH / (root.mon?.h ?? 1)
                    anchors.centerIn: parent
                    spacing: Theme.spaceL

                    Repeater {
                        model: root.spaces
                        Column {
                            id: space
                            required property int modelData
                            readonly property bool here: modelData === root.mon?.ws
                            readonly property bool hot: spaceArea.containsMouse || drop.containsDrag
                            spacing: Theme.spaceXs + 2

                            Item {
                                width: (root.mon?.w ?? 16) * strip.s
                                height: strip.thumbH
                                scale: space.hot ? 1.05 : 1
                                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: Theme.radiusSmall
                                    color: Theme.glassStrong
                                    Image {
                                        anchors.fill: parent
                                        source: root.wallpaper ? "file://" + root.wallpaper : ""
                                        sourceSize.width: 400
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                    }
                                    Repeater {
                                        model: root.clients.filter(c => c.workspace.id === space.modelData)
                                        ScreencopyView {
                                            required property var modelData
                                            x: (modelData.at[0] - root.mon.x) * strip.s
                                            y: (modelData.at[1] - root.mon.y) * strip.s
                                            width: modelData.size[0] * strip.s
                                            height: modelData.size[1] * strip.s
                                            captureSource: win.visible ? root.toplevel(modelData) : null
                                            live: false
                                        }
                                    }
                                }
                                Rectangle {   // ring: white for this desktop, accent while a window hovers over it
                                    anchors { fill: parent; margins: -3 }
                                    radius: Theme.radiusSmall + 3
                                    color: "transparent"
                                    border { width: 2; color: drop.containsDrag ? Theme.accent : space.here ? Theme.text : Theme.strokeStrong }
                                    opacity: space.here || space.hot ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                }
                                MouseArea { id: spaceArea; Accessible.role: Accessible.Button; Accessible.name: "Desktop " + space.modelData; Accessible.onPressAction: root.goTo(space.modelData); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goTo(space.modelData) }
                                DropArea { id: drop; anchors.fill: parent; onDropped: if (root.dragging) root.moveTo(root.dragging, space.modelData) }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Desktop " + space.modelData
                                color: space.here ? Theme.text : Theme.subtext
                                font { family: Theme.font; pixelSize: Theme.fontCaption; weight: space.here ? Font.DemiBold : Font.Medium }
                            }
                        }
                    }

                    // new empty desktop; drop a window here to give it one of its own
                    Column {
                        spacing: Theme.spaceXs + 2
                        Rectangle {
                            width: strip.thumbH * 0.75; height: strip.thumbH
                            radius: Theme.radiusSmall
                            color: addArea.containsMouse || addDrop.containsDrag ? Theme.fillActive : Theme.fill
                            border { color: addDrop.containsDrag ? Theme.accent : Theme.stroke; width: addDrop.containsDrag ? 2 : 1 }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Text { anchors.centerIn: parent; text: "\u{F0415}"; color: Theme.text; font { family: Theme.iconFont; pixelSize: 22 } }
                            MouseArea { id: addArea; Accessible.role: Accessible.Button; Accessible.name: "New desktop"; Accessible.onPressAction: root.goTo(root.nextSpace); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.goTo(root.nextSpace) }
                            DropArea { id: addDrop; anchors.fill: parent; onDropped: if (root.dragging) root.moveTo(root.dragging, root.nextSpace) }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "New"
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium }
                        }
                    }
                }
            }

            // ---- windows of this desktop ----
            Item {
                id: field
                anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom
                          leftMargin: 72; rightMargin: 72; topMargin: 170; bottomMargin: 110 }   // under the desktops, clear of the dock

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
                    Accessible.name: "No windows on this desktop"
                    Column {
                        id: empty
                        anchors.centerIn: parent
                        spacing: Theme.spaceS
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\u{F0570}"
                            color: Theme.subtext
                            font { family: Theme.iconFont; pixelSize: 32 }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No windows on this desktop"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Pick another desktop above, or press 1–9"
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
}
