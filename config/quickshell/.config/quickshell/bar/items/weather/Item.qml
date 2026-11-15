import QtQuick
import qs

// The sky now and the temperature; opens the forecast beside it.
BarIndicator {
    shown: Weather.ready || !Weather.hasPlace
    glyph: Weather.glyph
    word: "wx"
    value: Weather.ready ? Math.round(Weather.temperature) + "°" : ""
    showValue: Weather.ready
    level: Weather.temperature
    tip: "Weather"
    active: Weather.open
    opens: "weather"
    onPressed: Weather.toggle()
}
