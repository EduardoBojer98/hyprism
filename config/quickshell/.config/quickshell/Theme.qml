pragma Singleton
import Quickshell
import QtQuick

// Design tokens for every shell surface, all derived from the active theme (Themes.qml, picked with
// `theme NAME` or Settings > Themes). Components read Theme only, never Themes, so a theme switch
// restyles the whole desktop live. ThemeSync.qml carries the same theme to Hyprland, hyprlock, GTK,
// Ghostty and the wallpaper. Personal knobs on top: Config.appearance.fontScale and .animations.
Singleton {
    readonly property var a: Config.appearance
    readonly property var current: Themes.resolve(a.theme, a.custom, a.mode)   // the theme plus your adjustments
    readonly property var c: current.colour
    readonly property bool light: !current.dark

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

    // ---- surfaces: solid tone steps, glass only where the theme is about glass ----------------------
    readonly property string material: current.shape.material
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
    readonly property int line: current.shape.line                                           // panel border px
    function surface(tint) { return tint === "solid" ? menu : glass }

    readonly property color fill: Qt.alpha(c.text, light ? 0.06 : 0.07)        // idle control / track
    readonly property color fillHover: Qt.alpha(c.text, light ? 0.10 : 0.11)
    readonly property color fillActive: Qt.alpha(c.text, light ? 0.16 : 0.17)

    // toggles and slider fills: the accent
    readonly property color selected: accent
    readonly property color onSelected: accentText
    // Control Center tiles that are on: a solid accent block, or (popup.tiles "wash") an accent tint
    // with an accent icon, so glass stays glass
    readonly property bool washTiles: (current.popup.tiles ?? "solid") === "wash"
    readonly property color tileOn: washTiles ? Qt.alpha(accent, light ? 0.18 : 0.24) : accent
    readonly property color tileOnText: washTiles ? text : accentText
    readonly property color tileOnIcon: washTiles ? accent : accentText
    readonly property color tileOnBorder: washTiles ? Qt.alpha(accent, 0.55) : "transparent"
    readonly property color thumb: light ? "#ffffff" : c.text
    readonly property color thumbText: light ? c.text : c.ground   // text on a thumb: white thumbs in light themes
    function tinted(k, alpha) { return Qt.rgba(base.r * k, base.g * k, base.b * k, alpha) }
    function frosted(k, alpha) { return Qt.rgba(base.r + (1 - base.r) * k, base.g + (1 - base.g) * k, base.b + (1 - base.b) * k, alpha) }

    // ---- type --------------------------------------------------------------------------------------
    readonly property string font: current.font.ui
    readonly property string displayFont: current.font.display
    readonly property int displayWeight: current.font.displayWeight
    readonly property string monoFont: current.font.mono
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property real fontScale: a.fontScale
    readonly property int body: current.font.size
    readonly property int fontCaption: Math.round((body - 2) * fontScale)
    readonly property int fontLabel: Math.round((body - 1) * fontScale)
    readonly property int fontSize: Math.round(body * fontScale)
    readonly property int fontTitle: Math.round((body + 2) * fontScale)
    readonly property int fontHeading: Math.round((body + 7) * fontScale)
    readonly property int fontDisplay: Math.round((body + 13) * fontScale)

    // ---- shape and space ---------------------------------------------------------------------------
    readonly property int radiusSmall: current.shape.radiusSmall
    readonly property int radius: current.shape.radius
    readonly property int radiusLarge: current.shape.radius === 0 ? 0 : current.shape.radius + 2
    readonly property real radiusScale: 1
    readonly property int spaceXs: 4
    readonly property int spaceS: 8
    readonly property int spaceM: 12
    readonly property int spaceL: 16
    readonly property int spaceXl: 24
    readonly property int rowHeight: 34
    readonly property int controlHeight: 28
    readonly property int popupGap: 8

    // ---- the bar: the theme's own, with Settings > Menu Bar on top -------------------------------------
    readonly property var cb: Config.bar
    readonly property var barStyle: current.bar                             // fill, line, voice, ws, clock, decor …
    readonly property string barEdge: barStyle.edge                         // per theme: Themes.resolve applies Settings
    readonly property bool barVertical: barEdge === "left" || barEdge === "right"
    readonly property int barSize: barStyle.size
    readonly property bool barFloating: barStyle.floating
    readonly property int barMargin: barFloating ? cb.margin : 0            // gap to the screen edge (and along it)
    // the dock inside the bar is its "apps" item: in the middle unless placed, and only while the dock is there
    readonly property var barLayout: {
        const l = { start: Array.from(barStyle.start), center: Array.from(barStyle.center), end: Array.from(barStyle.end) }
        if (!dockInBar) for (const k of ["start", "center", "end"]) l[k] = l[k].filter(i => i !== "apps")
        else if (!l.start.concat(l.center, l.end).includes("apps")) l.center.unshift("apps")
        return l
    }
    readonly property int barHeight: barSize + barMargin                   // room the bar takes from the screen
    readonly property color barInk: barStyle.fill === "ink" ? base : text    // text on the bar's own ground
    function barShownOn(screen) { return !cb.hiddenOn.includes(screen?.name ?? "") }

    // ---- the dock: every theme has one; Settings > Dock places it ----------------------------------------
    readonly property var dockStyle: current.dock
    // where it goes: the theme's own edge by default, and inside the bar when that is the bar's edge too
    readonly property string dockMode: dockStyle.edge === barEdge ? "bar" : dockStyle.edge
    readonly property bool dockInBar: dockMode === "bar" && Config.dock.enabled
    readonly property string dockEdge: dockInBar ? barEdge : dockMode
    readonly property bool dockVertical: dockEdge === "left" || dockEdge === "right"
    readonly property int dockPad: ({ compact: 5, regular: 8, roomy: 12 })[Config.dock.size] ?? 8
    readonly property int dockLift: dockStyle.shape === "pill" || dockStyle.shape === "tile" ? 8 : 6   // gap to the edge
    readonly property int dockThickness: Config.dock.iconSize + dockPad * 2 + 8                      // icon + padding + marks
    readonly property bool dockReserves: Config.dock.enabled && !dockInBar && !Config.dock.autoHide
    function dockShownOn(screen) { return Config.dock.enabled && !dockInBar && !Config.dock.hiddenOn.includes(screen?.name ?? "") }

    // room taken on each side by the bar and a dock that doesn't hide (popups and banners keep clear)
    function reserve(side) {
        return (barEdge === side ? barHeight : 0) + (dockReserves && dockEdge === side ? dockThickness + dockLift : 0)
    }
    readonly property int reserveTop: reserve("top")
    readonly property int reserveBottom: reserve("bottom")
    readonly property int reserveLeft: reserve("left")
    readonly property int reserveRight: reserve("right")

    // ---- icons ---------------------------------------------------------------------------------------
    readonly property string iconTheme: a.iconTheme
    readonly property int iconSmall: 16
    readonly property int iconMedium: 22
    readonly property int iconLarge: 32
    readonly property int iconApp: 48

    // ---- depth ---------------------------------------------------------------------------------------
    readonly property color shadow: Qt.rgba(0, 0, 0, light ? 0.16 : 0.38)
    readonly property string depth: current.popup.depth                   // soft | hard | none (Panel.qml)
    readonly property real shadowBlur: depth === "soft" ? 0.6 : 0
    readonly property int shadowOffset: 4

    // ---- motion: the theme's character (Themes.qml motion), or less of it (Settings > Themes) -----------
    //   full     the theme's own: enter / exit times, its curve, travel from the trigger side, start scale
    //   reduced  short fades only, nothing travels or scales (Hyprland: quick fades)
    //   off      instant
    readonly property string motionLevel: a.motion
    readonly property bool animate: motionLevel !== "off"
    readonly property bool moves: motionLevel === "full"
    readonly property var m: current.motion
    readonly property int enter: motionLevel === "full" ? m.enter : motionLevel === "reduced" ? 90 : 0
    readonly property int exit: motionLevel === "full" ? m.exit : motionLevel === "reduced" ? 60 : 0
    readonly property var curve: m.curve.concat([1, 1])                    // for easing.bezierCurve
    readonly property int travel: moves ? m.travel : 0
    readonly property real startScale: moves ? m.scale : 1
    readonly property real pressScale: moves ? m.press : 1
    // small state changes (hover, colour, a toggle): short and the same feel everywhere
    readonly property int animFast: animate ? Math.min(120, Math.max(60, m.enter / 2)) : 0
    readonly property int anim: animate ? Math.min(220, m.enter) : 0
    readonly property int animSlow: animate ? m.enter * 2 : 0
    readonly property int easing: Easing.OutCubic
}
