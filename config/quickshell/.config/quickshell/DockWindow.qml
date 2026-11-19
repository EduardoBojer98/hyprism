import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: one open window (separate mode): a live picture with the app's icon in the corner, or (Settings >
// Dock > Open windows as names, dock.nameOnly) just the app's name on a plate.
// Used by Dock.qml, which passes itself in as `dock`.
Item {
    required property var dock
    id: win
    readonly property real radius: Theme.radius   // for the focus ring
    required property var modelData           // HyprlandToplevel
    readonly property var entry: dock.entryFor(modelData.wayland?.appId ?? "")
    readonly property bool minimised: dock.isMinimised(modelData)
    readonly property bool focused: modelData.activated
    readonly property real mid: (dock.vertical ? height : width) / 2   // tooltip / menu centre
    readonly property var windows: [modelData]
    readonly property string orderGroup: "windows"   // dragged along the open windows (dock.dragRunning)
    readonly property string orderKey: dock.address(modelData)
    readonly property bool nameOnly: Config.dock.nameOnly
    readonly property string appName: entry?.name || modelData.wayland?.appId || "Window"
    function activate(button) {
        if (button === Qt.RightButton) dock.menuBox.openFor(win, win.entry)
        else if (button === Qt.MiddleButton) dock.close(win.modelData)
        else if (win.focused && !win.minimised) dock.minimise(win.modelData)
        else dock.focus(win.modelData)
    }
    activeFocusOnTab: true
    Keys.onPressed: e => dock.key(e, win, () => win.activate(Qt.LeftButton), () => win.activate(Qt.RightButton))
    FocusRing {}
    // the window's shape (from its picture once there is one), fitted into the tile
    readonly property real aspect: shot.hasContent && shot.sourceSize.height > 0
        ? Math.max(0.5, Math.min(2.4, shot.sourceSize.width / shot.sourceSize.height)) : 1.6
    property bool retrying: false
    // the capture breaks when the window changes workspace: start it again once it's back
    onMinimisedChanged: if (!minimised) { retrying = true; retry.restart() }
    // a failed capture (window resized or just opened) is dropped without `stopped`: start it again
    Connections {
        target: dock
        function onSnapshot() {
            if (win.minimised) return
            if (shot.hasContent) shot.captureFrame(); else { win.retrying = true; retry.restart() }
        }
    }

    // a name sizes its tile to the text, up to four icons long (turned on its side on a vertical dock)
    readonly property real nameLength: Math.max(dock.iconSize, Math.min(nameText.implicitWidth + 28, dock.iconSize * 4))
    width: dock.vertical ? dock.cellCross : nameOnly ? nameLength : dock.thumbWidth
    height: dock.vertical ? (nameOnly ? nameLength : Math.round(dock.iconSize * 0.9)) : dock.cellCross

    Rectangle {   // hover plate
        anchors { fill: parent; margins: -1 }
        radius: Theme.radius
        color: Qt.alpha(dock.ink, winArea.pressed ? 0.17 : 0.11)
        opacity: winArea.containsMouse && dock.hoverStyle === "plate" || dock.menuBox.item === win ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    }

    Rectangle {
        id: frame
        readonly property real boxH: dock.iconSize - 4
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: dock.vertical ? -3 * dock.sign : 0
        anchors.verticalCenterOffset: dock.vertical ? 0 : -3 * dock.sign
        property real raise: dock.hoverStyle === "lift" && winArea.containsMouse && Theme.moves ? -5 * dock.sign : 0
        transform: Translate { x: dock.vertical ? frame.raise : 0; y: dock.vertical ? 0 : frame.raise }
        Behavior on raise { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        height: win.nameOnly ? (dock.vertical ? win.height - 6 : Math.round(dock.iconSize * 0.66))
              : dock.vertical ? Math.min(win.height - 6, (dock.iconSize - 4) / win.aspect) : Math.min(boxH, (win.width - 6) / win.aspect)
        width: win.nameOnly ? (dock.vertical ? Math.round(dock.iconSize * 0.66) : win.width - 6) : height * win.aspect
        radius: Theme.radiusSmall - 2
        color: win.nameOnly && win.focused ? Qt.alpha(Theme.accent, 0.14) : Qt.alpha(dock.ink, 0.07)
        border { color: win.focused ? Theme.accent : Qt.alpha(dock.ink, 0.2); width: win.focused ? 2 : 1 }
        opacity: win.minimised ? 0.55 : 1
        transformOrigin: dock.edgeOrigin
        scale: winArea.pressed ? Theme.pressScale : dock.hoverStyle === "grow" && winArea.containsMouse && Theme.moves ? 1.1 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
        clip: true

        ScreencopyView {
            id: shot
            anchors { fill: parent; margins: frame.border.width }
            // only while the dock can be seen: each live picture costs a little GPU
            captureSource: dock.shown && Config.dock.thumbnails && !win.nameOnly && dock.captureReady && !win.retrying ? win.modelData.wayland : null
            live: dock.liveShots && !win.minimised   // a minimised window keeps its last picture
            // a capture can fail (e.g. right at login); start it again a moment later
            onStopped: { win.retrying = true; retry.restart() }
            // Quickshell 0.3.2 never sends `stopped`: a lost picture (window resized) is the sign
            onHasContentChanged: if (!hasContent && captureSource) { win.retrying = true; retry.restart() }
        }
        Timer { id: retry; interval: 600; onTriggered: win.retrying = false }
        Text {   // name only: the app's name, set like the dock's tooltip
            id: nameText
            anchors.centerIn: parent
            visible: win.nameOnly
            width: Math.min(implicitWidth, (dock.vertical ? parent.height : parent.width) - 12)
            rotation: dock.vertical ? (dock.edge === "right" ? 90 : -90) : 0
            text: win.appName
            elide: Text.ElideRight
            color: Qt.alpha(dock.ink, win.focused ? 1 : 0.78)
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: win.focused ? Font.DemiBold : Font.Medium }
        }
        IconImage {   // no picture (yet): the app's icon fills in
            anchors.centerIn: parent
            visible: !shot.hasContent && !win.nameOnly
            implicitSize: Math.round(frame.height * 0.72)
            source: Quickshell.iconPath(win.entry?.icon ?? "", "application-x-executable")
        }
    }
    IconImage {   // whose window it is
        visible: shot.hasContent && !win.nameOnly
        anchors { right: frame.right; bottom: frame.bottom; rightMargin: -4; bottomMargin: -5 }
        implicitSize: Math.round(dock.iconSize * 0.42)
        source: Quickshell.iconPath(win.entry?.icon ?? "", "application-x-executable")
    }
    DockMark { dock: win.dock;   // focused / asking for attention
        on: true
        urgent: win.modelData.urgent
        opacity: win.modelData.urgent || win.focused ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }
    }

    MouseArea {
        id: winArea
        Accessible.role: Accessible.Button
        Accessible.name: win.modelData.title || win.entry?.name || "Window"
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: dock.runDrag === win.orderKey ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        property real pressAt: 0
        property bool moved: false
        onPressed: mouse => { pressAt = dock.vertical ? mouse.y : mouse.x; moved = false }
        onPositionChanged: mouse => {   // drag along the open windows to reorder them
            if (!pressed || pressedButtons !== Qt.LeftButton) return
            if (!moved && Math.abs((dock.vertical ? mouse.y : mouse.x) - pressAt) < 8) return
            moved = true
            const w = mapToItem(dock.contentItem, mouse.x, mouse.y)
            dock.dragRunning(win, dock.vertical ? w.y : w.x)
        }
        onReleased: dock.runDrag = ""
        onCanceled: dock.runDrag = ""
        onContainsMouseChanged: dock.hovering(win, (win.modelData.title || win.entry?.name || "") + (win.minimised ? "  (minimised)" : ""), containsMouse)
        // Left: bring it up (or minimise it when it already is the front window).
        // Middle: close. Right: dock.menuBox.
        onClicked: mouse => { if (!moved) win.activate(mouse.button) }
    }
}
