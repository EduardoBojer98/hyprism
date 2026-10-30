pragma Singleton
import Quickshell
import QtQuick

// "Liquid glass", dark: near-black translucent surfaces (Hyprland blurs behind them), hairline
// white strokes and a soft top highlight. Accents are Catppuccin Macchiato blue / lavender.
Singleton {
    // Glass surfaces: tint over the blurred background
    readonly property color glass: Qt.rgba(0.05, 0.05, 0.08, 0.42)        // bar, dock, OSD
    readonly property color glassStrong: Qt.rgba(0.05, 0.05, 0.08, 0.70)  // panels with lots of text
    readonly property color stroke: Qt.rgba(1, 1, 1, 0.10)
    readonly property color highlight: Qt.rgba(1, 1, 1, 0.07)

    // Controls on glass
    readonly property color fill: Qt.rgba(1, 1, 1, 0.07)        // idle tile / track
    readonly property color fillHover: Qt.rgba(1, 1, 1, 0.12)
    readonly property color fillActive: Qt.rgba(1, 1, 1, 0.18)

    readonly property color text: "#eceffa"
    readonly property color subtext: Qt.rgba(0.93, 0.94, 0.98, 0.64)  // neutral, no blue cast
    readonly property color muted: "#6e738d"
    readonly property color accent: "#8aadf4"
    readonly property color accent2: "#b7bdf8"
    readonly property color accentText: "#0f1117"
    readonly property color green: "#a6da95"
    readonly property color yellow: "#eed49f"
    readonly property color peach: "#f5a97f"
    readonly property color red: "#ed8796"

    readonly property string font: "Inter"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int radius: 16
    readonly property int radiusLarge: 22
    readonly property int anim: 220
}
