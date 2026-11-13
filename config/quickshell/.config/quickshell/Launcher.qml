pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

// Spotlight (Super): centred on the screen under the pointer, or at the pointer (Settings >
// Search & Launcher). A search pill plus four round buttons, like macOS Tahoe:
//   Search    opens on the apps grid; typing switches to results ranked by group in the order set
//             in Settings (default: apps, files, calculator, settings, actions, web)
//   Apps      every application as a grid, filtered by category chips and by what you type
//   Files     files and folders only        Actions   system and custom actions only
//   Clipboard the clipboard history inside this panel (or the Super+V popup, per Settings)
// Keys: type · ↑↓ (←→ in Apps) move · Enter open · Tab next mode · Esc close
// Look (Settings > Search & Widgets > Spotlight): separate options, the designs there are sets of them:
// split (search pill, round buttons and results as separate glass) or unified (one card), width,
// search size, colour, corners, apps per row, how the selected result is marked, and a dimmed screen.
Singleton {
    id: root

    // The look comes from the theme (Themes.qml launcher: placement, view, header, width); your
    // behaviour options (web search, files, actions, order, recent, clipboard) from Config.launcher.
    readonly property var rl: Theme.current.launcher
    readonly property real screenW: popup.targetScreen?.width ?? 1600
    readonly property real screenH: popup.targetScreen?.height ?? 1000
    readonly property var look: Object.assign({}, Config.launcher, {
        placement: rl.placement,
        style: Theme.glassy && rl.placement === "center" ? "split" : "unified",
        width: rl.placement === "strip" ? screenW - Theme.reserveLeft - Theme.reserveRight
             : rl.placement === "half" ? Math.round((screenW - Theme.reserveRight) / 2)
             : rl.placement === "fullscreen" ? Math.min(rl.width, screenW - 80) : rl.width,
        field: rl.header === "query" ? 64 : rl.placement === "strip" ? 40 : Math.round(Theme.body * 3.5),
        corners: Theme.radius === 0 ? "sharp" : Theme.radius >= 14 ? "round" : "soft",
        selection: "accent",
        // a light dim behind it, never a blur (Hyprland skips blur under see-through layers, rules.lua)
        dim: ({ fullscreen: 0.35, half: 0.25, column: 0.2, strip: 0.12, corner: 0, island: 0 })[rl.placement] ?? 0.18,
        startView: rl.view === "grid" || rl.view === "start" ? "apps" : rl.view === "inline" ? "search" : "home"
    })
    readonly property bool unified: look.style === "unified"
    readonly property bool bigQuery: rl.header === "query"   // Console, Poster, Atlas, Noir: the query set large
    readonly property color surface: Theme.surface("glass")
    readonly property real corner: Theme.radius === 0 ? 0 : Theme.radiusLarge
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
    readonly property var homeItems: Search.frequentApps.concat(Search.recentItems, Search.quickActions)
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
        return Search.results.slice(0, 40)
    }

    function activate(r) {
        if (!r) return
        if (r.confirm) { confirmFor = r; return }
        popup.hide()
        Search.activate(r)
    }
    property var confirmFor: null          // a custom action marked "ask first"

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
        onClosed: { field.text = ""; root.confirmFor = null }

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
    }
}
