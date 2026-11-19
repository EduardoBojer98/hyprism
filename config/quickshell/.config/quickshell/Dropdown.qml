import Quickshell
import QtQuick

// Button that shows the current value and opens a list of options below it.
Item {
    id: dd

    property var options: []
    property string current
    // opt-in: a current value outside options is listed too, labelled "(custom)"
    property bool showCustom: false
    readonly property bool isCustom: showCustom && current !== "" && options.indexOf(current) < 0
    signal picked(string value)

    implicitWidth: 200
    implicitHeight: Math.max(28, Theme.hit)
    property bool open: false

    // keyboard: Tab to it, Up / Down picks the one before or after, Space or Enter opens the list
    activeFocusOnTab: true
    function step(d) { const i = options.indexOf(current) + d; if (i >= 0 && i < options.length) picked(options[i]) }
    Keys.onUpPressed: step(-1)
    Keys.onDownPressed: step(1)
    Keys.onSpacePressed: dd.open = !dd.open
    Keys.onReturnPressed: dd.open = !dd.open
    FocusRing { radius: Theme.radiusSmall + 3 }
    property string accessibleName: ""
    Accessible.role: Accessible.ComboBox
    Accessible.name: dd.accessibleName !== "" ? dd.accessibleName : dd.current
    Accessible.description: dd.accessibleName !== "" ? dd.current : ""
    Accessible.focusable: true
    Accessible.onPressAction: dd.open = !dd.open

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: area.containsMouse ? Theme.fillHover : Theme.fill
        border { color: dd.open ? Theme.accent : Theme.stroke; width: 1 }
        Text {
            anchors { left: parent.left; leftMargin: 12; right: chevron.left; verticalCenter: parent.verticalCenter }
            text: dd.isCustom ? dd.current + " (custom)" : dd.current
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Chevron {
            id: chevron
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            open: dd.open
            size: 14
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dd.open = !dd.open }
    }

    // The compositor closes the list only for clicks in other apps; a click anywhere else in this window closes it
    // too (and does nothing else, like a macOS menu)
    MouseArea {
        parent: dd.open && dd.Window.contentItem ? dd.Window.contentItem : dd
        visible: dd.open
        anchors.fill: parent
        z: 1000000
        acceptedButtons: Qt.AllButtons
        onPressed: dd.open = false
        onWheel: wheel => { dd.open = false; wheel.accepted = false }
    }

    // A popup so the list floats above the rows below instead of being covered by them
    // The theme's depth and decor like every popup; the window leaves room around the list for its shadow.
    // Keyboard inside: Up / Down / Home / End, Enter picks, Escape closes.
    PopupWindow {
        id: menu
        readonly property int room: depthUnder.room
        visible: dd.open || box.opacity > 0   // stays up while it fades out
        anchor.item: dd
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.rect.width: dd.width
        anchor.rect.height: dd.height
        anchor.rect.y: 4 - room
        grabFocus: true
        implicitWidth: dd.width + room * 2
        implicitHeight: Math.min(list.contentHeight + 8, 260) + room * 2
        color: "transparent"
        onVisibleChanged: {
            if (!visible) dd.open = false
            else { list.currentIndex = Math.max(0, list.model.indexOf(dd.current)); list.forceActiveFocus() }
        }

        Rectangle {
            id: box
            anchors { fill: parent; margins: menu.room }
            radius: Theme.radius
            color: Theme.menu
            opacity: dd.open ? 1 : 0
            // drops out of the field, the theme's way, never more than a few px
            transform: Translate { y: dd.open ? 0 : -Math.min(6, Theme.travel); Behavior on y { NumberAnimation { duration: dd.open ? Theme.enter : Theme.exit; easing.type: Theme.easing } } }
            Behavior on opacity { NumberAnimation { duration: dd.open ? Theme.enter : Theme.exit; easing.type: Theme.easing } }
            border { color: Theme.stroke; width: Theme.line }
            PopupDepth { id: depthUnder; anchors.fill: parent; z: -1; radius: box.radius }
            PopupDepth { anchors.fill: parent; z: 10; over: true }

            ListView {
                id: list
                anchors { fill: parent; margins: 4 }
                clip: true
                Keys.onReturnPressed: { dd.open = false; dd.picked(model[currentIndex]) }
                Keys.onEnterPressed: { dd.open = false; dd.picked(model[currentIndex]) }
                Keys.onEscapePressed: dd.open = false
                Keys.onPressed: e => {
                    if (e.key === Qt.Key_Home) currentIndex = 0
                    else if (e.key === Qt.Key_End) currentIndex = count - 1
                    else return
                    e.accepted = true
                }
                model: dd.isCustom ? [dd.current].concat(dd.options) : dd.options
                delegate: Rectangle {
                    required property string modelData
                    required property int index
                    width: list.width
                    height: Math.max(26, Theme.fontLabel + 14)   // grows with Settings > Text size
                    radius: Theme.radiusSmall
                    Accessible.role: Accessible.MenuItem
                    Accessible.name: modelData
                    Accessible.checkable: true
                    Accessible.checked: modelData === dd.current
                    Accessible.onPressAction: { dd.open = false; dd.picked(modelData) }
                    readonly property bool lit: ListView.isCurrentItem
                    color: lit ? Theme.accent : "transparent"
                    Text {   // checkmark beside the current value
                        anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                        visible: modelData === dd.current
                        text: "\u{F012C}"
                        color: lit ? Theme.accentText : Theme.text
                        font { family: Theme.iconFont; pixelSize: Theme.fontLabel }
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 8 + Theme.fontLabel + 4; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: dd.isCustom && index === 0 ? modelData + " (custom)" : modelData
                        elide: Text.ElideRight
                        color: lit ? Theme.accentText : Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontLabel }
                    }
                    MouseArea {
                        id: optArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = index
                        onClicked: { dd.open = false; dd.picked(modelData) }
                    }
                }
            }
        }
    }
}
