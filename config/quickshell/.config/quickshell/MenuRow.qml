import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

// One row of a menu (inside a MenuList): an icon (a glyph, an image or your own item), the label, then a
// check or a submenu chevron. The accent marks the row under the pointer or the keyboard; Enter or Space picks it.
//   MenuRow { glyph: "\u{F0493}"; label: "Settings"; onClicked: … }
//   MenuRow { label: "English"; checked: true; Keycap {} }   (an item inside replaces the icon)
Rectangle {
    id: row
    property string label
    property string glyph            // an icon-font glyph
    property string iconSource       // or an image
    property bool checked: false     // a check mark at the end
    property bool more: false        // a submenu: a chevron at the end
    property bool danger: false
    property bool bold: false
    default property alias lead: slot.data
    readonly property bool menuRow: true   // MenuList finds its rows by this
    readonly property bool lit: (area.containsMouse || activeFocus) && enabled
    readonly property color ink: lit ? Theme.accentText : danger ? Theme.error : Theme.text
    signal clicked()

    Layout.fillWidth: true
    implicitHeight: Theme.controlHeight
    implicitWidth: line.implicitWidth + Theme.spaceS * 2
    radius: Math.max(0, Theme.radiusSmall - 2)
    opacity: enabled ? 1 : 0.4
    color: lit ? (danger ? Theme.error : Theme.accent) : "transparent"

    activeFocusOnTab: enabled
    Keys.onReturnPressed: row.clicked()
    Keys.onEnterPressed: row.clicked()
    Keys.onSpacePressed: row.clicked()
    Accessible.role: Accessible.MenuItem
    Accessible.name: label
    Accessible.checkable: checked
    Accessible.checked: checked
    Accessible.focusable: true
    Accessible.onPressAction: if (enabled) row.clicked()

    RowLayout {
        id: line
        anchors { fill: parent; leftMargin: Theme.spaceS; rightMargin: Theme.spaceS }
        spacing: Theme.spaceS
        Item {   // the icon's column, kept even when empty so labels line up
            Layout.preferredWidth: slot.children.length ? slot.childrenRect.width : Theme.iconSmall
            Layout.preferredHeight: Theme.iconSmall
            Item { id: slot; anchors.verticalCenter: parent.verticalCenter; width: childrenRect.width; height: childrenRect.height }
            Text {
                anchors.centerIn: parent
                visible: !slot.children.length && row.glyph !== ""
                text: row.glyph
                color: row.lit ? Theme.accentText : row.danger ? Theme.error : Theme.subtext
                font { family: Theme.iconFont; pixelSize: Theme.fontSize }
            }
            IconImage {
                anchors.centerIn: parent
                visible: !slot.children.length && row.glyph === "" && row.iconSource !== ""
                implicitSize: Theme.iconSmall - 2
                source: row.iconSource
            }
        }
        Text {
            Layout.fillWidth: true
            text: row.label
            elide: Text.ElideRight
            color: row.ink
            font { family: Theme.font; pixelSize: Theme.fontSize; weight: row.bold ? Font.DemiBold : Font.Normal }
        }
        Text {
            visible: row.checked || row.more
            text: row.more ? "\u{F0142}" : "\u{F012C}"
            color: row.lit ? Theme.accentText : row.more ? Theme.subtext : Theme.accent
            font { family: Theme.iconFont; pixelSize: Theme.fontSize }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (row.enabled) row.forceActiveFocus()   // one highlight: the pointer moves the keyboard's place
        onClicked: if (row.enabled) row.clicked()
    }
}
