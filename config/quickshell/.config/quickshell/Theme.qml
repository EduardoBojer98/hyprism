pragma Singleton
import Quickshell
import QtQuick

// Design tokens for every shell surface, all derived from the active rice (Rices.qml, picked with
// `rice NAME` or Settings > Rices). Components read Theme only, never Rices, so a rice switch
// restyles the whole desktop live. ThemeSync.qml carries the same rice to Hyprland, hyprlock, GTK,
// Ghostty and the wallpaper. Personal knobs on top: Config.appearance.fontScale and .animations.
Singleton {
    readonly property var a: Config.appearance
    readonly property var rice: Rices.resolve(a.rice, a.custom)   // the rice plus your adjustments
    readonly property var c: rice.colour
    readonly property bool light: !rice.dark

    // ---- colour ----------------------------------------------------------------------------------
    readonly property color base: c.ground                   // desktop / bar ground
    readonly property color text: c.text
    readonly property color subtext: c.muted
    readonly property color muted: c.faint
    readonly property color accent: c.accent
    readonly property color accent2: c.accent2
    readonly property color accentText: c.onAccent           // text on an accent fill
    readonly property color accentWash: Qt.alpha(accent, light ? 0.14 : 0.18)
    readonly property color success: c.ok
    readonly property color warning: c.warn
    readonly property color error: c.err
    readonly property color green: success                   // older names, kept for existing components
    readonly property color yellow: warning
    readonly property color red: error
    readonly property color peach: warning

    // ---- surfaces: solid tone steps, glass only where the rice is about glass ----------------------
    readonly property string material: rice.shape.material
    readonly property bool glassy: material === "glass"
    readonly property color surfaceColor: c.surface
    readonly property color glass: glassy ? Qt.alpha(c.surface, 0.78) : c.surface         // bar items, dock, OSD
    readonly property color glassStrong: glassy ? Qt.alpha(c.surface, 0.92) : c.surface   // panels with text
    readonly property color menu: c.surface                                                // menus, lists
    readonly property color raised: c.raised
    readonly property color sidebar: Qt.alpha(light ? "#000000" : "#000000", light ? 0.035 : 0.18)
    readonly property color stroke: c.line
    readonly property color strokeStrong: light ? Qt.darker(c.line, 1.25) : Qt.lighter(c.line, 1.5)
    readonly property color highlight: glassy ? Qt.rgba(1, 1, 1, 0.06) : "transparent"   // inner top rim on glass
    readonly property color scrim: Qt.rgba(0, 0, 0, light ? 0.18 : 0.42)
    readonly property int line: rice.shape.line                                           // panel border px
    function surface(tint) { return tint === "solid" ? menu : glass }

    readonly property color fill: Qt.alpha(c.text, light ? 0.06 : 0.07)        // idle control / track
    readonly property color fillHover: Qt.alpha(c.text, light ? 0.10 : 0.11)
    readonly property color fillActive: Qt.alpha(c.text, light ? 0.16 : 0.17)

    // toggles and slider fills: the accent
    readonly property color selected: accent
    readonly property color onSelected: accentText
    readonly property color thumb: light ? "#ffffff" : c.text
    readonly property color thumbText: c.ground
    function tinted(k, alpha) { return Qt.rgba(base.r * k, base.g * k, base.b * k, alpha) }
    function frosted(k, alpha) { return Qt.rgba(base.r + (1 - base.r) * k, base.g + (1 - base.g) * k, base.b + (1 - base.b) * k, alpha) }

    // ---- type --------------------------------------------------------------------------------------
    readonly property string font: rice.font.ui
    readonly property string displayFont: rice.font.display
    readonly property int displayWeight: rice.font.displayWeight
    readonly property string monoFont: rice.font.mono
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property real fontScale: a.fontScale
    readonly property int body: rice.font.size
    readonly property int fontCaption: Math.round((body - 2) * fontScale)
    readonly property int fontLabel: Math.round((body - 1) * fontScale)
    readonly property int fontSize: Math.round(body * fontScale)
    readonly property int fontTitle: Math.round((body + 2) * fontScale)
    readonly property int fontHeading: Math.round((body + 7) * fontScale)
    readonly property int fontDisplay: Math.round((body + 13) * fontScale)

    // ---- shape and space ---------------------------------------------------------------------------
    readonly property int radiusSmall: rice.shape.radiusSmall
    readonly property int radius: rice.shape.radius
    readonly property int radiusLarge: rice.shape.radius === 0 ? 0 : rice.shape.radius + 2
    readonly property real radiusScale: 1
    readonly property int spaceXs: 4
    readonly property int spaceS: 8
    readonly property int spaceM: 12
    readonly property int spaceL: 16
    readonly property int spaceXl: 24
    readonly property int rowHeight: 34
    readonly property int controlHeight: 28
    readonly property int popupGap: 8

    // ---- the bar: which edge it takes, and how much of it (popups keep clear of it) -----------------
    readonly property var bar: rice.bar
    readonly property string barEdge: bar.edge
    readonly property bool barVertical: barEdge === "left" || barEdge === "right"
    readonly property int barInset: ["pills", "island"].includes(bar.kind) ? 8 : 0
    readonly property int barHeight: bar.size + barInset               // thickness, whatever the edge
    // letterbox has a band at both ends
    readonly property int reserveTop: barEdge === "top" || bar.kind === "letterbox" ? barHeight : 0
    readonly property int reserveBottom: barEdge === "bottom" || bar.kind === "letterbox" ? barHeight : 0
    readonly property int reserveLeft: barEdge === "left" ? barHeight : 0
    readonly property int reserveRight: barEdge === "right" ? barHeight : 0

    // ---- icons ---------------------------------------------------------------------------------------
    readonly property string iconTheme: a.iconTheme
    readonly property int iconSmall: 16
    readonly property int iconMedium: 22
    readonly property int iconLarge: 32
    readonly property int iconApp: 48

    // ---- depth ---------------------------------------------------------------------------------------
    readonly property color shadow: Qt.rgba(0, 0, 0, light ? 0.16 : 0.38)
    readonly property real shadowBlur: rice.hypr.shadow === "soft" ? 0.6 : 0
    readonly property int shadowOffset: 4

    // ---- motion (Hyprland's own presets live in hypr/modules/animations.lua) ---------------------
    readonly property bool animate: a.animations
    readonly property real motionScale: ({ instant: 0.45, crisp: 0.7, snappy: 0.8, slam: 0.75, ease: 1, spring: 1.1, fade: 1.6 })[rice.hypr.motion] ?? 1
    readonly property int animFast: animate ? Math.round(120 * motionScale) : 0
    readonly property int anim: animate ? Math.round(200 * motionScale) : 0
    readonly property int animSlow: animate ? Math.round(600 * motionScale) : 0
    readonly property int easing: rice.hypr.motion === "spring" ? Easing.OutBack : rice.hypr.motion === "slam" ? Easing.OutExpo : Easing.OutCubic
}
