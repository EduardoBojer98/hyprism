pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

// Spotlight: opens at the cursor (Super). A search pill plus four round buttons, like macOS Tahoe:
//   Search    everything at once, best match first (Search.qml decides: apps, settings, actions,
//             calculator, "> command", files, "~/path", custom actions, web)
//   Apps      every application as a grid, filtered by category chips and by what you type
//   Files     files and folders only        Actions   system and custom actions only
//   Clipboard opens the clipboard history (Super+V)
// Keys: type · ↑↓ (←→ in Apps) move · Enter open · Tab next mode · Esc close
Singleton {
    id: root

    readonly property var modes: [
        { id: "apps",    name: "Applications", glyph: "\u{F003B}" },
        { id: "files",   name: "Files",        glyph: "\u{F024B}" },
        { id: "actions", name: "Actions",      glyph: "\u{F0E7}" },
        { id: "clip",    name: "Clipboard",    glyph: "\u{F014C}" },
    ]
    property string mode: "search"            // search | apps | files | actions
    property string category: "All"
    property bool open: popup.open

    function show(m) {
        mode = m || "search"
        category = "All"
        field.text = ""
        popup.show()
    }
    function toggle() { if (popup.open) popup.hide(); else show("search") }
    function setMode(m) {
        if (m === "clip") { popup.hide(); Clipboard.toggle(); return }
        mode = mode === m ? "search" : m
        results.currentIndex = 0
        grid.currentIndex = 0
        field.forceActiveFocus()
    }
    function cycleMode() {
        const order = ["search", "apps", "files", "actions"]
        mode = order[(order.indexOf(mode) + 1) % order.length]
        results.currentIndex = 0
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function apps(): void { root.show("apps") }
        function files(): void { root.show("files") }
        function clipboard(): void { Clipboard.toggle() }
        function search(text: string): void { root.show("search"); field.text = text }
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

    // ---- window --------------------------------------------------------------------------------
    CursorPopup {
        id: popup
        name: "launcher"
        boxWidth: 720
        boxHeight: pill.height + (panel.visible ? panel.height + Theme.spaceS : 0)
        focusItem: field
        onClosed: { field.text = ""; root.confirmFor = null }

        // Search pill and round mode buttons ----------------------------------------------------
        Item {
            id: pill
            width: parent.width
            height: 52

            Glass {
                id: searchBox
                anchors { left: parent.left; top: parent.top; bottom: parent.bottom; right: buttons.left; rightMargin: Theme.spaceS }
                strong: true
                radius: height / 2

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
                    font { family: Theme.font; pixelSize: Theme.fontHeading }
                    onTextChanged: { Search.query = text; results.currentIndex = 0; grid.currentIndex = 0; root.confirmFor = null }
                    Text {
                        visible: !field.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.mode === "search" ? "Spotlight Search" : root.modes.find(m => m.id === root.mode)?.name ?? ""
                        color: Theme.muted
                        font: field.font
                    }

                    Keys.onPressed: event => {
                        const inGrid = root.mode === "apps"
                        const view = inGrid ? grid : results
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

            Row {
                id: buttons
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Theme.spaceS
                Repeater {
                    model: root.modes
                    Glass {
                        required property var modelData
                        readonly property bool current: root.mode === modelData.id
                        width: 52; height: 52
                        radius: width / 2
                        strong: true
                        color: current ? Theme.accentWash : buttonArea.containsMouse ? Qt.darker(Theme.glassStrong, 1.2) : Theme.glassStrong
                        border.color: current ? Theme.accent : Theme.stroke
                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            color: current ? Theme.accent : Theme.text
                            font { family: Theme.iconFont; pixelSize: Theme.iconMedium }
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

        // Results / browse panel ------------------------------------------------------------------
        Glass {
            id: panel
            anchors { top: pill.bottom; topMargin: Theme.spaceS; left: parent.left; right: parent.right }
            strong: true
            radius: Theme.radiusLarge
            visible: root.mode !== "search" || field.text.trim() !== ""
            height: root.mode === "apps" ? 460
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

            // Apps: category chips and icon grid
            Item {
                anchors.fill: parent
                visible: root.mode === "apps"
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
                    cellWidth: Math.floor(width / 7)
                    cellHeight: 104
                    model: root.appGrid
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: Theme.animFast
                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        width: grid.cellWidth; height: grid.cellHeight
                        Rectangle {
                            anchors { fill: parent; margins: 3 }
                            radius: Theme.radius
                            color: cell.GridView.isCurrentItem ? Theme.fillActive : cellArea.containsMouse ? Theme.fillHover : "transparent"
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
                            text: cell.modelData.name
                            elide: Text.ElideRight
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontLabel }
                        }
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
                visible: root.mode !== "apps"
                anchors { fill: parent; margins: Theme.spaceS; topMargin: confirmBar.visible ? 52 : Theme.spaceS }
                clip: true
                model: root.listModel
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: Theme.animFast

                Text {
                    anchors.centerIn: parent
                    visible: results.count === 0
                    text: root.mode === "files" ? "Type a name, ~/path or /path" : "No results"
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontSize }
                }

                delegate: Column {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool topHit: index === 0 && root.mode === "search"
                    readonly property bool newSection: index > 0 && root.listModel[index - 1]?.kind !== modelData.kind && !(index === 1 && root.mode === "search")
                    width: results.width

                    Text {
                        visible: row.topHit || row.newSection || (row.index === 1 && root.mode === "search")
                        text: row.topHit ? "Top Hit" : row.modelData.kind
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
                        color: row.ListView.isCurrentItem ? Theme.accentWash : rowArea.containsMouse ? Theme.fillHover : "transparent"
                        border { color: row.ListView.isCurrentItem ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.5) : "transparent"; width: 1 }

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
}
