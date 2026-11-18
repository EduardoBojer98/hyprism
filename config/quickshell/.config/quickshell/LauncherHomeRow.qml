import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: one result row on the home view: glyph or icon, title, subtitle; `at` is its keyboard index.
Rectangle {
    id: hr
    property var item
    property int at
    readonly property bool current: Launcher.homeIndex === at
    width: parent ? parent.width : 0
    readonly property string look: Launcher.rows   // as the result rows: standard | compact | cards | text
    readonly property bool oneLine: look === "compact" || look === "text"
    height: look === "cards" ? 52 : oneLine ? Math.max(Theme.hit, Theme.rowHeight - 6) : Theme.rowHeight + 4
    radius: Launcher.corner === 0 ? 0 : Theme.radiusSmall
    color: current ? Launcher.selection : hrArea.containsMouse ? Theme.fillHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    LauncherMark { visible: hr.current }
    Item {
        id: hrIcon
        anchors { left: parent.left; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
        width: hr.look === "text" ? 0 : hr.look === "compact" ? 18 : hr.look === "cards" ? 32 : Theme.iconMedium; height: width
        visible: width > 0
        IconImage { anchors.fill: parent; visible: !!hr.item.icon; source: hr.item.icon ? Quickshell.iconPath(hr.item.icon, "application-x-executable") : "" }
        Text { anchors.centerIn: parent; visible: !hr.item.icon; text: hr.item.glyph ?? ""; color: hr.current ? Launcher.selText : Theme.text; font { family: Theme.iconFont; pixelSize: Math.max(12, hrIcon.width - 4) } }
    }
    Column {
        anchors { left: hrIcon.right; leftMargin: hrIcon.visible ? (hr.oneLine ? Theme.spaceS + 2 : Theme.spaceM) : 0; right: parent.right; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
        Text { width: parent.width; text: hr.item.title; elide: Text.ElideRight; color: hr.current ? Launcher.selText : Theme.text; font { family: Launcher.rowFont; pixelSize: Theme.fontSize; weight: Font.Medium } }
        Text { width: parent.width; visible: !!hr.item.subtitle && Config.launcher.subtitles && !hr.oneLine; text: hr.item.subtitle ?? ""; elide: Text.ElideMiddle; color: hr.current ? Launcher.selSub : Theme.subtext; font { family: Launcher.rowFont; pixelSize: Theme.fontCaption } }
    }
    MouseArea { id: hrArea; Accessible.role: Accessible.ListItem; Accessible.name: hr.item.title; Accessible.onPressAction: Launcher.activate(hr.item); anchors.fill: parent; hoverEnabled: true; onEntered: Launcher.homeIndex = hr.at; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: mouse => mouse.button === Qt.RightButton ? Launcher.menuFor(hr.item, hrArea, mouse.x, mouse.y) : Launcher.activate(hr.item) }
}
