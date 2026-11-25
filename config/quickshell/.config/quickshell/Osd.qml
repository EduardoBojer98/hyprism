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
    // Settings' look, or the theme's (theme.json osd.style): bar | numeral | ascii (OsdCard.qml)
    readonly property string look: Config.osd.style === "theme" ? (Theme.current.osd?.style ?? "bar") : Config.osd.style
    readonly property real level: Math.max(0, Math.min(1, value))

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

    // Settings > Notifications > On-screen display > Screen: the main screen (Settings > Displays; else the one you
    // work on), or always the screen you work on (Hyprland's focused monitor, which follows the cursor)
    screen: Config.osd.screen === "cursor" ? (Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Displays.popupScreen)
                                           : Displays.popupScreen
    anchors.bottom: pos === "bottom"
    anchors.top: pos === "top"
    // above a bottom bar and the dock (a hiding one too, it shows when the pointer is down there)
    margins.bottom: Theme.reserveBottom + (Config.dock.enabled && Config.dock.autoHide && Theme.dockEdge === "bottom" ? Theme.dockThickness + Theme.dockLift : 0) + 32
    margins.top: Theme.reserveTop + 32
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight
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

    // Caps Lock and Num Lock as Keyboard reads them from Hyprland (all keyboards, with or without a light)
    Connections {
        target: Keyboard
        function onCapsLockChanged() { if (Keyboard.locksKnown && Config.osd.capsLock) osd.show("capsLock", "\u{F0632}", 0, Keyboard.capsLock ? "Caps Lock on" : "Caps Lock off") }
        function onNumLockChanged() { if (Keyboard.locksKnown && Config.osd.capsLock) osd.show("capsLock", "\u{F03A0}", 0, Keyboard.numLock ? "Num Lock on" : "Num Lock off") }
    }

    IpcHandler {
        target: "osd"
        function caps(): void { Keyboard.readLocks() }   // older binds.lua
        function brightness(percent: int): void { Sys.brightness = percent; osd.show("brightness", "\u{F00DF}", percent / 100) }
        function test(kind: string, text: string): void { if (Config.osd[kind]) osd.present("\u{F030C}", 0, text) }
    }

    Timer { id: hideTimer; interval: 1400 }

    // Settings > Notifications > On-screen display > Show a sample
    Connections { target: SettingsApp; function onOsdDemo() { osd.present("\u{F057E}", 0.6) } }

    OsdCard {
        id: card
        anchors.fill: parent
        icon: osd.icon
        level: osd.level
        label: osd.label
        look: osd.look
        size: Config.osd.size
        opacity: hideTimer.running ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: hideTimer.running ? Theme.enter : Theme.exit; easing.type: Theme.easing } }
    }
}
