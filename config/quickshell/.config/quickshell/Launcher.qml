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

    // The look comes from the rice (Rices.qml launcher: placement, view, header, width); your
    // behaviour options (web search, files, actions, order, recent, clipboard) from Config.launcher.
    readonly property var rl: Theme.rice.launcher
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
        dim: ({ fullscreen: 0.6, half: 0.3, column: 0.25, strip: 0, corner: 0, island: 0 })[rl.placement] ?? 0.15,
        startView: rl.view === "grid" || rl.view === "start" ? "apps" : rl.view === "inline" ? "search" : "home"
    })
    readonly property bool unified: look.style === "unified"
    readonly property bool bigQuery: rl.header === "query"   // Console, Poster, Atlas, Noir: the query set large
    readonly property color surface: Theme.surface("glass")
    readonly property real corner: Theme.radius === 0 ? 0 : Theme.radiusLarge
    readonly property color selection: Theme.accentWash

    readonly property var modes: [
        { id: "apps",    name: "Applications", glyph: "\u{F003B}", hint: "Search applications" },
        { id: "files",   name: "Files",        glyph: "\u{F024B}", hint: "Search files and folders, or type ~/path" },
        { id: "actions", name: "Actions",      glyph: "\u{F0E7}",  hint: "Search actions" },
        { id: "clip",    name: "Clipboard",    glyph: "\u{F014C}", hint: "Search clipboard history" },
    ]
    property string mode: "search"            // search | apps | files | actions | clip
    // What the panel shows: an empty search opens on suggestions or the apps grid (Config.launcher.startView)
    readonly property string startView: Config.launcher.startView === "rice" ? look.startView : Config.launcher.startView
    readonly property string view: mode === "search" && Search.query.trim() === "" && startView !== "search" ? startView : mode
    // home view, in keyboard order: frequent apps, then recent items, then quick actions
    readonly property var homeItems: Search.frequentApps.concat(Search.recentItems, Search.quickActions)
    property int homeIndex: 0
    property string category: "All"
    property bool open: popup.open

    function show(m) {
        mode = m || "search"
        category = "All"
        field.text = ""
        homeIndex = 0
        Calendar.now = new Date()
        Clipboard.prepare()
        popup.show()
    }
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

        // Search pill and round mode buttons ----------------------------------------------------
        Item {
            id: pill
            width: parent.width
            height: root.look.field
            z: 1   // above the panel, so the mode buttons' tooltips show over it

            Glass {
                id: searchBox
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: buttons.left; rightMargin: root.unified ? 0 : Theme.spaceS }
                strong: true
                flat: root.unified
                color: root.unified ? "transparent" : root.surface
                border.width: root.unified ? 0 : 1
                radius: root.look.corners === "round" ? height / 2 : root.corner

                Text {
                    id: lens
                    anchors { left: parent.left; leftMargin: Theme.spaceL + 2; verticalCenter: parent.verticalCenter }
                    text: root.mode === "search" ? "\u{F0349}" : root.modes.find(m => m.id === root.mode)?.glyph ?? ""
                    color: Theme.subtext
                    font { family: Theme.iconFont; pixelSize: Theme.iconMedium }
                }
                TextInput {
                    id: field
                    anchors { left: lens.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: Theme.spaceL; verticalCenter: parent.verticalCenter }
                    color: Theme.text
                    selectionColor: Theme.accent
                    font {
                        family: root.bigQuery ? Theme.displayFont : Theme.font
                        pixelSize: Math.round(root.look.field * (root.bigQuery ? 0.5 : 0.38))
                        weight: root.bigQuery ? Theme.displayWeight : Font.Normal
                    }
                    onTextChanged: {
                        if (root.mode === "clip") { Clipboard.filter = text; clipView.reset(); return }
                        Search.query = text; results.currentIndex = 0; grid.currentIndex = 0; root.homeIndex = 0; root.confirmFor = null
                    }
                    Text {
                        visible: !field.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.mode === "search" ? (root.bigQuery ? "Search" : "Search apps, files, settings and more") : root.modes.find(m => m.id === root.mode)?.hint ?? ""
                        color: Theme.muted
                        font: field.font
                    }

                    Keys.onPressed: event => {
                        const inGrid = root.view === "apps"
                        if (root.view === "clip") {
                            if (event.key === Qt.Key_Down) clipView.down()
                            else if (event.key === Qt.Key_Up) clipView.up()
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) clipView.paste()
                            else if (event.key === Qt.Key_Delete) clipView.remove()
                            else if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) clipView.pin()
                            else if (event.key === Qt.Key_Space && !field.text) clipView.expand()
                            else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) root.cycleMode()
                            else if (event.key === Qt.Key_Escape) popup.hide()
                            else return
                            event.accepted = true
                            return
                        }
                        if (root.view === "home" && !root.confirmFor) {
                            const n = root.homeItems.length, nA = Search.frequentApps.length, i = root.homeIndex
                            if (event.key === Qt.Key_Right) root.homeIndex = Math.min(n - 1, i + 1)
                            else if (event.key === Qt.Key_Left) root.homeIndex = Math.max(0, i - 1)
                            else if (event.key === Qt.Key_Down) root.homeIndex = Math.min(n - 1, i < nA ? nA : i + 1)
                            else if (event.key === Qt.Key_Up) root.homeIndex = i < nA ? i : i === nA ? 0 : i - 1
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.activate(root.homeItems[i])
                            else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) root.cycleMode()
                            else if (event.key === Qt.Key_Escape) popup.hide()
                            else return
                            event.accepted = true
                            return
                        }
                        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) { root.cycleMode() }
                        else if (event.key === Qt.Key_Down) { inGrid ? grid.moveCurrentIndexDown() : results.incrementCurrentIndex() }
                        else if (event.key === Qt.Key_Up) { inGrid ? grid.moveCurrentIndexUp() : results.decrementCurrentIndex() }
                        else if (inGrid && event.key === Qt.Key_Right && field.cursorPosition === field.text.length) { grid.moveCurrentIndexRight() }
                        else if (inGrid && event.key === Qt.Key_Left && field.cursorPosition === 0) { grid.moveCurrentIndexLeft() }
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (root.confirmFor) { const r = root.confirmFor; root.confirmFor = null; popup.hide(); Search.activate(r) }
                            else if (inGrid) { const e = root.appGrid[grid.currentIndex]; if (e) { popup.hide(); Search.remember("app:" + e.id); e.execute() } }
                            else root.activate(root.listModel[results.currentIndex])
                        }
                        else if (event.key === Qt.Key_Escape) { if (root.confirmFor) root.confirmFor = null; else popup.hide() }
                        else return
                        event.accepted = true
                    }
                }
            }

            Glass {
                id: buttons
                anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                width: modeRow.implicitWidth + 12
                radius: height / 2
                strong: true
                flat: root.unified
                color: root.unified ? "transparent" : root.surface
                border.width: root.unified ? 0 : 1
                Row {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: 2
                Repeater {
                    model: root.modes
                    Rectangle {
                        required property var modelData
                        readonly property bool current: root.mode === modelData.id
                        width: 36; height: 36
                        radius: width / 2
                        color: current ? Theme.fillActive : buttonArea.containsMouse ? Theme.fillHover : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            color: current ? Theme.accent : Theme.subtext
                            font { family: Theme.iconFont; pixelSize: Theme.iconMedium - 4 }
                        }
                        MouseArea {
                            id: buttonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setMode(modelData.id)
                        }
                        ToolTipText { shown: buttonArea.containsMouse; text: modelData.name }
                    }
                }
                }
            }
        }

        // Results / browse panel ------------------------------------------------------------------
        Glass {
            id: panel
            anchors { top: pill.bottom; topMargin: root.unified ? 0 : Theme.spaceS; left: parent.left; right: parent.right }
            strong: true
            flat: root.unified
            color: root.unified ? "transparent" : root.surface
            border.width: root.unified ? 0 : 1
            radius: root.corner
            visible: root.view !== "search" || field.text.trim() !== ""
            height: root.view === "home" ? home.implicitHeight + Theme.spaceM * 2
                  : root.view === "apps" || root.view === "clip" ? 460
                  : Math.min(440, Math.max(64, results.contentHeight + Theme.spaceS * 2 + (root.confirmFor ? 44 : 0)))
            Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }

            // Confirmation strip for actions marked "ask first"
            Rectangle {
                id: confirmBar
                visible: root.confirmFor !== null
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
                height: 36
                radius: Theme.radiusSmall
                color: Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.16)
                Text {
                    anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                    text: "Run “" + (root.confirmFor?.title ?? "") + "”? Enter to confirm, Esc to cancel"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontSize }
                }
            }

            // Home: at a glance, frequent apps, recent items and quick actions
            Column {
                id: home
                visible: root.view === "home" && !root.confirmFor
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
                spacing: Theme.spaceS

                // weather, the next calendar event and the last thing copied
                Row {
                    id: glance
                    width: parent.width
                    spacing: Theme.spaceS
                    readonly property var clip: Clipboard.entries.find(e => !e.pinned) ?? null
                    readonly property var tiles: [
                        Weather.ready ? { glyph: Weather.glyph, title: Math.round(Weather.temperature) + "°  " + Weather.condition, sub: Weather.city,
                                          run: () => { popup.hide(); Weather.toggle() } } : null,
                        Calendar.next ? { glyph: "\u{F00ED}", title: Calendar.next.title,
                                          sub: (Calendar.next.days === 0 ? "Today" : Calendar.next.days === 1 ? "Tomorrow" : Calendar.locale.toString(Calendar.next.date, "ddd d MMM")),
                                          run: () => { popup.hide(); Calendar.toggle() } } : null,
                        clip ? { glyph: "\u{F014C}", title: clip.kind === "image" ? "Image" : clip.preview.replace(/\s+/g, " "), sub: "Last copied · click to paste",
                                 run: () => Clipboard.paste(glance.clip) } : null,
                    ].filter(t => t)
                    Repeater {
                        model: glance.tiles
                        Rectangle {
                            id: tile
                            required property var modelData
                            width: (glance.width - glance.spacing * (glance.tiles.length - 1)) / glance.tiles.length
                            height: 52
                            radius: Theme.radius
                            color: tileArea.containsMouse ? Theme.fillHover : Theme.fill
                            Text {
                                id: tileGlyph
                                anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                                text: tile.modelData.glyph
                                color: Theme.subtext
                                font { family: Theme.iconFont; pixelSize: Theme.iconMedium - 2 }
                            }
                            Column {
                                anchors { left: tileGlyph.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                                Text { width: parent.width; text: tile.modelData.title; elide: Text.ElideRight; maximumLineCount: 1; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium } }
                                Text { width: parent.width; text: tile.modelData.sub; elide: Text.ElideRight; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
                            }
                            MouseArea { id: tileArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.modelData.run() }
                        }
                    }
                }

                HomeLabel { text: "Frequently used" }
                Row {
                    id: freq
                    width: parent.width
                    z: 1   // name tooltips over the labels below
                    Repeater {
                        model: Search.frequentApps
                        Item {
                            id: app
                            required property var modelData
                            required property int index
                            readonly property bool current: root.homeIndex === index
                            width: freq.width / 8; height: 92
                            z: appArea.containsMouse ? 1 : 0
                            Rectangle {
                                anchors { fill: parent; margins: 3 }
                                radius: Theme.radius
                                color: app.current ? root.selection : appArea.containsMouse ? Theme.fillHover : "transparent"
                            }
                            IconImage {
                                id: freqIcon
                                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.spaceM }
                                implicitSize: 44
                                source: Quickshell.iconPath(app.modelData.icon, "application-x-executable")
                            }
                            Text {
                                anchors { left: parent.left; right: parent.right; top: freqIcon.bottom; topMargin: Theme.spaceXs; margins: Theme.spaceXs }
                                horizontalAlignment: Text.AlignHCenter
                                id: appName
                                text: app.modelData.title
                                elide: Text.ElideRight
                                color: Theme.text
                                font { family: Theme.font; pixelSize: Theme.fontLabel }
                            }
                            ToolTipText { gap: -Theme.spaceS; shown: appArea.containsMouse && appName.truncated; text: app.modelData.title }
                            MouseArea { id: appArea; anchors.fill: parent; hoverEnabled: true; onEntered: root.homeIndex = app.index; onClicked: root.activate(app.modelData) }
                        }
                    }
                }

                HomeLabel { visible: Search.recentItems.length > 0; text: "Recent" }
                Repeater {
                    model: Search.recentItems
                    HomeRow { required property var modelData; required property int index; item: modelData; at: Search.frequentApps.length + index }
                }

                HomeLabel { text: "Quick actions" }
                Grid {
                    width: parent.width
                    columns: 3
                    columnSpacing: Theme.spaceXs
                    rowSpacing: Theme.spaceXs
                    Repeater {
                        model: Search.quickActions
                        HomeRow {
                            required property var modelData
                            required property int index
                            width: (home.width - Theme.spaceXs * 2) / 3
                            item: modelData
                            at: Search.frequentApps.length + Search.recentItems.length + index
                        }
                    }
                }
            }

            // Clipboard history inside Spotlight
            ClipboardView {
                id: clipView
                visible: root.view === "clip"
                anchors { fill: parent; margins: Theme.spaceS }
            }

            // Apps: category chips and icon grid
            Item {
                anchors.fill: parent
                visible: root.view === "apps"
                Flow {
                    id: chips
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
                    spacing: Theme.spaceXs
                    Repeater {
                        model: root.categories
                        Chip {
                            required property string modelData
                            label: modelData
                            active: root.category === modelData
                            color: active ? Theme.fillActive : Theme.fill
                            onClicked: { root.category = modelData; grid.currentIndex = 0; field.forceActiveFocus() }
                        }
                    }
                }
                Rectangle { id: rule; anchors { left: parent.left; right: parent.right; top: chips.bottom; margins: Theme.spaceM } height: 1; color: Theme.stroke }
                GridView {
                    id: grid
                    anchors { left: parent.left; right: parent.right; top: rule.bottom; bottom: parent.bottom; margins: Theme.spaceS }
                    clip: true
                    cellWidth: Math.floor(width / root.look.columns)
                    cellHeight: 104
                    model: root.appGrid
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: Theme.animFast
                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        width: grid.cellWidth; height: grid.cellHeight
                        z: cellArea.containsMouse ? 1 : 0
                        Rectangle {
                            anchors { fill: parent; margins: 3 }
                            radius: Theme.radius
                            color: cell.GridView.isCurrentItem ? root.selection : cellArea.containsMouse ? Theme.fillHover : "transparent"
                        }
                        IconImage {
                            id: appIcon
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.spaceM }
                            implicitSize: Theme.iconApp
                            source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                        }
                        Text {
                            anchors { left: parent.left; right: parent.right; top: appIcon.bottom; topMargin: Theme.spaceXs; margins: Theme.spaceXs }
                            horizontalAlignment: Text.AlignHCenter
                            id: cellName
                            text: cell.modelData.name
                            elide: Text.ElideRight
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontLabel }
                        }
                        ToolTipText { gap: -Theme.spaceS; shown: cellArea.containsMouse && cellName.truncated; text: cell.modelData.name }
                        MouseArea {
                            id: cellArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: grid.currentIndex = cell.index
                            onClicked: { popup.hide(); Search.remember("app:" + cell.modelData.id); cell.modelData.execute() }
                        }
                    }
                }
            }

            // Search, Files, Actions: one ranked list, section label when the kind changes
            ListView {
                id: results
                visible: root.view !== "apps" && root.view !== "clip" && root.view !== "home"
                anchors { fill: parent; margins: Theme.spaceS; topMargin: confirmBar.visible ? 52 : Theme.spaceS }
                clip: true
                model: root.listModel
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: Theme.animFast

                Text {
                    anchors.centerIn: parent
                    visible: results.count === 0
                    text: root.mode === "files" ? (field.text ? "No files found" : "Start typing to search your home folder") : "No results"
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontSize }
                }

                delegate: Column {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool topHit: index === 0 && root.mode === "search"
                    readonly property string group: Search.groupNames[Search.groupOf[modelData.kind]] ?? modelData.kind
                    readonly property bool newSection: index > 0 && !(index === 1 && root.mode === "search")
                        && (Search.groupNames[Search.groupOf[root.listModel[index - 1]?.kind]] ?? root.listModel[index - 1]?.kind) !== group
                    width: results.width

                    Text {
                        visible: row.topHit || row.newSection || (row.index === 1 && root.mode === "search")
                        text: row.topHit ? "Top Hit" : row.group
                        leftPadding: Theme.spaceM
                        topPadding: row.index === 0 ? 2 : Theme.spaceS
                        bottomPadding: Theme.spaceXs
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                    }

                    Rectangle {
                        width: parent.width
                        height: row.topHit ? 56 : Theme.rowHeight + 4
                        radius: Theme.radiusSmall
                        color: row.ListView.isCurrentItem ? root.selection : rowArea.containsMouse ? Theme.fillHover : "transparent"

                        Item {
                            id: iconBox
                            anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                            width: row.topHit ? Theme.iconLarge : Theme.iconMedium + 4; height: width
                            IconImage {
                                anchors.fill: parent
                                visible: !!row.modelData.icon
                                source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !row.modelData.icon
                                text: row.modelData.glyph ?? ""
                                color: Theme.text
                                font { family: Theme.iconFont; pixelSize: row.topHit ? Theme.iconLarge - 6 : Theme.iconMedium - 2 }
                            }
                        }
                        Column {
                            anchors { left: iconBox.right; leftMargin: Theme.spaceM; right: kindLabel.left; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                            Text {
                                width: parent.width
                                text: row.modelData.title
                                elide: Text.ElideRight
                                color: Theme.text
                                font { family: Theme.font; pixelSize: row.topHit ? Theme.fontTitle : Theme.fontSize; weight: row.topHit ? Font.DemiBold : Font.Medium }
                            }
                            Text {
                                width: parent.width
                                visible: !!row.modelData.subtitle
                                text: row.modelData.subtitle ?? ""
                                elide: Text.ElideMiddle
                                color: Theme.subtext
                                font { family: Theme.font; pixelSize: Theme.fontCaption }
                            }
                        }
                        Text {
                            id: kindLabel
                            anchors { right: parent.right; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                            visible: row.ListView.isCurrentItem
                            text: "↵"
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontSize }
                        }
                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: results.currentIndex = row.index
                            onClicked: root.activate(row.modelData)
                        }
                    }
                }
            }
        }
    }

    component HomeLabel: Text {
        topPadding: Theme.spaceXs
        leftPadding: Theme.spaceXs
        color: Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
    }
    // one result row on the home view: glyph or icon, title, subtitle; `at` is its keyboard index
    component HomeRow: Rectangle {
        id: hr
        property var item
        property int at
        readonly property bool current: root.homeIndex === at
        width: parent ? parent.width : 0
        height: Theme.rowHeight + 4
        radius: Theme.radiusSmall
        color: current ? root.selection : hrArea.containsMouse ? Theme.fillHover : "transparent"
        Item {
            id: hrIcon
            anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
            width: Theme.iconMedium; height: width
            IconImage { anchors.fill: parent; visible: !!hr.item.icon; source: hr.item.icon ? Quickshell.iconPath(hr.item.icon, "application-x-executable") : "" }
            Text { anchors.centerIn: parent; visible: !hr.item.icon; text: hr.item.glyph ?? ""; color: Theme.text; font { family: Theme.iconFont; pixelSize: Theme.iconMedium - 4 } }
        }
        Column {
            anchors { left: hrIcon.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
            Text { width: parent.width; text: hr.item.title; elide: Text.ElideRight; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium } }
            Text { width: parent.width; visible: !!hr.item.subtitle; text: hr.item.subtitle ?? ""; elide: Text.ElideMiddle; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption } }
        }
        MouseArea { id: hrArea; anchors.fill: parent; hoverEnabled: true; onEntered: root.homeIndex = hr.at; onClicked: root.activate(hr.item) }
    }
}
