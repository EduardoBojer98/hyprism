import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: Launchpad's apps, in pages. Big icons straight on the dark scrim, as many rows as fit; a row of dots
// under them. Paging: swipe or drag sideways, the scroll wheel or touchpad, ←→ past a page's edge, PageUp/PageDown,
// a click on a dot. On All with nothing typed it is your arrangement (Launcher.padEntries, saved in
// Config.launcher.padLayout): hold an icon and drag it to move it, drop it on another app to make a folder, on a
// folder to add it. A click opens a folder in place (its name is editable); drag an app out of the folder to take it
// out. Used by LauncherApps.qml as its `grid` (currentIndex, moveCurrentIndex*, currentItem: the keys in LauncherHeader).
Item {
    id: pad
    readonly property Item me: pad            // handed to each LauncherPadCell (a `pad: pad` binding would name the cell's own)
    property bool wave: false                 // LauncherApps: the icons arrive in a wave as it opens
    readonly property bool arranging: Launcher.category === "All" && Search.query.trim() === ""
    readonly property var entries: arranging ? Launcher.padEntries : Launcher.appGrid.map(e => ({ app: e }))
    // a short screen gets slightly smaller icons rather than a single row
    readonly property int icon: Math.round(Math.max(40, Math.min(Launcher.look.icon, pages.height / 2 - 58)))
    readonly property int cols: Math.max(3, Math.floor(width / (icon + 88)))
    readonly property int rows: Math.max(1, Math.floor(pages.height / (icon + 56)))
    readonly property int perPage: cols * rows
    readonly property int pageCount: Math.max(1, Math.ceil(entries.length / perPage))
    readonly property real cellW: Math.floor(pages.width / cols)
    readonly property real cellH: pages.height / rows
    readonly property real side: (pages.width - cellW * cols) / 2

    // ---- the keyboard's place: an entry on the pages, or an app in the open folder --------------------------
    property int currentIndex: 0
    property int folderIndex: -1              // the open folder's index in entries
    property int folderCurrent: 0
    readonly property var folder: folderIndex >= 0 ? entries[folderIndex] ?? null : null
    readonly property var currentEntry: folder ? folder.apps[folderCurrent] ?? null : entries[currentIndex]?.app ?? null
    property Item currentItem: null
    onCurrentIndexChanged: if (currentIndex >= 0 && entries.length) page = Math.floor(currentIndex / perPage)
    onEntriesChanged: currentIndex = Math.max(0, Math.min(currentIndex, entries.length - 1))
    onArrangingChanged: closeFolder()
    Connections { target: Launcher; function onOpenChanged() { pad.closeFolder(); pad.page = 0; pad.currentIndex = 0 } }

    function step(d) {
        if (folder) folderCurrent = Math.max(0, Math.min(folder.apps.length - 1, folderCurrent + d))
        else currentIndex = Math.max(0, Math.min(entries.length - 1, currentIndex + d))
    }
    readonly property int folderCols: folder ? Math.min(folder.apps.length <= 4 ? 2 : folder.apps.length <= 9 ? 3 : 5, folder.apps.length) : 1
    function moveCurrentIndexRight() { step(1) }
    function moveCurrentIndexLeft() { step(-1) }
    function moveCurrentIndexDown() { step(folder ? folderCols : cols) }
    function moveCurrentIndexUp() { step(folder ? -folderCols : -cols) }
    function turn(d) { page = Math.max(0, Math.min(pageCount - 1, page + d)); if (Math.floor(currentIndex / perPage) !== page) currentIndex = page * perPage }
    // Enter or a click: an app opens, a folder opens in place
    function activate() {
        const e = folder ? null : entries[currentIndex]
        if (e && e.folder !== undefined) { openFolder(currentIndex); return }
        const app = currentEntry
        if (!app) return
        Launcher.close(); Search.remember("app:" + app.id); app.execute()
    }
    function openFolder(i) { folderIndex = i; folderCurrent = 0 }
    function closeFolder() { if (folderIndex < 0) return; Launcher.field.forceActiveFocus(); folderIndex = -1 }   // focus leaves the name first, so a rename in progress is kept

    // ---- paging ----------------------------------------------------------------------------------------------
    property int page: 0
    onPageChanged: if (pages.currentIndex !== page) pages.currentIndex = page
    property real wheelSum: 0
    Timer { id: wheelRest; interval: 380 }   // one flick of the wheel or the touchpad turns one page
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (pad.folder) return
            const d = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y) ? -event.angleDelta.x : -event.angleDelta.y
            if (wheelRest.running) { wheelRest.restart(); return }
            pad.wheelSum += d
            if (Math.abs(pad.wheelSum) >= 90) { pad.turn(pad.wheelSum > 0 ? 1 : -1); pad.wheelSum = 0; wheelRest.restart() }
        }
    }

    ListView {
        id: pages
        anchors { left: parent.left; right: parent.right; top: parent.top; bottom: dots.top; bottomMargin: Theme.spaceM }
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: Theme.moves ? 320 : 0
        highlightMoveVelocity: -1
        preferredHighlightBegin: 0
        preferredHighlightEnd: width
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: Math.max(0, width) * 30           // pages stay made, so an icon held in a drag lives on while the pages turn
        clip: true
        interactive: !pad.drag && !pad.folder
        model: Launcher.open ? pad.pageCount : 0
        onCurrentIndexChanged: if (pad.page !== currentIndex) { pad.page = currentIndex; if (Math.floor(pad.currentIndex / pad.perPage) !== currentIndex) pad.currentIndex = currentIndex * pad.perPage }
        delegate: Item {
            id: pageItem
            required property int index
            width: pages.width; height: pages.height
            Repeater {
                model: pad.entries.slice(pageItem.index * pad.perPage, (pageItem.index + 1) * pad.perPage)
                LauncherPadCell {
                    pad: me
                    required property var modelData
                    required property int index
                    entry: modelData
                    at: pageItem.index * pad.perPage + index
                    x: pad.side + (index % pad.cols) * pad.cellW
                    y: Math.floor(index / pad.cols) * pad.cellH
                    width: pad.cellW; height: pad.cellH
                    current: !pad.folder && pad.currentIndex === at
                    order: index
                }
            }
        }
    }

    // the pages as dots, the one you're on bright; a click goes there
    Row {
        id: dots
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.spaceS }
        height: 20
        spacing: 2
        opacity: pad.pageCount > 1 ? 1 : 0
        Repeater {
            model: pad.pageCount
            Item {
                id: dot
                required property int index
                width: 18; height: 20
                Rectangle {
                    anchors.centerIn: parent
                    width: 8; height: 8; radius: 4
                    color: "white"   // palette: on Launchpad's dark scrim in every theme
                    opacity: pad.page === dot.index ? 0.95 : dotArea.containsMouse ? 0.55 : 0.3
                    scale: pad.page === dot.index ? 1 : 0.8
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    Behavior on scale { NumberAnimation { duration: Theme.animFast } }
                }
                MouseArea {
                    id: dotArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button; Accessible.name: "Page " + (dot.index + 1)
                    onClicked: pad.turn(dot.index - pad.page)
                }
            }
        }
    }

    // ---- drag: hold an icon, then move it ----------------------------------------------------------------------
    property var drag: null      // { cell, x, y } in pad's coordinates
    property var drop: null      // { idx, into (onto that icon), insert (the gap it goes in) } or null (nowhere)
    function beginDrag(cell, p) { drag = { cell: cell, from: cell.inFolder, at: cell.at, x: p.x, y: p.y } }
    function moveDrag(p) {
        drag = Object.assign({}, drag, { x: p.x, y: p.y })
        // an app out of an open folder: past the folder's sheet the folder closes and it goes back on the pages
        if (folder && !sheet.contains(sheet.mapFromItem(pad, p.x, p.y))) folderIndex = -1
        if (folder) { drop = null; return }
        const g = pages.mapFromItem(pad, p.x, p.y)
        // near the left or right edge the pages turn
        if (g.x < 48 && page > 0) edge.go(-1)
        else if (g.x > pages.width - 48) edge.go(1)
        else edge.stop()
        if (g.y < 0 || g.y > pages.height || g.x < 0 || g.x > pages.width) { drop = null; return }
        const col = Math.max(0, Math.min(cols - 1, Math.floor((g.x - side) / cellW))), row = Math.max(0, Math.min(rows - 1, Math.floor(g.y / cellH)))
        const idx = page * perPage + row * cols + col
        const cx = side + col * cellW + cellW / 2, cy = row * cellH + Math.max(16, (cellH - icon - 52) / 2) + icon / 2
        const into = idx < entries.length && Math.abs(g.x - cx) < icon * 0.42 && Math.abs(g.y - cy) < icon * 0.42
        drop = { idx: idx, into: into, insert: Math.min(entries.length, g.x > cx ? idx + 1 : idx) }
    }
    Timer {
        id: edge
        property int dir: 0
        interval: 560
        repeat: true
        function go(d) { if (dir !== d || !running) { dir = d; restart() } }
        onTriggered: pad.page = Math.max(0, Math.min(pad.pageCount - 1, pad.page + dir))
    }
    function endDrag() {
        const d = drag, s = drop
        drag = null; drop = null; edge.stop()
        // the arrangement as it is, as data: app ids and { name, apps: [ids] }
        let L = entries.map(e => e.folder !== undefined ? { name: e.folder, apps: e.apps.map(a => a.id) } : e.app.id)
        let moving
        if (d.from >= 0) {                          // out of a folder
            if (!s) return                          // let go on the folder (or nowhere): no change
            const f = L[d.from]
            moving = f.apps[d.at]
            f.apps.splice(d.at, 1)
            if (f.apps.length === 1) L[d.from] = f.apps[0]   // a folder of one is just that app
        } else {
            if (!s) return
            moving = L[d.at]
            L[d.at] = null                          // keeps the indices while it's placed
        }
        const t = s.idx
        if (s.into && typeof moving === "string" && L[t] !== null && L[t] !== undefined) {
            if (typeof L[t] === "string") L[t] = { name: folderName(L[t], moving), apps: [L[t], moving] }
            else if (!L[t].apps.includes(moving)) L[t].apps.push(moving)
        } else L.splice(s.into ? t : s.insert, 0, moving)
        Config.set("launcher", "padLayout", L.filter(x => x !== null))
    }
    // a new folder is named for what its two apps have in common (Launcher.categoryOf), else "Folder"
    function folderName(a, b) {
        const ea = entries.find(e => e.app?.id === a)?.app, eb = entries.find(e => e.app?.id === b)?.app
        for (const k of Launcher.categories.slice(1))
            if ((Launcher.categoryOf[k] ?? []).some(c => ea?.categories.includes(c)) && (Launcher.categoryOf[k] ?? []).some(c => eb?.categories.includes(c))) return k
        return "Folder"
    }
    function rename(name) {
        const n = name.trim()
        if (!folder || !n || n === folder.folder) return
        const L = entries.map(e => e.folder !== undefined ? { name: e.folder, apps: e.apps.map(a => a.id) } : e.app.id)
        L[folderIndex].name = n
        Config.set("launcher", "padLayout", L)
    }

    // the icon in your hand
    Item {
        visible: pad.drag !== null
        z: 30
        x: (pad.drag?.x ?? 0) - pad.icon / 2
        y: (pad.drag?.y ?? 0) - pad.icon / 2
        width: pad.icon; height: pad.icon
        scale: 1.12
        IconImage {
            visible: !(pad.drag?.cell.isFolder ?? false)
            anchors.fill: parent
            implicitSize: pad.icon
            source: pad.drag && !pad.drag.cell.isFolder ? Quickshell.iconPath(pad.drag.cell.entry?.app?.icon ?? pad.drag.cell.entry?.icon ?? "", "application-x-executable") : ""
        }
        Rectangle {
            visible: pad.drag?.cell.isFolder ?? false
            anchors.fill: parent
            radius: pad.icon * 0.26
            color: Qt.rgba(1, 1, 1, 0.22)   // palette: on the dark scrim
        }
    }
    // where it will go: a thin bar in the gap
    Rectangle {
        readonly property var s: pad.drop
        visible: s !== null && !s.into && pad.drag !== null
        z: 29
        readonly property int col: s ? (s.insert > s.idx ? (s.idx % pad.perPage) % pad.cols + 1 : (s.idx % pad.perPage) % pad.cols) : 0
        readonly property int row: s ? Math.floor((s.idx % pad.perPage) / pad.cols) : 0
        x: pages.x + pad.side + col * pad.cellW - 2
        y: pages.y + row * pad.cellH + Math.max(16, (pad.cellH - pad.icon - 52) / 2)
        width: 4; height: pad.icon; radius: 2
        color: "white"   // palette: on the dark scrim
        opacity: 0.8
    }

    // ---- an open folder: its apps on a frosted sheet, over the dimmed pages -------------------------------------
    Item {
        id: folderLayer
        anchors.fill: parent
        z: 20
        visible: opacity > 0 || (pad.drag !== null && pad.drag.from >= 0)   // the held app's cell lives here: keep it
        opacity: pad.folder ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: pad.folder ? Theme.enter : Theme.exit; easing.type: Easing.OutCubic } }
        property var shown: null              // the folder drawn, kept while it fades out
        Connections { target: pad; function onFolderChanged() { if (pad.folder) { folderLayer.shown = pad.folder; nameField.text = pad.folder.folder } } }
        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.5 }   // palette: dims the pages behind
        MouseArea { anchors.fill: parent; Accessible.ignored: true; enabled: pad.folder !== null && !pad.drag; onClicked: pad.closeFolder() }
        Rectangle {
            id: sheet
            readonly property int n: folderLayer.shown?.apps.length ?? 0
            readonly property int c: Math.max(1, Math.min(n <= 4 ? 2 : n <= 9 ? 3 : 5, n))
            readonly property real cw: pad.icon + 72
            readonly property real ch: pad.icon + 64
            anchors.centerIn: parent
            width: Math.max(320, c * cw + Theme.spaceXl * 2)
            height: Math.min(parent.height - Theme.spaceL, nameField.height + Theme.spaceXl * 2 + Theme.spaceL + Math.ceil(n / c) * ch)
            radius: 32
            color: Qt.rgba(0.17, 0.17, 0.19, 0.96)   // palette: a dark sheet on the dark scrim (no blur under it)
            border { width: 1; color: Qt.rgba(1, 1, 1, 0.10) }
            scale: pad.folder || !Theme.moves ? 1 : 0.92
            Behavior on scale { NumberAnimation { duration: Theme.enter; easing.type: Easing.OutCubic } }
            MouseArea { anchors.fill: parent; Accessible.ignored: true }   // a click on the sheet keeps it open
            TextInput {
                id: nameField
                anchors { top: parent.top; topMargin: Theme.spaceXl; horizontalCenter: parent.horizontalCenter }
                width: Math.min(implicitWidth + 4, parent.width - Theme.spaceXl * 2)
                horizontalAlignment: TextInput.AlignHCenter
                color: "white"   // palette: on the dark scrim
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                font { family: Theme.displayFont; pixelSize: Theme.fontHeading; weight: Font.DemiBold }
                maximumLength: 40
                Accessible.role: Accessible.EditableText; Accessible.name: "Folder name"
                onAccepted: { pad.rename(text); Launcher.field.forceActiveFocus() }
                onActiveFocusChanged: if (!activeFocus) pad.rename(text)
                Keys.onEscapePressed: { text = pad.folder?.folder ?? text; Launcher.field.forceActiveFocus() }
                Rectangle {   // an underline while you rename it
                    anchors { left: parent.left; right: parent.right; top: parent.bottom; topMargin: 2 }
                    height: 1
                    color: "white"   // palette: on the dark scrim
                    opacity: parent.activeFocus ? 0.6 : 0
                }
            }
            Grid {
                anchors { top: nameField.bottom; topMargin: Theme.spaceL; horizontalCenter: parent.horizontalCenter }
                columns: sheet.c
                Repeater {
                    model: folderLayer.shown?.apps ?? []
                    LauncherPadCell {
                        pad: me
                        required property var modelData
                        required property int index
                        entry: ({ app: modelData })
                        at: index
                        inFolder: pad.folderIndex
                        width: sheet.cw; height: sheet.ch
                        current: pad.folder !== null && pad.folderCurrent === index
                    }
                }
            }
        }
    }
}
