import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// Installed Apps: every app in the menu, filtered by where it came from (repository, AUR, Flatpak,
// your own folder, by hand) and sorted by name or size. Click an app for its details (what it is,
// where it came from, version, size, dates, where its files are); open it, show it in the file
// manager or uninstall it. ~/.local/bin/installed-apps does the looking up and removing; package
// removals run in a terminal, which shows what goes and asks before anything is removed.
ColumnLayout {
    id: page
    spacing: 20

    property var info: null   // desktop id -> {source, package, version, size, path}; null while loading
    property var details: ({})   // desktop id -> installed-apps info, fetched when an app is opened
    property string expanded: ""
    property string query: ""
    property int filter: 0
    property bool bySize: false

    readonly property var sourceName: ({ pacman: "Repository", aur: "AUR", rpm: "Package", flatpak: "Flatpak", user: "Your apps folder", other: "Installed by hand" })
    // Where-from filters: label, glyph, the sources each covers (none = all)
    readonly property var filters: [
        { name: "All apps",   glyph: "\u{F003B}", sources: [] },
        { name: "Repository", glyph: "\u{F03D6}", sources: ["pacman", "rpm"] },
        { name: "AUR",        glyph: "\u{F08EA}", sources: ["aur"] },
        { name: "Flatpak",    glyph: "\u{F01A7}", sources: ["flatpak"] },
        { name: "Your apps",  glyph: "\u{F0004}", sources: ["user"] },
        { name: "By hand",    glyph: "\u{F05B7}", sources: ["other"] },
    ]
    readonly property var visibleApps: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    function count(f) { return f.sources.length ? visibleApps.filter(e => f.sources.includes(info?.[e.id]?.source)).length : visibleApps.length }
    // All, plus the filters with apps in them (counts known once the lookup is done)
    readonly property var shownFilters: info ? filters.filter((f, i) => i === 0 || count(f) > 0) : [filters[0]]
    readonly property var apps: {
        const q = query.trim().toLowerCase()
        const f = shownFilters[filter] ?? filters[0]
        return visibleApps
            .filter(e => (!f.sources.length || f.sources.includes(info?.[e.id]?.source))
                      && (!q || e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q)
                          || (info?.[e.id]?.package ?? "").toLowerCase().includes(q)))
            .sort((a, b) => bySize ? bytes(b.id) - bytes(a.id) || a.name.localeCompare(b.name) : a.name.localeCompare(b.name))
    }

    // "46.87 MiB" (pacman) or "1.3 MB" (flatpak) -> bytes, near enough to sort by
    function bytes(id) {
        const m = /^([\d.]+)\s*([KMGT]?)i?B$/.exec(info?.[id]?.size ?? "")
        return m ? parseFloat(m[1]) * Math.pow(1024, " KMGT".indexOf(m[2] || " ")) : 0
    }

    function detail(id) {
        const i = info?.[id]
        if (!i) return info ? "" : "Looking up…"
        return [sourceName[i.source], i.package && i.package !== id ? i.package : "", i.version, i.size].filter(s => s).join(" · ")
    }

    function toggle(id) {
        expanded = expanded === id ? "" : id
        if (expanded && !details[id]) { infoProc.command = ["installed-apps", "info", id]; infoProc.running = true }
    }

    Process {
        running: true
        command: ["installed-apps", "list"]
        stdout: StdioCollector { onStreamFinished: { try { page.info = JSON.parse(text) } catch (e) { page.info = {} } } }
    }
    Process {
        id: infoProc
        stdout: StdioCollector {
            onStreamFinished: {
                const d = Object.assign({}, page.details)
                try { d[infoProc.command[2]] = JSON.parse(text) } catch (e) { d[infoProc.command[2]] = { fields: [] } }
                page.details = d
            }
        }
    }

    // ---- toolbar: search and sort, then the where-from filters --------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: height / 2
            color: Theme.fill
            border { color: search.activeFocus ? Theme.accent : Theme.stroke; width: 1 }
            Text {
                id: lens
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                text: "\u{F0349}"
                color: Theme.subtext
                font { family: Theme.iconFont; pixelSize: 16 }
            }
            TextInput {
                id: search
                anchors { left: lens.right; leftMargin: 10; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                clip: true
                color: Theme.text
                selectionColor: Theme.accent
                font { family: Theme.font; pixelSize: Theme.fontSize }
                onTextChanged: page.query = text
                Text {
                    visible: !search.text
                    text: "Search " + page.visibleApps.length + " apps by name or package"
                    color: Theme.muted
                    font: search.font
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
        Dropdown {
            implicitWidth: 150
            implicitHeight: 36
            options: ["Sort by name", "Sort by size"]
            current: page.bySize ? "Sort by size" : "Sort by name"
            onPicked: v => page.bySize = v === "Sort by size"
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: page.shownFilters
            Rectangle {
                id: chip
                required property var modelData
                required property int index
                readonly property bool active: page.filter === index
                width: chipRow.implicitWidth + 24
                height: 34
                radius: height / 2
                color: active ? Theme.accent : chipArea.containsMouse ? Theme.fillHover : Theme.fill
                border { color: active ? "transparent" : Theme.stroke; width: 1 }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: chip.modelData.glyph
                        color: chip.active ? Theme.accentText : Theme.subtext
                        font { family: Theme.iconFont; pixelSize: 15 }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: chip.modelData.name
                        color: chip.active ? Theme.accentText : Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium }
                    }
                    Rectangle {   // count badge
                        visible: page.info !== null
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(22, num.implicitWidth + 12)
                        height: 20
                        radius: 10
                        color: chip.active ? Qt.alpha(Theme.accentText, 0.18) : Theme.fillActive
                        Text {
                            id: num
                            anchors.centerIn: parent
                            text: page.info ? page.count(chip.modelData) : ""
                            color: chip.active ? Theme.accentText : Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                        }
                    }
                }
                MouseArea { id: chipArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.filter = chip.index }
            }
        }
    }

    // ---- the apps -----------------------------------------------------------------------------
    Text {
        visible: page.info !== null && page.apps.length === 0
        Layout.fillWidth: true
        Layout.topMargin: 20
        horizontalAlignment: Text.AlignHCenter
        text: "No apps match"
        color: Theme.muted
        font { family: Theme.font; pixelSize: Theme.fontSize }
    }

    SettingGroup {
        visible: page.apps.length > 0
        Repeater {
            model: page.apps
            ColumnLayout {
                id: row
                required property var modelData
                required property int index
                readonly property var src: page.info?.[modelData.id]?.source ?? ""
                readonly property bool open: page.expanded === modelData.id
                readonly property var more: page.details[modelData.id] ?? null
                Layout.fillWidth: true
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 56
                    Rectangle { visible: row.index > 0; anchors { left: parent.left; right: parent.right; leftMargin: 16 } height: 1; color: Theme.stroke }
                    Rectangle {   // hover and open highlight
                        anchors { fill: parent; margins: 1 }
                        radius: Theme.radiusSmall
                        color: row.open ? Theme.accentWash : headArea.containsMouse ? Theme.fillHover : "transparent"
                    }
                    MouseArea { id: headArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: page.toggle(row.modelData.id) }
                    Chevron {
                        id: chev
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        open: row.open
                        size: 16
                        rotation: row.open ? 0 : -90
                    }
                    IconImage {
                        id: icon
                        anchors { left: chev.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
                        implicitSize: 30
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    }
                    Column {
                        anchors { left: icon.right; leftMargin: 12; right: buttons.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        Text {
                            width: parent.width
                            text: row.modelData.name
                            elide: Text.ElideRight
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium }
                        }
                        Text {
                            width: parent.width
                            text: page.detail(row.modelData.id)
                            elide: Text.ElideRight
                            color: Theme.muted
                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                        }
                    }
                    Row {
                        id: buttons
                        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        PillButton { text: "Open"; onClicked: row.modelData.execute() }
                        PillButton { text: "Show in Files"; enabled: row.src !== ""; onClicked: Quickshell.execDetached(["installed-apps", "show", row.modelData.id]) }
                        PillButton {
                            text: row.src === "user" ? "Remove" : "Uninstall"
                            enabled: row.src !== "" && row.src !== "other"
                            onClicked: Quickshell.execDetached(["installed-apps", "remove", row.modelData.id])
                        }
                    }
                }

                // details: what it is, then label/value lines; paths can be selected and copied
                ColumnLayout {
                    visible: row.open
                    Layout.fillWidth: true
                    Layout.leftMargin: 64
                    Layout.rightMargin: 24
                    Layout.topMargin: 14
                    Layout.bottomMargin: 24
                    spacing: 18
                    Text {
                        visible: text !== ""
                        Layout.fillWidth: true
                        text: row.more ? (row.more.description || row.modelData.comment || row.modelData.genericName) : "Looking up…"
                        wrapMode: Text.Wrap
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontSize }
                    }
                    GridLayout {
                        visible: row.more !== null
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 24
                        rowSpacing: 11
                        Repeater {
                            model: [].concat(...(row.more?.fields ?? []).map(f => [{ text: f[0], label: true }, { text: f[1], label: false }]))
                            TextEdit {
                                required property var modelData
                                Layout.fillWidth: !modelData.label
                                Layout.alignment: Qt.AlignTop
                                Layout.preferredWidth: modelData.label ? 130 : -1
                                text: modelData.text
                                readOnly: true
                                selectByMouse: !modelData.label
                                wrapMode: TextEdit.Wrap
                                selectionColor: Theme.accent
                                color: modelData.label ? Theme.muted : Theme.text
                                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: modelData.label ? Font.Medium : Font.Normal }
                            }
                        }
                    }
                    PillButton {
                        visible: (row.more?.url ?? "") !== ""
                        text: row.src === "flatpak" ? "Open on Flathub" : "Open website"
                        onClicked: Qt.openUrlExternally(row.more.url)
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Click an app for its details. Uninstall opens a terminal that lists what will be removed and asks first (packages need your password). "
            + "Remove moves an entry from ~/.local/share/applications to the Trash. Apps installed by hand (in /usr/local or /opt) can't be uninstalled from here."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
