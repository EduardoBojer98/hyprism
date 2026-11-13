import QtQuick
import qs

// Power button: opens the power menu.
BarIndicator {
    glyph: "\u{F0425}"
    word: "power"
    tip: "Power menu"
    active: PowerMenu.open
    onPressed: PowerMenu.toggle()
}
