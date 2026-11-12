import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: the all-apps button at the start of the dock (a frosted tile with a 2 x 2 grid).
// Used by Dock.qml, which passes itself in as `dock`.
// App menu / Spotlight-style launcher
Item {
    required property var dock
    id: launcher
    readonly property real mid: (dock.vertical ? height : width) / 2
    width: dock.vertical ? dock.cellCross : dock.slot
    height: dock.vertical ? dock.slot : dock.cellCross

    // a frosted tile with a 2 x 2 grid; on hover the grid turns a quarter and one square
    // becomes an accent dot
    Rectangle {
        id: launcherTile
        readonly property bool lit: Launcher.open || launcherArea.containsMouse
        anchors.centerIn: parent
        width: dock.iconSize
        height: dock.iconSize
        radius: dock.shape === "block" ? 0 : Math.round(dock.iconSize * 0.27)
        color: launcherTile.lit ? Qt.alpha(dock.ink, 0.17) : Qt.alpha(dock.ink, 0.07)
        border { color: Qt.alpha(dock.ink, launcherTile.lit ? 0.3 : 0.15); width: 1 }
        scale: launcherArea.pressed ? Theme.pressScale : 1
        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.anim } }

        Rectangle {   // top sheen, like light on glass
            visible: Theme.glassy
            anchors { fill: parent; margins: 1 }
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0; color: Theme.highlight }
                GradientStop { position: 0.5; color: "transparent" }
            }
        }

        Grid {
            id: dots
            readonly property real cell: dock.iconSize * 0.2
            anchors.centerIn: parent
            columns: 2
            spacing: dock.iconSize * 0.09
            rotation: launcherTile.lit && Theme.moves ? 45 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    readonly property bool dot: index === 1 && launcherTile.lit
                    width: dots.cell; height: dots.cell
                    radius: dot ? dots.cell / 2 : dots.cell * 0.3
                    color: index === 1 ? Theme.accent : dock.ink
                    opacity: index === 1 ? 1 : 0.88
                    Behavior on radius { NumberAnimation { duration: Theme.anim } }
                }
            }
        }
    }

    MouseArea {
        id: launcherArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: dock.hovering(launcher, "Apps & search", containsMouse)
        onClicked: { Anchor.take(launcher, dock.edge, dock.origin()); Launcher.toggle() }
    }
}
