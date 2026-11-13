import QtQuick
import qs

// The sky now and the temperature; opens the forecast beside it.
BarIndicator {
    shown: Weather.ready
    glyph: Weather.glyph
    word: "wx"
    value: Math.round(Weather.temperature) + "°"
    showValue: true
    level: Weather.temperature
    tip: "Weather"
    active: Weather.open
    opens: "weather"
    onPressed: Weather.toggle()
}
