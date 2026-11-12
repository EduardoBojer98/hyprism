import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: one pinned or running app: its icon, open-app mark, drag to reorder, click and right-click.
// Used by Dock.qml, which passes itself in as `dock`.
Item {
    required property var dock
    id: app
    required property DesktopEntry modelData
    required property int index
    readonly property bool pinned: dock.pinnedIds.includes(modelData?.id ?? "")
    readonly property bool dragged: dock.dragId !== "" && dock.dragId === modelData?.id
    readonly property var windows: dock.windowsOf(modelData)
    readonly property var visibleWindows: windows.filter(t => !dock.isMinimised(t))
    property bool launching: false
    onWindowsChanged: if (windows.length) launching = false

    width: dock.vertical ? dock.cellCross : dock.slot
    height: dock.vertical ? dock.slot : dock.cellCross
    readonly property real along: dock.vertical ? y : x
    readonly property real mid: (dock.vertical ? height : width) / 2   // tooltip / menu centre
    z: dragged ? 1 : 0
    // neighbours glide aside while an icon is dragged past them
    Behavior on x { enabled: dock.dragId !== "" && !dock.vertical; NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
    Behavior on y { enabled: dock.dragId !== "" && dock.vertical; NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

    Item {
        id: cell
        anchors.fill: parent
        // the dragged icon follows the pointer, a little off the edge
        readonly property real follow: app.dragged ? dock.dragX - (app.along + app.mid) : 0
        transform: Translate {
            x: dock.vertical ? (app.dragged ? -4 * dock.sign : 0) : cell.follow
            y: dock.vertical ? cell.follow : (app.dragged ? -4 * dock.sign : 0)
        }

        // hover plate: a soft tile behind the icon (hover "plate"; always while dragged or in a menu)
        Rectangle {
            anchors { fill: parent; margins: -1 }
            radius: Theme.radius
            color: Qt.alpha(dock.ink, area.pressed || app.dragged ? 0.17 : 0.11)
            opacity: area.containsMouse && dock.hoverStyle === "plate" || app.dragged || dock.menuBox.item === app ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }

        IconImage {
            id: icon
            anchors.centerIn: parent
            // a little away from the edge, so the open-app mark has room on the edge side
            anchors.horizontalCenterOffset: dock.vertical ? -3 * dock.sign : 0
            anchors.verticalCenterOffset: dock.vertical ? 0 : -3 * dock.sign
            implicitSize: dock.iconSize
            source: Quickshell.iconPath(app.modelData?.icon ?? "", "application-x-executable")
            transformOrigin: dock.edgeOrigin
            // hover: lift (moves off the edge) or grow (from the edge); press: a small give
            property real raise: dock.hoverStyle === "lift" && area.containsMouse && !app.dragged && Theme.moves ? -6 * dock.sign : 0
            transform: Translate { x: dock.vertical ? icon.raise : 0; y: dock.vertical ? 0 : icon.raise }
            Behavior on raise { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
            scale: area.pressed && !app.dragged ? Theme.pressScale : dock.hoverStyle === "grow" && area.containsMouse && !app.dragged && Theme.moves ? 1.14 : 1
            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

            // launching: a slow breath until the first window shows up
            SequentialAnimation on opacity {
                running: app.launching && Theme.animate
                loops: Animation.Infinite
                onRunningChanged: if (!running) icon.opacity = 1
                NumberAnimation { to: 0.45; duration: 520; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 520; easing.type: Easing.InOutSine }
            }
        }
        Timer { running: app.launching; interval: 10000; onTriggered: app.launching = false }
        DockMark { dock: app.dock; visible: dock.combine && app.windows.length > 0; on: app.windows.some(t => t.activated) }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: app.dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        property real pressX: 0
        property bool moved: false
        onContainsMouseChanged: dock.hovering(app, app.modelData?.name ?? "", containsMouse)
        onPressed: mouse => { pressX = dock.vertical ? mouse.y : mouse.x; moved = false }
        // drag a pinned icon along the dock to reorder
        onPositionChanged: mouse => {
            if (!pressed || pressedButtons !== Qt.LeftButton || !app.pinned) return
            const at = dock.vertical ? mouse.y : mouse.x
            if (!app.dragged && Math.abs(at - pressX) < 8) return
            if (!app.dragged) { moved = true; dock.dragId = app.modelData.id }
            const p = mapToItem(dock.rowItem, mouse.x, mouse.y)
            dock.dragTo(dock.vertical ? p.y : p.x)
        }
        onReleased: if (app.dragged) dock.endDrag()
        onCanceled: if (app.dragged) dock.endDrag()
        // Left: focus the app (cycling through its windows), bring back minimised ones, or start it.
        // Middle: always a new window. Right: windows and pin / minimise / quit dock.menuBox.
        onClicked: mouse => {
            if (!app.modelData || moved) return   // delegate is being replaced / was a drag
            if (mouse.button === Qt.RightButton) { dock.menuBox.openFor(app); return }
            const w = app.visibleWindows
            if (mouse.button === Qt.MiddleButton || app.windows.length === 0) {
                app.launching = app.windows.length === 0
                app.modelData.execute()
                return
            }
            if (w.length === 0) { for (const t of app.windows) dock.restore(t); return }
            const i = w.findIndex(t => t.activated)
            w[(i + 1) % w.length].wayland.activate()
        }
    }
}
