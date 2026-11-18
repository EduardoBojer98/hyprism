import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: the Apps view, category chips over an icon grid. Launchpad (`pad`): text tabs and big icons
// straight on the dark scrim, a lift and glow for the current one, the icons arriving in a quick wave.
// Used by LauncherPanel.qml; reads the panel's state from the Launcher singleton.
Item {
    id: apps
    property alias grid: gridView
    readonly property bool pad: Launcher.bare
    visible: Launcher.view === "apps"
    // the wave plays once per open, not on every keystroke that refilters the grid
    property bool wave: true   // armed while closed, so the icons made as it opens play it
    Connections { target: Launcher; function onOpenChanged() { if (Launcher.open) waveEnd.restart(); else apps.wave = true } }
    Timer { id: waveEnd; interval: 600; onTriggered: apps.wave = false }
    // one row of category chips; a narrow panel scrolls it sideways instead of stacking rows over the grid
    ListView {
        id: chips
        visible: !apps.pad
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
        height: visible ? Math.max(26, Theme.hit) : 0   // a Chip's height
        orientation: ListView.Horizontal
        spacing: Theme.spaceXs
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Launcher.categories
        delegate: Chip {
            required property string modelData
            label: modelData
            active: Launcher.category === modelData
            color: active ? Theme.fillActive : Theme.fill
            radius: Launcher.corner === 0 ? 0 : height / 2
            onClicked: { Launcher.category = modelData; gridView.currentIndex = 0; Launcher.field.forceActiveFocus() }
        }
    }
    // Launchpad's categories: quiet text tabs, a dot under the one you're on
    Row {
        id: tabs
        visible: apps.pad
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.spaceL }
        height: visible ? 34 : 0
        spacing: Theme.spaceXl
        Repeater {
            model: Launcher.categories
            Item {
                id: tab
                required property string modelData
                readonly property bool on: Launcher.category === modelData
                width: tabText.implicitWidth; height: tabs.height
                Text {
                    id: tabText
                    text: tab.modelData
                    color: "white"
                    opacity: tab.on ? 1 : tabArea.containsMouse ? 0.85 : 0.55
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    font { family: Theme.font; pixelSize: Theme.fontSize; weight: tab.on ? Font.DemiBold : Font.Normal }
                }
                Rectangle {
                    anchors { horizontalCenter: parent.horizontalCenter; top: tabText.bottom; topMargin: 6 }
                    width: 5; height: 5; radius: 2.5; color: "white"
                    scale: tab.on ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
                }
                MouseArea {
                    id: tabArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.PageTab; Accessible.name: tab.modelData
                    onClicked: { Launcher.category = tab.modelData; gridView.currentIndex = 0; Launcher.field.forceActiveFocus() }
                }
            }
        }
    }
    Rectangle { id: rule; visible: !apps.pad; anchors { left: parent.left; right: parent.right; top: apps.pad ? tabs.bottom : chips.bottom; margins: Theme.spaceM } height: visible ? 1 : 0; color: Theme.stroke }
    GridView {
        id: gridView
        anchors { left: parent.left; right: parent.right; top: rule.bottom; margins: Theme.spaceS; topMargin: apps.pad ? Theme.spaceXl : Theme.spaceS }
        // Launchpad: whole rows only, never an icon cut in half at the bottom (it still scrolls)
        readonly property real room: parent.height - y - Theme.spaceS
        height: apps.pad ? Math.max(cellHeight, Math.floor(room / cellHeight) * cellHeight + topMargin) : room
        clip: true
        // your apps per row (Settings), fewer when the panel is too narrow for them
        readonly property int cols: apps.pad ? Math.max(3, Math.floor(width / (Launcher.look.icon + 88)))
                                             : Math.max(2, Math.min(Launcher.look.columns, Math.floor(width / (Launcher.look.icon + 44))))
        cellWidth: Math.floor(width / cols)
        cellHeight: Launcher.look.icon + (apps.pad ? 72 : 58)
        leftMargin: (width - cellWidth * cols) / 2   // the cells centred, not the remainder on the right
        topMargin: Theme.spaceXs
        model: Launcher.open ? Launcher.appGrid : []   // icons only while shown (the closed launcher kept ~50 MB)
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.animFast
        // the filtered set settles in place instead of jumping
        displaced: Transition { NumberAnimation { properties: "x,y"; duration: Theme.enter; easing.type: Easing.OutCubic } }
        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool lit: GridView.isCurrentItem || cellArea.containsMouse
            width: gridView.cellWidth; height: gridView.cellHeight
            z: cellArea.containsMouse ? 1 : 0
            // Launchpad's wave: each icon fades and grows in, a few ms after the one before it
            opacity: 1
            Component.onCompleted: if (apps.pad && apps.wave && Theme.enter > 0) arrive.start()
            SequentialAnimation {
                id: arrive
                PropertyAction { target: cell; property: "opacity"; value: 0 }
                PropertyAction { target: appIcon; property: "scale"; value: 0.6 }
                PauseAnimation { duration: Math.min(cell.index, 30) * 9 }
                ParallelAnimation {
                    NumberAnimation { target: cell; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                    NumberAnimation { target: appIcon; property: "scale"; to: 1; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
            }
            Rectangle {   // Launchpad: a soft light under the current icon, no box
                visible: apps.pad
                anchors.centerIn: appIcon
                width: Launcher.look.icon + 28; height: width; radius: width / 2
                color: "white"
                opacity: cell.lit ? 0.14 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            }
            Rectangle {
                visible: !apps.pad
                anchors { fill: parent; margins: 3 }
                radius: Launcher.corner === 0 ? 0 : Theme.radius
                color: cell.GridView.isCurrentItem ? Launcher.selection : cellArea.containsMouse ? Theme.fillHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
            IconImage {
                id: appIcon
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.spaceM }
                implicitSize: Launcher.look.icon
                source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                // Launchpad lifts the current icon a little (the wave sets scale itself while it plays)
                property real lift: apps.pad && cell.lit ? 1.08 : 1
                Behavior on lift { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
                transform: Scale { origin.x: appIcon.width / 2; origin.y: appIcon.height / 2; xScale: appIcon.lift; yScale: appIcon.lift }
            }
            Text {
                anchors { left: parent.left; right: parent.right; top: appIcon.bottom; topMargin: Theme.spaceXs; margins: Theme.spaceXs }
                horizontalAlignment: Text.AlignHCenter
                id: cellName
                text: cell.modelData.name
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
                lineHeight: 0.95
                color: apps.pad ? "white" : cell.GridView.isCurrentItem ? Launcher.selText : Theme.text
                style: apps.pad ? Text.Raised : Text.Normal   // a shadow so names hold over any wallpaper
                styleColor: Qt.alpha("black", 0.55)
                font { family: Launcher.rowFont; pixelSize: apps.pad ? Theme.fontSize : Theme.fontLabel; weight: apps.pad ? Font.Medium : Font.Normal }
            }
            ToolTipText { gap: -Theme.spaceS; shown: cellArea.containsMouse && cellName.truncated; text: cell.modelData.name }
            MouseArea {
                id: cellArea
                Accessible.role: Accessible.ListItem
                Accessible.name: cell.modelData.name
                anchors.fill: parent
                hoverEnabled: true
                onEntered: gridView.currentIndex = cell.index
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) Launcher.menuFor(cell.modelData, cellArea, mouse.x, mouse.y)
                    else { Launcher.close(); Search.remember("app:" + cell.modelData.id); cell.modelData.execute() }
                }
            }
        }
    }
}
