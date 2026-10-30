import QtQuick
import QtQuick.Layouts

// Appearance & Themes: the knobs every shell surface derives its tokens from (Theme.qml).
// Applied live; the accent and corners also reach window borders, the lock screen and GTK apps.
ColumnLayout {
    spacing: 20

    SettingGroup {
        title: "Colour"
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
                        color: Theme.macchiato[modelData]
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
