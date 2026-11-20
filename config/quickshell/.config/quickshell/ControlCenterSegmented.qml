import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Control Center building block (used by ControlCenter.qml and its parts).
// Segmented choice across the full width, equal segments (current -1 = none picked).
// Keyboard: Tab to it, Left / Right picks the one beside.
Rectangle {
    id: seg
    property var options: []
    property int current: -1
    property string accessibleName: ""
    signal picked(int index)
    Layout.fillWidth: true
    implicitHeight: Theme.ccSlider
    radius: Theme.radiusSmall
    color: Theme.fill
    border { color: Theme.stroke; width: Theme.selectInverse ? Math.max(1, Theme.line) : 0 }

    activeFocusOnTab: true
    function step(d) { const i = Math.max(0, Math.min(options.length - 1, Math.max(0, current) + d)); if (i !== current) picked(i) }
    Keys.onLeftPressed: step(-1)
    Keys.onRightPressed: step(1)
    FocusRing {}
    Accessible.role: Accessible.RadioButton
    Accessible.name: accessibleName || String(options[current] ?? "")
    Accessible.description: accessibleName ? String(options[current] ?? "") : ""
    Accessible.focusable: true

    readonly property int inset: Theme.selectInverse ? Math.max(1, Theme.line) + 2 : 3
    Rectangle {   // the picked segment slides between places
        visible: seg.current >= 0
        width: (parent.width - seg.inset * 2) / Math.max(1, seg.options.length)
        height: parent.height - seg.inset * 2
        y: seg.inset
        x: seg.inset + Math.max(0, seg.current) * width
        radius: Math.max(0, Theme.radiusSmall - seg.inset)
        color: Theme.selectInverse ? Theme.segOn : Theme.thumb
        Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    }
    Row {
        anchors { fill: parent; margins: seg.inset }
        Repeater {
            model: seg.options
            Item {
                required property string modelData
                required property int index
                width: parent.width / seg.options.length
                height: parent.height
                Text {
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, parent.width - 4)
                    elide: Text.ElideRight
                    text: modelData
                    color: seg.current === index ? (Theme.selectInverse ? Theme.segOnText : Theme.thumbText) : segArea.containsMouse ? Theme.text : Theme.subtext
                    font { family: ControlCenter.textFont; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
                MouseArea { id: segArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: seg.picked(index); Accessible.role: Accessible.RadioButton; Accessible.name: modelData; Accessible.checkable: true; Accessible.checked: seg.current === index; Accessible.onPressAction: seg.picked(index) }
            }
        }
    }
}
