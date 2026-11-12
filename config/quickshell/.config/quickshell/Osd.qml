import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

// Pop-up above the dock (or at the top / centre) on the focused screen for volume, brightness, microphone
// mute, keyboard layout and caps lock changes. Nothing shows for the state at shell start, only for changes.
// Volume, mic and layout follow the system by themselves; brightness is pushed by the key binds:
//   qs ipc call osd brightness <percent>
// Test hook: qs ipc call osd test <volume|brightness|micMute|layout|capsLock> <text>
PanelWindow {
    id: osd

    property string icon
    property real value
    property string label                // a word instead of the level bar ("Mic muted", "US")
    property bool armed: false           // set a moment after start, so the initial state stays quiet
    readonly property string pos: Config.osd.position

    // kind is the settings key that turns this one on or off
    function show(kind, i, v, t) {
        if (!armed || !Config.osd[kind]) return
        present(i, v, t)
    }
    function present(i, v, t) {
        icon = i
        value = v
        label = t ?? ""
        hideTimer.interval = Config.osd.timeoutMs
        hideTimer.restart()
    }

    Timer { running: true; interval: 2500; onTriggered: osd.armed = true }

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    anchors.bottom: pos === "bottom"
    anchors.top: pos === "top"
    // above a bottom bar and the dock (a hiding one too, it shows when the pointer is down there)
    margins.bottom: Theme.reserveBottom + (Config.dock.enabled && Config.dock.autoHide && Theme.dockEdge === "bottom" ? Theme.dockThickness + Theme.dockLift : 0) + 32
    margins.top: Theme.reserveTop + 32
    implicitWidth: 260
    implicitHeight: 48
    exclusiveZone: 0
    color: "transparent"
    visible: card.opacity > 0
    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {} // never takes input

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [osd.sink, osd.source] }

    Connections {
        target: osd.sink?.audio ?? null
        function onVolumesChanged() { osd.show("volume", "\u{F057E}", osd.sink.audio.volume) }
        function onMutedChanged() { osd.show("volume", osd.sink.audio.muted ? "\u{F075F}" : "\u{F057E}", osd.sink.audio.muted ? 0 : osd.sink.audio.volume) }
    }
    Connections {
        target: osd.source?.audio ?? null
        function onMutedChanged() { osd.show("micMute", osd.source.audio.muted ? "\u{F036D}" : "\u{F036C}", 0, osd.source.audio.muted ? "Mic muted" : "Mic on") }
    }
    Connections {
        target: Keyboard
        function onShortChanged() { osd.show("layout", "\u{F030C}", 0, Keyboard.short) }
    }

    // caps lock: the keyboard's light, if it has one; read twice a second only while this is switched on
    property string capsFile: ""
    property int caps: -1
    Process {
        running: true
        command: ["sh", "-c", "ls /sys/class/leds/*capslock/brightness 2>/dev/null | head -1"]
        stdout: StdioCollector { onStreamFinished: osd.capsFile = text.trim() }
    }
    Process {
        id: capsRead
        command: ["cat", osd.capsFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(text)
                if (isNaN(v)) return
                const on = v > 0 ? 1 : 0
                if (osd.caps !== -1 && on !== osd.caps) osd.show("capsLock", "\u{F030C}", 0, on ? "Caps Lock on" : "Caps Lock off")
                osd.caps = on
            }
        }
    }
    Timer {
        interval: 500; repeat: true; triggeredOnStart: true
        running: osd.capsFile !== "" && Config.osd.capsLock
        onRunningChanged: if (!running) osd.caps = -1   // the next start takes a fresh baseline
        onTriggered: capsRead.running = true
    }

    IpcHandler {
        target: "osd"
        function brightness(percent: int): void { Sys.brightness = percent; osd.show("brightness", "\u{F00DF}", percent / 100) }
        function test(kind: string, text: string): void { if (Config.osd[kind]) osd.present("\u{F030C}", 0, text) }
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

        Text {   // a word or value ("Mic muted", "US") where there is no level to draw
            visible: osd.label !== ""
            anchors { left: glyph.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: Theme.spaceL; verticalCenter: parent.verticalCenter }
            text: osd.label
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
        }

        Text {   // the level as a number: a bar alone can't say 0 % from muted, or 45 from 50
            id: level
            visible: osd.label === ""
            anchors { right: parent.right; rightMargin: Theme.spaceL; verticalCenter: parent.verticalCenter }
            width: Theme.fontLabel * 2.4
            horizontalAlignment: Text.AlignRight
            text: Math.round(Math.max(0, Math.min(1, osd.value)) * 100)
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } }
        }
        Rectangle {
            visible: osd.label === ""
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
