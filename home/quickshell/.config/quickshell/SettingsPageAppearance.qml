import QtQuick
import QtQuick.Layouts

// Appearance & Themes: the knobs every shell surface derives its tokens from (Theme.qml).
// Applied live; the accent and corners also reach window borders, the lock screen and GTK apps.
ColumnLayout {
    spacing: 20

    SettingGroup {
        title: "Colour"
        SettingRow {
            label: "Appearance"
            hint: "Light or dark glass for the bar, panels and Settings"
            ConfigChoice { section: "appearance"; key: "mode"; values: ["light", "dark"]; labels: ["Light", "Dark"] }
        }
        SettingRow {
            label: "Accent"
            hint: "Active items, toggles, selection, window borders"
            Row {
                spacing: 6
                Repeater {
                    model: ["blue", "lavender", "mauve", "pink", "peach", "yellow", "green", "teal", "sky"]
                    Rectangle {
                        required property string modelData
                        width: 24; height: 24; radius: 12
                        color: Theme.accents[modelData]
                        border { color: Config.appearance.accent === modelData ? Theme.text : "transparent"; width: 2 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Config.set("appearance", "accent", parent.modelData) }
                    }
                }
            }
        }
        SettingRow {
            label: "Glass"
            hint: "How much of the blurred background shows through panels"
            ConfigChoice { section: "appearance"; key: "glassOpacity"; values: [0.35, 0.55, 0.8]; labels: ["Clear", "Balanced", "Solid"] }
        }
    }

    SettingGroup {
        title: "Window border"
        SettingRow {
            label: "Focused window"
            hint: "The border around the window you're working in"
            ConfigChoice { section: "appearance"; key: "border"; values: ["rainbow", "accent"]; labels: ["Rainbow", "Accent colour"] }
        }
        SettingRow {
            visible: Config.appearance.border === "rainbow"
            label: "Rainbow rotation"
            hint: "Still when animations are off"
            ConfigChoice { section: "appearance"; key: "borderSpin"; values: [0, 120, 60, 25]; labels: ["Still", "Slow", "Medium", "Fast"] }
        }
        SettingRow {
            label: "Thickness"
            ConfigChoice { section: "appearance"; key: "borderSize"; values: [1, 2, 3]; labels: ["Thin", "Medium", "Thick"] }
        }
    }

    SettingGroup {
        title: "Shape and text"
        SettingRow {
            label: "Corners"
            ConfigChoice { section: "appearance"; key: "radiusScale"; values: [0, 0.6, 1, 1.4]; labels: ["Square", "Subtle", "Round", "Extra"] }
        }
        SettingRow {
            label: "Text size"
            ConfigChoice { section: "appearance"; key: "fontScale"; values: [0.92, 1, 1.1]; labels: ["Small", "Default", "Large"] }
        }
        SettingRow {
            label: "Font"
            ConfigChoice { section: "appearance"; key: "font"; values: ["Inter", "Cantarell", "Noto Sans"]; labels: ["Inter", "Cantarell", "Noto Sans"] }
        }
        SettingRow {
            label: "Animations"
            hint: "Off makes every panel open and move instantly"
            ConfigToggle { section: "appearance"; key: "animations" }
        }
    }

    ResetGroup { sections: ["appearance"] }
}
