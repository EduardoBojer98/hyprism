import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: one icon on Launchpad's pages or in an open folder: an app, or a folder of them (its first apps,
// small, on a frosted square). Holding it starts a drag; LauncherPad.qml does the rest.
Item {
    id: cell
    required property var pad                 // the LauncherPad it's on
    property var entry: null
    property int at: -1                   // index in entries (pages) or in the folder's apps (folder > 0)
    property int inFolder: -1             // the folder's index in entries, for an app inside an open folder
    property bool current: false
    property int order: 0                 // for the wave
    readonly property bool isFolder: entry?.folder !== undefined
    readonly property bool lit: current || area.containsMouse
    readonly property bool held: !!pad?.drag && pad.drag.cell === cell
    readonly property bool target: !!pad?.drop && pad.drop.into && pad.drop.idx === at && inFolder < 0 && !held
    onCurrentChanged: if (current) pad.currentItem = cell
    opacity: held ? 0.25 : 1
    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
    Component.onCompleted: if (pad.wave && Theme.moves && order < 40) arrive.start()
    SequentialAnimation {
        id: arrive
        PropertyAction { target: tile; property: "opacity"; value: 0 }
        PropertyAction { target: tile; property: "scale"; value: Theme.popFrom }
        PauseAnimation { duration: cell.order * Theme.stagger }
        ParallelAnimation {
            NumberAnimation { target: tile; property: "opacity"; to: 1; duration: Theme.popFade; easing.type: Theme.easing }
            NumberAnimation { target: tile; property: "scale"; to: 1; duration: Theme.pop; easing.type: Easing.OutBack; easing.overshoot: Theme.popOvershoot }
        }
    }
    Item {
        id: tile
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Math.max(16, (cell.height - pad.icon - 52) / 2) }
        width: pad.icon; height: pad.icon
        // lifts a little under the pointer or the keys, more when something is dropped on it
        property real lift: cell.target ? 1.16 : cell.lit ? 1.08 : 1
        Behavior on lift { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
        transform: Scale { origin.x: tile.width / 2; origin.y: tile.height / 2; xScale: tile.lift; yScale: tile.lift }
        Rectangle {   // a soft light under the current icon, a ring when it will take the dropped app
            anchors.centerIn: parent
            width: pad.icon + 28; height: width; radius: width / 2
            color: "white"   // palette: on the dark scrim
            opacity: cell.target ? 0.22 : cell.lit ? 0.14 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
        }
        IconImage {
            visible: !cell.isFolder
            anchors.fill: parent
            implicitSize: pad.icon
            source: cell.isFolder ? "" : Quickshell.iconPath(cell.entry?.app?.icon ?? cell.entry?.icon ?? "", "application-x-executable")
        }
        // a folder: its first apps, small, on a frosted square
        Rectangle {
            visible: cell.isFolder
            anchors.fill: parent
            radius: pad.icon * 0.26
            color: Qt.rgba(1, 1, 1, 0.16)   // palette: on the dark scrim
            border { width: 1; color: Qt.rgba(1, 1, 1, 0.14) }
            Grid {
                anchors.centerIn: parent
                columns: (cell.entry?.apps?.length ?? 0) <= 4 ? 2 : 3
                spacing: pad.icon * (columns === 2 ? 0.08 : 0.05)
                Repeater {
                    model: cell.isFolder ? cell.entry.apps.slice(0, cell.entry.apps.length <= 4 ? 4 : 9) : []
                    IconImage {
                        required property var modelData
                        implicitSize: Math.floor(pad.icon * ((cell.entry?.apps?.length ?? 0) <= 4 ? 0.34 : 0.24))
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    }
                }
            }
        }
    }
    Text {
        id: label
        anchors { left: parent.left; right: parent.right; top: tile.bottom; topMargin: Theme.spaceS; margins: Theme.spaceXs }
        horizontalAlignment: Text.AlignHCenter
        text: cell.isFolder ? cell.entry.folder : cell.entry?.app?.name ?? cell.entry?.name ?? ""
        elide: Text.ElideRight
        wrapMode: Text.Wrap
        maximumLineCount: 2
        lineHeight: 0.95
        color: "white"   // palette: on the dark scrim
        style: Text.Raised   // a shadow so names hold over any wallpaper
        styleColor: Qt.alpha("black", 0.55)
        font { family: Launcher.rowFont; pixelSize: Theme.fontSize; weight: Font.Medium }
    }
    ToolTipText { gap: -Theme.spaceS; shown: area.containsMouse && label.truncated && !pad.drag; text: label.text }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        pressAndHoldInterval: 280
        Accessible.role: cell.isFolder ? Accessible.Button : Accessible.ListItem
        Accessible.name: label.text + (cell.isFolder ? ", folder" : "")
        onEntered: if (!pad.drag) { if (cell.inFolder >= 0) pad.folderCurrent = cell.at; else if (!pad.folder) pad.currentIndex = cell.at }
        onPressAndHold: mouse => {
            if (!pad.arranging || mouse.button !== Qt.LeftButton) return
            preventStealing = true
            pad.beginDrag(cell, area.mapToItem(pad, mouse.x, mouse.y))
        }
        onPositionChanged: mouse => { if (pad.drag?.cell === cell) pad.moveDrag(area.mapToItem(pad, mouse.x, mouse.y)) }
        onReleased: { if (pad.drag?.cell === cell) pad.endDrag(); preventStealing = false }
        onClicked: mouse => {
            if (pad.drag) return
            if (mouse.button === Qt.RightButton) { if (!cell.isFolder) Launcher.menuFor(cell.entry?.app ?? cell.entry, area, mouse.x, mouse.y); return }
            if (cell.inFolder >= 0) pad.folderCurrent = cell.at; else pad.currentIndex = cell.at
            pad.activate()
        }
    }
}
