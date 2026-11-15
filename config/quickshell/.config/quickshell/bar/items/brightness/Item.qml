import QtQuick
import qs

// Screen brightness: shown only where there is a backlight. Click opens its flyout (every screen's brightness); scroll changes it (defaults.json: scroll).
BarIndicator {
    shown: Sys.brightness >= 0
    glyph: "\u{F00DF}"
    word: "lux"
    value: String(Sys.brightness)
    tip: "Brightness " + Sys.brightness + "%"
    opens: "brightness"
    active: Flyouts.isOpen("brightness")
    onPressed: Flyouts.toggle("brightness")
    onScrolled: d => Sys.nudgeBrightness(d)
}
