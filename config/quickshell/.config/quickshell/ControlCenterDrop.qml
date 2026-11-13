import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A dropdown under its tile: title with an on/off switch, the content, then a link to Settings
Rectangle {
    id: drop
    property string title
    property bool switchOn: false
    property bool hasSwitch: true
    property string settingsLabel
    property string settingsPage
    property bool open: false
    default property alias body: dropBody.data
    signal switched()

    // slides open and shut: the height follows the content, so it also grows as networks appear
    property real shown: open ? dropCol.implicitHeight + 16 : 0
    Behavior on shown { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    Layout.fillWidth: true
    Layout.preferredHeight: shown
    visible: shown > 0
    clip: true
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    radius: Theme.radius
    color: Theme.fill
    border { color: Theme.stroke; width: 1 }

    ColumnLayout {
        id: dropCol
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 4
            Layout.topMargin: 2
            Layout.bottomMargin: 2
            Text {
                Layout.fillWidth: true
                text: drop.title
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
            }
            Toggle { visible: drop.hasSwitch; checked: drop.switchOn; onToggled: drop.switched() }
        }
        ColumnLayout { id: dropBody; Layout.fillWidth: true; spacing: 2 }
        ControlCenterSettingsLink { visible: drop.settingsLabel !== ""; label: drop.settingsLabel; page: drop.settingsPage }
    }
}
