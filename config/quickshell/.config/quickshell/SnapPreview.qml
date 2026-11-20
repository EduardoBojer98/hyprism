import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Where a dragged window will land when dropped on a screen edge (edge snap): a tinted
// outline that glides from zone to zone. Shown and hidden by the Lua snap_preview() (hypr modules/windows.lua),
// which the minimize plugin calls while a floating window is dragged near an edge. Never takes input.
PanelWindow {
    id: root

    property rect zone: Qt.rect(0, 0, 0, 0)   // global layout coordinates, title bar included
    property bool open: false

    // the screen holding the zone's centre; stays put while the preview fades out
    screen: Quickshell.screens.find(s => zone.x + zone.width / 2 >= s.x && zone.x + zone.width / 2 < s.x + s.width
                                         && zone.y + zone.height / 2 >= s.y && zone.y + zone.height / 2 < s.y + s.height) ?? null
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: open || box.opacity > 0
    mask: Region {}
    WlrLayershell.namespace: "qs-snap-preview"
    WlrLayershell.layer: WlrLayer.Overlay

    IpcHandler {
        target: "snappreview"
        function place(x: int, y: int, w: int, h: int): void {
            box.grow = root.open || box.opacity > 0   // a fresh preview starts at its zone, not from the last one
            root.zone = Qt.rect(x, y, w, h)
            root.open = true
            box.grow = true
        }
        function clear(): void { root.open = false }
    }

    Rectangle {
        id: box
        property bool grow: true
        x: root.zone.x - (root.screen?.x ?? 0)
        y: root.zone.y - (root.screen?.y ?? 0)
        width: root.zone.width
        height: root.zone.height
        radius: Theme.radiusLarge
        color: Qt.alpha(Theme.accent, 0.16)
        border { width: 2; color: Qt.alpha(Theme.accent, 0.7) }
        opacity: root.open ? 1 : 0
        scale: root.open || !Theme.moves ? 1 : 0.97
        Behavior on opacity { NumberAnimation { duration: root.open ? Theme.animFast : Theme.exit; easing.type: Theme.easing } }
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
        Behavior on x { enabled: box.grow && Theme.moves; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        Behavior on y { enabled: box.grow && Theme.moves; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        Behavior on width { enabled: box.grow && Theme.moves; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
        Behavior on height { enabled: box.grow && Theme.moves; NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
    }
}
