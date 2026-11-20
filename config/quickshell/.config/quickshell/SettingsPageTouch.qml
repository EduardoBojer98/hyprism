import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Touch & Tablet: the touchscreen (on or off for now, which screen it belongs to, swipes), tablet mode on a 2-in-1
// (~/.local/bin/panel reads touch.autoRotate and touch.oskInTablet) and the on-screen keyboard (Osk.qml).
// Only listed on a computer with a touchscreen or the on-screen keyboard.
ColumnLayout {
    id: page
    spacing: 20

    SettingGroup {
        title: "Touchscreen"
        visible: Inputs.hasTouchscreen
        SettingRow {
            label: "Use the touchscreen"
            hint: "Also the pen. Back on after you log in, so the screen never stays dead"
            Toggle { checked: Inputs.touchscreen; onToggled: on => Inputs.setTouchscreen(on) }
        }
        SettingRow {
            label: "Belongs to"
            hint: "The screen your touches and the pen land on"
            Dropdown {
                width: 200
                accessibleName: "Touchscreen belongs to"
                readonly property var keys: [""].concat(Hyprland.monitors.values.map(m => m.name).filter(n => Machine.realScreen(n)))
                readonly property var names: ["The laptop's own screen"].concat(keys.slice(1))
                options: names
                current: names[Math.max(0, keys.indexOf(Config.touch.output))]
                onPicked: v => Config.set("touch", "output", keys[names.indexOf(v)])
            }
        }
        SettingRow {
            label: "Swipe to switch workspaces"
            hint: "Three fingers sideways on the screen, like on the touchpad"
            ConfigToggle { section: "touch"; key: "swipe" }
        }
    }

    SettingGroup {
        title: "Tablet mode"
        visible: Inputs.hasTouchscreen
        SettingRow {
            label: "Turn the screen with the device"
            hint: "When the screen is folded back; controls grow to finger size either way"
            ConfigToggle { section: "touch"; key: "autoRotate" }
        }
        SettingRow {
            visible: Osk.installed
            label: "Show the on-screen keyboard"
            hint: "Opens when the screen folds back, closes when it comes up"
            ConfigToggle { section: "touch"; key: "oskInTablet" }
        }
    }

    SettingGroup {
        title: "On-screen keyboard"
        SettingRow {
            visible: Osk.installed
            label: "Show it now"
            Toggle { checked: Osk.visible; onToggled: Osk.toggle() }
        }
        SettingRow {
            visible: Osk.installed
            label: "Pop up when I tap a text field"
            hint: "Off: only the keyboard button (Control Center, the menu bar) shows it"
            ConfigToggle { section: "touch"; key: "oskAuto" }
        }
        SettingRow {
            visible: Osk.installed
            label: "Use my keyboard layouts"
            hint: Array.from(Config.input.layouts).map(l => l.code.toUpperCase()).join(", ") + ": its globe key switches between them"
            ConfigToggle { section: "touch"; key: "oskLayouts" }
        }
        SettingRow {
            visible: !Osk.installed
            label: "Not installed"
            hint: "./install.sh --only modules (tablet) adds it"
        }
    }

    ResetGroup { sections: ["touch"] }
}
