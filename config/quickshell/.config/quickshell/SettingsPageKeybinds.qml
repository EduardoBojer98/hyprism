import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Keyboard Shortcuts: every Hyprland bind from hypr/modules/binds.lua, grouped, with the keys it
// uses now. Click the keys to record new ones (Esc cancels); a combination that's already taken
// is refused. Changes go to Config.keybinds, which ThemeSync writes to hypr/settings/keybinds.lua
// before reloading Hyprland. Mouse buttons and hardware switches are shown but can't be changed.
ColumnLayout {
    id: page
    spacing: 20

    property var binds: []          // { id, group, label, fixed, def, keys }
    property string filter: ""
    property string recording: ""   // id waiting for keys
    property string message: ""

    readonly property var overrides: Config.keybinds.overrides
    readonly property var groups: {
        const q = filter.trim().toLowerCase()
        const out = []
        for (const b of binds) {
            if (q && !(b.label + " " + b.keys + " " + b.group).toLowerCase().includes(q)) continue
            let g = out.find(x => x.name === b.group)
            if (!g) { g = { name: b.group, items: [] }; out.push(g) }
            g.items.push(b)
        }
        return out
    }

    // hyprctl modmask bits -> names, in the order binds.lua writes them
    function keysOf(modmask, key) {
        const mods = [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]].filter(m => modmask & m[0]).map(m => m[1])
        return mods.concat([key]).join(" + ")
    }
    // Same combination regardless of modifier order or letter case
    function norm(keys) {
        const parts = String(keys).split("+").map(s => s.trim()).filter(s => s)
        const key = (parts.pop() ?? "").toLowerCase()
        return parts.map(s => s.toUpperCase()).sort().concat([key]).join("+")
    }

    // "SUPER + SHIFT + period" -> "Super + Shift + ."
    function pretty(keys) {
        if (keys === "SUPER + Super_L") return "Super (tap)"
        const names = { SUPER: "Super", CTRL: "Ctrl", ALT: "Alt", SHIFT: "Shift", period: ".", comma: ",", minus: "-", equal: "=",
                        slash: "/", backslash: "\\", semicolon: ";", apostrophe: "'", bracketleft: "[", bracketright: "]", grave: "`",
                        left: "←", right: "→", up: "↑", down: "↓", Return: "Enter", Prior: "Page Up", Next: "Page Down", BackSpace: "Backspace" }
        return String(keys).split(" + ").map(k => names[k] ?? k.replace(/^XF86/, "")).join(" + ")
    }

    function load() { reader.running = true }
    function save(b, keys) {
        const o = Object.assign({}, overrides)
        if (keys === b.def) delete o[b.id]
        else o[b.id] = { keys: keys, label: b.label, group: b.group, def: b.def }
        Config.set("keybinds", "overrides", o)
        refresh.restart()
    }
    function resetAll() { Config.set("keybinds", "overrides", ({})); refresh.restart() }

    function record(b, event) {
        const ignore = [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr]
        if (ignore.includes(event.key)) return
        event.accepted = true
        if (event.key === Qt.Key_Escape) { recording = ""; message = ""; return }
        const key = keyName(event)
        if (!key) { message = "That key can't be used for a shortcut"; return }
        const mods = []
        if (event.modifiers & Qt.MetaModifier) mods.push("SUPER")
        if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
        if (event.modifiers & Qt.AltModifier) mods.push("ALT")
        if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")
        const standalone = /^(F\d+|Print|XF86)/.test(key)
        if (!standalone && !mods.some(m => m !== "SHIFT")) { message = "Hold Super, Ctrl or Alt with the key"; return }
        const keys = mods.concat([key]).join(" + ")
        const taken = binds.find(x => x.id !== b.id && x.keys && norm(x.keys) === norm(keys))
        if (taken) { message = `${pretty(keys)} is already used by “${taken.label}”`; return }
        recording = ""; message = ""
        save(b, keys)
    }
    // Turns a Qt key code into the name Hyprland uses. Shifted digits arrive as symbols (US layout).
    function keyName(e) {
        const k = e.key
        if (k >= Qt.Key_A && k <= Qt.Key_Z) return String.fromCharCode(k)
        if (k >= Qt.Key_0 && k <= Qt.Key_9) return String.fromCharCode(k)
        if (k >= Qt.Key_F1 && k <= Qt.Key_F24) return "F" + (k - Qt.Key_F1 + 1)
        const shifted = { [Qt.Key_Exclam]: "1", [Qt.Key_At]: "2", [Qt.Key_NumberSign]: "3", [Qt.Key_Dollar]: "4", [Qt.Key_Percent]: "5",
                          [Qt.Key_AsciiCircum]: "6", [Qt.Key_Ampersand]: "7", [Qt.Key_Asterisk]: "8", [Qt.Key_ParenLeft]: "9", [Qt.Key_ParenRight]: "0" }
        if (shifted[k]) return shifted[k]
        const named = {
            [Qt.Key_Space]: "Space", [Qt.Key_Return]: "Return", [Qt.Key_Enter]: "Return", [Qt.Key_Tab]: "Tab", [Qt.Key_Backtab]: "Tab",
            [Qt.Key_Left]: "left", [Qt.Key_Right]: "right", [Qt.Key_Up]: "up", [Qt.Key_Down]: "down",
            [Qt.Key_Period]: "period", [Qt.Key_Greater]: "period", [Qt.Key_Comma]: "comma", [Qt.Key_Less]: "comma",
            [Qt.Key_Minus]: "minus", [Qt.Key_Underscore]: "minus", [Qt.Key_Equal]: "equal", [Qt.Key_Plus]: "equal",
            [Qt.Key_Slash]: "slash", [Qt.Key_Question]: "slash", [Qt.Key_Backslash]: "backslash", [Qt.Key_Bar]: "backslash",
            [Qt.Key_Semicolon]: "semicolon", [Qt.Key_Colon]: "semicolon", [Qt.Key_Apostrophe]: "apostrophe", [Qt.Key_QuoteDbl]: "apostrophe",
            [Qt.Key_BracketLeft]: "bracketleft", [Qt.Key_BraceLeft]: "bracketleft", [Qt.Key_BracketRight]: "bracketright", [Qt.Key_BraceRight]: "bracketright",
            [Qt.Key_QuoteLeft]: "grave", [Qt.Key_AsciiTilde]: "grave",
            [Qt.Key_Delete]: "Delete", [Qt.Key_Backspace]: "BackSpace", [Qt.Key_Home]: "Home", [Qt.Key_End]: "End",
            [Qt.Key_PageUp]: "Prior", [Qt.Key_PageDown]: "Next", [Qt.Key_Insert]: "Insert", [Qt.Key_Print]: "Print",
        }
        return named[k] ?? ""
    }

    // While recording, Hyprland's empty "keyrecord" submap passes every combination to this page
    onRecordingChanged: Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.submap("${recording ? "keyrecord" : "reset"}")`])
    Component.onDestruction: if (recording) Quickshell.execDetached(["hyprctl", "dispatch", 'hl.dsp.submap("reset")'])
    Connections { target: SettingsApp; function onOpenChanged() { if (!SettingsApp.open) page.recording = "" } }

    Component.onCompleted: load()
    Timer { id: refresh; interval: 1200; onTriggered: page.load() }

    Process {
        id: reader
        command: ["hyprctl", "-j", "binds"]
        stdout: StdioCollector {
            onStreamFinished: {
                let list = []
                try {
                    for (const b of JSON.parse(text)) {
                        const d = (b.description ?? "").split("|")
                        if (d.length < 5) continue
                        list.push({ id: d[0], group: d[1], label: d[2], fixed: d[3] === "fixed", def: d[4], keys: page.keysOf(b.modmask, b.key) })
                    }
                } catch (e) { page.message = "Couldn't read the shortcuts from Hyprland" }
                // shortcuts that are turned off aren't bound, so they come from the saved overrides
                for (const id in page.overrides) {
                    const o = page.overrides[id]
                    if (o.keys === "" && !list.some(b => b.id === id)) list.push({ id: id, group: o.group, label: o.label, fixed: false, def: o.def, keys: "" })
                }
                page.binds = list
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.spaceS
        TextField {
            Layout.fillWidth: true
            placeholder: "Search shortcuts"
            onTextChanged: page.filter = text
        }
        PillButton { text: "Reset all"; visible: Object.keys(page.overrides).length > 0; onClicked: page.resetAll() }
    }

    Text {
        visible: page.message !== ""
        Layout.fillWidth: true
        text: page.message
        color: Theme.warning
        wrapMode: Text.WordWrap
        font { family: Theme.font; pixelSize: Theme.fontSize }
    }

    Repeater {
        model: page.groups
        SettingGroup {
            id: group
            required property var modelData
            title: modelData.name
            Repeater {
                model: group.modelData.items
                SettingRow {
                    id: row
                    required property var modelData
                    readonly property bool changed: page.overrides[modelData.id] !== undefined
                    readonly property bool isRecording: page.recording === modelData.id
                    HoverHandler { id: rowHover }   // the turn-off × only shows on the row under the pointer
                    label: modelData.label
                    hint: modelData.fixed ? "Can't be changed here"
                        : !changed ? "" : modelData.keys === "" ? `Turned off · default ${page.pretty(modelData.def)}` : `Default ${page.pretty(modelData.def)}`

                    RowLayout {
                        spacing: Theme.spaceXs

                        // the keys; click to record new ones
                        Rectangle {
                            Layout.preferredHeight: Theme.controlHeight
                            Layout.preferredWidth: Math.max(110, keysText.implicitWidth + Theme.spaceL * 2)
                            radius: Theme.radiusSmall
                            color: row.isRecording ? Theme.accentWash : keyArea.containsMouse && !row.modelData.fixed ? Theme.fillHover : Theme.fillActive
                            border { color: row.isRecording ? Theme.accent : Theme.stroke; width: 1 }
                            Text {
                                id: keysText
                                anchors.centerIn: parent
                                text: row.isRecording ? "Press keys…" : row.modelData.keys === "" ? "Off" : page.pretty(row.modelData.keys)
                                color: row.modelData.keys === "" && !row.isRecording ? Theme.muted : Theme.text
                                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                            }
                            MouseArea {
                                id: keyArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !row.modelData.fixed
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { page.recording = row.modelData.id; page.message = ""; catcher.forceActiveFocus() }
                            }
                            Item {
                                id: catcher
                                focus: row.isRecording
                                Keys.onPressed: event => page.record(row.modelData, event)
                                onActiveFocusChanged: if (!activeFocus && row.isRecording) page.recording = ""
                            }
                        }
                        Chip {
                            visible: !row.modelData.fixed && row.modelData.keys !== ""
                            opacity: rowHover.hovered || hovered ? 1 : 0   // keeps its room, so the row doesn't shift
                            icon: "\u{F0156}"
                            onClicked: page.save(row.modelData, "")
                            ToolTipText { shown: parent.hovered; text: "Turn off" }
                        }
                        Chip {
                            visible: row.changed
                            icon: "\u{F0450}"
                            onClicked: page.save(row.modelData, row.modelData.def)
                            ToolTipText { shown: parent.hovered; text: "Back to default" }
                        }
                    }
                }
            }
        }
    }
}
