import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

// A full-screen sheet: a card centred on the focused screen over a dimmed backdrop (the power menu, the
// cheat sheet, the welcome). It takes the keyboard while open; Escape or a click outside (on any screen)
// asks to close with dismissed(); keys the content leaves unhandled arrive as keyPressed(event) first.
//   Overlay { name: "power"; open: root.open; cardWidth: 600; cardHeight: content.implicitHeight + 48
//             onDismissed: root.hide()
//             Column { id: content; … } }     (the content sits in the card; the card's height is capped to the screen)
Scope {
    id: overlay

    property string name: "overlay"          // layer namespace: qs-<name>
    property bool open: false
    property int cardWidth: 600               // widest the card gets; never wider than the screen minus a margin
    property int cardHeight: 400              // its natural height, capped the same way
    property real startScale: 0.97
    default property alias content: card.data
    readonly property alias card: card
    readonly property int margin: Math.max(Theme.spaceL, Math.min(win.width, win.height) * 0.04)
    readonly property real screenWidth: win.width

    signal dismissed()
    signal keyPressed(var event)

    PanelWindow {
        id: win
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: overlay.open || stage.opacity > 0
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "qs-" + overlay.name
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: overlay.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        mask: Region { item: overlay.open ? stage : null }   // a closing sheet takes no input
        onVisibleChanged: if (visible) stage.forceActiveFocus()

        Item {
            id: stage
            anchors.fill: parent
            opacity: overlay.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
            focus: overlay.open

            Keys.onPressed: event => {
                event.accepted = false
                overlay.keyPressed(event)
                if (!event.accepted && event.key === Qt.Key_Escape) { overlay.dismissed(); event.accepted = true }
            }

            Rectangle { anchors.fill: parent; color: Theme.backdrop }
            MouseArea { anchors.fill: parent; onClicked: overlay.dismissed(); Accessible.ignored: true }

            Glass {
                id: card
                width: Math.min(overlay.cardWidth, win.width - overlay.margin * 2)
                height: Math.min(overlay.cardHeight, win.height - overlay.margin * 2)
                anchors.centerIn: parent
                strong: true
                radius: Theme.radiusPanel
                scale: overlay.open ? 1 : overlay.startScale
                Behavior on scale { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                MouseArea { anchors.fill: parent; z: -1 }   // clicks on the card don't close it
            }
        }
    }

    // the backdrop above only covers this screen; Hyprland reports clicks on the others
    HyprlandFocusGrab {
        windows: [win]
        active: overlay.open
        onCleared: overlay.dismissed()
    }
}
