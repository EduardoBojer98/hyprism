import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// A short notice with one button, at the top of the focused screen: "Switched to Desk · Undo" after a display
// preset applied itself. Shown by Displays.qml; goes away on its own after 6 s.
PanelWindow {
    id: toast

    property string text
    property bool open: false
    signal undone()

    function show(t) { text = t; open = true; hide.restart() }

    screen: Displays.popupScreen   // the main screen (Settings > Displays), else the one you work on
    anchors.top: true
    margins.top: Theme.reserveTop + 24
    implicitWidth: 380
    implicitHeight: 56
    exclusiveZone: 0
    color: "transparent"
    visible: card.opacity > 0
    WlrLayershell.namespace: "qs-display-toast"
    WlrLayershell.layer: WlrLayer.Overlay

    Timer { id: hide; interval: 6000; onTriggered: toast.open = false }

    Glass {
        id: card
        anchors.fill: parent
        radius: Math.min(height / 2, Theme.radiusLarge)
        strong: true
        opacity: toast.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: toast.open ? Theme.enter : Theme.exit; easing.type: Easing.OutCubic } }

        RowLayout {
            anchors { fill: parent; leftMargin: Theme.spaceL; rightMargin: Theme.spaceM }
            Text {
                Layout.fillWidth: true
                text: toast.text
                elide: Text.ElideRight
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.Medium }
            }
            PillButton { text: "Undo"; primary: true; onClicked: { toast.open = false; toast.undone() } }
        }
    }
}
