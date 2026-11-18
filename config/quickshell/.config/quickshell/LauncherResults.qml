import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: the ranked result list for Search, Files and Actions, with section headings.
// Used by LauncherPanel.qml; reads the panel's state from the Launcher singleton.
ListView {
    id: results
    visible: Launcher.view !== "apps" && Launcher.view !== "clip" && Launcher.view !== "home"
    clip: true
    model: Launcher.open ? Launcher.listModel : []
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

        LauncherHomeLabel {
            visible: row.topHit || row.newSection || (row.index === 1 && Launcher.mode === "search")
            text: row.topHit ? "Top Hit" : row.group
            leftPad: Theme.spaceM
            topPad: row.index === 0 ? 2 : Theme.spaceS
            bottomPad: Theme.spaceXs
        }

        // the row's look (Launcher.rows): standard | compact (one line) | cards (tall, big icon) | text (no icon, a kind column)
        readonly property string look: Launcher.rows
        readonly property bool oneLine: look === "compact" || look === "text"
        readonly property int iconSize: look === "text" ? 0 : look === "compact" ? (topHit ? 28 : 18) : look === "cards" ? (topHit ? 48 : 34)
                                      : topHit ? Theme.iconLarge : Theme.iconMedium + 4
        readonly property bool sub: Config.launcher.subtitles && !!modelData.subtitle

        Rectangle {
            width: parent.width
            height: row.look === "cards" ? (row.topHit ? 72 : 56) : row.oneLine ? Math.max(Theme.hit, Theme.rowHeight - 6) + (row.topHit && row.look === "compact" ? 14 : 0)
                  : row.topHit ? 56 : Theme.rowHeight + 4
            radius: Launcher.corner === 0 ? 0 : row.look === "cards" ? Theme.radius : Theme.radiusSmall
            color: row.ListView.isCurrentItem ? Launcher.selection : rowArea.containsMouse ? Theme.fillHover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            LauncherMark { visible: row.ListView.isCurrentItem }

            Text {   // text rows: what kind of result, in a fixed column
                id: kindTag
                visible: row.look === "text"
                anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                width: visible ? 64 : 0
                text: (Search.groupOf[row.modelData.kind] ?? row.modelData.kind ?? "").replace(/s$/, "")
                color: row.ListView.isCurrentItem ? Launcher.selSub : Theme.accent
                font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
            }
            Item {
                id: iconBox
                anchors { left: kindTag.visible ? kindTag.right : parent.left; leftMargin: kindTag.visible ? 0 : Theme.spaceM; verticalCenter: parent.verticalCenter }
                width: row.iconSize; height: width
                visible: row.iconSize > 0
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
                    font { family: Theme.iconFont; pixelSize: Math.max(12, row.iconSize - 6) }
                }
            }
            Column {
                visible: !row.oneLine
                anchors { left: iconBox.right; leftMargin: Theme.spaceM; right: kindLabel.left; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                Text {
                    width: parent.width
                    text: row.modelData.title
                    elide: Text.ElideRight
                    color: row.ListView.isCurrentItem ? Launcher.selText : Theme.text
                    font { family: Launcher.rowFont; pixelSize: row.topHit ? Theme.fontTitle : row.look === "cards" ? Theme.fontSize + 1 : Theme.fontSize; weight: row.topHit || row.look === "cards" ? Font.DemiBold : Font.Medium }
                }
                Text {
                    width: parent.width
                    visible: row.sub
                    text: row.modelData.subtitle ?? ""
                    elide: Text.ElideMiddle
                    color: row.ListView.isCurrentItem ? Launcher.selSub : Theme.subtext
                    font { family: Launcher.rowFont; pixelSize: Theme.fontCaption }
                }
            }
            Row {   // one line: the title, then the subtitle quieter after it
                id: line
                visible: row.oneLine
                anchors { left: iconBox.visible ? iconBox.right : kindTag.right; leftMargin: iconBox.visible ? Theme.spaceS + 2 : 0; right: kindLabel.left; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
                spacing: Theme.spaceS
                Text {
                    id: lineTitle
                    width: Math.min(implicitWidth, line.width)
                    text: row.modelData.title
                    elide: Text.ElideRight
                    color: row.ListView.isCurrentItem ? Launcher.selText : Theme.text
                    font { family: Launcher.rowFont; pixelSize: Theme.fontSize; weight: row.topHit ? Font.DemiBold : Font.Normal }
                }
                Text {
                    width: Math.max(0, line.width - lineTitle.width - line.spacing)
                    visible: row.sub && width > 30
                    anchors.baseline: lineTitle.baseline
                    text: row.modelData.subtitle ?? ""
                    elide: Text.ElideMiddle
                    color: row.ListView.isCurrentItem ? Launcher.selSub : Theme.muted
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
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => mouse.button === Qt.RightButton ? Launcher.menuFor(row.modelData, rowArea, mouse.x, mouse.y) : Launcher.activate(row.modelData)
            }
        }
    }
}
