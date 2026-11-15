import Quickshell
import QtQuick
import qs
import "format.js" as Format

// The time and date, as this clock's settings say (format.js); opens the calendar. The theme's bar style picks
// plain, accent, display, a full-height block, or split: the date on a raised step, then the time in the accent
// block (tmux's status-right). Each copy on the bar has its own settings and its own tick.
BarItem {
    id: clock
    required property var bar
    readonly property string style: Theme.barStyle.clock      // plain | accent | display | block | split
    readonly property bool split: style === "split" && !bar.vertical
    readonly property bool block: style === "block" || style === "split" && bar.vertical
    // the large display face shows the time alone unless this clock asks for its date (or shows no time)
    readonly property var fmt: Format.patterns(bar.cfg, { h24: Config.bar.clock24, seconds: Config.bar.seconds, date: style !== "display" || bar.cfg.time === false })
    // split: the date on the step and the time in the block; your own pattern (or one part alone) goes in the block
    readonly property string step: split && !fmt.custom && fmt.time !== "" ? fmt.date : ""
    readonly property string main: step !== "" ? fmt.time : fmt.all
    function text(p) { return p === "" ? "" : Qt.formatDateTime(tick.date, p) }

    SystemClock { id: tick; precision: Format.ticksSeconds(clock.fmt.all) ? SystemClock.Seconds : SystemClock.Minutes }
    shown: fmt.all !== ""
    actions: bar.cfg
    vertical: bar.vertical
    // block: an inverse accent segment the bar's full height, like tmux's status-right (inside a floating bar's border)
    minHeight: (block || split) && !bar.vertical ? bar.thickness - (Theme.barFloating ? 2 * Theme.line : 1) : 0
    radius: block || split ? 0 : Theme.radiusSmall
    pad: split ? 0 : bar.vertical ? 4 : block ? 12 : 8     // a rail is narrow: every part on a line of its own fits
    spacing: split ? 12 : 6
    color: split ? Qt.tint(Theme.raised, lit ? pressedColor : hovered ? hover : "transparent")
         : block ? (lit ? Qt.darker(Theme.accent, 1.15) : Theme.accent) : lit ? pressedColor : hovered ? hover : "transparent"
    tip: "Clock: " + Qt.formatDateTime(tick.date, "dddd d MMMM yyyy")
    active: Calendar.open === true
    opens: "calendar"
    onPressed: Calendar.toggle()
    Text {   // split: the date on the raised step
        visible: clock.step !== ""
        leftPadding: 12
        text: clock.bar.say(clock.text(clock.step))
        color: clock.bar.tone
        font { family: clock.bar.family; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } }
    }
    Rectangle {   // split: the time in the accent block
        visible: clock.split
        implicitWidth: splitTime.implicitWidth + 24
        implicitHeight: clock.minHeight
        color: clock.lit ? Qt.darker(Theme.accent, 1.15) : Theme.accent
        Text {
            id: splitTime
            anchors.centerIn: parent
            text: clock.text(clock.main)
            color: Theme.accentText
            font { family: clock.bar.family; pixelSize: Theme.fontLabel + 1; weight: Font.Bold; features: { "tnum": 1 } }
        }
    }
    Text {   // a vertical bar stacks the parts: 14 / 40, Sun / 15 / Nov, 15 / 11 / 2026
        visible: !clock.split
        text: clock.bar.vertical ? clock.text(clock.fmt.custom || clock.fmt.time === "" ? clock.fmt.all : clock.fmt.time).trim().replace(/[\s:\/.,]+/g, "\n")
                                 : clock.text(clock.main)
        horizontalAlignment: Text.AlignHCenter
        lineHeight: clock.bar.vertical ? 0.85 : 1
        color: clock.block ? Theme.accentText : clock.style === "accent" ? Theme.accent : clock.bar.tone
        font {
            family: clock.style === "display" ? Theme.displayFont : clock.bar.family
            pixelSize: clock.style === "display" ? Math.round(Math.min(clock.bar.thickness * (clock.bar.vertical ? 0.42 : 0.62), 34)) : Theme.fontLabel + (clock.bar.words ? 0 : 1)
            weight: clock.style === "display" ? Theme.displayWeight : clock.block ? Font.Bold : Font.Medium
            letterSpacing: clock.style === "display" ? -1 : 0
            features: { "tnum": 1 }
        }
    }
}
