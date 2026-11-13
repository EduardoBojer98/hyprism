import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: the ranked result list for Search, Files and Actions, with section headings.
// Used by LauncherPanel.qml; reads the panel's state from the Launcher singleton.
ListView {
    id: results
    visible: Launcher.view !== "apps" && Launcher.view !== "clip" && Launcher.view !== "home"
    clip: true
    model: Launcher.listModel
    boundsBehavior: Flickable.StopAtBounds
    highlightMoveDuration: Theme.animFast

    // nothing to show: a quiet glyph, what happened, and what to try instead
    Column {
        anchors.centerIn: parent
        visible: results.count === 0
        spacing: Theme.spaceXs
        readonly property bool waiting: Launcher.mode === "files" && !Launcher.field.text
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Launcher.mode === "files" ? "\u{F024B}" : "\u{F0349}"
            color: Theme.muted
            font { family: Theme.iconFont; pixelSize: Theme.iconLarge }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: parent.waiting ? "Start typing to search your home folder"
                : Launcher.mode === "files" ? "No files match “" + Launcher.field.text.trim() + "”"
                : "Nothing matches “" + Launcher.field.text.trim() + "”"
            color: Theme.text
            font { family: Launcher.rowFont; pixelSize: Theme.fontSize; weight: Font.Medium }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !parent.waiting
            text: "Try fewer letters, or Tab to another mode"
            color: Theme.subtext
            font { family: Launcher.rowFont; pixelSize: Theme.fontCaption }
        }
    }

    delegate: Column {
        id: row
        required property var modelData
        required property int index
        readonly property bool topHit: index === 0 && Launcher.mode === "search"
        // Actions with nothing typed: the menu, under its own headings (Appearance, Screens & capture, …)
        readonly property bool menu: Launcher.mode === "actions" && Search.query.trim() === ""
        readonly property string group: menu ? modelData.group : Search.groupNames[Search.groupOf[modelData.kind]] ?? modelData.kind
        readonly property bool newSection: menu ? Launcher.listModel[index - 1]?.group !== modelData.group
            : index > 0 && !(index === 1 && Launcher.mode === "search")
            && (Search.groupNames[Search.groupOf[Launcher.listModel[index - 1]?.kind]] ?? Launcher.listModel[index - 1]?.kind) !== group
        width: results.width

        Text {
            visible: row.topHit || row.newSection || (row.index === 1 && Launcher.mode === "search")
            text: row.topHit ? "Top Hit" : row.group
            leftPadding: Theme.spaceM
            topPadding: row.index === 0 ? 2 : Theme.spaceS
            bottomPadding: Theme.spaceXs
            color: Theme.subtext
            font { family: Launcher.rowFont; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
        }

        Rectangle {
            width: parent.width
            height: row.topHit ? 56 : Theme.rowHeight + 4
            radius: Launcher.corner === 0 ? 0 : Theme.radiusSmall
            color: row.ListView.isCurrentItem ? Launcher.selection : rowArea.containsMouse ? Theme.fillHover : "transparent"
            LauncherMark { visible: row.ListView.isCurrentItem }

            Item {
                id: iconBox
                anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                width: row.topHit ? Theme.iconLarge : Theme.iconMedium + 4; height: width
                IconImage {
                    anchors.fill: parent
                    visible: !!row.modelData.icon
                    source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                }
                Text {
                    anchors.centerIn: parent
                    visible: !row.modelData.icon
                    text: row.modelData.glyph ?? ""
                    color: row.ListView.isCurrentItem ? Launcher.selText : Theme.text
                    font { family: Theme.iconFont; pixelSize: row.topHit ? Theme.iconLarge - 6 : Theme.iconMedium - 2 }
                }
            }
            Column {
                anchors { left: iconBox.right; leftMargin: Theme.spaceM; right: kindLabel.left; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                Text {
                    width: parent.width
                    text: row.modelData.title
                    elide: Text.ElideRight
                    color: row.ListView.isCurrentItem ? Launcher.selText : Theme.text
                    font { family: Launcher.rowFont; pixelSize: row.topHit ? Theme.fontTitle : Theme.fontSize; weight: row.topHit ? Font.DemiBold : Font.Medium }
                }
                Text {
                    width: parent.width
                    visible: !!row.modelData.subtitle
                    text: row.modelData.subtitle ?? ""
                    elide: Text.ElideMiddle
                    color: row.ListView.isCurrentItem ? Launcher.selSub : Theme.subtext
                    font { family: Launcher.rowFont; pixelSize: Theme.fontCaption }
                }
            }
            Text {
                id: kindLabel
                anchors { right: parent.right; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                visible: row.ListView.isCurrentItem
                text: "↵"
                color: Launcher.selSub
                font { family: Launcher.rowFont; pixelSize: Theme.fontSize }
            }
            MouseArea {
                id: rowArea
                Accessible.role: Accessible.ListItem
                Accessible.name: row.modelData.title
                Accessible.onPressAction: Launcher.activate(row.modelData)
                anchors.fill: parent
                hoverEnabled: true
                onEntered: results.currentIndex = row.index
                onClicked: Launcher.activate(row.modelData)
            }
        }
    }
}
