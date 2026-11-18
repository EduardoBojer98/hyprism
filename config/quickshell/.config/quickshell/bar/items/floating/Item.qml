import QtQuick
import qs

// Whether new windows open floating or tiled; click switches (the Control Center's Floating tile, Settings > Windows).
BarIndicator {
    readonly property bool on: Config.windows.floatAll
    glyph: on ? "\u{F05B2}" : "\u{F056E}"
    word: on ? "float" : "tile"
    tip: on ? "New windows open floating: click to tile them" : "New windows tile: click to open them floating"
    active: on
    onPressed: Config.set("windows", "floatAll", !on)
}
