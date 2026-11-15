import QtQuick
import qs

// The time; opens the calendar. The theme's bar style picks plain, accent, display, a full-height block, or
// split: the date on a raised step, then the time in the accent block (tmux's status-right).
BarItem {
    id: clock
    required property var bar
    readonly property string style: Theme.barStyle.clock      // plain | accent | display | block | split
    readonly property bool split: style === "split" && !bar.vertical
    readonly property bool block: style === "block" || style === "split" && bar.vertical
    actions: bar.cfg
    vertical: bar.vertical
    // block: an inverse accent segment the bar's full height, like tmux's status-right
    minHeight: (block || split) && !bar.vertical ? bar.thickness - 1 : 0
    radius: block || split ? 0 : Theme.radiusSmall
    pad: split ? 0 : block ? 12 : 8
    spacing: split ? 12 : 6
    color: split ? Qt.tint(Theme.raised, lit ? pressedColor : hovered ? hover : "transparent")
         : block ? (lit ? Qt.darker(Theme.accent, 1.15) : Theme.accent) : lit ? pressedColor : hovered ? hover : "transparent"
    tip: "Clock: " + Sys.clockText
    active: Calendar.open === true
    opens: "calendar"
    onPressed: Calendar.toggle()
    Text {   // split: the date on the raised step
        visible: clock.split
        leftPadding: 12
        text: clock.bar.say(Qt.formatDateTime(Sys.now, "ddd d MMM"))
        color: clock.bar.tone
        font { family: clock.bar.family; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } }
    }
    Rectangle {   // split: the time in the accent block
        visible: clock.split
        implicitWidth: splitTime.implicitWidth + 24
        implicitHeight: clock.bar.thickness - 1
        color: clock.lit ? Qt.darker(Theme.accent, 1.15) : Theme.accent
        Text {
            id: splitTime
            anchors.centerIn: parent
            text: Sys.time()
            color: Theme.accentText
            font { family: clock.bar.family; pixelSize: Theme.fontLabel + 1; weight: Font.Bold; features: { "tnum": 1 } }
        }
    }
    Text {
        visible: !clock.split
        text: clock.bar.vertical ? Sys.hours() + "\n" + Sys.minutes() : clock.style === "display" ? Sys.time() : Sys.clockText
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
