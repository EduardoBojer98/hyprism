import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A tile with a title row (and a clickable detail on the right)
Rectangle {   // same look as Tile
    id: mod
    radius: Theme.radius
    color: Theme.fill
    property string title
    property string detail
    property bool warn: false          // detail in the warning colour
    property bool expandable: false    // header shows a chevron and opens/closes a list
    property bool isExpanded: false
    default property alias body: inner.data
    signal detailClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: inner.implicitHeight + 22

    ColumnLayout {
        id: inner
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 11; leftMargin: 12; rightMargin: 12 }
        spacing: 6
        Item {
            id: header
            visible: mod.title !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: 16
            Text {
                id: headerTitle
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                text: mod.title
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
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
                    font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
                }
                Chevron { visible: mod.expandable; open: mod.isExpanded; size: 13; anchors.verticalCenter: parent.verticalCenter }
            }
            MouseArea {
                anchors.fill: mod.expandable ? header : headerDetail
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: mod.detailClicked()
            }
        }
    }
}
