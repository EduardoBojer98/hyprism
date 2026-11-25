import Quickshell
import Quickshell.Widgets
import QtQuick

// Launcher part: one result row on the home view: glyph or icon, title, subtitle; `at` is its keyboard index.
Rectangle {
    id: hr
    property var item
    property int at
    property bool lead: true   // the sheet's letter and the prompt's index (not in the quick-action columns)
    readonly property bool current: Launcher.homeIndex === at
    width: parent ? parent.width : 0
    readonly property string look: Launcher.rows   // as the result rows: standard | compact | cards | text
    readonly property bool oneLine: look === "compact" || look === "text"
    height: Launcher.layout === "sheet" ? Math.round(Theme.rowHeight * 1.6) : look === "cards" ? 52 : oneLine ? Math.max(Theme.hit, Theme.rowHeight - 6) : Theme.rowHeight + 4
    radius: Launcher.corner === 0 ? 0 : Theme.radiusSmall
    color: hrArea.containsMouse && !current ? Theme.fillHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    LauncherSelection { on: hr.current; radius: parent.radius; inset: hrLead.width }
    LauncherMark { visible: hr.current && !Launcher.layout }
    LauncherLead { id: hrLead; visible: hr.lead && width > 0; width: hr.lead ? implicitWidth : 0; current: hr.current; number: hr.at + 1; letter: Launcher.initial(hr.item, Launcher.homeItems[hr.at - 1]) }
    Item {
        id: hrIcon
        anchors { left: hrLead.right; leftMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
        width: hr.look === "text" ? 0 : Launcher.layout === "prompt" ? Theme.iconSmall : hr.look === "compact" ? 18 : hr.look === "cards" ? 32 : Theme.iconMedium; height: width
        visible: width > 0
        LauncherPlate { pad: Theme.spaceXs + 1 }
        IconImage { anchors.fill: parent; visible: !!hr.item.icon; source: hr.item.icon ? Quickshell.iconPath(hr.item.icon, "application-x-executable") : "" }
        Text { anchors.centerIn: parent; visible: !hr.item.icon; text: hr.item.glyph ?? ""; color: hr.current ? Launcher.selText : Theme.text; font { family: Theme.iconFont; pixelSize: Math.max(12, hrIcon.width - 4) } }
    }
    Column {
        anchors { left: hrIcon.right; leftMargin: hrIcon.visible ? (hr.oneLine ? Theme.spaceS + 2 : Theme.spaceM) : 0; right: hrTag.visible ? hrTag.left : hrKind.left; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
        Text { width: parent.width; text: hr.item.title; elide: Text.ElideRight; color: hr.current ? Launcher.selText : Theme.text; font { family: Launcher.rowFont; pixelSize: Launcher.layout === "sheet" ? Theme.fontTitle : Theme.fontSize; weight: Launcher.layout === "sheet" ? Font.Bold : Font.Medium } }
        Text { width: parent.width; visible: !!hr.item.subtitle && Config.launcher.subtitles && !hr.oneLine && Launcher.layout !== "sheet"; text: hr.item.subtitle ?? ""; elide: Text.ElideMiddle; color: hr.current ? Launcher.selSub : Theme.subtext; font { family: Launcher.rowFont; pixelSize: Theme.fontCaption } }
    }
    LauncherTag { id: hrTag; visible: hr.lead && Launcher.layout === "sheet" && kind !== ""; anchors { right: parent.right; rightMargin: Theme.spaceM + Theme.shadowOffset; verticalCenter: parent.verticalCenter } item: hr.item; current: hr.current }
    LauncherKind { id: hrKind; anchors { right: parent.right; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter } item: hr.item; current: hr.current; kindShown: false }
    MouseArea { id: hrArea; Accessible.role: Accessible.ListItem; Accessible.name: hr.item.title; Accessible.onPressAction: Launcher.activate(hr.item); anchors.fill: parent; hoverEnabled: true; onEntered: Launcher.homeIndex = hr.at; acceptedButtons: Qt.LeftButton | Qt.RightButton; onClicked: mouse => mouse.button === Qt.RightButton ? Launcher.menuFor(hr.item, hrArea, mouse.x, mouse.y) : Launcher.activate(hr.item) }
}
