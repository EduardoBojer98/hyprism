pragma Singleton
import Quickshell
import QtQuick

// Design tokens for every shell surface. macOS-style smoked glass (neutral grey tint, bright rim)
// over Hyprland blur, Catppuccin Macchiato accents. The user-facing knobs live in Config.appearance; everything here derives
// from them, so changing one option restyles the whole desktop live. ThemeSync.qml pushes the
// same values to Hyprland, hyprlock, GTK and Qt.
Singleton {
    readonly property var a: Config.appearance

    // ---- palette (Catppuccin Macchiato) ------------------------------------------------------
    readonly property var macchiato: ({
        rosewater: "#f4dbd6", flamingo: "#f0c6c6", pink: "#f5bde6", mauve: "#c6a0f6", red: "#ed8796",
        maroon: "#ee99a0", peach: "#f5a97f", yellow: "#eed49f", green: "#a6da95", teal: "#8bd5ca",
        sky: "#91d7e3", sapphire: "#7dc4e4", blue: "#8aadf4", lavender: "#b7bdf8",
        text: "#cad3f5", subtext1: "#b8c0e0", overlay0: "#6e738d", surface0: "#363a4f",
        base: "#24273a", mantle: "#1e2030", crust: "#181926"
    })

    // ---- colour roles ---------------------------------------------------------------------------
    readonly property real glassAlpha: a.glassOpacity
    // neutral smoke, no blue cast: the blurred wallpaper shows through, white text stays readable
    readonly property color glass: Qt.rgba(0.22, 0.22, 0.24, glassAlpha * 0.75)       // bar, dock, OSD
    readonly property color glassStrong: Qt.rgba(0.17, 0.17, 0.19, Math.min(0.88, glassAlpha + 0.15)) // panels with text
    readonly property color stroke: Qt.rgba(1, 1, 1, 0.16)                             // the white rim
    readonly property color strokeStrong: Qt.rgba(1, 1, 1, 0.28)
    readonly property color highlight: Qt.rgba(1, 1, 1, 0.12)
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.18)

    readonly property color fill: Qt.rgba(1, 1, 1, 0.07)          // idle control / track
    readonly property color fillHover: Qt.rgba(1, 1, 1, 0.12)
    readonly property color fillActive: Qt.rgba(1, 1, 1, 0.18)

    readonly property color text: "#eceffa"
    readonly property color subtext: Qt.rgba(0.93, 0.94, 0.98, 0.64)
    readonly property color muted: Qt.rgba(1, 1, 1, 0.40)
    readonly property color accent: macchiato[a.accent] ?? macchiato.blue
    readonly property color accent2: macchiato.lavender
    readonly property color accentWash: Qt.rgba(accent.r, accent.g, accent.b, 0.18)
    readonly property color accentText: "#0f1117"
    readonly property color success: macchiato.green
    readonly property color warning: macchiato.yellow
    readonly property color error: macchiato.red
    readonly property color green: success      // older names, kept for existing components
    readonly property color yellow: warning
    readonly property color peach: macchiato.peach
    readonly property color red: error

    // ---- type ----------------------------------------------------------------------------------
    readonly property string font: a.font
    readonly property string monoFont: "JetBrainsMono Nerd Font"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property real fontScale: a.fontScale
    readonly property int fontCaption: Math.round(11 * fontScale)
    readonly property int fontLabel: Math.round(12 * fontScale)
    readonly property int fontSize: Math.round(13 * fontScale)    // body
    readonly property int fontTitle: Math.round(15 * fontScale)
    readonly property int fontHeading: Math.round(20 * fontScale)
    readonly property int fontDisplay: Math.round(26 * fontScale)

    // ---- shape and space -------------------------------------------------------------------
    readonly property real radiusScale: a.radiusScale
    readonly property int radiusSmall: Math.round(8 * radiusScale)   // rows, tiles, keycaps
    readonly property int radius: Math.round(12 * radiusScale)        // default surface
    readonly property int radiusLarge: Math.round(14 * radiusScale)   // panels, launcher, dock
    readonly property int spaceXs: 4
    readonly property int spaceS: 8
    readonly property int spaceM: 12
    readonly property int spaceL: 16
    readonly property int spaceXl: 24
    readonly property int rowHeight: 38
    readonly property int controlHeight: 30
    readonly property int popupGap: 10               // distance from cursor / anchor

    // ---- icons -----------------------------------------------------------------------------------
    readonly property string iconTheme: a.iconTheme
    readonly property int iconSmall: 16
    readonly property int iconMedium: 22
    readonly property int iconLarge: 32
    readonly property int iconApp: 48

    // ---- depth -----------------------------------------------------------------------------------
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.32)
    readonly property real shadowBlur: 0.6
    readonly property int shadowOffset: 4

    // ---- motion ----------------------------------------------------------------------------------
    readonly property bool animate: a.animations
    readonly property int animFast: animate ? 140 : 0
    readonly property int anim: animate ? 220 : 0
    readonly property int animSlow: animate ? 600 : 0
    readonly property int easing: Easing.OutCubic
}
