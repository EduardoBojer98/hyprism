import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: window previews for one app (combined mode), beside the island.
// Used by Dock.qml, which passes itself in as `dock`.
// Window previews for one app (combined mode): a picture of each of its windows, beside the island
Glass {
    required property var dock
    id: preview
    readonly property var wins: dock.previewOn ? (dock.previewFor?.windows ?? []) : []
    readonly property int tileW: 220
    readonly property point at: dock.previewFor ? dock.beside(width, height, dock.middleOf(dock.previewFor), Theme.spaceS) : Qt.point(0, 0)
    visible: wins.length > 0 && dock.menuBox.entry === null && dock.dragId === ""
    x: at.x; y: at.y
    strong: true
    radius: Theme.radiusLarge
    width: tiles.implicitWidth + 16
    height: tiles.implicitHeight + 16
    HoverHandler { id: previewHover; onHoveredChanged: dock.previewLeave(hovered) }
    Grid {
        id: tiles
        anchors.centerIn: parent
        columns: dock.vertical ? 1 : Math.max(1, Math.min(preview.wins.length, 4))
        spacing: 8
        Repeater {
            model: preview.wins.slice(0, 8)
            Rectangle {
                id: pv
                required property var modelData
                width: preview.tileW; height: preview.tileW * 0.62 + 26
                radius: Theme.radius
                color: pvArea.containsMouse ? Theme.fillHover : "transparent"
                border { color: pv.modelData.activated ? Theme.accent : "transparent"; width: 2 }
                Text {
                    anchors { left: parent.left; right: closeBtn.left; top: parent.top; margins: 6 }
                    text: pv.modelData.title || ""
                    elide: Text.ElideRight
                    color: Theme.text
                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium }
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6; topMargin: 24 }
                    height: preview.tileW * 0.62 - 6
                    radius: Theme.radiusSmall
                    color: Theme.fill
                    clip: true
                    ScreencopyView {
                        anchors.fill: parent
                        captureSource: preview.visible && dock.captureReady && !dock.isMinimised(pv.modelData) ? pv.modelData.wayland : null
                        live: true
                    }
                }
                MouseArea {
                    id: pvArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: mouse => { if (mouse.button === Qt.MiddleButton) dock.close(pv.modelData); else { dock.focus(pv.modelData); dock.previewOn = false } }
                }
                Rectangle {
                    id: closeBtn
                    anchors { right: parent.right; top: parent.top; margins: 4 }
                    width: 18; height: 18; radius: Theme.radius === 0 ? 0 : 9
                    visible: pvArea.containsMouse || closeArea.containsMouse
                    color: closeArea.containsMouse ? Theme.error : Theme.fillActive
                    Text { anchors.centerIn: parent; text: "\u{F0156}"; color: Theme.text; font { family: Theme.iconFont; pixelSize: 11 } }
                    MouseArea { id: closeArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dock.close(pv.modelData) }
                }
            }
        }
    }
}
