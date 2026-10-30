pragma Singleton
import Quickshell
import QtQuick

// Design tokens for every shell surface ("Graphite Glass"): frosted glass over Hyprland blur, dark
// graphite (default) or light. The user-facing knobs live in Config.appearance; everything here derives from them, so
// changing one option restyles the whole desktop live. ThemeSync.qml pushes the same values to
// Hyprland, hyprlock and GTK.
Singleton {
    readonly property var a: Config.appearance
    readonly property bool light: a.mode !== "dark"

    // ---- accents: a curated palette (deeper in light mode, softer-bright in dark), keyed by the
    // saved names; display names in accentNames. "custom" is Config.appearance.customAccent.
    readonly property var accents: light ? ({
        blue: "#2f6fe4", lavender: "#6a5fe0", mauve: "#9b51e0", pink: "#e0457b", peach: "#e8622c",
        yellow: "#c98a00", green: "#4f9a2f", mint: "#19a37a", teal: "#12968f", sky: "#2a8fd6",
        champagne: "#a8834a", silver: "#6b7280", red: "#e5484d", custom: a.customAccent
    }) : ({
        blue: "#5b9cff", lavender: "#8f86ff", mauve: "#c58af9", pink: "#ff7aa2", peach: "#ff8a5c",
        yellow: "#f7c85b", green: "#8fd16a", mint: "#5ee0b5", teal: "#3cc7c0", sky: "#7cc8ff",
        champagne: "#e2c08d", silver: "#b9c0cc", red: "#ff5f57", custom: a.customAccent
    })
    readonly property var accentNames: ({
        blue: "Azure", lavender: "Iris", mauve: "Orchid", pink: "Rose", peach: "Coral", yellow: "Amber",
        green: "Matcha", mint: "Mint", teal: "Lagoon", sky: "Glacier", champagne: "Champagne", silver: "Silver",
        custom: "Custom"
    })
    readonly property var macchiato: accents     // older name, kept for existing components

    // ---- dark tint: the base colour of the dark glass ------------------------------------------
    readonly property var tints: ({ midnight: [0.085, 0.095, 0.13], graphite: [0.11, 0.11, 0.12], mocha: [0.13, 0.11, 0.10] })
    readonly property var tint: tints[a.darkTint] ?? tints.midnight
    function tinted(k, alpha) { return Qt.rgba(tint[0] * k, tint[1] * k, tint[2] * k, alpha) }

    // ---- surfaces ------------------------------------------------------------------------------
    readonly property real glassAlpha: a.glassOpacity
    // light: white frost; dark: neutral smoke. Both let the blurred wallpaper through.
    readonly property color glass: light ? Qt.rgba(0.97, 0.97, 0.98, Math.min(0.92, glassAlpha + 0.25))
                                         : tinted(1.05, 0.28 + glassAlpha * 0.6)   // bar, dock, OSD
    readonly property color glassStrong: light ? Qt.rgba(0.98, 0.98, 0.99, Math.min(0.95, glassAlpha + 0.35))
                                               : tinted(0.82, Math.min(0.9, 0.5 + glassAlpha * 0.7)) // panels with text
    readonly property color menu: light ? Qt.rgba(0.99, 0.99, 1, 0.98) : tinted(0.95, 0.97)  // dropdown lists
    readonly property color sidebar: light ? Qt.rgba(0, 0, 0, 0.035) : Qt.rgba(0, 0, 0, 0.18)
    readonly property color stroke: light ? Qt.rgba(0, 0, 0, 0.09) : Qt.rgba(1, 1, 1, 0.10)    // hairline edge
    readonly property color strokeStrong: light ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(1, 1, 1, 0.22)
    readonly property color highlight: light ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.07) // inner top rim
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.18)

    readonly property color fill: light ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.06)    // idle control / track
    readonly property color fillHover: light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.10)
    readonly property color fillActive: light ? Qt.rgba(0, 0, 0, 0.13) : Qt.rgba(1, 1, 1, 0.16)

    readonly property color text: light ? "#1d1d1f" : "#f3f4f8"
    readonly property color subtext: light ? Qt.rgba(0, 0, 0, 0.58) : Qt.rgba(1, 1, 1, 0.62)
    readonly property color muted: light ? Qt.rgba(0, 0, 0, 0.38) : Qt.rgba(1, 1, 1, 0.40)
    readonly property color accent: accents[a.accent] ?? accents.blue
    readonly property color accent2: accents.lavender
    readonly property color accentWash: Qt.rgba(accent.r, accent.g, accent.b, light ? 0.14 : 0.2)
    // text on an accent fill: dark on light accents (by relative luminance), white otherwise
    readonly property color accentText: 0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b > 0.62 ? "#1d1d1f" : "#ffffff"
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
    readonly property int rowHeight: 34
    readonly property int controlHeight: 28
    readonly property int popupGap: 8                // distance from cursor / anchor

    // ---- icons -----------------------------------------------------------------------------------
    readonly property string iconTheme: a.iconTheme
    readonly property int iconSmall: 16
    readonly property int iconMedium: 22
    readonly property int iconLarge: 32
    readonly property int iconApp: 48

    // ---- depth -----------------------------------------------------------------------------------
    readonly property color shadow: Qt.rgba(0, 0, 0, light ? 0.16 : 0.38)
    readonly property real shadowBlur: 0.6
    readonly property int shadowOffset: 4

    // ---- motion ----------------------------------------------------------------------------------
    readonly property bool animate: a.animations
    readonly property int animFast: animate ? 120 : 0
    readonly property int anim: animate ? 200 : 0
    readonly property int animSlow: animate ? 600 : 0
    readonly property int easing: Easing.OutCubic
}
