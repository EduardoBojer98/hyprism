import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: the home view (weather, next event and last copy; frequent apps; recent items; quick actions).
// Used by LauncherPanel.qml; reads the panel's state from the Launcher singleton.
Column {
    id: home
    visible: Launcher.view === "home" && !Launcher.confirmFor
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
                              run: () => { Launcher.close(); Weather.toggle() } } : null,
            Calendar.next ? { glyph: "\u{F00ED}", title: Calendar.next.title,
                              sub: (Calendar.next.days === 0 ? "Today" : Calendar.next.days === 1 ? "Tomorrow" : Calendar.locale.toString(Calendar.next.date, "ddd d MMM")),
                              run: () => { Launcher.close(); Calendar.toggle() } } : null,
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
                radius: Launcher.corner === 0 ? 0 : Theme.radius
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
                    Text { width: parent.width; text: tile.modelData.title; elide: Text.ElideRight; maximumLineCount: 1; color: Theme.text; font { family: Launcher.rowFont; pixelSize: Theme.fontSize; weight: Font.Medium } }
                    Text { width: parent.width; text: tile.modelData.sub; elide: Text.ElideRight; color: Theme.subtext; font { family: Launcher.rowFont; pixelSize: Theme.fontCaption } }
                }
                MouseArea { id: tileArea; Accessible.role: Accessible.Button; Accessible.name: tile.modelData.title; Accessible.onPressAction: tile.modelData.run(); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.modelData.run() }
            }
        }
    }

    LauncherHomeLabel { text: "Frequently used" }
    // a centred row of up to 8 (two rows in a narrow panel); a few apps get wider cells instead of a gap at the end
    Grid {
        id: freq
        readonly property int fits: Math.max(3, Math.min(8, Math.floor(home.width / 80)))
        readonly property int perRow: Math.max(1, Math.min(Search.frequentApps.length, fits))
        readonly property real cell: Math.floor(home.width / Math.max(perRow, Math.min(fits, 6)))
        anchors.horizontalCenter: parent.horizontalCenter
        columns: perRow
        z: 1   // name tooltips over the labels below
        Repeater {
            model: Search.frequentApps
            Item {
                id: app
                required property var modelData
                required property int index
                readonly property bool current: Launcher.homeIndex === index
                width: freq.cell; height: 104   // room for a two-line name ("Visual Studio Code")
                z: appArea.containsMouse ? 1 : 0
                Rectangle {
                    anchors { fill: parent; margins: 3 }
                    radius: Launcher.corner === 0 ? 0 : Theme.radius
                    color: app.current ? Launcher.selection : appArea.containsMouse ? Theme.fillHover : "transparent"
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
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    color: app.current ? Launcher.selText : Theme.text
                    font { family: Launcher.rowFont; pixelSize: Theme.fontLabel }
                }
                ToolTipText { gap: -Theme.spaceS; shown: appArea.containsMouse && appName.truncated; text: app.modelData.title }
                MouseArea { id: appArea; Accessible.role: Accessible.ListItem; Accessible.name: app.modelData.title; Accessible.onPressAction: Launcher.activate(app.modelData); anchors.fill: parent; hoverEnabled: true; onEntered: Launcher.homeIndex = app.index; onClicked: Launcher.activate(app.modelData) }
            }
        }
    }

    LauncherHomeLabel { visible: Search.recentItems.length > 0; text: "Recent" }
    Repeater {
        model: Search.recentItems
        LauncherHomeRow { required property var modelData; required property int index; item: modelData; at: Search.frequentApps.length + index }
    }

    LauncherHomeLabel { text: "Quick actions" }
    Grid {
        id: quick
        width: parent.width
        columns: Math.max(1, Math.min(3, Math.floor(home.width / 200)))
        columnSpacing: Theme.spaceXs
        rowSpacing: Theme.spaceXs
        Repeater {
            model: Search.quickActions
            LauncherHomeRow {
                required property var modelData
                required property int index
                width: (home.width - Theme.spaceXs * (quick.columns - 1)) / quick.columns
                item: modelData
                at: Search.frequentApps.length + Search.recentItems.length + index
            }
        }
    }
}
