import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

// An app in a Settings list: icon, name, and a button on the right; a hairline above every row but
// the first. Used by Startup Apps and the dock's pinned apps.
Item {
    id: row
    property var entry: null
    property string fallback: ""
    property bool first: false
    property string action
    signal triggered()
    Layout.fillWidth: true
    implicitHeight: 46
    Rectangle { visible: !row.first; anchors { left: parent.left; right: parent.right; leftMargin: 16 } height: 1; color: Theme.stroke }
    IconImage {
        id: icon
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
        implicitSize: 24
        source: Quickshell.iconPath(row.entry?.icon ?? "", "application-x-executable")
    }
    Text {
        anchors { left: icon.right; leftMargin: 12; right: btn.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: row.entry?.name ?? (row.fallback + " (not installed)")
        elide: Text.ElideRight
        color: row.entry ? Theme.text : Theme.muted
        font { family: Theme.font; pixelSize: Theme.fontSize }
    }
    PillButton {
        id: btn
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: row.action
        primary: row.action === "Add"
        onClicked: row.triggered()
    }
}
