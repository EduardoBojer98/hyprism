import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Keyboard & Touchpad: keyboard layouts (any xkb layout or variant, up to 4, the first is the
// default), the layout shortcut, key repeat, touchpad and pointer.
// Saved in settings.json (input); SettingsSync.qml writes hypr/settings/input.lua and applies it live.
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

    // settings.json input, under the names the controls use (SettingsSync.qml writes input.lua and applies it)
    readonly property var s: ({ list: Array.from(Config.input.layouts), shortcut: Config.input.shortcut, repeat_rate: Config.input.repeatRate,
                                repeat_delay: Config.input.repeatDelay, sensitivity: Config.input.sensitivity,
                                natural_scroll: Config.input.naturalScroll, tap_to_click: Config.input.tapToClick })
    readonly property var keyOf: ({ list: "layouts", shortcut: "shortcut", repeat_rate: "repeatRate", repeat_delay: "repeatDelay",
                                    sensitivity: "sensitivity", natural_scroll: "naturalScroll", tap_to_click: "tapToClick",
                                    scroll_factor: "scrollFactor" })
    // until the values written before are imported, the controls are off, so nothing can overwrite them
    readonly property bool loaded: Config.input.imported
    enabled: loaded
    opacity: loaded ? 1 : 0.5
    function set(k, v) { if (loaded) Config.set("input", keyOf[k], v) }

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

    Text {
        visible: !page.loaded
        Layout.fillWidth: true
        text: "Couldn't read the current settings from Hyprland, so the controls are off."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
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
                    Text { anchors.centerIn: parent; text: lay.modelData.code.toUpperCase(); color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Bold } }
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
            hint: (page.shortcuts[page.s.shortcut].option ? "Also " : "") + "Super+Ctrl+Space, or click the layout in the bar"
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

    SettingGroup {
        visible: Inputs.touchpadName !== ""   // only on a computer with a touchpad
        title: "Touchpad"
        SettingRow {
            label: "Pause while typing"
            hint: "Ignores the pad while you type, so a palm can't move the cursor"
            ConfigToggle { section: "input"; key: "disableWhileTyping" }
        }
        SettingRow {
            label: "Click with"
            hint: "Fingers: one, two or three fingers pressed = left, right, middle. Corners: press the pad's bottom corners"
            ConfigChoice { section: "input"; key: "clickMethod"; values: ["clickfinger", "buttonareas"]; labels: ["Fingers", "Corners"] }
        }
        SettingRow {
            label: "Scroll speed"
            hint: Config.input.scrollFactor.toFixed(1) + "×"
            Slider {
                width: 260
                icon: "\u{F037D}"
                value: (Config.input.scrollFactor - 0.2) / 2.8
                onMoved: v => page.set("scroll_factor", Math.round((0.2 + v * 2.8) * 10) / 10)
            }
        }
        SettingRow {
            label: "Left + right = middle click"
            ConfigToggle { section: "input"; key: "middleEmulation" }
        }
        SettingRow {
            label: "Drag lock"
            hint: "Lifting your finger mid-drag keeps holding the item until you tap again"
            ConfigToggle { section: "input"; key: "dragLock" }
        }
    }

    // Logitech buttons, DPI, battery and haptics are Solaar's own window (the logitech module installs it)
    property bool solaar: false
    Process {
        running: true
        command: ["sh", "-c", "command -v solaar"]
        onExited: code => page.solaar = code === 0
    }
    SettingGroup {
        visible: page.solaar
        title: "Logitech devices"
        SettingRow {
            label: "Buttons, scroll wheel, DPI and haptics"
            hint: "Opens Solaar"
            PillButton { text: "Open"; onClicked: Quickshell.execDetached(["solaar"]) }
        }
    }
}
