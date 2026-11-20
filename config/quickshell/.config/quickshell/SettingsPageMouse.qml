import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Mouse & Touchpad: pointer speed and acceleration for every device, the mouse wheel, the touchpad's own
// options, and Solaar for Logitech extras. Saved in settings.json (input) like the Keyboard page;
// SettingsSync.qml writes hypr/settings/input.lua and applies it live.
ColumnLayout {
    id: page
    spacing: 20

    // settings.json input, under the names the controls use
    readonly property var s: ({ sensitivity: Config.input.sensitivity, natural_scroll: Config.input.naturalScroll, tap_to_click: Config.input.tapToClick })
    readonly property var keyOf: ({ sensitivity: "sensitivity", natural_scroll: "naturalScroll", tap_to_click: "tapToClick", scroll_factor: "scrollFactor" })
    // until the values written before are imported, the controls are off, so nothing can overwrite them
    readonly property bool loaded: Config.input.imported
    enabled: loaded
    opacity: loaded ? 1 : 0.5
    function set(k, v) { if (loaded) Config.set("input", keyOf[k], v) }

    // every mouse and touchpad; a device's own app (Solaar, a vendor tool) can still set its buttons and DPI
    SettingGroup {
        title: "Pointer"
        SettingRow {
            label: "Pointer speed"
            hint: page.s.sensitivity === 0 ? "Default" : (page.s.sensitivity > 0 ? "Faster: +" : "Slower: ") + Math.round(page.s.sensitivity * 100) + "%"
            Slider {
                width: 220
                value: (page.s.sensitivity + 1) / 2
                onMoved: v => page.set("sensitivity", Math.round((v * 2 - 1) * 100) / 100)
            }
        }
        SettingRow {
            label: "Acceleration"
            hint: "Adaptive: a quick flick goes further. Flat: the same distance at any speed, good for games"
            ConfigChoice { section: "input"; key: "accelProfile"; values: ["adaptive", "flat"]; labels: ["Adaptive", "Flat"] }
        }
        SettingRow {
            label: "Left-handed"
            hint: "Swaps the left and right buttons"
            ConfigToggle { section: "input"; key: "leftHanded" }
        }
    }

    SettingGroup {
        title: "Mouse"
        SettingRow {
            label: "Natural scrolling"
            hint: "Rolling the wheel down moves the page up, like a touchpad"
            ConfigToggle { section: "input"; key: "mouseNaturalScroll" }
        }
        SettingRow {
            label: "Scroll speed"
            hint: Config.input.mouseScrollFactor.toFixed(1) + "×"
            Slider {
                width: 220
                value: (Config.input.mouseScrollFactor - 0.2) / 2.8
                onMoved: v => Config.set("input", "mouseScrollFactor", Math.round((0.2 + v * 2.8) * 10) / 10)
            }
        }
    }
    Text {
        Layout.fillWidth: true
        Layout.topMargin: -12
        text: "These apply to every mouse. An app made for your mouse (Solaar for Logitech, for example) can still change its buttons and DPI."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    SettingGroup {
        visible: Inputs.touchpadName !== ""   // only on a computer with a touchpad
        title: "Touchpad"
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
                width: 220
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

    ResetGroup {
        sections: ["input"]
        keys: ["sensitivity", "naturalScroll", "tapToClick", "disableWhileTyping", "clickMethod", "scrollFactor", "middleEmulation",
               "dragLock", "mouseNaturalScroll", "mouseScrollFactor", "accelProfile", "leftHanded"]
    }
}
