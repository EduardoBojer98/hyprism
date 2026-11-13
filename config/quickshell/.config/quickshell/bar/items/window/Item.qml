import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

// The focused app's name and title; on a vertical bar its icon. Hidden with no focused window.
Item {
    required property var bar
    property bool shown: Sys.appClass !== ""
    visible: shown
    implicitWidth: bar.vertical ? icon.implicitWidth : app.implicitWidth
    implicitHeight: bar.vertical ? icon.implicitHeight : app.implicitHeight
    BarApp {
        id: app
        visible: !bar.vertical
        anchors.verticalCenter: parent.verticalCenter
        tone: bar.tone; family: bar.family; lower: bar.voice === "words"
        weight: Theme.barStyle.ws === "blocks" ? Font.ExtraBold : Font.DemiBold
        size: Theme.barStyle.ws === "blocks" ? Theme.fontTitle + 2 : Theme.fontSize
    }
    IconImage {   // a vertical bar has no room for words: the app's icon
        id: icon
        visible: bar.vertical
        anchors.horizontalCenter: parent.horizontalCenter
        implicitSize: 22
        source: Quickshell.iconPath(Sys.appEntry?.icon ?? "", "application-x-executable")
    }
}
