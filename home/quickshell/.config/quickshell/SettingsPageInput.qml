import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Keyboard & Touchpad: second layout, layout shortcut, key repeat, touchpad and pointer.
// Applied live (hyprctl eval) and saved to hypr/settings/input.lua.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var layouts: [
        { name: "None",             layout: "",   variant: "" },
        { name: "Serbian (Latin)",  layout: "rs", variant: "latin" },
        { name: "Serbian (Cyrillic)", layout: "rs", variant: "" },
        { name: "German",           layout: "de", variant: "" },
        { name: "Croatian",         layout: "hr", variant: "" },
    ]
    readonly property var shortcuts: [
        { name: "Alt+Shift",  option: "grp:alt_shift_toggle" },
        { name: "Ctrl+Shift", option: "grp:ctrl_shift_toggle" },
        { name: "Caps Lock",  option: "grp:caps_toggle" },
    ]

    // Mirrors hypr/settings/input.lua; starts from the shipped defaults until read back
    property var s: ({ second: 1, shortcut: 0, repeat_rate: 25, repeat_delay: 600, sensitivity: 0, natural_scroll: true, tap_to_click: true })

    function set(k, v) { const n = Object.assign({}, s); n[k] = v; s = n; saveTimer.restart() }
    Timer { id: saveTimer; interval: 300; onTriggered: page.save() } // sliders: save once dragging pauses

    function save() {
        const second = layouts[s.second]
        const t = {
            kb_layout: "us" + (second.layout ? "," + second.layout : ""),
            kb_variant: second.layout ? "," + second.variant : "",
            kb_options: second.layout ? shortcuts[s.shortcut].option : "",
            repeat_rate: s.repeat_rate, repeat_delay: s.repeat_delay, sensitivity: s.sensitivity,
            natural_scroll: s.natural_scroll, tap_to_click: s.tap_to_click,
        }
        const table = SettingsApp.lua(t)
        Quickshell.execDetached(["hyprctl", "eval", "INPUT = " + table.replace(/\n/g, " ") + "; apply_input()"])
        SettingsApp.writeHyprFile("settings/input.lua", "-- Written by the Settings app (Keyboard & Touchpad). Safe to edit by hand.\nreturn " + table)
    }

    SettingGroup {
        title: "Keyboard"
        SettingRow {
            label: "Second layout"
            hint: "US is always the first layout"
            Dropdown {
                width: 200
                options: page.layouts.map(l => l.name)
                current: page.layouts[page.s.second].name
                onPicked: v => page.set("second", page.layouts.findIndex(l => l.name === v))
            }
        }
        SettingRow {
            visible: page.s.second > 0
            label: "Switch layouts with"
            Choice {
                options: page.shortcuts.map(x => x.name)
                index: page.s.shortcut
                onPicked: i => page.set("shortcut", i)
            }
        }
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
                const second = page.layouts.findIndex((l, i) => i > 0 && p[0] === "us," + l.layout && (p[1].split(",")[1] ?? "") === l.variant)
                page.s = {
                    second: Math.max(0, second),
                    shortcut: Math.max(0, page.shortcuts.findIndex(x => x.option === p[2])),
                    repeat_rate: parseInt(p[3]), repeat_delay: parseInt(p[4]), sensitivity: parseFloat(p[5]),
                    natural_scroll: p[6] === "true", tap_to_click: p[7] === "true",
                }
            }
        }
    }
}
