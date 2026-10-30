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
            visible: !Theme.light
            label: "Dark tint"
            hint: "The colour of the dark glass"
            ConfigChoice { section: "appearance"; key: "darkTint"; values: ["midnight", "graphite", "mocha"]; labels: ["Midnight", "Graphite", "Mocha"] }
        }
        SettingRow {
            label: "Accent"
            hint: (Theme.accentNames[Config.appearance.accent] ?? "") + " · active items, toggles, selection, window borders"
            Flow {
                width: Math.min(13 * 30, 260)
                spacing: 6
                Repeater {
                    model: ["blue", "lavender", "mauve", "pink", "red", "peach", "yellow", "champagne", "green", "mint", "teal", "sky", "silver", "custom"]
                    Rectangle {
                        id: swatch
                        required property string modelData
                        readonly property bool chosen: Config.appearance.accent === modelData
                        width: 24; height: 24; radius: 12
                        color: Theme.accents[modelData]
                        border { color: chosen ? Theme.text : Theme.stroke; width: chosen ? 2 : 1 }
                        scale: swatchArea.containsMouse ? 1.12 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                        Text {   // the custom swatch is marked with a pencil
                            anchors.centerIn: parent
                            visible: swatch.modelData === "custom"
                            text: "\u{F03EB}"
                            color: 0.2126 * swatch.color.r + 0.7152 * swatch.color.g + 0.0722 * swatch.color.b > 0.6 ? "#1d1d1f" : "#ffffff"
                            font { family: Theme.iconFont; pixelSize: 12 }
                        }
                        MouseArea { id: swatchArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Config.set("appearance", "accent", swatch.modelData) }
                    }
                }
            }
        }
        SettingRow {
            visible: Config.appearance.accent === "custom"
            label: "Custom colour"
            hint: hexError !== "" ? hexError : "Drag for the hue, or type a hex colour"
            property string hexError: ""
            Item {
                width: 150; height: 24
                Rectangle {   // hue strip; click or drag to pick (saturation and brightness stay pleasant)
                    id: hues
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width; height: 12; radius: 6
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.hsva(0.0, 0.62, 0.98, 1) }
                        GradientStop { position: 0.17; color: Qt.hsva(0.17, 0.62, 0.98, 1) }
                        GradientStop { position: 0.33; color: Qt.hsva(0.33, 0.62, 0.98, 1) }
                        GradientStop { position: 0.5; color: Qt.hsva(0.5, 0.62, 0.98, 1) }
                        GradientStop { position: 0.67; color: Qt.hsva(0.67, 0.62, 0.98, 1) }
                        GradientStop { position: 0.83; color: Qt.hsva(0.83, 0.62, 0.98, 1) }
                        GradientStop { position: 1.0; color: Qt.hsva(1.0, 0.62, 0.98, 1) }
                    }
                    Rectangle {
                        x: Math.max(0, Theme.accent.hsvHue) * (hues.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 8
                        color: Theme.accent
                        border { color: "#ffffff"; width: 2 }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function pick(x) {
                        const c = Qt.hsva(Math.max(0, Math.min(0.999, x / width)), 0.62, 0.98, 1)
                        Config.set("appearance", "customAccent", c.toString().slice(0, 7))
                    }
                    onPressed: mouse => pick(mouse.x)
                    onPositionChanged: mouse => { if (pressed) pick(mouse.x) }
                }
            }
            TextField {
                width: 96
                text: Config.appearance.customAccent
                onAccepted: parent.parent.hexError = Config.set("appearance", "customAccent", text.trim().startsWith("#") ? text.trim() : "#" + text.trim())
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
