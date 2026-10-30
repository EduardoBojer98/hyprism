import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Keyboard & Touchpad: keyboard layouts (any xkb layout or variant, up to 4, the first is the
// default), the layout shortcut, key repeat, touchpad and pointer.
// Applied live (hyprctl eval) and saved to hypr/settings/input.lua.
ColumnLayout {
    id: page
    spacing: 20

    readonly property int maxLayouts: 4   // xkb holds at most four layouts at once
    readonly property var shortcuts: [
        { name: "Alt+Shift",  option: "grp:alt_shift_toggle" },
        { name: "Ctrl+Shift", option: "grp:ctrl_shift_toggle" },
        { name: "Caps Lock",  option: "grp:caps_toggle" },
        { name: "None",       option: "" },        // only the layout widget in the bar switches
    ]

    // Mirrors hypr/settings/input.lua; starts from the shipped defaults until read back
    property var s: ({ list: [{ code: "us", variant: "" }], shortcut: 0, repeat_rate: 25, repeat_delay: 600, sensitivity: 0, natural_scroll: true, tap_to_click: true })

    function set(k, v) { const n = Object.assign({}, s); n[k] = v; s = n; saveTimer.restart() }
    Timer { id: saveTimer; interval: 300; onTriggered: page.save() } // sliders: save once dragging pauses

    // layouts: add from the search, remove, move one to the top (the default)
    property string query: ""
    readonly property var matches: {
        const q = query.trim().toLowerCase()
        if (!q) return []
        return Keyboard.catalog
            .filter(c => !s.list.some(l => l.code === c.code && l.variant === c.variant)
                         && (c.name.toLowerCase().includes(q) || c.code === q))
            .slice(0, 8)
    }
    function addLayout(c) {
        if (s.list.length >= maxLayouts) return
        set("list", s.list.concat([{ code: c.code, variant: c.variant }]))
        query = ""; search.text = ""
    }
    function removeLayout(i) { if (s.list.length > 1) set("list", s.list.filter((_, j) => j !== i)) }
    function makeFirst(i) { const l = s.list.slice(); l.unshift(l.splice(i, 1)[0]); set("list", l) }

    function save() {
        const many = s.list.length > 1
        const t = {
            kb_layout: s.list.map(l => l.code).join(","),
            kb_variant: many || s.list[0].variant ? s.list.map(l => l.variant).join(",") : "",
            kb_options: many ? shortcuts[s.shortcut].option : "",
            repeat_rate: s.repeat_rate, repeat_delay: s.repeat_delay, sensitivity: s.sensitivity,
            natural_scroll: s.natural_scroll, tap_to_click: s.tap_to_click,
        }
        const table = SettingsApp.lua(t)
        Quickshell.execDetached(["hyprctl", "eval", "INPUT = " + table.replace(/\n/g, " ") + "; apply_input()"])
        SettingsApp.writeHyprFile("settings/input.lua", "-- Written by the Settings app (Keyboard & Touchpad). Safe to edit by hand.\nreturn " + table)
    }

    SettingGroup {
        title: "Keyboard layouts"
        Repeater {
            model: page.s.list
            Item {
                id: lay
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 46
                Rectangle { visible: lay.index > 0; anchors { left: parent.left; right: parent.right; leftMargin: 16 } height: 1; color: Theme.stroke }
                Rectangle { // keycap, as in the bar
                    id: cap
                    anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                    width: 30; height: 18; radius: 4
                    color: "transparent"
                    border { color: Qt.alpha(Theme.text, 0.45); width: 1 }
                    Text { anchors.centerIn: parent; text: lay.modelData.code.toUpperCase(); color: Theme.text; font { family: Theme.font; pixelSize: 10; weight: Font.Bold } }
                }
                Column {
                    anchors { left: cap.right; leftMargin: 12; right: buttons.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    Text { width: parent.width; text: Keyboard.nameOf(lay.modelData.code, lay.modelData.variant); elide: Text.ElideRight; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize } }
                    Text { visible: lay.index === 0; text: "Default"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                }
                Row {
                    id: buttons
                    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    spacing: 6
                    PillButton { visible: lay.index > 0; text: "Make default"; onClicked: page.makeFirst(lay.index) }
                    PillButton { visible: page.s.list.length > 1; text: "Remove"; onClicked: page.removeLayout(lay.index) }
                }
            }
        }
        SettingRow {
            visible: page.s.list.length > 1
            label: "Switch layouts with"
            hint: page.shortcuts[page.s.shortcut].option ? "Or click the layout in the bar" : "Only from the layout in the bar"
            Choice {
                options: page.shortcuts.map(x => x.name)
                index: page.s.shortcut
                onPicked: i => page.set("shortcut", i)
            }
        }
    }

    SettingGroup {
        title: "Add a layout"
        SettingRow {
            label: "Search"
            hint: page.s.list.length >= page.maxLayouts ? "Four layouts is the most a keyboard can hold; remove one first"
                                                         : "A language or country, e.g. German, Serbian, Dvorak"
            TextField {
                id: search
                width: 220
                enabled: page.s.list.length < page.maxLayouts
                placeholder: "e.g. German"
                onTextChanged: page.query = text
                onAccepted: if (page.matches.length) page.addLayout(page.matches[0])
            }
        }
        Repeater {
            model: page.s.list.length < page.maxLayouts ? page.matches : []
            Item {
                id: hit
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 40
                Rectangle { anchors { left: parent.left; right: parent.right; leftMargin: 16 } height: 1; color: Theme.stroke }
                Text {
                    anchors { left: parent.left; leftMargin: 16; right: addBtn.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    text: hit.modelData.name
                    elide: Text.ElideRight
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontSize }
                }
                PillButton { id: addBtn; anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter } text: "Add"; primary: true; onClicked: page.addLayout(hit.modelData) }
            }
        }
    }

    SettingGroup {
        title: "Typing"
        SettingRow {
            label: "Key repeat delay"
            hint: page.s.repeat_delay + " ms before a held key repeats"
            Slider {
                width: 260
                icon: "\u{F0954}"
                value: (page.s.repeat_delay - 150) / 850
                onMoved: v => page.set("repeat_delay", Math.round(150 + v * 850))
            }
        }
        SettingRow {
            label: "Key repeat rate"
            hint: page.s.repeat_rate + " characters per second"
            Slider {
                width: 260
                icon: "\u{F04C5}"
                value: (page.s.repeat_rate - 10) / 50
                onMoved: v => page.set("repeat_rate", Math.round(10 + v * 50))
            }
        }
    }

    SettingGroup {
        title: "Touchpad & mouse"
        SettingRow {
            label: "Natural scrolling"
            hint: "Content follows your fingers, like a phone"
            Toggle { checked: page.s.natural_scroll; onToggled: v => page.set("natural_scroll", v) }
        }
        SettingRow {
            label: "Tap to click"
            Toggle { checked: page.s.tap_to_click; onToggled: v => page.set("tap_to_click", v) }
        }
        SettingRow {
            label: "Pointer speed"
            Slider {
                width: 260
                icon: "\u{F037D}"
                value: (page.s.sensitivity + 1) / 2
                onMoved: v => page.set("sensitivity", Math.round((v * 2 - 1) * 100) / 100)
            }
        }
    }

    // Read the current values back from Hyprland
    Component.onCompleted: reader.running = true
    Process {
        id: reader
        command: ["hyprctl", "repl", "INPUT.kb_layout .. '|' .. INPUT.kb_variant .. '|' .. INPUT.kb_options .. '|' .. INPUT.repeat_rate .. '|' .. INPUT.repeat_delay .. '|' .. INPUT.sensitivity .. '|' .. tostring(INPUT.natural_scroll) .. '|' .. tostring(INPUT.tap_to_click)"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split("|")
                if (p.length < 8) return
                const variants = p[1].split(",")
                page.s = {
                    list: p[0].split(",").filter(c => c).map((c, i) => ({ code: c, variant: variants[i] ?? "" })),
                    shortcut: Math.max(0, page.shortcuts.findIndex(x => x.option === p[2])),
                    repeat_rate: parseInt(p[3]), repeat_delay: parseInt(p[4]), sensitivity: parseFloat(p[5]),
                    natural_scroll: p[6] === "true", tap_to_click: p[7] === "true",
                }
            }
        }
    }
}
