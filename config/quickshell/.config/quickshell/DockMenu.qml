import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: the right-click menu for one dock icon: its windows, then actions.
// Used by Dock.qml, which passes itself in as `dock`.
// Right-click menu for one dock icon: its windows, then actions
Glass {
    required property var dock
    id: menu
    property var entry: null      // DesktopEntry
    property var item: null       // the dock icon it belongs to
    readonly property var windows: item?.windows ?? []   // a window tile has just its own window
    readonly property bool pinned: entry ? Config.dock.pinned.includes(entry.id) : false
    function openFor(icon, appEntry) { item = icon; entry = appEntry ?? icon.modelData; closeTimer.restart() }
    function done() { entry = null; item = null }

    visible: entry !== null
    strong: true
    radius: Theme.radius
    width: 220
    height: actions.implicitHeight + Theme.spaceS * 2
    readonly property point at: item ? dock.beside(width, height, dock.middleOf(item), Theme.spaceS) : Qt.point(0, 0)
    x: at.x; y: at.y

    // closes a moment after the pointer leaves it (or never enters it)
    HoverHandler { onHoveredChanged: if (!hovered) closeTimer.restart(); else closeTimer.stop() }
    Timer { id: closeTimer; interval: 1500; onTriggered: menu.done() }

    Column {
        id: actions
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
        Text {
            width: parent.width; leftPadding: Theme.spaceS; bottomPadding: Theme.spaceXs
            text: menu.entry?.name ?? ""; elide: Text.ElideRight
            color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
        }
        Repeater {
            model: menu.windows.slice(0, 8).map(t => ({
                label: t.title || menu.entry?.name || "", window: t, run: () => dock.focus(t)
            })).concat([
                { label: "New window", show: menu.entry !== null, run: () => menu.entry.execute() },
                { label: "Minimise", show: menu.windows.some(t => !dock.isMinimised(t)), run: () => menu.windows.forEach(dock.minimise) },
                { label: "Restore", show: menu.windows.some(dock.isMinimised), run: () => menu.windows.filter(dock.isMinimised).forEach(dock.restore) },
                { label: menu.pinned ? "Unpin from dock" : "Pin to dock", show: menu.entry !== null, run: () => dock.setPinned(menu.entry, !menu.pinned) },
                { label: menu.item?.mid !== undefined ? "Close window" : menu.windows.length > 1 ? `Quit (${menu.windows.length} windows)` : "Quit", show: menu.windows.length > 0, run: () => menu.windows.forEach(dock.close) }
            ].filter(a => a.show).map((a, i) => Object.assign(a, { sep: i === 0 && menu.windows.length > 0 })))
            Item {
                id: menuRow
                required property var modelData
                width: actions.width
                height: Theme.controlHeight - 2 + (modelData.sep ? 9 : 0)
                Rectangle {   // between the windows and the actions
                    visible: !!menuRow.modelData.sep
                    anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 4; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS }
                    height: 1
                    color: Theme.stroke
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: Theme.controlHeight - 2
                    radius: Theme.radiusSmall - 2
                    color: rowArea.containsMouse ? Theme.accent : "transparent"
                    Row {
                        anchors { left: parent.left; right: parent.right; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        Rectangle {   // window rows: focused / minimised marker
                            visible: !!menuRow.modelData.window
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6; height: 6; radius: 3
                            color: rowArea.containsMouse ? Theme.accentText : Theme.text
                            opacity: menuRow.modelData.window?.activated ? 1 : dock.isMinimised(menuRow.modelData.window ?? {}) ? 0.25 : 0.55
                        }
                        Text {
                            width: parent.width - (menuRow.modelData.window ? 12 : 0)
                            text: menuRow.modelData.label; elide: Text.ElideRight
                            color: rowArea.containsMouse ? Theme.accentText : Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontSize }
                        }
                    }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { menuRow.modelData.run(); menu.done() }
                    }
                }
            }
        }
    }
}
