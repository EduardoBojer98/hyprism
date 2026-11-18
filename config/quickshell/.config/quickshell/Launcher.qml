pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

// Spotlight (Super): centred on the screen under the pointer (default), at the pointer, or the style's own place (Settings >
// Search & Launcher). A search pill plus four round buttons, like macOS Tahoe:
//   Search    opens on the apps grid; typing switches to results ranked by group in the order set
//             in Settings (default: apps, files, calculator, settings, actions, web)
//   Apps      every application as a grid, filtered by category chips and by what you type
//   Files     files and folders only        Actions   system and custom actions only
//   Clipboard the clipboard history inside this panel (or the Super+V popup, per Settings)
// Keys: type · ↑↓ (←→ in Apps) move · Enter open · Tab next mode · Esc close
// Look (Settings > Search & Launcher > Style): the theme's own (its launcher block in theme.json) or one of
// `styles` below. A style picks only shape and place; colours and fonts stay the theme's, so each works in every theme.
Singleton {
    id: root

    // placement, view, header, width, select, prompt: as in a theme's launcher block (Themes.qml). The style's own:
    // split (search pill and buttons as separate glass), corners (theme | sharp | round), field (search height px),
    // dim, fill (the panel's share of the free height; 0 = as tall as its content), icon (apps grid),
    // mono (rows and typing in the mono face). Config.launcher.style names one, or "theme". A theme's block adds
    // labels (plain | rule: section headings as a ruled line). Apps per row is yours (Config.launcher.columns).
    // Each style is its own way of working, not only a place: `rows` (standard | compact: one line, small icons |
    // cards: tall rows, big icons | text: no icons, a kind column), `home` (the suggestions it shows: glance,
    // frequent, recent, quick) and `bare` (Launchpad: icons straight on the dimmed screen, no sheet; dark themes).
    readonly property var styles: ({
        spotlight: { name: "Spotlight", about: "Like macOS: one search bar, results only once you type",
                     placement: "center", view: "inline", header: "none", width: 680, select: "wash", prompt: "",
                     split: true, corners: "round", field: 56, dim: 0, rows: "standard", home: ["frequent", "recent"] },
        launchpad: { name: "Launchpad", about: "Every app as big icons over the whole dimmed screen",
                     placement: "fullscreen", view: "grid", header: "query", width: 1180, select: "wash", prompt: "",
                     split: true, bare: true, corners: "round", field: 60, dim: 0.62, fill: 0.86, icon: 68, rows: "cards",
                     home: ["frequent", "recent", "quick"] },
        drawer:    { name: "Drawer", about: "A sheet from the bottom: today at a glance, big rows",
                     placement: "island", view: "home", header: "none", width: 760, select: "wash", prompt: "",
                     split: false, corners: "round", field: 52, dim: 0.22, fill: 0.78, rows: "cards",
                     home: ["glance", "frequent", "recent", "quick"] },
        sidebar:   { name: "Sidebar", about: "A full-height column on the left, a dense one-line list",
                     placement: "column", view: "home", header: "none", width: 420, select: "inverse", prompt: "",
                     split: false, corners: "sharp", field: 50, dim: 0.2, fill: 1, rows: "compact",
                     home: ["recent", "quick", "frequent"] },
        terminal:  { name: "Terminal", about: "Keyboard first: a prompt, plain text rows, no icons",
                     placement: "center", view: "inline", header: "query", width: 720, select: "inverse", prompt: "❯",
                     split: false, corners: "sharp", field: 60, dim: 0.24, mono: true, rows: "text", home: ["recent", "quick"] },
    })
    readonly property var styleIds: Object.keys(styles)
    readonly property var preset: styles[Config.launcher.style] ?? null

    // The look comes from the style or the theme; your behaviour options (web search, files, actions, order,
    // recent, clipboard) from Config.launcher.
    readonly property var rl: preset ?? Theme.current.launcher
    readonly property real screenW: popup.targetScreen?.width ?? 1600
    readonly property real screenH: popup.targetScreen?.height ?? 1000
    // "center" (the default): every style floats in the middle of the screen under the pointer; "pointer": around
    // the mouse pointer, kept on its screen; "theme": the style's own place (strips and edges included)
    readonly property bool pointer: Config.launcher.position !== "theme"
    // your adjustments over the style (Settings > Search & Launcher > Adjust)
    readonly property real size: (Config.launcher.size || 100) / 100
    readonly property string rows: Config.launcher.rows !== "style" ? Config.launcher.rows : rl.rows ?? (rl.prompt ? "text" : "standard")
    readonly property bool bare: (preset?.bare ?? false) && !Theme.light   // icons on the dimmed screen need a dark one
    readonly property var homeSections: (rl.home ?? ["glance", "frequent", "recent", "quick"]).filter(h => Config.launcher.home.includes(h))
    readonly property var homeParts: ({ frequent: Search.frequentApps, recent: Search.recentItems, quick: Search.quickActions })
    // where a home section starts in keyboard order (sections in the order the home view draws them)
    function homeOffset(h) {
        let n = 0
        for (const k of ["frequent", "recent", "quick"]) { if (k === h) return n; if (homeSections.includes(k)) n += homeParts[k].length }
        return n
    }
    property bool fromClick: false   // opened by clicking a bar item: then it stays beside that item
    readonly property var look: Object.assign({}, Config.launcher, {
        placement: Config.launcher.position === "center" ? "center" : pointer ? "cursor" : rl.placement,
        style: preset ? (preset.split ? "split" : "unified") : Theme.glassy && rl.placement === "center" ? "split" : "unified",
        width: pointer ? Math.min((rl.width > 0 ? rl.width : 680) * size, 1100, screenW - Theme.spaceL * 2) : rl.placement === "strip" ? screenW - Theme.reserveLeft - Theme.reserveRight
             : rl.placement === "half" ? Math.round((screenW - Theme.reserveRight) / 2)
             : rl.placement === "fullscreen" ? Math.min(rl.width * size, screenW - 80)
             : Math.min(rl.width * size, screenW - Theme.spaceL * 2),
        field: Math.round((preset?.field ?? (rl.header === "query" ? 64 : rl.placement === "strip" ? 40 : Math.round(Theme.body * 3.5))) * Math.sqrt(size)),
        corners: Config.launcher.corners !== "style" ? Config.launcher.corners
               : preset && preset.corners !== "theme" ? preset.corners : Theme.radius === 0 ? "sharp" : Theme.radius >= 14 ? "round" : "soft",
        selection: "accent",
        // a light dim behind it, never a blur (Hyprland skips blur under see-through layers, rules.lua)
        dim: Config.launcher.dim !== "style" ? ({ none: 0, light: 0.15, dark: 0.45 })[Config.launcher.dim] ?? 0.15
           : preset?.dim ?? (pointer ? 0.12 : ({ fullscreen: 0.35, half: 0.25, column: 0.2, strip: 0.12, corner: 0, island: 0 })[rl.placement] ?? 0.18),
        fill: pointer ? Math.min(preset?.fill ?? 0, 0.6) : preset?.fill ?? 0,
        columns: Config.launcher.columns,
        icon: Math.round((preset?.icon ?? Theme.iconApp) * Math.sqrt(size)),
        startView: rl.view === "grid" || rl.view === "start" ? "apps" : rl.view === "inline" ? "search" : "home"
    })
    readonly property bool unified: look.style === "unified"
    readonly property bool bigQuery: rl.header === "query"   // Poster: the query set large
    // Monolith: section headings as a ruled line in accent2; the theme's type, so it holds in every style
    readonly property bool ruled: (Theme.current.launcher.labels ?? "plain") === "rule"
    readonly property string rowFont: preset?.mono ? Theme.monoFont : Theme.font
    readonly property color surface: Theme.surface("glass")
    readonly property real corner: look.corners === "sharp" ? 0 : look.corners === "round" ? Math.max(Theme.radiusLarge, 18) : Theme.radiusLarge
    // the most the panel under the search field can take: from where CursorPopup.place() puts the top (the
    // centred ones sit lower; bottom-anchored ones grow upwards) down to the dock
    readonly property real top: ({ center: Math.max(popup.topReserve, screenH * 0.2), fullscreen: Math.max(popup.topReserve, screenH * 0.1),
                                   strip: Theme.reserveTop, half: Theme.reserveTop, column: Theme.reserveTop })[look.placement] ?? popup.topReserve
    readonly property real room: Math.max(180, screenH - popup.bottomReserve - top - look.field - (unified ? 0 : Theme.spaceS))   // a floor for tiny screens
    // the selected row, the theme's way: a soft accent tint (glass themes) or a solid accent block with
    // inverted text (the flat and terminal themes)
    readonly property bool inverse: (rl.select ?? "wash") === "inverse"
    readonly property color selection: inverse ? Theme.accent : Theme.accentWash
    readonly property color selText: inverse ? Theme.accentText : Theme.text
    readonly property color selSub: inverse ? Qt.alpha(Theme.accentText, 0.78) : Theme.subtext
    readonly property string prompt: rl.prompt ?? ""     // a typed prompt instead of the lens (terminal themes)

    readonly property var modes: [
        { id: "apps",    name: "Applications", glyph: "\u{F003B}", hint: "Search applications" },
        { id: "files",   name: "Files",        glyph: "\u{F024B}", hint: "Search files and folders, or type ~/path" },
        { id: "actions", name: "Actions",      glyph: "\u{F0E7}",  hint: "Search actions" },
        { id: "clip",    name: "Clipboard",    glyph: "\u{F014C}", hint: "Search clipboard history" },
    ]
    property string mode: "search"            // search | apps | files | actions | clip
    // What the panel shows: an empty search opens on suggestions or the apps grid (Config.launcher.startView)
    readonly property string startView: Config.launcher.startView === "theme" ? look.startView : Config.launcher.startView
    readonly property string view: mode === "search" && Search.query.trim() === "" && startView !== "search" ? startView : mode
    // home view, in keyboard order: frequent apps, then recent items, then quick actions
    readonly property var homeItems: ["frequent", "recent", "quick"].filter(h => homeSections.includes(h)).reduce((all, h) => all.concat(homeParts[h]), [])
    property int homeIndex: 0
    property string category: "All"
    property bool open: popup.open
    // the parts' controls, reached by the key handling and the mode switch
    property alias field: pill.input
    property alias results: panel.results
    property alias grid: panel.grid
    property alias clipView: panel.clipView

    function show(m) {
        mode = m || "search"
        category = "All"
        field.text = ""
        homeIndex = 0
        Calendar.now = new Date()
        Clipboard.prepare()
        fromClick = Anchor.fresh
        popup.show()
    }
    function close() { popup.hide() }
    function toggle() { if (popup.open) popup.hide(); else show("search") }
    function setMode(m) {
        if (m === "clip" && !Config.launcher.clipboardInside) { popup.hide(); Clipboard.toggle(); return }
        enter(mode === m ? "search" : m)
    }
    function cycleMode() {
        const order = ["search", "apps", "files", "actions"].concat(Config.launcher.clipboardInside ? ["clip"] : [])
        enter(order[(order.indexOf(mode) + 1) % order.length])
    }
    // the text is kept between search modes, but the clipboard filters on its own text
    function enter(m) {
        const clipSwitch = (m === "clip") !== (mode === "clip")
        mode = m
        if (m === "clip") Clipboard.prepare()
        if (clipSwitch) { field.text = ""; Clipboard.filter = ""; Search.query = "" }
        if (m === "clip") clipView.reset()
        results.currentIndex = 0
        grid.currentIndex = 0
        confirmFor = null
        field.forceActiveFocus()
    }
    Binding { target: Search; property: "fileMode"; value: root.open && root.mode === "files" }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function apps(): void { root.show("apps") }
        function files(): void { root.show("files") }
        function clipboard(): void { Clipboard.toggle() }
        function search(text: string): void { root.show("search"); field.text = text }
        function mode(m: string): void { root.show("search"); if (m !== "search") root.setMode(m) }
    }

    // ---- data for the current mode -------------------------------------------------------------
    readonly property var categories: ["All", "Development", "Internet", "Office", "Graphics", "Multimedia", "Games", "Utilities", "System"]
    readonly property var categoryOf: ({ Development: ["Development", "IDE"], Internet: ["Network", "WebBrowser", "Email", "Chat"],
        Office: ["Office"], Graphics: ["Graphics"], Multimedia: ["AudioVideo", "Audio", "Video"], Games: ["Game"],
        Utilities: ["Utility", "Accessories"], System: ["System", "Settings"] })

    readonly property var appGrid: {
        const q = Search.query.trim().toLowerCase()
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .filter(e => category === "All" || (categoryOf[category] ?? []).some(c => e.categories.includes(c)))
            .filter(e => !q || Search.match(e.name, q) > 0 || Search.match(e.genericName, q) > 0)
            .sort((a, b) => a.name.localeCompare(b.name))
    }

    readonly property var listModel: {
        if (mode === "files") return Search.fileResults(Search.query.trim().toLowerCase())
        if (mode === "actions") return Search.actionList(Search.query.trim())
        return Search.results.slice(0, Config.launcher.maxResults)
    }

    function activate(r) {
        if (!r) return
        if (r.confirm) { confirmFor = r; return }
        popup.hide()
        Search.activate(r)
    }
    property var confirmFor: null          // an action marked "ask first"
    // an action run from elsewhere (a hot corner, a shortcut) that asks first: the launcher opens to ask
    function ask(r) { if (!popup.open) show("search"); confirmFor = r }
    // the right-click menu for an app: a DesktopEntry, or a result that carries one (anything else has no menu)
    function menuFor(r, item, x, y) { const e = r?.entry ?? (r?.execute ? r : null); if (e) menu.openFor(e, item, x, y) }

    Connections { target: Clipboard; function onPasted() { popup.hide() } }

    // ---- window --------------------------------------------------------------------------------
    CursorPopup {
        id: popup
        name: "launcher"
        placement: root.look.placement
        boxWidth: root.look.width
        boxHeight: pill.height + (panel.visible ? panel.height + panel.anchors.topMargin : 0)
        dim: root.look.dim
        focusItem: field
        onOpened: if (root.pointer && !root.fromClick) popup.anchorRect = null   // a shortcut opens centred or at the pointer, not beside the bar item
        onClosed: { field.text = ""; root.confirmFor = null; menu.entry = null }
        onOpenChanged: Actions.watch("launcher", popup.open)   // toggles show their real state

        // unified: one card behind the search field and the results, a hairline between them
        Glass {
            visible: root.unified
            width: parent.width
            height: popup.boxHeight
            radius: root.corner
            color: root.surface
            Rectangle {
                visible: panel.visible
                anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: pill.height }
                height: 1
                color: Theme.stroke
            }
        }

        LauncherHeader { id: pill }

        LauncherPanel {
            id: panel
            anchors { top: pill.bottom; topMargin: root.unified ? 0 : Theme.spaceS; left: parent.left; right: parent.right }
        }

        LauncherMenu { id: menu; z: 10; width: parent.width; height: popup.boxHeight }
    }
}
