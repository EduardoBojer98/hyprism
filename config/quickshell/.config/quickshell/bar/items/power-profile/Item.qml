import QtQuick
import qs

// The power mode (Silent, Balanced, Performance); click opens the battery and power flyout to pick one.
BarIndicator {
    readonly property int p: PowerMode.profile
    glyph: ["\u{F032A}", "\u{F0E0E}", "\u{F0E0F}"][p] ?? "\u{F0E0E}"
    word: ["silent", "balanced", "perf"][p] ?? ""
    tip: "Power mode: " + (["Silent", "Balanced", "Performance"][p] ?? "")
    opens: "battery"
    active: Flyouts.isOpen("battery")
    onPressed: Flyouts.toggle("battery")
}
