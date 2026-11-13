import QtQuick
import qs

// One line: what this item shows.
// `bar` is the bar it sits in (bar.tone, bar.vertical, bar.voice); `cfg` holds its settings (defaults.json + yours).
BarIndicator {
    glyph: "\u{F0493}"        // the icon (Material Design Icons in the Nerd Font)
    word: "item"              // its name in themes that use words instead of icons
    value: ""                 // the reading, e.g. "45%"
    showValue: true
    // level: 45              // set it to compare against cfg.warn / cfg.critical
    tip: "What the tooltip says"
    onPressed: ControlCenter.toggle()
}
