pragma Singleton
import Quickshell
import QtQuick

// Design tokens for every shell surface ("Graphite Glass"): frosted glass over Hyprland blur, dark
// graphite (default) or light. The user-facing knobs live in Config.appearance; everything here derives from them, so
// changing one option restyles the whole desktop live. ThemeSync.qml pushes the same values to
// Hyprland, hyprlock and GTK.
Singleton {
    readonly property var a: Config.appearance
    readonly property bool light: a.mode === "auto" ? NightLight.daytime : a.mode !== "dark"

    // ---- accents: a curated palette (deeper in light mode, softer-bright in dark), keyed by the
    // saved names; display names in accentNames. "custom" is Config.appearance.customAccent, "theme" the chosen theme's own.
    readonly property var accents: light ? ({
        blue: "#2f6fe4", lavender: "#6a5fe0", mauve: "#9b51e0", pink: "#e0457b", peach: "#e8622c",
        yellow: "#c98a00", green: "#4f9a2f", mint: "#19a37a", teal: "#12968f", sky: "#2a8fd6",
        champagne: "#a8834a", silver: "#6b7280", red: "#e5484d", custom: a.customAccent, theme: pal[2]
    }) : ({
        blue: "#5b9cff", lavender: "#8f86ff", mauve: "#c58af9", pink: "#ff7aa2", peach: "#ff8a5c",
        yellow: "#f7c85b", green: "#8fd16a", mint: "#5ee0b5", teal: "#3cc7c0", sky: "#7cc8ff",
        champagne: "#e2c08d", silver: "#b9c0cc", red: "#ff5f57", custom: a.customAccent, theme: pal[2]
    })
    readonly property var accentNames: ({
        blue: "Azure", lavender: "Iris", mauve: "Orchid", pink: "Rose", peach: "Coral", yellow: "Amber",
        green: "Matcha", mint: "Mint", teal: "Lagoon", sky: "Glacier", champagne: "Champagne", silver: "Silver",
        red: "Ruby", custom: "Custom", theme: th.name + " accent"
    })
    readonly property var macchiato: accents     // older name, kept for existing components

    // ---- themes: the base colour of the glass, the text and the theme's own accent, for dark and
    // light ([base, text, accent]); term is the matching Ghostty theme [dark, light] (ThemeSync).
    readonly property var themes: ({
        midnight:    { name: "Midnight", dark: ["#161821", "#f3f4f8", "#5b9cff"], light: ["#f7f7fa", "#1d1d1f", "#2f6fe4"], term: ["Catppuccin Macchiato", "Catppuccin Latte"] },
        graphite:    { name: "Graphite", dark: ["#1c1c1f", "#f3f4f8", "#b9c0cc"], light: ["#f5f5f6", "#1d1d1f", "#6b7280"], term: ["Catppuccin Macchiato", "Catppuccin Latte"] },
        cocoa:       { name: "Cocoa", dark: ["#211c1a", "#f5efe9", "#e2c08d"], light: ["#faf6f2", "#2a2220", "#a8834a"], term: ["Catppuccin Macchiato", "Catppuccin Latte"] },
        catppuccin:  { name: "Catppuccin", dark: ["#1e1e2e", "#cdd6f4", "#cba6f7"], light: ["#eff1f5", "#4c4f69", "#8839ef"], term: ["Catppuccin Mocha", "Catppuccin Latte"] },
        tokyonight:  { name: "Tokyo Night", dark: ["#1a1b26", "#c0caf5", "#7aa2f7"], light: ["#e1e2e7", "#343b58", "#2e7de9"], term: ["TokyoNight", "TokyoNight Day"] },
        dracula:     { name: "Dracula", dark: ["#282a36", "#f8f8f2", "#bd93f9"], light: ["#fffbeb", "#1f1f1f", "#644ac9"], term: ["Dracula", "Atom One Light"] },
        nord:        { name: "Nord", dark: ["#2e3440", "#eceff4", "#88c0d0"], light: ["#eceff4", "#2e3440", "#5e81ac"], term: ["Nord", "Nord Light"] },
        gruvbox:     { name: "Gruvbox", dark: ["#282828", "#ebdbb2", "#fe8019"], light: ["#fbf1c7", "#3c3836", "#af3a03"], term: ["Gruvbox Dark", "Gruvbox Light"] },
        rosepine:    { name: "Rosé Pine", dark: ["#191724", "#e0def4", "#c4a7e7"], light: ["#faf4ed", "#575279", "#907aa9"], term: ["Rose Pine", "Rose Pine Dawn"] },
        everforest:  { name: "Everforest", dark: ["#2d353b", "#d3c6aa", "#a7c080"], light: ["#fdf6e3", "#5c6a72", "#8da101"], term: ["Everforest Dark Med", "Everforest Light Med"] },
        kanagawa:    { name: "Kanagawa", dark: ["#1f1f28", "#dcd7ba", "#7e9cd8"], light: ["#f2ecbc", "#545464", "#4d699b"], term: ["Kanagawa Wave", "Kanagawa Lotus"] },
        onedark:     { name: "One Dark", dark: ["#282c34", "#abb2bf", "#61afef"], light: ["#fafafa", "#383a42", "#4078f2"], term: ["Atom One Dark", "Atom One Light"] },
        solarized:   { name: "Solarized", dark: ["#002b36", "#93a1a1", "#268bd2"], light: ["#fdf6e3", "#586e75", "#268bd2"], term: ["iTerm2 Solarized Dark", "iTerm2 Solarized Light"] },
        // Neon themes (docs/DESIGN.md): near-black base, a signature accent plus a second one for the
        // window-border gradient and glow, [base, text, accent, accent2]. status = [success, warning, error],
        // chosen so they never read as an accent. Terminal themes ship in ghostty/themes/.
        radioactive: { name: "Radioactive", dark: ["#0b0d0a", "#eef2e6", "#e4ff1a", "#00e5ff"], light: ["#f6f7f0", "#15170f", "#5f6f00", "#00788a"],
                       status: ["#4ade80", "#ff9f1c", "#ff4d6d"], term: ["Radioactive", "Atom One Light"] },
        molten:      { name: "Molten", dark: ["#100b0a", "#f7eee8", "#ff6b1a", "#ff3dbb"], light: ["#fbf6f3", "#1e1410", "#c2410c", "#b0127f"],
                       status: ["#34d399", "#ffd60a", "#ff4040"], term: ["Molten", "Atom One Light"] },
        cyber:       { name: "Cyber", dark: ["#0a0b14", "#eef0ff", "#00e5ff", "#ff2bd6"], light: ["#f3f5fb", "#0f1120", "#0077a3", "#b0129a"],
                       status: ["#3ee07f", "#ffc53d", "#ff4d5e"], term: ["Cyber", "Atom One Light"] }
    })
    readonly property var themeIds: Object.keys(themes)
    readonly property var th: themes[a.theme] ?? themes.midnight
    readonly property var pal: light ? th.light : th.dark
    readonly property color base: pal[0]
    function tinted(k, alpha) { return Qt.rgba(base.r * k, base.g * k, base.b * k, alpha) }                              // darker shades of the base
    function frosted(k, alpha) { return Qt.rgba(base.r + (1 - base.r) * k, base.g + (1 - base.g) * k, base.b + (1 - base.b) * k, alpha) } // toward white

    // ---- surfaces ------------------------------------------------------------------------------
    readonly property real glassAlpha: a.glassOpacity
    // light: white frost; dark: neutral smoke. Both let the blurred wallpaper through.
    readonly property color glass: light ? frosted(0, Math.min(0.92, glassAlpha + 0.25))
                                         : tinted(1.05, 0.28 + glassAlpha * 0.6)   // bar, dock, OSD
    readonly property color glassStrong: light ? frosted(0.35, Math.min(0.95, glassAlpha + 0.35))
                                               : tinted(0.82, Math.min(0.9, 0.5 + glassAlpha * 0.7)) // panels with text
    // the menu bar's real size: its height plus the gap the floating shapes keep from the screen edge
    // (Bar.qml draws it; popups that open from it sit just past it)
    readonly property int barInset: ["floating", "islands", "compact"].includes(Config.bar.style) ? 6 : 0
    readonly property int barHeight: Config.bar.size + barInset
    // a bar or dock surface: "glass" (frosted), "solid" (opaque) or "accent" (glass washed with the accent)
    function surface(tint) { return tint === "solid" ? menu : tint === "accent" ? Qt.tint(glass, Qt.rgba(accent.r, accent.g, accent.b, light ? 0.25 : 0.38)) : glass }
    readonly property color menu: light ? frosted(0.7, 0.98) : tinted(0.95, 0.97)  // dropdown lists
    readonly property color sidebar: light ? Qt.rgba(0, 0, 0, 0.035) : Qt.rgba(0, 0, 0, 0.18)
    readonly property color stroke: light ? Qt.rgba(0, 0, 0, 0.09) : Qt.rgba(1, 1, 1, 0.10)    // hairline edge
    readonly property color strokeStrong: light ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(1, 1, 1, 0.22)
    readonly property color highlight: light ? Qt.rgba(1, 1, 1, 0.55) : Qt.rgba(1, 1, 1, 0.07) // inner top rim
    readonly property color scrim: Qt.rgba(0, 0, 0, 0.18)

    readonly property color fill: light ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(1, 1, 1, 0.06)    // idle control / track
    readonly property color fillHover: light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.10)
    readonly property color fillActive: light ? Qt.rgba(0, 0, 0, 0.13) : Qt.rgba(1, 1, 1, 0.16)

    readonly property color text: pal[1]
    readonly property color subtext: Qt.rgba(text.r, text.g, text.b, light ? 0.66 : 0.64)
    readonly property color muted: Qt.rgba(text.r, text.g, text.b, light ? 0.46 : 0.42)
    readonly property color accent: accents[a.accent] ?? accents.blue
    readonly property color accent2: pal[3] ?? accents.lavender   // second accent: border gradient end, glow
    readonly property color accentWash: Qt.rgba(accent.r, accent.g, accent.b, light ? 0.14 : 0.2)
    // text on an accent fill: dark on light accents (by relative luminance), white otherwise
    readonly property color accentText: 0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b > 0.62 ? "#1d1d1f" : "#ffffff"
    // "on" state of toggles, slider fills: accent in light, bright white in dark (like macOS)
    readonly property color selected: light ? accent : text
    readonly property color onSelected: light ? accentText : accent
    readonly property color thumb: light ? "#ffffff" : "#f2f4fa"      // segmented-control knob
    readonly property color thumbText: "#1d1d1f"
    // status colours: the theme's own (neon themes keep them apart from the accents), else the palette's
    readonly property var status: !light && th.status ? th.status : [accents.green, light ? "#c27c00" : accents.yellow, accents.red]
    readonly property color success: status[0]
    readonly property color warning: status[1]   // readable on white in light mode
    readonly property color error: status[2]
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
