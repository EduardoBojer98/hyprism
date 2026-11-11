import QtQuick
import qs

// Screen brightness: shown only where there is a backlight. Scroll changes it (defaults.json: scroll).
BarIndicator {
    shown: Sys.brightness >= 0
    glyph: "\u{F00DF}"
    word: "lux"
    value: String(Sys.brightness)
    tip: "Brightness " + Sys.brightness + "%"
    onPressed: ControlCenter.toggle()
    onScrolled: d => Sys.nudgeBrightness(d)
}
