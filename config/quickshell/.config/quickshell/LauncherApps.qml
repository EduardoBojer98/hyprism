import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: the Apps view, category chips over an icon grid. Launchpad (`pad`): text tabs over pages of big
// icons straight on the dark scrim (LauncherPad.qml), the icons arriving in a quick wave.
// Used by LauncherPanel.qml; reads the panel's state from the Launcher singleton.
Item {
    id: apps
    // what the keys move in (LauncherHeader): the grid, or Launchpad's pages
    readonly property Item grid: pad ? padView : gridView
    readonly property alias flick: gridView
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
    // Launchpad's categories: quiet text tabs, a dot under the one you're on; centred, or scrolled sideways when the
    // screen is too narrow for all of them (the one you pick is kept in view)
    ListView {
        id: tabs
        visible: apps.pad
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.spaceL }
        width: Math.min(contentWidth, parent.width - Theme.spaceXl * 2)
        height: visible ? 34 : 0
        orientation: ListView.Horizontal
        spacing: Theme.spaceXl
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Launcher.categories
        currentIndex: Launcher.categories.indexOf(Launcher.category)
        highlightFollowsCurrentItem: false
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
        delegate: Item {
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
                onClicked: { Launcher.category = tab.modelData; padView.currentIndex = 0; Launcher.field.forceActiveFocus() }
            }
        }
    }
    // a fade at a cut end says there are more tabs that way
    Repeater {
        model: tabs.visible && tabs.contentWidth > tabs.width ? [0, 1] : []
        Rectangle {
            required property int modelData
            readonly property bool more: modelData === 0 ? !tabs.atXBeginning : !tabs.atXEnd
            x: modelData === 0 ? tabs.x : tabs.x + tabs.width - width
            y: tabs.y; width: 36; height: tabs.height
            opacity: more ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: modelData === 0 ? Qt.rgba(0, 0, 0, 0.7) : "transparent" }   // palette: the scrim's tone
                GradientStop { position: 1; color: modelData === 0 ? "transparent" : Qt.rgba(0, 0, 0, 0.7) }   // palette: the scrim's tone
            }
        }
    }
    LauncherPad {
        id: padView
        visible: apps.pad
        anchors { left: parent.left; right: parent.right; top: tabs.bottom; bottom: parent.bottom; topMargin: Theme.spaceL; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS }
        wave: apps.wave
    }
    Rectangle { id: rule; visible: !apps.pad; anchors { left: parent.left; right: parent.right; top: apps.pad ? tabs.bottom : chips.bottom; margins: Theme.spaceM } height: visible ? 1 : 0; color: Theme.stroke }
    GridView {
        id: gridView
        visible: !apps.pad
        anchors { left: parent.left; right: parent.right; top: rule.bottom; margins: Theme.spaceS; topMargin: apps.pad ? Theme.spaceXl : Theme.spaceS }
        // Launchpad: whole rows only, never an icon cut in half at the bottom (it still scrolls)
        readonly property real room: parent.height - y - Theme.spaceS
        height: apps.pad ? Math.max(cellHeight, Math.floor(room / cellHeight) * cellHeight + topMargin) : room
        clip: true
        // your apps per row (Settings), fewer when the panel is too narrow for them
        readonly property int cols: apps.pad ? Math.max(3, Math.floor(width / (Launcher.look.icon + 88)))
                                             : Math.max(2, Math.min(Launcher.look.columns, Math.floor(width / (Launcher.look.icon + 44))))
        cellWidth: Math.floor(width / cols)
        cellHeight: Launcher.look.icon + (apps.pad ? 72 : Launcher.layout === "grid" ? 72 : 58)
        leftMargin: (width - cellWidth * cols) / 2   // the cells centred, not the remainder on the right
        topMargin: Theme.spaceXs
        model: Launcher.open ? Launcher.appGrid : []   // icons only while shown (the closed launcher kept ~50 MB)
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.animFast
        // the filtered set settles in place instead of jumping
        displaced: Transition { NumberAnimation { properties: "x,y"; duration: Theme.enter; easing.type: Theme.easing } }
        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool lit: GridView.isCurrentItem || cellArea.containsMouse
            width: gridView.cellWidth; height: gridView.cellHeight
            z: cellArea.containsMouse ? 1 : 0
            // Launchpad's wave: each icon fades and grows in, a few ms after the one before it
            opacity: 1
            Component.onCompleted: if (apps.pad && apps.wave && Theme.moves) arrive.start()
            SequentialAnimation {
                id: arrive
                PropertyAction { target: cell; property: "opacity"; value: 0 }
                PropertyAction { target: appIcon; property: "scale"; value: Theme.popFrom }
                PauseAnimation { duration: Math.min(cell.index, 30) * Theme.stagger }
                ParallelAnimation {
                    NumberAnimation { target: cell; property: "opacity"; to: 1; duration: Theme.popFade; easing.type: Theme.easing }
                    NumberAnimation { target: appIcon; property: "scale"; to: 1; duration: Theme.pop; easing.type: Easing.OutBack; easing.overshoot: Theme.popOvershoot }
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
                color: cellArea.containsMouse && !cell.GridView.isCurrentItem ? Theme.fillHover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                LauncherSelection { on: cell.GridView.isCurrentItem; radius: parent.radius }
            }
            IconImage {
                id: appIcon
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.spaceM }
                implicitSize: Launcher.look.icon
                source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
                // Launchpad lifts the current icon a little (the wave sets scale itself while it plays)
                property real lift: apps.pad && cell.lit ? 1.08 : 1
                Behavior on lift { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
                transform: Scale { origin.x: appIcon.width / 2; origin.y: appIcon.height / 2; xScale: appIcon.lift; yScale: appIcon.lift }
            }
            Text {
                anchors { left: parent.left; right: parent.right; top: appIcon.bottom; topMargin: Theme.spaceXs + (Launcher.layout === "grid" ? Theme.spaceS : 0); margins: Theme.spaceXs }
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
