import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects

// Dock part: the all-apps button at the start of the dock (a frosted tile with a DockLauncherIcon design).
// Used by Dock.qml, which passes itself in as `dock`.
// App menu / Spotlight-style launcher
Item {
    required property var dock
    id: launcher
    transform: Translate { x: dock.magnify && !dock.vertical ? dock.push(launcher) : 0; y: dock.magnify && dock.vertical ? dock.push(launcher) : 0 }   // magnify: make room
    readonly property real radius: Theme.radius   // for the focus ring
    function activate() { Anchor.take(launcher, dock.edge, dock.origin()); Launcher.toggle() }
    activeFocusOnTab: true
    Keys.onPressed: e => dock.key(e, launcher, launcher.activate, () => {})
    FocusRing {}
    readonly property real mid: (dock.vertical ? height : width) / 2
    width: dock.vertical ? dock.cellCross : dock.slot
    height: dock.vertical ? dock.slot : dock.cellCross

    // a frosted tile; the design inside (Config.dock.launcherIcon) animates on hover
    Rectangle {
        id: launcherTile
        readonly property bool lit: Launcher.open || launcherArea.containsMouse
        anchors.centerIn: parent
        width: dock.iconSize
        height: dock.iconSize
        radius: dock.shape === "block" ? 0 : Math.round(dock.iconSize * 0.27)
        // look "none" has no island behind it: a solid tile, like an app icon, so it reads on any wallpaper
        readonly property bool bare: dock.look === "none"
        color: bare ? Qt.tint(Theme.surfaceColor, Qt.alpha(dock.ink, launcherTile.lit ? 0.12 : 0))
                    : launcherTile.lit ? Qt.alpha(dock.ink, 0.17) : Qt.alpha(dock.ink, 0.07)
        border { color: bare ? Theme.stroke : Qt.alpha(dock.ink, launcherTile.lit ? 0.3 : 0.15); width: 1 }
        transformOrigin: dock.edgeOrigin
        scale: (launcherArea.pressed ? Theme.pressScale : 1) * (dock.magnify ? dock.swell(launcher) : 1)
        Behavior on scale { enabled: !dock.magnify; NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } }
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

        DockLauncherIcon {
            anchors.centerIn: parent
            style: Config.dock.launcherIcon
            size: dock.iconSize
            lit: launcherTile.lit
            ink: dock.ink
        }
    }

    MouseArea {
        id: launcherArea
        Accessible.role: Accessible.Button
        Accessible.name: "Apps and search"
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: dock.hovering(launcher, "Apps & search", containsMouse)
        onClicked: launcher.activate()
    }
}
