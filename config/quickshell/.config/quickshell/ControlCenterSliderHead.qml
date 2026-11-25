import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Label over a slider or a section; with a detail (device name) it is a button that opens the device list.
// The layout sets its voice: the UI font (cards), capitals in the display font (bento), `// sound` in mono (hud).
Item {
    id: sh
    property string title
    property string detail
    property bool isExpanded: false
    signal clicked()
    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(16, shTitle.implicitHeight)
    Layout.bottomMargin: -4
    Text {
        id: shTitle
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text: (ControlCenter.hud ? "// " : "") + sh.title
        color: ControlCenter.hud ? Theme.accent2 : Theme.text
        font { family: ControlCenter.bento ? Theme.displayFont : ControlCenter.hud ? Theme.monoFont : Theme.font
               pixelSize: ControlCenter.bento ? Theme.fontTitle : Theme.fontLabel; weight: ControlCenter.hud ? Font.Normal : Font.DemiBold
               capitalization: ControlCenter.bento ? Font.AllUppercase : ControlCenter.hud ? Font.AllLowercase : Font.MixedCase }
    }
    Text {   // hud: a dot leader from the title to its detail, `// sound ······ 100%`
        visible: ControlCenter.hud
        anchors { left: shTitle.right; right: shDetail.visible ? shDetail.left : parent.right; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS
                  verticalCenter: shTitle.verticalCenter }
        text: "·".repeat(160)
        clip: true
        opacity: 0.4
        color: Theme.muted
        font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
    }
    Row {
        id: shDetail
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        visible: sh.detail !== ""
        spacing: 2
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, sh.width - shTitle.implicitWidth - 30)
            text: sh.detail
            elide: Text.ElideRight
            color: Theme.subtext
            font { family: ControlCenter.hud ? Theme.monoFont : Theme.font; pixelSize: Theme.fontCaption }
        }
        Chevron { open: sh.isExpanded; size: 13; anchors.verticalCenter: parent.verticalCenter }
    }
    MouseArea {
        anchors.fill: parent
        enabled: sh.detail !== ""
        Accessible.role: Accessible.Button
        Accessible.name: sh.title
        Accessible.onPressAction: sh.clicked()
        cursorShape: Qt.PointingHandCursor
        onClicked: sh.clicked()
    }
}
