import QtQuick
import qs

// Caps Lock and Num Lock while they are on; hidden while both are off. Read from Hyprland when either key is
// pressed (Keyboard.capsLock / numLock), so keyboards without lights work too.
BarIndicator {
    readonly property bool caps: Keyboard.capsLock
    readonly property bool num: Keyboard.numLock
    readonly property bool shown: caps || num   // BarWidget hides the whole slot, no gap
    glyph: [caps ? "\u{F0632}" : "", num ? "\u{F03A0}" : ""].filter(g => g).join(" ")
    word: [caps ? "caps" : "", num ? "num" : ""].filter(w => w).join(" ")
    tip: [caps ? "Caps Lock is on" : "", num ? "Num Lock is on" : ""].filter(t => t).join(" · ")
    active: true
}
