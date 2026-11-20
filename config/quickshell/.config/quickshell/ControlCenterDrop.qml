import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// A dropdown under its tile: title with an on/off switch, the content, then a link to Settings. The layout frames it:
// a soft card (cards), a block on the hard shadow with its title in caps display type (bento), a `// wi-fi` readout
// with an accent rail down its left and `[x] on` for the switch (hud).
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
    readonly property real full: dropCol.implicitHeight + 16
    property real shown: open ? full : 0
    Behavior on shown { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    Layout.fillWidth: true
    Layout.preferredHeight: shown
    visible: shown > 0
    clip: shown < full   // only while it slides: open, Poster's shadow block sits outside it
    opacity: open ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    radius: ControlCenter.cards ? Theme.radiusLarge : Theme.radius
    color: ControlCenter.hud ? "transparent" : Theme.fill
    border { color: ControlCenter.bento ? Theme.strokeStrong : Theme.stroke; width: ControlCenter.hud || ControlCenter.cards ? 0 : 1 }
    PressFeel { visible: ControlCenter.bento && !drop.clip }
    Rectangle { visible: ControlCenter.hud; width: 1; height: parent.height; color: Theme.accent2 }   // the hud's rail

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
                text: (ControlCenter.hud ? "// " : "") + drop.title
                color: ControlCenter.hud ? Theme.accent2 : Theme.text
                font { family: ControlCenter.bento ? Theme.displayFont : ControlCenter.textFont
                       pixelSize: ControlCenter.hud ? Theme.fontLabel : Theme.fontTitle; weight: ControlCenter.hud ? Font.Normal : Font.DemiBold
                       capitalization: ControlCenter.bento ? Font.AllUppercase : ControlCenter.hud ? Font.AllLowercase : Font.MixedCase }
            }
            ControlCenterSwitch { visible: drop.hasSwitch; checked: drop.switchOn; accessibleName: drop.title; onToggled: drop.switched() }
        }
        ColumnLayout { id: dropBody; Layout.fillWidth: true; spacing: 2 }
        ControlCenterSettingsLink { visible: drop.settingsLabel !== ""; label: drop.settingsLabel; page: drop.settingsPage }
    }
}
