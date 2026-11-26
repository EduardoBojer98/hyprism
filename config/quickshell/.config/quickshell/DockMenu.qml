import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: the right-click menu for one dock icon: its windows, then actions.
// Used by Dock.qml, which passes itself in as `dock`.
// Right-click menu for one dock icon: its windows, then actions. It closes on Escape, on a click outside it, when
// an action runs, or when another icon's menu opens; Up / Down and Enter work it from the keyboard.
Glass {
    required property var dock
    id: menu
    property var entry: null      // DesktopEntry
    property var item: null       // the dock icon it belongs to
    readonly property var windows: item?.windows ?? []   // a window tile has just its own window
    readonly property bool pinned: entry ? Config.dock.pinned.includes(entry.id) : false
    property int cur: -1          // the row the keyboard is on
    function openFor(icon, appEntry) { item = icon; entry = appEntry ?? icon.modelData; cur = -1; forceActiveFocus() }
    function done() {
        const back = item
        entry = null; item = null
        if (DockFocus.active && back) back.forceActiveFocus()
    }
    readonly property var rows: !entry ? [] : menu.windows.slice(0, 8).map(t => ({
        label: t.title || menu.entry?.name || "", window: t, run: () => dock.focus(t)
    })).concat([
        { label: "New window", show: menu.entry !== null, run: () => menu.entry.execute() },
        { label: "Minimise", show: menu.windows.some(t => !dock.isMinimised(t)), run: () => menu.windows.forEach(dock.minimise) },
        { label: "Restore", show: menu.windows.some(dock.isMinimised), run: () => menu.windows.filter(dock.isMinimised).forEach(dock.restore) },
        { label: menu.pinned ? "Unpin from dock" : "Pin to dock", show: menu.entry !== null, run: () => dock.setPinned(menu.entry, !menu.pinned) },
        { label: menu.item?.mid !== undefined ? "Close window" : menu.windows.length > 1 ? `Quit (${menu.windows.length} windows)` : "Quit", show: menu.windows.length > 0, run: () => menu.windows.forEach(dock.close) }
    ].filter(a => a.show).map((a, i) => Object.assign(a, { sep: i === 0 && menu.windows.length > 0 })))
    function runRow(r) { r.run(); done() }
    focus: visible
    Keys.onEscapePressed: done()
    Keys.onUpPressed: cur = Math.max(0, (cur < 0 ? rows.length : cur) - 1)
    Keys.onDownPressed: cur = Math.min(rows.length - 1, cur + 1)
    Keys.onReturnPressed: if (rows[cur]) runRow(rows[cur])
    Keys.onEnterPressed: if (rows[cur]) runRow(rows[cur])
    // a click anywhere outside the dock closes it (clicks on the dock itself are its icons' own)
    // armed a beat after opening: Hyprland clears a grab that starts in the same commit as the dock's new mask
    HyprlandFocusGrab { id: grab; windows: [menu.dock]; onCleared: menu.done() }
    Timer { id: arm; interval: 150; onTriggered: grab.active = menu.entry !== null }
    onEntryChanged: if (entry) arm.restart(); else { arm.stop(); grab.active = false }

    visible: entry !== null
    strong: true
    radius: Theme.radius
    width: Math.round(220 * Theme.density)
    height: actions.implicitHeight + Theme.spaceS * 2
    readonly property point at: item ? dock.beside(width, height, dock.middleOf(item), Theme.spaceS) : Qt.point(0, 0)
    x: at.x; y: at.y

    Column {
        id: actions
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
        Text {
            width: parent.width; leftPadding: Theme.spaceS; bottomPadding: Theme.spaceXs
            text: menu.entry?.name ?? ""; elide: Text.ElideRight
            color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
        }
        Repeater {
            model: menu.rows
            Item {
                id: menuRow
                required property var modelData
                required property int index
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
                    color: rowArea.containsMouse || menu.cur === menuRow.index ? Theme.accent : "transparent"
                    Row {
                        anchors { left: parent.left; right: parent.right; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS; verticalCenter: parent.verticalCenter }
                        spacing: 6
                        Rectangle {   // window rows: focused / minimised marker
                            visible: !!menuRow.modelData.window
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6; height: 6; radius: 3
                            color: rowArea.containsMouse || menu.cur === menuRow.index ? Theme.accentText : Theme.text
                            opacity: menuRow.modelData.window?.activated ? 1 : dock.isMinimised(menuRow.modelData.window ?? {}) ? 0.25 : 0.55
                        }
                        Text {
                            width: parent.width - (menuRow.modelData.window ? 12 : 0)
                            text: menuRow.modelData.label; elide: Text.ElideRight
                            color: rowArea.containsMouse || menu.cur === menuRow.index ? Theme.accentText : Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontSize }
                        }
                    }
                    MouseArea {
                        id: rowArea
                        Accessible.role: Accessible.MenuItem
                        Accessible.name: menuRow.modelData.label
                        Accessible.onPressAction: menu.runRow(menuRow.modelData)
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: menu.runRow(menuRow.modelData)
                    }
                }
            }
        }
    }
}
