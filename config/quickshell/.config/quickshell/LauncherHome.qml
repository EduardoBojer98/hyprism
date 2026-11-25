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
    readonly property bool listy: !Launcher.iconHome   // frequent apps as rows, not icons
    readonly property bool plated: Launcher.layout === "grid"   // recent items as icons too
    function has(h) { return Launcher.homeSections.includes(h) }

    // weather, the next calendar event and the last thing copied
    Row {
        id: glance
        visible: home.has("glance")
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
                color: tileArea.containsMouse ? Theme.fillHover : "transparent"
                border { width: 1; color: Theme.stroke }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Rectangle {   // the glyph on a disc tinted with the accent, so the tile reads as live information
                    id: tileGlyph
                    anchors { left: parent.left; leftMargin: Theme.spaceS + 2; verticalCenter: parent.verticalCenter }
                    width: Theme.iconMedium + Theme.spaceS; height: width
                    radius: Launcher.corner === 0 ? 0 : width / 2
                    color: Theme.accentWash
                    Text {
                        anchors.centerIn: parent
                        text: tile.modelData.glyph
                        color: Theme.accent
                        font { family: Theme.iconFont; pixelSize: Theme.glyph }
                    }
                }
                Column {
                    anchors { left: tileGlyph.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                    Text { width: parent.width; text: tile.modelData.title; elide: Text.ElideRight; maximumLineCount: 1; color: Theme.text; font { family: Launcher.rowFont; pixelSize: Theme.fontSize; weight: Font.DemiBold } }
                    Text { width: parent.width; text: tile.modelData.sub; elide: Text.ElideRight; color: Theme.subtext; font { family: Launcher.rowFont; pixelSize: Theme.fontCaption } }
                }
                MouseArea { id: tileArea; Accessible.role: Accessible.Button; Accessible.name: tile.modelData.title; Accessible.onPressAction: tile.modelData.run(); anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tile.modelData.run() }
            }
        }
    }

    // grid (Lumen): the Recent row first, as icons on plates
    LauncherHomeLabel { visible: home.plated && home.has("recent") && Search.recentItems.length > 0; text: "Recent" }
    IconGrid { visible: home.plated && home.has("recent"); items: Search.recentItems; section: "recent" }

    LauncherHomeLabel { visible: home.has("frequent"); text: "Frequently used" }
    Repeater {
        model: Launcher.open && home.has("frequent") && home.listy ? Search.frequentApps : []
        LauncherHomeRow { required property var modelData; required property int index; item: modelData; at: Launcher.homeOffset("frequent") + index }
    }
    IconGrid { visible: home.has("frequent") && !home.listy; items: Search.frequentApps; section: "frequent" }

    LauncherHomeLabel { visible: !home.plated && home.has("recent") && Search.recentItems.length > 0; text: "Recent" }
    Repeater {
        model: Launcher.open && home.has("recent") && !home.plated ? Search.recentItems : []
        LauncherHomeRow { required property var modelData; required property int index; item: modelData; at: Launcher.homeOffset("recent") + index }
    }

    LauncherHomeLabel { visible: home.has("quick"); text: "Quick actions" }
    // quick actions as chips that wrap, each with its whole name (columns cut them off)
    Flow {
        id: quick
        visible: home.has("quick")
        width: parent.width
        spacing: Theme.spaceS
        Repeater {
            model: Launcher.open && quick.visible ? Search.quickActions : []
            LauncherChip { required property var modelData; required property int index; item: modelData; at: Launcher.homeOffset("quick") + index }
        }
    }

    // a centred row of up to 8 icons (two rows in a narrow panel); a few get wider cells instead of a gap at the end
    component IconGrid: Grid {
        id: freq
        property var items: []
        property string section
        readonly property int fits: Math.max(3, Math.min(8, Math.floor(home.width / 80)))
        // more than fit: rows of even length (4 + 4, not 7 + 1)
        readonly property int perRow: Math.max(1, Math.ceil(items.length / Math.max(1, Math.ceil(items.length / fits))))
        readonly property real cell: Math.floor(home.width / Math.max(perRow, Math.min(fits, 6)))
        anchors.horizontalCenter: parent.horizontalCenter
        columns: perRow
        z: 1   // name tooltips over the labels below
        Repeater {
            model: Launcher.open && freq.visible ? freq.items : []
            Item {
                id: app
                required property var modelData
                required property int index
                readonly property int at: Launcher.homeOffset(freq.section) + index
                readonly property bool current: Launcher.homeIndex === at
                width: freq.cell; height: 104   // room for a two-line name ("Visual Studio Code")
                z: appArea.containsMouse ? 1 : 0
                Rectangle {
                    anchors { fill: parent; margins: 3 }
                    radius: Launcher.corner === 0 ? 0 : Theme.radius
                    color: appArea.containsMouse && !app.current ? Theme.fillHover : "transparent"
                    LauncherSelection { on: app.current; radius: parent.radius }
                }
                Item {
                    id: freqIcon
                    anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.spaceM }
                    width: 44; height: width
                    LauncherPlate {}
                    IconImage {
                        anchors.fill: parent
                        visible: !!app.modelData.icon
                        source: app.modelData.icon ? Quickshell.iconPath(app.modelData.icon, "application-x-executable") : ""
                    }
                    Text {   // a recent file, setting or action: its glyph on the plate
                        anchors.centerIn: parent
                        visible: !app.modelData.icon
                        text: app.modelData.glyph ?? ""
                        color: app.current ? Launcher.selText : Theme.text
                        font { family: Theme.iconFont; pixelSize: Theme.iconMedium }
                    }
                }
                Text {
                    anchors { left: parent.left; right: parent.right; top: freqIcon.bottom; topMargin: Theme.spaceXs + (Launcher.layout === "grid" ? Theme.spaceS : 0); margins: Theme.spaceXs }
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
                MouseArea { id: appArea; Accessible.role: Accessible.ListItem; Accessible.name: app.modelData.title; Accessible.onPressAction: Launcher.activate(app.modelData); anchors.fill: parent; hoverEnabled: true; onEntered: Launcher.homeIndex = app.at; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: mouse => mouse.button === Qt.RightButton ? Launcher.menuFor(app.modelData, appArea, mouse.x, mouse.y) : Launcher.activate(app.modelData) }
            }
        }
    }
}
