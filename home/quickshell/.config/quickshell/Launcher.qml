pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

// Spotlight-style launcher with three tabs:
//   Apps       apps · calculator (type a sum) · system actions · "> cmd" · web search
//   Files      files in your home folder (fd, respects .gitignore, skips hidden folders)
//   Clipboard  cliphist history; Enter copies the entry back
// Keys: Super+Space apps · Super+Shift+Space files · Super+V clipboard (hypr/modules/binds.lua)
//       Tab / Shift+Tab or Ctrl+1/2/3 switch tabs · ↑↓ move · Enter open · Esc close
Singleton {
    id: root

    readonly property var tabs: [
        { name: "Apps",      glyph: "\u{F003B}" },
        { name: "Files",     glyph: "\u{F0214}" },
        { name: "Clipboard", glyph: "\u{F014C}" },
    ]
    property bool open: false
    property int tab: 0
    property string query: ""
    property var clips: []   // [{ id, text }] from cliphist, newest first
    property var files: []   // absolute paths from fd

    function show(t) {
        tab = t
        query = ""
        files = []
        cliphist.running = true
        open = true
    }
    function toggle() { if (open) open = false; else show(0) }
    function setTab(t) { tab = (t + tabs.length) % tabs.length; filesTimer.restart() }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggle() }
        function files(): void { root.show(1) }
        function clipboard(): void { root.show(2) }
    }

    Process {
        id: cliphist
        command: ["cliphist", "list"]
        property var buffer: []
        onStarted: buffer = []
        stdout: SplitParser {
            onRead: line => {
                const tab = line.indexOf("\t")
                if (tab > 0 && cliphist.buffer.length < 200)
                    cliphist.buffer.push({ id: line.slice(0, tab), text: line.slice(tab + 1) })
            }
        }
        onExited: root.clips = buffer
    }

    // File search runs shortly after typing stops
    onQueryChanged: filesTimer.restart()
    Timer {
        id: filesTimer
        interval: 150
        onTriggered: {
            if (root.tab !== 1 || root.query.trim().length < 2) { root.files = []; return }
            fd.running = false
            fd.command = ["fd", "--type", "f", "--ignore-case", "--max-results", "40",
                          "--exclude", "node_modules", "--exclude", "vendor", "--", root.query.trim(), Quickshell.env("HOME")]
            fd.running = true
        }
    }
    Process {
        id: fd
        property var buffer: []
        onStarted: buffer = []
        stdout: SplitParser { onRead: line => fd.buffer.push(line) }
        onExited: root.files = buffer
    }

    readonly property var actions: [
        { title: "Lock",       glyph: "\u{F033E}", cmd: ["loginctl", "lock-session"] },
        { title: "Suspend",    glyph: "\u{F04B2}", cmd: ["systemctl", "suspend"] },
        { title: "Hibernate",  glyph: "\u{F0717}", cmd: ["systemctl", "hibernate"] },
        { title: "Log out",    glyph: "\u{F0343}", cmd: ["hyprshutdown"] },
        { title: "Restart",    glyph: "\u{F0709}", cmd: ["systemctl", "reboot"] },
        { title: "Shut down",  glyph: "\u{F0425}", cmd: ["systemctl", "poweroff"] },
        { title: "Monitor to / from work PC", glyph: "\u{F0379}", cmd: ["monswitch", "toggle"] },
        { title: "Screenshot (area)", glyph: "\u{F0104}", cmd: ["sh", "-c", "sleep 0.3; hyprshot -m region -o ~/Pictures/Screenshots"] },
        { title: "Colour picker", glyph: "\u{F0266}", cmd: ["sh", "-c", "sleep 0.3; hyprpicker -a"] },
        { title: "ROG Control Center", glyph: "\u{F0493}", cmd: ["rog-control-center"] },
        { title: "Settings", glyph: "\u{F0493}", cmd: ["qs", "ipc", "call", "settings", "open", ""] },
    ]

    // 0 = no match; prefix beats word start beats substring
    function score(text, q) {
        const t = (text || "").toLowerCase()
        if (t.startsWith(q)) return 3
        if (t.includes(" " + q) || t.includes("-" + q)) return 2
        if (t.includes(q)) return 1
        return 0
    }

    function calculate(q) {
        // Only digits, operators and brackets reach Function(), so it can't run arbitrary code
        if (!/^[0-9+\-*/%^(). ,]+$/.test(q) || !/[0-9]/.test(q) || !/[+\-*/%^]/.test(q)) return null
        try {
            const v = Function("return (" + q.replace(/\^/g, "**").replace(/,/g, ".") + ")")()
            return Number.isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : null
        } catch (e) { return null }
    }

    function fileGlyph(path) {
        const ext = path.split(".").pop().toLowerCase()
        if (["png", "jpg", "jpeg", "webp", "gif", "svg"].includes(ext)) return "\u{F021F}"
        if (["pdf"].includes(ext)) return "\u{F0226}"
        if (["doc", "docx", "odt", "xls", "xlsx", "ods", "ppt", "pptx"].includes(ext)) return "\u{F0219}"
        if (["js", "ts", "tsx", "jsx", "php", "py", "lua", "qml", "sh", "css", "scss", "html", "json", "liquid"].includes(ext)) return "\u{F0169}"
        if (["zip", "tar", "gz", "zst", "7z"].includes(ext)) return "\u{F05C4}"
        return "\u{F0214}"
    }

    function copyClip(id) {
        Quickshell.execDetached(["sh", "-c", "cliphist decode " + id.replace(/[^0-9]/g, "") + " | wl-copy"])
    }

    readonly property var results: {
        const raw = query.trim()
        const q = raw.toLowerCase()
        const out = []
        const home = Quickshell.env("HOME")

        if (tab === 2) {
            for (const c of clips)
                if (!q || c.text.toLowerCase().includes(q))
                    out.push({ section: "Clipboard", title: c.text.trim() || "(blank text)", glyph: "\u{F014C}", run: () => copyClip(c.id) })
            return out.slice(0, 60)
        }

        if (tab === 1) {
            for (const f of files) {
                const name = f.split("/").pop()
                out.push({ section: "Files", title: name, subtitle: f.replace(home, "~"), glyph: fileGlyph(f),
                           run: () => Quickshell.execDetached(["xdg-open", f]) })
            }
            return out
        }

        if (q.startsWith(">")) {
            const cmd = raw.slice(1).trim()
            if (cmd) out.push({ section: "Run", title: cmd, subtitle: "Run in the background", glyph: "\u{F018D}",
                                run: () => Quickshell.execDetached(["sh", "-c", cmd]) })
            return out
        }

        const sum = calculate(q)
        if (sum !== null)
            out.push({ section: "Calculator", title: sum, subtitle: "Enter copies the result", glyph: "\u{F00EC}",
                       run: () => Quickshell.execDetached(["wl-copy", sum]) })

        const apps = DesktopEntries.applications.values
            .filter(e => !e.noDisplay)
            .map(e => ({ e, s: q ? Math.max(score(e.name, q) * 2, score(e.genericName, q), e.keywords.some(k => k.toLowerCase().startsWith(q)) ? 1 : 0) : 1 }))
            .filter(x => x.s > 0)
            .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
            .slice(0, q ? 6 : 14)
        for (const x of apps)
            out.push({ section: "Applications", title: x.e.name, subtitle: x.e.genericName || x.e.comment,
                       icon: x.e.icon, run: () => x.e.execute() })

        if (q) {
            for (const a of actions)
                if (score(a.title, q) > 0)
                    out.push({ section: "System", title: a.title, glyph: a.glyph, run: () => Quickshell.execDetached(a.cmd) })
            out.push({ section: "Web", title: "Search the web for “" + raw + "”", glyph: "\u{F059F}",
                       run: () => Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(raw)]) })
        }
        return out
    }

    // ---- window ----------------------------------------------------------------------------

    PanelWindow {
        visible: root.open
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Dimmed backdrop; clicking it closes the launcher
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, root.open ? 0.35 : 0)
            Behavior on color { ColorAnimation { duration: 140 } }
            MouseArea { anchors.fill: parent; onClicked: root.open = false }
        }

        Glass {
            id: panel
            strong: true
            radius: Theme.radiusLarge
            width: Math.min(720, parent.width - 40)
            height: Math.min(header.height + Math.max(list.contentHeight, list.count === 0 ? 56 : 0) + footer.height + 48, parent.height * 0.72)
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.17
            clip: true

            scale: root.open ? 1 : 0.96
            opacity: root.open ? 1 : 0
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent } // keep clicks inside from closing it

            // Search field + tabs
            Item {
                id: header
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                height: 46

                Text {
                    id: searchGlyph
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    text: "\u{F0349}"
                    color: Theme.muted
                    font { family: Theme.iconFont; pixelSize: 20 }
                }

                TextInput {
                    id: input
                    anchors { left: searchGlyph.right; leftMargin: 12; right: tabRow.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                    color: Theme.text
                    selectionColor: Theme.fillActive
                    clip: true
                    font { family: Theme.font; pixelSize: 20 }
                    focus: root.open
                    text: root.query
                    onTextEdited: { root.query = text; list.currentIndex = 0 }
                    onVisibleChanged: if (visible) forceActiveFocus()

                    Text {
                        visible: !input.text
                        text: ["Search apps, actions, sums…", "Search files…", "Search clipboard…"][root.tab]
                        color: Theme.muted
                        font: input.font
                    }

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier
                        if (event.key === Qt.Key_Escape) root.open = false
                        else if (event.key === Qt.Key_Tab) root.setTab(root.tab + 1)
                        else if (event.key === Qt.Key_Backtab) root.setTab(root.tab - 1)
                        else if (ctrl && event.key >= Qt.Key_1 && event.key <= Qt.Key_3) root.setTab(event.key - Qt.Key_1)
                        else if (event.key === Qt.Key_Down) list.incrementCurrentIndex()
                        else if (event.key === Qt.Key_Up) list.decrementCurrentIndex()
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) list.activate(list.currentIndex)
                        else return
                        event.accepted = true
                    }
                }

                // Segmented tabs with a sliding highlight
                Rectangle {
                    id: tabRow
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    width: tabsLayout.width + 8
                    height: 34
                    radius: height / 2
                    color: Theme.fill

                    Rectangle {
                        x: 4 + root.tab * (tabsLayout.width / root.tabs.length)
                        anchors.verticalCenter: parent.verticalCenter
                        width: tabsLayout.width / root.tabs.length
                        height: 26
                        radius: height / 2
                        color: Theme.fillActive
                        border { color: Theme.stroke; width: 1 }
                        Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    Row {
                        id: tabsLayout
                        anchors.centerIn: parent
                        Repeater {
                            model: root.tabs
                            Item {
                                required property var modelData
                                required property int index
                                width: 104
                                height: 26
                                Row {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: modelData.glyph
                                        color: root.tab === index ? Theme.accent : Theme.subtext
                                        font { family: Theme.iconFont; pixelSize: 14 }
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: modelData.name
                                        color: root.tab === index ? Theme.text : Theme.subtext
                                        font { family: Theme.font; pixelSize: 12; weight: Font.Medium }
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.setTab(index); input.forceActiveFocus() }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { // hairline under the header
                anchors { left: parent.left; right: parent.right; top: header.bottom; topMargin: 10 }
                height: 1
                color: Theme.stroke
            }

            ListView {
                id: list
                anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: footer.top; margins: 8; topMargin: 16 }
                model: root.results
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: 0

                function activate(i) {
                    const r = root.results[i]
                    if (!r) return
                    root.open = false
                    r.run()
                }

                // Empty states
                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 18 }
                    visible: list.count === 0
                    text: root.tab === 1 ? (root.query.trim().length < 2 ? "Type at least 2 letters to search your files" : "No files found")
                         : root.tab === 2 ? "Clipboard is empty" : "No results"
                    color: Theme.muted
                    font { family: Theme.font; pixelSize: 13 }
                }

                // Section title above the first result of each group
                delegate: Column {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool firstOfSection: index === 0 || root.results[index - 1]?.section !== modelData.section
                    width: list.width

                    Text {
                        visible: row.firstOfSection && root.tab === 0
                        text: row.modelData.section
                        topPadding: row.index === 0 ? 2 : 10
                        bottomPadding: 4
                        leftPadding: 12
                        color: Theme.muted
                        font { family: Theme.font; pixelSize: 11; weight: Font.DemiBold; capitalization: Font.AllUppercase }
                    }

                    Rectangle {
                        width: parent.width
                        height: 46
                        radius: 12
                        color: row.ListView.isCurrentItem ? Theme.fillActive : "transparent"
                        border { color: row.ListView.isCurrentItem ? Theme.stroke : "transparent"; width: 1 }

                        Item {
                            id: iconBox
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            width: 30; height: 30

                            IconImage {
                                visible: !!row.modelData.icon
                                anchors.fill: parent
                                source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                            }
                            Rectangle {
                                visible: !row.modelData.icon
                                anchors.fill: parent
                                radius: 9
                                color: Theme.fill
                                Text {
                                    anchors.centerIn: parent
                                    text: row.modelData.glyph ?? ""
                                    color: Theme.accent
                                    font { family: Theme.iconFont; pixelSize: 16 }
                                }
                            }
                        }

                        Column {
                            anchors { left: iconBox.right; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            Text {
                                width: parent.width
                                text: row.modelData.title ?? ""
                                color: Theme.text
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font { family: Theme.font; pixelSize: 14 }
                            }
                            Text {
                                width: parent.width
                                visible: !!row.modelData.subtitle
                                text: row.modelData.subtitle ?? ""
                                color: Theme.muted
                                elide: Text.ElideMiddle
                                font { family: Theme.font; pixelSize: 11 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: list.currentIndex = row.index
                            onClicked: list.activate(row.index)
                        }
                    }
                }
            }

            // Key hints
            Row {
                id: footer
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 12 }
                height: 18
                spacing: 18
                Repeater {
                    model: [["↑↓", "move"], ["↵", "open"], ["Tab", "switch tab"], ["Esc", "close"]]
                    Row {
                        required property var modelData
                        spacing: 6
                        Rectangle {
                            width: keyLabel.implicitWidth + 10; height: 18; radius: 5
                            color: Theme.fill
                            border { color: Theme.stroke; width: 1 }
                            Text { id: keyLabel; anchors.centerIn: parent; text: modelData[0]; color: Theme.subtext; font { family: Theme.font; pixelSize: 11 } }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData[1]; color: Theme.muted; font { family: Theme.font; pixelSize: 11 } }
                    }
                }
            }
        }
    }
}
