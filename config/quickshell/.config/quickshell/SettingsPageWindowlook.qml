import QtQuick
import QtQuick.Layouts

// Window Look: the focused window's border, title bars, the space around windows, and how windows
// you're not using look. Title bars come from the hyprbars plugin (hypr/modules/plugins.lua). Border and gaps are Config.appearance (ThemeSync sends them to Hyprland with the
// theme); opacity and dimming are Config.windows (hypr/modules/windows.lua). Corners stay on
// Appearance because they shape panels and menus too.
ColumnLayout {
    id: page
    spacing: 20

    SettingGroup {
        title: "Border"
        SettingRow {
            label: "Focused window"
            hint: "The border around the window you're working in"
            ConfigChoice { section: "appearance"; key: "border"; values: ["rainbow", "accent"]; labels: ["Rainbow", "Accent colour"] }
        }
        SettingRow {
            visible: Config.appearance.border === "rainbow"
            label: "Rainbow rotation"
            hint: Theme.animate ? "How fast the colours go round" : "Still while animations are off (Windows > Animations)"
            ConfigChoice { section: "appearance"; key: "borderSpin"; values: [0, 100, 60, 25]; labels: ["Still", "Slow", "Medium", "Fast"] }
        }
        SettingRow {
            label: "Thickness"
            ConfigChoice { section: "appearance"; key: "borderSize"; values: [1, 2, 3, 4]; labels: ["1 px", "2 px", "3 px", "4 px"] }
        }
    }

    SettingGroup {
        title: "Title bars"
        SettingRow {
            label: "Title bars on apps without buttons"
            hint: "Minimise, maximise, close and ⋯ (the window menu, also Super+Z). Apps that draw their own, like Chrome, Firefox and GNOME apps, keep theirs"
            ConfigToggle { section: "windows"; key: "titleBars" }
        }
    }

    SettingGroup {
        title: "Spacing"
        SettingRow {
            label: "Space around windows"
            hint: "Between two windows it is half. Corners: Appearance > Glass and shape"
            ConfigSlider { section: "appearance"; key: "gaps"; from: 0; to: 40; step: 1; format: v => v + " px" }
        }
    }

    SettingGroup {
        title: "Windows you're not using"
        SettingRow {
            label: "Opacity"
            ConfigSlider { section: "windows"; key: "inactiveOpacity"; from: 0.6; to: 1; step: 0.01; format: v => Math.round(v * 100) + "%" }
        }
        SettingRow {
            label: "Dim them"
            ConfigToggle { section: "windows"; key: "dimInactive" }
        }
        SettingRow {
            visible: Config.windows.dimInactive
            label: "How much"
            ConfigSlider { section: "windows"; key: "dimStrength"; from: 0.05; to: 0.6; step: 0.01; format: v => Math.round(v * 100) + "%" }
        }
    }

    SettingGroup {
        SettingRow {
            label: "Reset to defaults"
            hint: "Only the options on this page"
            PillButton {
                text: "Reset"
                onClicked: {
                    Config.reset("appearance", ["border", "borderSpin", "borderSize", "gaps"])
                    Config.reset("windows", ["titleBars", "inactiveOpacity", "dimInactive", "dimStrength"])
                }
            }
        }
    }
}
