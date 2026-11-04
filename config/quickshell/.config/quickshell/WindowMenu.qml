pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Window menu for the focused window, at the pointer: snap layouts (click a part of a picture to
// put the window there), move to another screen or desktop, floating, on every desktop,
// fullscreen and opacity. Opens from the "⋯" button on title bars (hypr/modules/plugins.lua),
// Super+Z, or `qs ipc call windowmenu open`.
Singleton {
    id: root

    property var win: ({})          // hyprctl -j activewindow
    property var monitors: []       // hyprctl -j monitors
    property var bars: ({ on: false, height: 0 })   // title_bar_info() from plugins.lua
    property real opacity: 1

    readonly property string addr: "address:" + (win.address ?? "")
    readonly property var monitor: monitors.find(m => m.id === win.monitor) ?? null

    // Pictures of a screen, each split into the parts a window can take: [x, y, w, h] fractions
    readonly property var layouts: [
        [[0, 0, 1/2, 1], [1/2, 0, 1/2, 1]],
        [[0, 0, 2/3, 1], [2/3, 0, 1/3, 1]],
        [[0, 0, 1/3, 1], [1/3, 0, 2/3, 1]],
        [[0, 0, 1/2, 1/2], [1/2, 0, 1/2, 1/2], [0, 1/2, 1/2, 1/2], [1/2, 1/2, 1/2, 1/2]],
        [[0, 0, 1/3, 1], [1/3, 0, 1/3, 1], [2/3, 0, 1/3, 1]],
        [[0, 0, 1, 1/2], [0, 1/2, 1, 1/2]],
    ]

    function show() { reader.running = true }
    IpcHandler {
        target: "windowmenu"
        function open(): void { root.show() }
    }

    // The window, the screens, whether bars are drawn and the window's opacity, in one call
    Process {
        id: reader
        command: ["sh", "-c", "w=$(hyprctl -j activewindow); a=$(printf '%s' \"$w\" | jq -r '.address // empty');"
            + " o=$(hyprctl getprop \"address:$a\" opacity 2>/dev/null);"
            + " printf '{\"win\":%s,\"monitors\":%s,\"bars\":%s,\"opacity\":\"%s\"}' \"$w\" \"$(hyprctl -j monitors)\" \"$(hyprctl repl 'return title_bar_info()')\" \"$o\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let d
                try { d = JSON.parse(text) } catch (e) { return }
                if (!d.win?.address) return   // nothing focused
                root.win = d.win
                root.monitors = d.monitors ?? []
                root.bars = d.bars ?? { on: false }
                const o = parseFloat(d.opacity)
                root.opacity = isNaN(o) ? 1 : Math.max(0.3, Math.min(1, o))
                popup.show()
            }
        }
    }

    // Run Hyprland dispatchers (Lua) on this window, one after another
    function run(list) {
        Quickshell.execDetached(["sh", "-c", list.map(l => "hyprctl dispatch '" + l.replace(/'/g, "") + "' >/dev/null").join("; ")])
    }
    function act(list) { popup.hide(); run(list) }

    // RE2's (?i) prefix -> a JS case-insensitive RegExp
    function re(s) { return s?.startsWith("(?i)") ? new RegExp(s.slice(4), "i") : new RegExp(s ?? "^$") }
    readonly property bool hasBar: bars.on === true && !re(bars.skipClass).test(win.class ?? "") && !re(bars.skipTitle).test(win.title ?? "")

    // Float the window into part [fx, fy, fw, fh] of its screen's free area, keeping the same gaps
    // as tiling (gaps_out outside, gaps_in on each side between windows) and room for its title bar
    function snap(p) {
        const m = monitor
        if (!m) return
        const rotated = m.transform % 2 === 1
        const W = (rotated ? m.height : m.width) / m.scale, H = (rotated ? m.width : m.height) / m.scale
        const [l, t, r, b] = m.reserved ?? [0, 0, 0, 0]
        const g = Theme.rice.hypr.gapsOut, gi = Theme.rice.hypr.gapsIn   // the rice's gaps (look.lua)
        const ax = m.x + l + g, ay = m.y + t + g, aw = W - l - r - 2 * g, ah = H - t - b - 2 * g
        const x0 = ax + p[0] * aw + (p[0] > 0 ? gi : 0), x1 = ax + (p[0] + p[2]) * aw - (p[0] + p[2] < 0.999 ? gi : 0)
        let y0 = ay + p[1] * ah + (p[1] > 0 ? gi : 0)
        const y1 = ay + (p[1] + p[3]) * ah - (p[1] + p[3] < 0.999 ? gi : 0)
        if (hasBar) y0 += bars.height ?? 28
        const steps = []
        if ((win.fullscreen ?? 0) > 0)   // out of maximised or fullscreen first
            steps.push(`hl.dsp.window.fullscreen({ action = "toggle", mode = "${win.fullscreen === 1 ? "maximized" : "fullscreen"}", window = "${addr}" })`)
        steps.push(`hl.dsp.window.float({ action = "enable", window = "${addr}" })`,
                   `hl.dsp.window.resize({ x = ${Math.round(x1 - x0)}, y = ${Math.round(y1 - y0)}, window = "${addr}" })`,
                   `hl.dsp.window.move({ x = ${Math.round(x0)}, y = ${Math.round(y0)}, window = "${addr}" })`)
        act(steps)
    }

    CursorPopup {
        id: popup
        name: "windowmenu"
        boxWidth: 340
        boxHeight: menu.implicitHeight + Theme.spaceM * 2

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge

            ColumnLayout {
                id: menu
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
                spacing: Theme.spaceS

                RowLayout {   // which window
                    Layout.fillWidth: true
                    spacing: Theme.spaceS
                    IconImage {
                        implicitSize: 22
                        source: Quickshell.iconPath(DesktopEntries.heuristicLookup(root.win.class ?? "")?.icon ?? "", "application-x-executable")
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.win.title ?? ""
                        elide: Text.ElideRight
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                    }
                }

                Label_ { text: "Snap" }
                Grid {   // snap layouts: hover a part, click to put the window there
                    Layout.fillWidth: true
                    columns: 3
                    spacing: Theme.spaceS
                    Repeater {
                        model: root.layouts
                        Rectangle {
                            id: shot
                            required property var modelData
                            width: (menu.width - 2 * Theme.spaceS) / 3
                            height: Math.round(width * 0.62)
                            radius: Theme.radiusSmall
                            color: Theme.fill
                            border { color: Theme.stroke; width: 1 }
                            Repeater {
                                model: shot.modelData
                                Rectangle {
                                    required property var modelData
                                    readonly property real inner: shot.width - 8
                                    readonly property real innerH: shot.height - 8
                                    x: 4 + modelData[0] * inner + 1.5; y: 4 + modelData[1] * innerH + 1.5
                                    width: modelData[2] * inner - 3; height: modelData[3] * innerH - 3
                                    radius: 3
                                    color: part.containsMouse ? Theme.accent : Theme.fillActive
                                    MouseArea { id: part; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.snap(parent.modelData) }
                                }
                            }
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceS
                    Pill_ { text: "Big, centred"; onClicked: root.snap([0.125, 0.08, 0.75, 0.84]) }
                    Pill_ {
                        text: (root.win.fullscreen ?? 0) === 1 ? "Restore" : "Maximise"
                        onClicked: root.act([`hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized", window = "${root.addr}" })`])
                    }
                    Pill_ {
                        text: (root.win.fullscreen ?? 0) === 2 ? "Leave fullscreen" : "Fullscreen"
                        onClicked: root.act([`hl.dsp.window.fullscreen({ action = "toggle", window = "${root.addr}" })`])
                    }
                }

                Label_ { visible: root.monitors.length > 1; text: "Move to screen" }
                Flow {
                    visible: root.monitors.length > 1
                    Layout.fillWidth: true
                    spacing: Theme.spaceXs + 2
                    Repeater {
                        model: root.monitors
                        Pill_ {
                            required property var modelData
                            text: modelData.name + (modelData.id === root.win.monitor ? " (here)" : "")
                            current: modelData.id === root.win.monitor
                            onClicked: root.act([`hl.dsp.window.move({ monitor = "${modelData.name}", window = "${root.addr}" })`])
                        }
                    }
                }

                Label_ { text: "Move to desktop" }
                Grid {
                    Layout.fillWidth: true
                    columns: 5
                    spacing: Theme.spaceXs + 2
                    Repeater {
                        model: 10
                        Pill_ {
                            required property int index
                            width: (menu.width - 4 * (Theme.spaceXs + 2)) / 5
                            text: String(index + 1)
                            current: root.win.workspace?.id === index + 1
                            onClicked: root.act([`hl.dsp.window.move({ workspace = ${index + 1}, follow = false, window = "${root.addr}" })`])
                        }
                    }
                }

                Label_ { text: "Window" }
                Flow {
                    Layout.fillWidth: true
                    spacing: Theme.spaceXs + 2
                    Pill_ {
                        text: "Floating"; current: root.win.floating === true
                        onClicked: root.act([`hl.dsp.window.float({ action = "toggle", window = "${root.addr}" })`])
                    }
                    Pill_ {
                        text: "On top, every desktop"; current: root.win.pinned === true
                        // pin only works on floating windows
                        onClicked: root.act((root.win.floating ? [] : [`hl.dsp.window.float({ action = "enable", window = "${root.addr}" })`])
                                            .concat([`hl.dsp.window.pin({ action = "toggle", window = "${root.addr}" })`]))
                    }
                    Pill_ {
                        text: "Centre"; enabled: root.win.floating === true
                        onClicked: root.act([`hl.dsp.window.center({ window = "${root.addr}" })`])
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spaceS
                    Text { text: "Opacity"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontLabel } }
                    Slider {
                        Layout.fillWidth: true
                        height: 22
                        value: (root.opacity - 0.3) / 0.7
                        onMoved: v => {
                            root.opacity = Math.round((0.3 + v * 0.7) * 100) / 100
                            root.run([`hl.dsp.window.set_prop({ prop = "opacity", value = "${root.opacity}", window = "${root.addr}" })`])
                        }
                    }
                    Text { text: Math.round(root.opacity * 100) + "%"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontLabel } }
                }
            }
        }
    }

    component Label_: Text {
        Layout.topMargin: Theme.spaceXs
        color: Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
    }

    component Pill_: Rectangle {
        id: pill
        property string text
        property bool current: false
        signal clicked()
        implicitWidth: lbl.implicitWidth + 22
        implicitHeight: 28
        radius: height / 2
        opacity: enabled ? 1 : 0.4
        color: current ? Theme.accent : area.containsMouse ? Theme.fillHover : Theme.fill
        border { color: current ? "transparent" : Theme.stroke; width: 1 }
        Text {
            id: lbl
            anchors.centerIn: parent
            text: pill.text
            color: pill.current ? Theme.accentText : Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }
}
