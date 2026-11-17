pragma Singleton
import Quickshell
import QtQuick

// Design tokens for every shell surface, all derived from the active theme (Themes.qml, picked with
// `theme NAME` or Settings > Themes). Components read Theme only, never Themes, so a theme switch
// restyles the whole desktop live. ThemeSync.qml carries the same theme to Hyprland, hyprlock, GTK,
// Ghostty and the wallpaper. Personal knobs on top: Config.appearance.fontScale and .animations.
Singleton {
    readonly property var a: Config.appearance
    readonly property var current: Themes.resolve(a.theme, a.custom, a.mode, Config.bar.layout)   // the theme, your adjustments, and your one bar layout
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
    readonly property color errorText: Themes.textOn(c.err, c)   // text on an error fill (badges)
    // an accent that reads as "danger" (red themes): safe things then use ink instead of the accent
    readonly property bool accentLikeError: Math.min(Math.abs(accent.hslHue - error.hslHue), 1 - Math.abs(accent.hslHue - error.hslHue)) < 0.06
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
    readonly property color sidebar: Qt.alpha("#000000", light ? 0.035 : 0.18)
    readonly property color stroke: c.line
    readonly property color strokeStrong: light ? Qt.darker(c.line, 1.25) : Qt.lighter(c.line, 1.5)
    readonly property color highlight: glassy ? Qt.rgba(1, 1, 1, 0.06) : "transparent"   // inner top rim on glass
    readonly property color backdrop: light ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.42)   // behind full-screen modes
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
    readonly property color tileOn: washTiles ? Qt.alpha(accent, light ? 0.26 : 0.40) : accent
    readonly property color tileOnText: washTiles ? text : accentText
    readonly property color tileOnIcon: washTiles ? accent : accentText
    readonly property color tileOnBorder: washTiles ? Qt.alpha(accent, 0.85) : "transparent"
    // themes with a solid "inverse" selection (Poster, Monolith) show a picked segment in reverse video:
    // Monolith in the accent, Poster in ink on paper
    readonly property bool selectInverse: current.launcher.select === "inverse"
    readonly property color segOn: a.theme === "monolith" ? accent : text
    readonly property color segOnText: a.theme === "monolith" ? accentText : surfaceColor
    readonly property color thumb: light ? "#ffffff" : c.text
    readonly property color onImage: "#f5f5f7"   // text over a photo (lock screen on a picture): light, whatever the theme
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
    readonly property int fontCaption: Math.max(11, Math.round((body - 2) * fontScale))   // floors: small copy stays readable
    readonly property int fontLabel: Math.max(12, Math.round((body - 1) * fontScale))
    readonly property int fontSize: Math.round(body * fontScale)
    readonly property int fontTitle: Math.round((body + 2) * fontScale)
    readonly property int fontHeading: Math.round((body + 7) * fontScale)
    readonly property int fontDisplay: Math.round((body + 13) * fontScale)
    readonly property int fontHero: Math.round((body + 28) * fontScale)   // the one big number in a panel (date, temperature)

    // ---- shape and space ---------------------------------------------------------------------------
    readonly property int panelWidth: 336   // standard panel: Control Center, flyouts, System
    readonly property int panelWide: 368    // wide panel: Weather, Calendar
    readonly property int radiusSmall: current.shape.radiusSmall
    readonly property int radius: current.shape.radius
    readonly property int radiusLarge: current.shape.radius === 0 ? 0 : current.shape.radius + 2
    readonly property int radiusPanel: current.shape.radius === 0 ? 0 : current.shape.radius + 6   // panels and sheets; square themes stay square
    readonly property real radiusScale: 1
    // density (theme.json shape.density): compact | regular | roomy scales padding, gaps and row heights
    readonly property real density: ({ compact: 0.85, roomy: 1.2 })[current.shape.density] ?? 1
    readonly property int spaceXs: 4
    readonly property int spaceS: Math.round(8 * density)
    readonly property int spaceM: Math.round(12 * density)
    readonly property int spaceL: Math.round(16 * density)
    readonly property int spaceXl: Math.round(24 * density)
    readonly property int rowHeight: Math.round(34 * Math.sqrt(density))
    readonly property int controlHeight: Math.round(28 * Math.sqrt(density))
    readonly property int hit: Inputs.tablet ? 40 : 0   // smallest touch target in tablet mode (0: none, desktop sizes)
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
    function withDock(l) {
        if (!dockInBar) for (const k of ["start", "center", "end"]) l[k] = l[k].filter(i => i !== "apps")
        else if (!l.start.concat(l.center, l.end).includes("apps")) l.center.unshift("apps")
        return l
    }
    readonly property var barLayout: withDock({ start: Array.from(barStyle.start), center: Array.from(barStyle.center), end: Array.from(barStyle.end) })
    // the layout one screen's bar uses: its own (Config.bar.monitors[screen] = { start, center, end }), else the
    // global one (barLayout: bar.layout over the theme). Older settings named a preset instead: a screen's name
    // for one, or bar.preset while bar.layout is empty; both still read. Unknown ids are skipped once the item folders are read.
    function barLayoutFor(screenName) {
        const m = cb.monitors?.[screenName]
        const p = m && typeof m === "object" ? m : cb.presets?.[m || (hasLayout ? "" : cb.preset)]
        if (!p || typeof p !== "object") return barLayout
        const l = {}
        for (const k of ["start", "center", "end"])
            l[k] = Array.from(p[k] ?? []).filter((i, n, a) => (!BarItems.ready || BarItems.has(i)) && a.indexOf(i) === n)
        return withDock(l)
    }
    // the one global layout: { edge, size, floating, dock, start, center, end } in Config.bar.layout, empty while
    // the theme's own is in use. The first edit copies what is on screen now, so nothing jumps.
    readonly property bool hasLayout: Object.keys(cb.layout ?? {}).length > 0
    // The item lists are one layout for every theme (bar.layout). The bar's shape (edge, size, floating, the dock's
    // place) belongs to each theme: a change goes into this theme's adjustments, so switching theme brings its own.
    function layoutNow() {
        return { start: Array.from(barStyle.start), center: Array.from(barStyle.center), end: Array.from(barStyle.end) }
    }
    function setLayout(patch) {   // "" when saved, else why not
        const p = Object.assign({}, patch)
        if (p.edge && p.edge !== barEdge && p.size === undefined && (p.edge === "left" || p.edge === "right") !== barVertical)
            p.size = barVertical ? Math.min(barSize, 44) : Math.max(barSize, 44)   // a rail's width is not a strip's height
        const shape = { edge: "barEdge", size: "barSize", floating: "barFloating", dock: "dock" }
        let err = ""
        if (Object.keys(shape).some(k => p[k] !== undefined)) {   // one write for this theme's adjustments
            const all = JSON.parse(JSON.stringify(Config.appearance.custom ?? {})), id = Config.appearance.theme, o = all[id] ?? {}
            for (const k of Object.keys(shape)) if (p[k] !== undefined) o[shape[k]] = p[k]
            all[id] = o
            err = Config.set("appearance", "custom", all)
        }
        if (["start", "center", "end"].some(k => p[k] !== undefined)) {
            const l = layoutNow()
            for (const k of ["start", "center", "end"]) if (p[k] !== undefined) l[k] = Array.from(p[k])
            err = Config.set("bar", "layout", l) || err
        }
        return err
    }
    // back to the active theme's own bar: drops the global layout and this theme's old per-theme bar adjustments
    function useThemeLayout() {
        for (const k of ["barEdge", "barSize", "barFloating", "barItems", "dock"]) Themes.adjust(k, undefined)
        Config.set("bar", "layout", {})
    }
    readonly property int barHeight: barSize + barMargin                   // room the bar takes from the screen
    readonly property color barInk: barStyle.fill === "ink" ? base : text    // text on the bar's own ground
    readonly property color barDim: barStyle.fill === "ink" ? Qt.alpha(base, 0.62) : subtext   // secondary text on it
    function barShownOn(screen) { return !(screen && cb.hiddenOn.some(k => Displays.matches(k, screen))) }

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
    readonly property var dockWidgets: ({   // dock.widgets ids, in the order Settings lists the unused ones
        clock: { name: "Clock", about: "An analogue clock; click for the calendar" },
        date: { name: "Date", about: "Today's weekday and day; click for the calendar" },
        weather: { name: "Weather", about: "The sky and temperature now; click for the forecast" },
        media: { name: "Media player", about: "Cover and progress of what's playing; click to pause, scroll to skip" },
        volume: { name: "Volume", about: "The output level; click to mute, scroll to change" },
        battery: { name: "Battery", about: "Charge left, on computers with a battery" },
        load: { name: "CPU load", about: "How busy the processor is; click for the system monitor" },
        network: { name: "Network speed", about: "Download and upload speed right now" },
        screenshot: { name: "Screenshot", about: "Click to capture an area; right-click for the other screen tools" },
        trash: { name: "Trash", about: "What's in the trash; right-click twice to empty it" },
        downloads: { name: "Downloads", about: "Files downloaded today; click to open the folder" }
    })
    readonly property bool dockReserves: Config.dock.enabled && !dockInBar && !Config.dock.autoHide
    function dockShownOn(screen) { return Config.dock.enabled && !dockInBar && !(screen && Config.dock.hiddenOn.some(k => Displays.matches(k, screen))) }

    // room taken on each side by the bar and a dock that doesn't hide (popups and banners keep clear)
    function reserve(side) {
        return (barEdge === side ? barHeight : 0) + (dockReserves && dockEdge === side ? dockThickness + dockLift : 0)
    }
    readonly property int reserveTop: reserve("top")
    readonly property int reserveBottom: reserve("bottom")
    readonly property int reserveLeft: reserve("left")
    readonly property int reserveRight: reserve("right")

    // ---- icons ---------------------------------------------------------------------------------------
    // icons and cursor: the theme's own (theme.json icons / cursor) unless you picked one; "Papirus" follows light/dark
    readonly property string iconTheme: a.iconTheme === "theme" ? (current.icons || "Papirus") : a.iconTheme
    readonly property string cursorTheme: a.cursorTheme === "theme" ? (current.cursor || "default") : a.cursorTheme
    readonly property int iconSmall: 16
    readonly property int iconMedium: 22
    readonly property int iconLarge: 32
    readonly property int iconApp: 48

    // ---- depth ---------------------------------------------------------------------------------------
    readonly property color shadow: Qt.rgba(0, 0, 0, light ? 0.16 : 0.38)
    readonly property string depth: current.popup.depth                   // soft | hard | none (Panel.qml)
    readonly property real shadowBlur: depth === "soft" ? 0.6 : 0
    readonly property int shadowOffset: 4

    // ---- motion: a look (Settings > Themes > Motion), then how much of it (Animations) -------------------
    //   look     "theme" is the theme's own (Themes.qml motion + hypr.motion); the others are the same everywhere.
    //            Each sets the panels (enter / exit ms, curve, travel px from the trigger side, start and press
    //            scale) and the Hyprland preset for windows (modules/animations.lua) in one go.
    //   full     the look as it is
    //   reduced  short fades only, nothing travels or scales (Hyprland: quick fades)
    //   off      instant
    readonly property var looks: ({
        smooth:  { name: "Smooth",  about: "Long, soft glides that settle gently",       enter: 260, exit: 160, curve: [0.32, 0.72, 0, 1],   travel: 12, scale: 0.96, press: 0.97, hypr: "ease" },
        snappy:  { name: "Snappy",  about: "Quick and crisp, no overshoot",              enter: 150, exit: 90,  curve: [0.23, 1, 0.32, 1],   travel: 6,  scale: 0.98, press: 0.96, hypr: "snappy" },
        springy: { name: "Springy", about: "A little bounce as things land",             enter: 300, exit: 140, curve: [0.34, 1.56, 0.64, 1], travel: 16, scale: 0.92, press: 0.94, hypr: "spring" },
        minimal: { name: "Minimal", about: "Fades only; nothing slides or grows",        enter: 140, exit: 90,  curve: [0.23, 1, 0.32, 1],   travel: 0,  scale: 1,    press: 0.98, hypr: "minimal" }
    })
    readonly property var lookIds: ["theme"].concat(Object.keys(looks))
    function look(id) { return looks[id] ?? Object.assign({ name: current.name + "'s own", about: "Follows the theme, and changes with it", hypr: current.hypr.motion }, current.motion) }
    readonly property string motionLevel: a.motion
    readonly property bool animate: motionLevel !== "off"
    readonly property bool moves: motionLevel === "full"
    readonly property var m: look(a.motionStyle)
    readonly property int enter: motionLevel === "full" ? m.enter : motionLevel === "reduced" ? 90 : 0
    readonly property int exit: motionLevel === "full" ? m.exit : motionLevel === "reduced" ? 60 : 0
    // for easing.bezierCurve; reduced motion never overshoots
    readonly property var curve: (moves ? m.curve : [0.23, 1, 0.32, 1]).concat([1, 1])
    readonly property int travel: moves ? m.travel : 0
    readonly property real startScale: moves ? m.scale : 1
    readonly property real pressScale: moves ? m.press : 1
    readonly property string hyprMotion: moves ? m.hypr : motionLevel === "reduced" ? "minimal" : "off"
    // small state changes (hover, colour, a toggle): short and the same feel everywhere
    readonly property int animFast: animate ? Math.min(120, Math.max(60, m.enter / 2)) : 0
    readonly property int anim: animate ? Math.min(220, m.enter) : 0
    readonly property int easing: Easing.OutCubic

    // ---- Control Center tokens ---------------------------------------------------------------------------
    // One rhythm for the quick-settings panel and the flyouts that reuse its modules: gaps from the density,
    // two radii (tiles and panels take `radius`, wells and buttons inside them `radiusSmall`), and one "on" signal:
    // an accent icon well (wash themes) or a solid accent tile (solid themes).
    readonly property int ccGap: spaceS                                                   // between tiles in a group
    readonly property int ccGroupGap: spaceL                                              // between groups
    readonly property int ccPad: spaceM                                                   // panel edge to content
    readonly property int ccInset: Math.round(10 * density)                               // tile edge to its content
    readonly property int ccWell: Math.max(Math.round(32 * Math.sqrt(density)), hit)      // icon well, footer button
    readonly property int ccTile: Math.max(Math.round(60 * Math.sqrt(density)), hit)      // large tile height
    readonly property int ccToggle: Math.max(Math.round(62 * Math.sqrt(density)), hit)    // small tile height
    readonly property int ccSlider: Math.max(Math.round(34 * Math.sqrt(density)), hit)    // slider row (its hit area)
    readonly property int ccTrack: Math.max(14, Math.round(22 * Math.sqrt(density)))     // slider track: thick, the fill carries the handle
    readonly property int ccKnob: ccTrack - 10                                            // the handle inside the fill's end
    readonly property color ccTileOn: washTiles ? Qt.alpha(accent, light ? 0.16 : 0.13) : accent
    readonly property color ccTileOnHover: washTiles ? Qt.alpha(accent, light ? 0.22 : 0.19) : Qt.lighter(accent, light ? 1.06 : 1.1)
    readonly property color ccWellOn: washTiles ? accent : Qt.alpha(accentText, 0.18)
    readonly property color ccOnText: washTiles ? text : accentText
    readonly property color ccOnSubtext: washTiles ? subtext : Qt.alpha(accentText, 0.82)
    readonly property color ccIconOn: washTiles ? accent : accentText                     // a small tile's icon when on
}
