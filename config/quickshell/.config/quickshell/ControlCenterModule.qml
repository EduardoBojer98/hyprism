import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A tile with a title row (and a clickable detail on the right)
ControlCenterTile {
    id: mod
    property string title
    property string detail
    property bool warn: false          // detail in the warning colour
    property bool expandable: false    // header shows a chevron and opens/closes a list
    property bool isExpanded: false
    default property alias body: inner.data
    signal detailClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: inner.implicitHeight + Theme.ccInset * 2

    ColumnLayout {
        id: inner
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.ccInset; leftMargin: ControlCenter.inset; rightMargin: ControlCenter.inset }
        spacing: Theme.spaceS
        Item {
            id: header
            visible: mod.title !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(16, headerTitle.implicitHeight)
            Text {
                id: headerTitle
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: (ControlCenter.hud ? "// " : "") + mod.title
                color: ControlCenter.hud ? Theme.accent2 : Theme.text
                font { family: ControlCenter.bento ? Theme.displayFont : ControlCenter.hud ? Theme.monoFont : Theme.font
                       pixelSize: ControlCenter.bento ? Theme.fontTitle : Theme.fontLabel; weight: ControlCenter.hud ? Font.Normal : Font.DemiBold
                       capitalization: ControlCenter.bento ? Font.AllUppercase : ControlCenter.hud ? Font.AllLowercase : Font.MixedCase }
            }
            Text {   // hud: a dot leader from the title to its detail, `// sound ······ 100%`
                visible: ControlCenter.hud
                anchors { left: headerTitle.right; right: headerDetail.visible ? headerDetail.left : parent.right; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS
                          verticalCenter: headerTitle.verticalCenter }
                text: "·".repeat(160)
                clip: true
                opacity: 0.4
                color: Theme.muted
                font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
            }
            Row {
                id: headerDetail
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 4
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, header.width - headerTitle.implicitWidth - 40)
                    text: mod.detail
                    elide: Text.ElideRight
                    color: mod.warn ? Theme.warning : Theme.subtext
                    font { family: ControlCenter.hud ? Theme.monoFont : Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
                }
                Chevron { visible: mod.expandable; open: mod.isExpanded; size: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea {
                anchors.fill: mod.expandable ? header : headerDetail
                anchors.margins: -6
                Accessible.role: Accessible.Button
                Accessible.name: mod.title
                Accessible.onPressAction: mod.detailClicked()
                cursorShape: Qt.PointingHandCursor
                onClicked: mod.detailClicked()
            }
        }
    }
}
