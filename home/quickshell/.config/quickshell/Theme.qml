pragma Singleton
import Quickshell
import QtQuick

// Design tokens for every shell surface: frosted glass over Hyprland blur, light (default) or
// dark. The user-facing knobs live in Config.appearance; everything here derives from them, so
// changing one option restyles the whole desktop live. ThemeSync.qml pushes the same values to
// Hyprland, hyprlock and GTK.
Singleton {
    readonly property var a: Config.appearance
    readonly property bool light: a.mode !== "dark"

    // ---- accents: Apple's system colours (light / dark variants), keyed by the saved names --------
    readonly property var accents: light ? ({
        blue: "#007aff", lavender: "#5856d6", mauve: "#af52de", pink: "#ff2d55", peach: "#ff9500",
        yellow: "#ffcc00", green: "#34c759", teal: "#30b0c7", sky: "#32ade6", red: "#ff3b30"
    }) : ({
        blue: "#0a84ff", lavender: "#5e5ce6", mauve: "#bf5af2", pink: "#ff375f", peach: "#ff9f0a",
        yellow: "#ffd60a", green: "#30d158", teal: "#40c8e0", sky: "#64d2ff", red: "#ff453a"
    })
    readonly property var macchiato: accents     // older name, kept for existing components

    // ---- surfaces ------------------------------------------------------------------------------
    readonly property real glassAlpha: a.glassOpacity
    // light: white frost; dark: neutral smoke. Both let the blurred wallpaper through.
    readonly property color glass: light ? Qt.rgba(0.97, 0.97, 0.98, Math.min(0.92, glassAlpha + 0.25))
                                         : Qt.rgba(0.22, 0.22, 0.24, glassAlpha * 0.75)      // bar, dock, OSD
    readonly property color glassStrong: light ? Qt.rgba(0.98, 0.98, 0.99, Math.min(0.95, glassAlpha + 0.35))
                                               : Qt.rgba(0.17, 0.17, 0.19, Math.min(0.88, glassAlpha + 0.15)) // panels with text
    readonly property color menu: light ? Qt.rgba(0.99, 0.99, 1, 0.98) : Qt.rgba(0.11, 0.11, 0.12, 0.97)  // dropdown lists
    readonly property color sidebar: light ? Qt.rgba(0, 0, 0, 0.035) : Qt.rgba(0, 0, 0, 0.18)
    readonly property color stroke: light ? Qt.rgba(0, 0, 0, 0.09) : Qt.rgba(1, 1, 1, 0.16)    // hairline edge
    readonly property color strokeStrong: light ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(1, 1, 1, 0.28)
    readonly property color highlight: light ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.12) // inner top rim
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.18)

    readonly property color fill: light ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.07)    // idle control / track
    readonly property color fillHover: light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.12)
    readonly property color fillActive: light ? Qt.rgba(0, 0, 0, 0.13) : Qt.rgba(1, 1, 1, 0.18)

    readonly property color text: light ? "#1d1d1f" : "#f2f2f7"
    readonly property color subtext: light ? Qt.rgba(0, 0, 0, 0.58) : Qt.rgba(1, 1, 1, 0.64)
    readonly property color muted: light ? Qt.rgba(0, 0, 0, 0.38) : Qt.rgba(1, 1, 1, 0.40)
    readonly property color accent: accents[a.accent] ?? accents.blue
    readonly property color accent2: accents.lavender
    readonly property color accentWash: Qt.rgba(accent.r, accent.g, accent.b, light ? 0.14 : 0.2)
    // text on an accent fill: dark on yellow, white otherwise
    readonly property color accentText: a.accent === "yellow" ? "#1d1d1f" : "#ffffff"
    // "on" state of toggles, slider fills: accent in light, bright white in dark (like macOS)
    readonly property color selected: light ? accent : "#f2f4fa"
    readonly property color onSelected: light ? accentText : accent
    readonly property color thumb: light ? "#ffffff" : "#f2f4fa"      // segmented-control knob
    readonly property color thumbText: "#1d1d1f"
    readonly property color success: accents.green
    readonly property color warning: light ? "#c27c00" : accents.yellow   // readable on white
    readonly property color error: accents.red
    readonly property color green: success      // older names, kept for existing components
    readonly property color yellow: warning
    readonly property color peach: accents.peach
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
    readonly property color shadow: Qt.rgba(0, 0, 0, light ? 0.18 : 0.32)
    readonly property real shadowBlur: 0.6
    readonly property int shadowOffset: 4

    // ---- motion ----------------------------------------------------------------------------------
    readonly property bool animate: a.animations
    readonly property int animFast: animate ? 140 : 0
    readonly property int anim: animate ? 220 : 0
    readonly property int animSlow: animate ? 600 : 0
    readonly property int easing: Easing.OutCubic
}
