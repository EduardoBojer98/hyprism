pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts

// Keyboard shortcut cheatsheet (Super+/, `qs ipc call cheatsheet toggle`): every shortcut from
// hypr/modules/binds.lua, read live from Hyprland (`hyprctl -j binds`), so it always shows your
// current keys, including the ones changed in Settings > Keyboard Shortcuts.
// Type to filter · Esc, Super+/ or a click / tap outside closes.
Singleton {
    id: root

    property bool open: false
    property var binds: []      // { group, label, keys }
    property string filter: ""

    // Groups in a fixed reading order; the per-workspace binds fold into one row each
    readonly property var order: ["Apps", "Windows", "Workspaces", "Screen", "Keyboard", "Session", "Media", "Hardware"]
    readonly property var groups: {
        const q = filter.trim().toLowerCase()
        const out = []
        for (const b of binds) {
            if (q && !(b.label + " " + b.keys + " " + b.group).toLowerCase().includes(q)) continue
            let g = out.find(x => x.name === b.group)
            if (!g) { g = { name: b.group, items: [] }; out.push(g) }
            if (!(b.folded && g.items.some(i => i.label === b.label))) g.items.push(b)
        }
        const rank = name => order.includes(name) ? order.indexOf(name) : order.length   // unknown groups last
        return out.sort((a, b) => rank(a.name) - rank(b.name))
    }

    function show() { filter = ""; reader.running = true; open = true }
    function hide() { open = false }
    function toggle() { if (open) hide(); else show() }

    // hyprctl modmask bits -> names, same order as binds.lua (and SettingsPageKeybinds)
    function keysOf(modmask, key) {
        const mods = [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]].filter(m => modmask & m[0]).map(m => m[1])
        const names = { period: ".", comma: ",", slash: "/", left: "←", right: "→", up: "↑", down: "↓", Return: "Enter",
                        Super_L: "(tap)", Print: "Print", Escape: "Esc", "mouse:272": "Left drag", "mouse:273": "Right drag",
                        mouse_down: "Wheel down", mouse_up: "Wheel up", Space: "Space", grave: "`", backslash: "\\", minus: "-", equal: "=" }
        return mods.concat([names[key] ?? key.replace(/^XF86/, "")]).join(" + ").replace("Super + (tap)", "Super (tap)")
    }

    IpcHandler {
        target: "cheatsheet"
        function toggle(): void { root.toggle() }
    }

    Process {
        id: reader
        command: ["hyprctl", "-j", "binds"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = []
                try {
                    for (const b of JSON.parse(text)) {
                        const d = (b.description ?? "").split("|")   // id|group|label|fixed|default keys (binds.lua)
                        if (d.length < 5) continue
                        let label = d[2], keys = root.keysOf(b.modmask, b.key)
                        // "Go to workspace 3" x10 -> one row "Go to workspace 1-10" with "Super + 1…0"
                        const ws = label.match(/^(.*workspace) \d+$/)
                        if (ws) { label = ws[1] + " 1–10"; keys = keys.replace(/\d$/, "1…0") }
                        list.push({ group: d[1], label: label, keys: keys, folded: !!ws })
                    }
                } catch (e) {}
                root.binds = list
            }
        }
    }

    PanelWindow {
        id: win
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: root.open || stage.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-cheatsheet"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        Item {
            id: stage
            anchors.fill: parent
            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
            focus: root.open

            // typing filters; Esc clears the filter first, then closes; Super+/ toggles from Hyprland
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) { if (root.filter) root.filter = ""; else root.hide() }
                else if (event.key === Qt.Key_Backspace) root.filter = root.filter.slice(0, -1)
                else if (event.text && event.text.trim() && !(event.modifiers & Qt.MetaModifier)) root.filter += event.text
                else return
                event.accepted = true
            }

            Rectangle { anchors.fill: parent; color: Theme.backdrop }
            MouseArea { anchors.fill: parent; onClicked: root.hide(); Accessible.ignored: true }

            Glass {
                id: card
                readonly property int margin: Math.max(Theme.spaceL, Math.min(win.width, win.height) * 0.04)
                readonly property int pad: Theme.spaceXl
                width: Math.min(1180, win.width - margin * 2)
                height: Math.min(content.implicitHeight + pad * 2, win.height - margin * 2)
                anchors.centerIn: parent
                strong: true
                radius: Theme.radiusPanel
                scale: root.open ? 1 : 0.97
                Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                MouseArea { anchors.fill: parent }   // clicks on the card don't close it

                MoreBelow { z: 1; flick: sheet; anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: card.pad } }
                Flickable {   // scrolls on short screens (the laptop at 1.2 scale, tablet mode)
                    id: sheet
                    anchors { fill: parent; margins: card.pad }
                    QQC.ScrollBar.vertical: GlassScrollBar {}
                    contentHeight: content.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: content
                        width: parent.width
                        spacing: Theme.spaceL

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Keyboard shortcuts"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontHeading; weight: Font.DemiBold } }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: root.filter ? "Filter: " + root.filter : "Type to filter · Esc closes · change keys in Settings › Keyboard Shortcuts"
                                color: root.filter ? Theme.accent : Theme.subtext
                                font { family: Theme.font; pixelSize: Theme.fontLabel }
                            }
                        }

                        Flow {   // groups as columns that wrap to the card width
                            id: flow
                            Layout.fillWidth: true
                            spacing: Theme.spaceXl
                            readonly property int cols: Math.max(1, Math.floor((width + spacing) / (330 + spacing)))
                            readonly property real colWidth: (width - spacing * (cols - 1)) / cols

                            Repeater {
                                model: root.groups
                                ColumnLayout {
                                    required property var modelData
                                    width: flow.colWidth
                                    spacing: 2
                                    Text {
                                        text: modelData.name.toUpperCase()
                                        color: Theme.accent
                                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Bold; letterSpacing: 1.2 }
                                        Layout.bottomMargin: Theme.spaceXs
                                    }
                                    Repeater {
                                        model: modelData.items
                                        RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.minimumHeight: 26
                                            spacing: Theme.spaceS
                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.label
                                                color: Theme.text
                                                wrapMode: Text.Wrap   // two lines rather than a word cut off
                                                maximumLineCount: 2
                                                elide: Text.ElideRight
                                                font { family: Theme.font; pixelSize: Theme.fontSize }
                                            }
                                            Rectangle {   // keycap
                                                implicitWidth: cap.implicitWidth + 12
                                                implicitHeight: 22
                                                radius: Theme.radiusSmall - 2
                                                color: Theme.fill
                                                border { color: Theme.strokeStrong; width: 1 }
                                                Text {
                                                    id: cap
                                                    anchors.centerIn: parent
                                                    text: modelData.keys
                                                    color: Theme.text
                                                    font { family: Theme.monoFont; pixelSize: Theme.fontLabel }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
