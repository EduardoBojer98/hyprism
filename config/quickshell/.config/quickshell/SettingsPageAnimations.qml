import QtQuick
import QtQuick.Layouts

// Animations: how windows open, close and move, and how desktops switch, plus overall speed
// (Config.windows; hypr/modules/windows.lua turns each choice into Hyprland animation settings).
// The shell's own motion (menus, panels, the dock) is the first switch (Config.appearance.animations).
ColumnLayout {
    id: page
    spacing: 20

    readonly property bool on: Config.windows.animations

    SettingGroup {
        SettingRow {
            label: "Menus, panels and the dock"
            hint: "Off: they open and move instantly; the rainbow border stands still"
            ConfigToggle { section: "appearance"; key: "animations" }
        }
        SettingRow {
            label: "Windows and desktops"
            hint: "Off: windows and desktops change instantly"
            ConfigToggle { section: "windows"; key: "animations" }
        }
        SettingRow {
            enabled: page.on
            opacity: enabled ? 1 : 0.45
            label: "Speed"
            ConfigChoice { section: "windows"; key: "animSpeed"; values: ["slow", "normal", "fast"]; labels: ["Relaxed", "Normal", "Quick"] }
        }
    }

    SettingGroup {
        title: "Windows"
        enabled: page.on
        opacity: enabled ? 1 : 0.45
        SettingRow {
            label: "Opening"
            hint: "Pop: grows from slightly smaller · Slide: comes in from the nearest edge · Grow: unfolds from the middle"
            ConfigChoice { section: "windows"; key: "animOpen"; values: ["popin", "slide", "gnomed", "fade", "none"]; labels: ["Pop", "Slide", "Grow", "Fade", "None"] }
        }
        SettingRow {
            label: "Closing"
            ConfigChoice { section: "windows"; key: "animClose"; values: ["popin", "slide", "gnomed", "fade", "none"]; labels: ["Pop", "Slide", "Shrink", "Fade", "None"] }
        }
        SettingRow {
            label: "Moving and resizing"
            hint: "Smooth: eases into place · Snappy: quick and direct · Bouncy: overshoots a little"
            ConfigChoice { section: "windows"; key: "animMove"; values: ["smooth", "snappy", "bouncy", "none"]; labels: ["Smooth", "Snappy", "Bouncy", "None"] }
        }
    }

    SettingGroup {
        title: "Desktops"
        enabled: page.on
        opacity: enabled ? 1 : 0.45
        SettingRow {
            label: "Switching desktops"
            ConfigChoice { section: "windows"; key: "animWorkspace"; values: ["slidefade", "slide", "slidevert", "fade", "none"]; labels: ["Glide", "Slide", "Slide up", "Fade", "None"] }
        }
    }

    SettingGroup {
        SettingRow {
            label: "Reset to defaults"
            hint: "Only the options on this page"
            PillButton {
                text: "Reset"
                onClicked: {
                    Config.reset("appearance", ["animations"])
                    Config.reset("windows", ["animations", "animOpen", "animClose", "animMove", "animWorkspace", "animSpeed"])
                }
            }
        }
    }
}
