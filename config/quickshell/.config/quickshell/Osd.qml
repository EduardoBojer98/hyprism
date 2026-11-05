import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

// Volume / brightness pop-up above the dock on the focused screen.
// Volume follows PipeWire by itself; brightness is pushed by the key binds:
//   qs ipc call osd brightness <percent>
PanelWindow {
    id: osd

    property string icon
    property real value

    function show(i, v) {
        icon = i
        value = v
        hideTimer.restart()
    }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    anchors.bottom: true
    // above a bottom bar and the dock (a hiding one too, it shows when the pointer is down there)
    margins.bottom: Theme.reserveBottom + (Config.dock.enabled && Config.dock.autoHide && Theme.dockEdge === "bottom" ? Theme.dockThickness + Theme.dockLift : 0) + 32
    implicitWidth: 260
    implicitHeight: 48
    exclusiveZone: 0
    color: "transparent"
    visible: card.opacity > 0
    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {} // never takes input

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [osd.sink] }

    Connections {
        target: osd.sink?.audio ?? null
        function onVolumesChanged() { osd.show("\u{F057E}", osd.sink.audio.volume) }
        function onMutedChanged() { osd.show(osd.sink.audio.muted ? "\u{F075F}" : "\u{F057E}", osd.sink.audio.muted ? 0 : osd.sink.audio.volume) }
    }

    IpcHandler {
        target: "osd"
        function brightness(percent: int): void { Sys.brightness = percent; osd.show("\u{F00DF}", percent / 100) }
    }

    Timer { id: hideTimer; interval: 1400 }

    Glass {
        id: card
        anchors.fill: parent
        radius: Math.min(height / 2, Theme.radiusLarge)
        strong: true
        opacity: hideTimer.running ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: hideTimer.running ? Theme.enter : Theme.exit } }

        Text {
            id: glyph
            anchors { left: parent.left; leftMargin: Theme.spaceL; verticalCenter: parent.verticalCenter }
            text: osd.icon
            color: Theme.text
            font { family: Theme.iconFont; pixelSize: Theme.iconMedium - 2 }
        }

        Text {   // the level as a number: a bar alone can't say 0 % from muted, or 45 from 50
            id: level
            anchors { right: parent.right; rightMargin: Theme.spaceL; verticalCenter: parent.verticalCenter }
            width: Theme.fontLabel * 2.4
            horizontalAlignment: Text.AlignRight
            text: Math.round(Math.max(0, Math.min(1, osd.value)) * 100)
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } }
        }
        Rectangle {
            anchors { left: glyph.right; leftMargin: Theme.spaceM; right: level.left; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
            height: 6
            radius: Math.min(3, Theme.radiusSmall)
            color: Theme.fill

            Rectangle {   // the level: a scale from the left, not a width change (no layout per frame)
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: Theme.accent
                transform: Scale { xScale: Math.max(0, Math.min(1, osd.value)); Behavior on xScale { NumberAnimation { duration: Theme.animFast } } }
            }
        }
    }
}
