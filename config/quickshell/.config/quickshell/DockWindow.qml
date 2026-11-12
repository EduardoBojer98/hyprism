import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: one open window (separate mode): a live picture with the app's icon in the corner.
// Used by Dock.qml, which passes itself in as `dock`.
Item {
    required property var dock
    id: win
    required property var modelData           // HyprlandToplevel
    readonly property var entry: dock.entryFor(modelData.wayland?.appId ?? "")
    readonly property bool minimised: dock.isMinimised(modelData)
    readonly property bool focused: modelData.activated
    readonly property real mid: (dock.vertical ? height : width) / 2   // tooltip / menu centre
    readonly property var windows: [modelData]
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

    width: dock.vertical ? dock.cellCross : dock.thumbWidth
    height: dock.vertical ? Math.round(dock.iconSize * 0.9) : dock.cellCross

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
        Behavior on raise { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
        height: dock.vertical ? Math.min(win.height - 6, (dock.iconSize - 4) / win.aspect) : Math.min(boxH, (win.width - 6) / win.aspect)
        width: height * win.aspect
        radius: Theme.radiusSmall - 2
        color: Qt.alpha(dock.ink, 0.07)
        border { color: win.focused ? Theme.accent : Qt.alpha(dock.ink, 0.2); width: win.focused ? 2 : 1 }
        opacity: win.minimised ? 0.55 : 1
        transformOrigin: dock.edgeOrigin
        scale: winArea.pressed ? Theme.pressScale : dock.hoverStyle === "grow" && winArea.containsMouse && Theme.moves ? 1.1 : 1
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        clip: true

        ScreencopyView {
            id: shot
            anchors { fill: parent; margins: frame.border.width }
            // only while the dock can be seen: each live picture costs a little GPU
            captureSource: dock.shown && Config.dock.thumbnails && dock.captureReady && !win.retrying ? win.modelData.wayland : null
            live: dock.liveShots && !win.minimised   // a minimised window keeps its last picture
            // a capture can fail (e.g. right at login); start it again a moment later
            onStopped: { win.retrying = true; retry.restart() }
            // Quickshell 0.3.2 never sends `stopped`: a lost picture (window resized) is the sign
            onHasContentChanged: if (!hasContent && captureSource) { win.retrying = true; retry.restart() }
        }
        Timer { id: retry; interval: 600; onTriggered: win.retrying = false }
        IconImage {   // no picture (yet): the app's icon fills in
            anchors.centerIn: parent
            visible: !shot.hasContent
            implicitSize: Math.round(frame.height * 0.72)
            source: Quickshell.iconPath(win.entry?.icon ?? "", "application-x-executable")
        }
    }
    IconImage {   // whose window it is
        visible: shot.hasContent
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
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onContainsMouseChanged: dock.hovering(win, (win.modelData.title || win.entry?.name || "") + (win.minimised ? "  (minimised)" : ""), containsMouse)
        // Left: bring it up (or minimise it when it already is the front window).
        // Middle: close. Right: dock.menuBox.
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) dock.menuBox.openFor(win, win.entry)
            else if (mouse.button === Qt.MiddleButton) dock.close(win.modelData)
            else if (win.focused && !win.minimised) dock.minimise(win.modelData)
            else dock.focus(win.modelData)
        }
    }
}
