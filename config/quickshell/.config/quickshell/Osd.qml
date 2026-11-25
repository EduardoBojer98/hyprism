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
    // the theme's look (theme.json osd.style): bar (a thin level bar), numeral (a big number over a segmented bar),
    // ascii (a terminal meter, [████░░░░] 50)
    readonly property string look: Theme.current.osd?.style ?? "bar"
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
    implicitWidth: look === "numeral" ? 300 : 260
    implicitHeight: look === "numeral" && label === "" ? 76 : 48
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

    Glass {
        id: card
        anchors.fill: parent
        radius: Math.min(height / 2, Theme.radiusLarge)
        strong: true
        opacity: hideTimer.running ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: hideTimer.running ? Theme.enter : Theme.exit; easing.type: Theme.easing } }

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
            visible: osd.label === "" && osd.look === "bar"
            anchors { right: parent.right; rightMargin: Theme.spaceL; verticalCenter: parent.verticalCenter }
            width: Theme.fontLabel * 2.4
            horizontalAlignment: Text.AlignRight
            text: Math.round(osd.level * 100)
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } }
        }
        Rectangle {
            visible: osd.label === "" && osd.look === "bar"
            anchors { left: glyph.right; leftMargin: Theme.spaceM; right: level.left; rightMargin: Theme.spaceM; verticalCenter: parent.verticalCenter }
            height: 6
            radius: Math.min(3, Theme.radiusSmall)
            color: Theme.fill

            Rectangle {   // the level: a scale from the left, not a width change (no layout per frame)
                width: parent.width
                height: parent.height
                radius: parent.radius
                color: Theme.accent
                transform: Scale { xScale: osd.level; Behavior on xScale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.easing } } }
            }
        }
    
        // numeral: the level as a poster number, ten blocks under it that snap (no tween: a stamp, not a glide)
        Column {
            visible: osd.label === "" && osd.look === "numeral"
            anchors { left: glyph.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: Theme.spaceL; verticalCenter: parent.verticalCenter }
            spacing: Theme.spaceXs
            Text {
                anchors.right: parent.right
                text: Math.round(osd.level * 100)
                color: Theme.text
                font { family: Theme.displayFont; pixelSize: Theme.fontHeading; weight: Theme.displayWeight; features: { "tnum": 1 } }
            }
            Row {
                width: parent.width
                spacing: 3
                Repeater {
                    model: 10
                    Rectangle {
                        required property int index
                        width: (parent.width - 9 * 3) / 10
                        height: 10
                        radius: Math.min(2, Theme.radiusSmall)
                        color: index < Math.round(osd.level * 10) ? Theme.accent : Theme.fill
                    }
                }
            }
        }

        // ascii: a terminal meter in the mono face, the number after it
        Text {
            visible: osd.label === "" && osd.look === "ascii"
            anchors { left: glyph.right; leftMargin: Theme.spaceM; right: parent.right; rightMargin: Theme.spaceL; verticalCenter: parent.verticalCenter }
            readonly property int cells: 16
            readonly property int on: Math.round(osd.level * cells)
            textFormat: Text.StyledText
            text: "<font color='" + Theme.subtext + "'>[</font><font color='" + Theme.accent + "'>" + "█".repeat(on) + "</font><font color='" + Theme.muted + "'>"
                  + "░".repeat(cells - on) + "]</font> " + String(Math.round(osd.level * 100)).padStart(3, " ")
            color: Theme.text
            font { family: Theme.monoFont; pixelSize: Theme.fontLabel; features: { "tnum": 1 } }
        }
}
}
