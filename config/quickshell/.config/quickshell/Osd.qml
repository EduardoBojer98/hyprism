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
    margins.bottom: Theme.reserveBottom + 90   // above a bottom bar, island or dock
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
        radius: height / 2
        opacity: hideTimer.running ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.anim } }

        Text {
            id: glyph
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            text: osd.icon
            color: Theme.text
            font { family: Theme.iconFont; pixelSize: 20 }
        }

        Rectangle {
            anchors { left: glyph.right; leftMargin: 14; right: parent.right; rightMargin: 18; verticalCenter: parent.verticalCenter }
            height: 6
            radius: 3
            color: Theme.fill

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, osd.value))
                height: parent.height
                radius: 3
                color: Theme.text
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }
    }
}
