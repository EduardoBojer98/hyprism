import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: the Apps view, category chips over an icon grid.
// Used by LauncherPanel.qml; reads the panel's state from the Launcher singleton.
Item {
    property alias grid: gridView
    visible: Launcher.view === "apps"
    // one row of category chips; a narrow panel scrolls it sideways instead of stacking rows over the grid
    ListView {
        id: chips
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceM }
        height: Math.max(26, Theme.hit)   // a Chip's height
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
    Rectangle { id: rule; anchors { left: parent.left; right: parent.right; top: chips.bottom; margins: Theme.spaceM } height: 1; color: Theme.stroke }
    GridView {
        id: gridView
        anchors { left: parent.left; right: parent.right; top: rule.bottom; bottom: parent.bottom; margins: Theme.spaceS }
        clip: true
        cellWidth: Math.floor(width / Launcher.look.columns)
        cellHeight: Launcher.look.icon + 58
        leftMargin: (width - cellWidth * Launcher.look.columns) / 2   // the cells centred, not the remainder on the right
        topMargin: Theme.spaceXs
        model: Launcher.appGrid
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: Theme.animFast
        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            width: gridView.cellWidth; height: gridView.cellHeight
            z: cellArea.containsMouse ? 1 : 0
            Rectangle {
                anchors { fill: parent; margins: 3 }
                radius: Launcher.corner === 0 ? 0 : Theme.radius
                color: cell.GridView.isCurrentItem ? Launcher.selection : cellArea.containsMouse ? Theme.fillHover : "transparent"
            }
            IconImage {
                id: appIcon
                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.spaceM }
                implicitSize: Launcher.look.icon
                source: Quickshell.iconPath(cell.modelData.icon, "application-x-executable")
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
                color: cell.GridView.isCurrentItem ? Launcher.selText : Theme.text
                font { family: Launcher.rowFont; pixelSize: Theme.fontLabel }
            }
            ToolTipText { gap: -Theme.spaceS; shown: cellArea.containsMouse && cellName.truncated; text: cell.modelData.name }
            MouseArea {
                id: cellArea
                Accessible.role: Accessible.ListItem
                Accessible.name: cell.modelData.name
                anchors.fill: parent
                hoverEnabled: true
                onEntered: gridView.currentIndex = cell.index
                onClicked: { Launcher.close(); Search.remember("app:" + cell.modelData.id); cell.modelData.execute() }
            }
        }
    }
}
