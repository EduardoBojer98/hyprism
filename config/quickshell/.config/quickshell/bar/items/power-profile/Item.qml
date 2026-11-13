import QtQuick
import qs

// The power profile (quiet, balanced, performance); click goes to the next one.
BarIndicator {
    readonly property int p: PowerMode.profile
    glyph: ["\u{F032A}", "\u{F0E0E}", "\u{F0E0F}"][p] ?? "\u{F0E0E}"
    word: ["quiet", "balanced", "perf"][p] ?? ""
    tip: "Power profile: " + (["quiet", "balanced", "performance"][p] ?? "")
    onPressed: PowerMode.set((p + 1) % 3)
}
