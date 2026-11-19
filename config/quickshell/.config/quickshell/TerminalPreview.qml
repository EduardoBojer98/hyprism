import Quickshell
import QtQuick

// Settings > Terminal: a small Ghostty window over your wallpaper, drawn from the same picks ThemeSync writes:
// the theme's palette and mono face, cursor shape and blink, background opacity and padding. While Cursor
// animation is on (and Animations is Full, as for the real shaders) it types a command and plays the typing effect.
Item {
    id: pv

    readonly property var tc: Config.terminal
    readonly property bool own: Config.appearance.terminal
    readonly property var t: own ? (Theme.current.term ?? {}) : ({})
    // the values ThemeSync.termLook resolves; Ghostty's own defaults where it writes nothing
    readonly property string cursorStyle: tc.cursor !== "theme" ? tc.cursor : (t.cursorStyle ?? "block")
    readonly property bool blinks: tc.blink !== "theme" ? tc.blink === "on" : (t.blink ?? true)
    readonly property real alpha: ({ solid: 1, soft: 0.92, clear: 0.8 })[tc.opacity] ?? (own && Theme.glassy ? 0.86 : 1)
    readonly property var pad: ({ tight: [6, 4], normal: [12, 10], roomy: [20, 16] })[tc.padding] ?? (Array.isArray(t.padding) ? t.padding : [2, 2])
    readonly property color bg: t.background ?? Theme.base
    readonly property color fg: t.foreground ?? Theme.text
    readonly property color cursorColour: t.cursor ?? Theme.accent
    readonly property color promptColour: Array.isArray(t.palette) ? t.palette[2] ?? Theme.accent : Theme.accent
    readonly property bool effects: tc.trail && Theme.motionLevel === "full"

    readonly property string command: "git status"
    property int typed: command.length

    implicitHeight: 136
    Accessible.role: Accessible.Graphic
    Accessible.name: "Terminal preview"

    Rectangle {   // the desktop behind the window, so a see-through background shows
        anchors.fill: parent
        radius: Theme.radiusSmall
        color: Theme.fill
        clip: true
        border { color: Theme.stroke; width: 1 }
        Image { anchors { fill: parent; margins: 1 } source: Wallpapers.current ? "file://" + Wallpapers.current : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 600 }

        Rectangle {   // the Ghostty window
            id: win
            anchors { top: parent.top; bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; margins: Theme.spaceM }
            width: Math.min(parent.width - Theme.spaceM * 2, 520)
            radius: Theme.radius
            color: Qt.alpha(pv.bg, pv.alpha)
            border { color: Qt.alpha(pv.fg, 0.14); width: 1 }
            clip: true

            FontMetrics { id: fm; font: line.font }
            Column {
                id: text
                x: pv.pad[0]; y: pv.pad[1]
                Behavior on x { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                Behavior on y { NumberAnimation { duration: Theme.anim; easing.type: Theme.easing } }
                Repeater {
                    model: [["~/projects", " ❯ ls", ""], ["", "notes.md&nbsp;&nbsp;src&nbsp;&nbsp;hyprism", ""]]
                    Text {
                        required property var modelData
                        textFormat: Text.StyledText
                        text: "<font color='" + pv.promptColour + "'>" + modelData[0] + "</font>" + modelData[1]
                        color: pv.fg
                        font: line.font
                    }
                }
                Text {
                    id: line
                    textFormat: Text.StyledText
                    text: "<font color='" + pv.promptColour + "'>~/projects</font> ❯ " + pv.command.slice(0, pv.typed)
                    color: pv.fg
                    font { family: Theme.monoFont; pixelSize: Theme.fontCaption }
                }
            }

            Item {   // the cursor cell, after the typed text
                id: cell
                x: text.x + line.x + line.contentWidth + 1
                y: text.y + line.y
                width: fm.averageCharacterWidth
                height: fm.height
                Rectangle {
                    id: caret
                    readonly property string s: pv.cursorStyle
                    x: 0
                    y: s === "underline" ? parent.height - height : 0
                    width: s === "bar" ? 2 : parent.width
                    height: s === "underline" ? 2 : parent.height
                    color: s === "block_hollow" ? "transparent" : pv.cursorColour
                    border { color: pv.cursorColour; width: s === "block_hollow" ? 1 : 0 }
                    property bool on: true
                    opacity: on ? 1 : 0
                    Timer { running: pv.blinks && pv.visible && Theme.animate; repeat: true; interval: Theme.blink; onTriggered: caret.on = !caret.on; onRunningChanged: caret.on = true }
                }

                // the typing effect, replayed at the cursor on every key (hyprism-type-*.glsl, roughly)
                Rectangle {   // pulse and ripple: a ring that grows and fades
                    id: ring
                    anchors.centerIn: parent
                    width: parent.height; height: width; radius: width / 2
                    color: "transparent"
                    border { color: pv.cursorColour; width: pv.tc.typing === "ripple" ? 1 : 2 }
                    opacity: 0
                }
                Rectangle {   // ghost: an afterimage of the cursor that sinks away
                    id: ghost
                    width: parent.width; height: parent.height
                    color: pv.cursorColour
                    opacity: 0
                }
                Repeater {    // sparks: a few dots thrown up and out
                    id: sparks
                    model: 5
                    Rectangle {
                        id: spark
                        required property int index
                        readonly property real dx: (index - 2) * 5
                        width: 3; height: 3; radius: 1.5
                        x: parent.width / 2; y: 0
                        color: pv.cursorColour
                        opacity: 0
                        ParallelAnimation {
                            id: fly
                            NumberAnimation { target: spark; property: "x"; from: cell.width / 2; to: cell.width / 2 + spark.dx; duration: Theme.pulse / 2; easing.type: Theme.easing }
                            SequentialAnimation {
                                NumberAnimation { target: spark; property: "y"; from: 0; to: -8 - Math.abs(2 - spark.index) * 3; duration: Theme.pulse / 4; easing.type: Theme.easing }
                                NumberAnimation { target: spark; property: "y"; to: 4; duration: Theme.pulse / 4 }
                            }
                            NumberAnimation { target: spark; property: "opacity"; from: 1; to: 0; duration: Theme.pulse / 2 }
                        }
                        function play() { fly.restart() }
                    }
                }
                ParallelAnimation {
                    id: pulseAnim
                    NumberAnimation { target: ring; property: "scale"; from: 1; to: pv.tc.typing === "ripple" ? 5 : 2.4; duration: pv.tc.typing === "ripple" ? Theme.pulse : Theme.pulse / 2; easing.type: Theme.easing }
                    NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: pv.tc.typing === "ripple" ? Theme.pulse : Theme.pulse / 2 }
                }
                ParallelAnimation {
                    id: ghostAnim
                    NumberAnimation { target: ghost; property: "y"; from: 0; to: cell.height * 0.6; duration: Theme.pulse / 2; easing.type: Theme.easing }
                    NumberAnimation { target: ghost; property: "opacity"; from: 0.55; to: 0; duration: Theme.pulse / 2 }
                }
                function play() {
                    const e = pv.tc.typing
                    if (e === "pulse" || e === "ripple") pulseAnim.restart()
                    else if (e === "ghost") { ghost.x = -cell.width; ghostAnim.restart() }
                    else if (e === "sparks") for (let i = 0; i < sparks.count; i++) sparks.itemAt(i).play()
                }
            }
        }
    }

    // types the command one key at a time, rests, and starts over: only while the effect is shown
    Timer {
        property int rest: 0
        running: pv.effects && pv.visible
        repeat: true
        interval: Theme.pulse / 5
        onRunningChanged: { pv.typed = pv.command.length; rest = 0 }
        onTriggered: {
            if (pv.typed < pv.command.length) { pv.typed++; caret.on = true; cell.play() }
            else if (++rest > 10) { rest = 0; pv.typed = 0 }
        }
    }
}
