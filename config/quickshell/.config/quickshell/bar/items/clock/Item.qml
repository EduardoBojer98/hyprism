import QtQuick
import qs

// The time; opens the calendar. The theme's bar style picks plain, accent, display or a full-height block.
BarItem {
    id: clock
    required property var bar
    readonly property string style: Theme.barStyle.clock      // plain | accent | display | block
    readonly property bool block: style === "block"
    actions: bar.cfg
    vertical: bar.vertical
    // block: an inverse accent segment the bar's full height, like tmux's status-right
    minHeight: block && !bar.vertical ? bar.thickness - 1 : 0
    radius: block ? 0 : Theme.radiusSmall
    pad: block ? 12 : 8
    color: block ? (active ? Qt.darker(Theme.accent, 1.15) : Theme.accent) : active ? pressedColor : hovered ? hover : "transparent"
    tip: "Clock: " + Sys.clockText
    active: Calendar.open === true
    opens: "calendar"
    onPressed: Calendar.toggle()
    Text {
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
