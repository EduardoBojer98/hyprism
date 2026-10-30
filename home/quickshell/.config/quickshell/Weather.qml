pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Current weather from Open-Meteo (free, no account), refreshed every 15 minutes.
// The place comes from settings.json ({ "weather": { "city", "latitude", "longitude" } }),
// which the Settings app writes; until then it defaults to Belgrade.
Singleton {
    id: root

    property string city: "Belgrade"
    property real latitude: 44.82
    property real longitude: 20.46
    property real temperature: NaN
    property int code: -1
    property bool isDay: true
    readonly property bool ready: !isNaN(temperature)

    readonly property string condition: ({
        0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Fog",
        51: "Drizzle", 53: "Drizzle", 55: "Drizzle", 61: "Rain", 63: "Rain", 65: "Heavy rain",
        66: "Freezing rain", 67: "Freezing rain", 71: "Snow", 73: "Snow", 75: "Heavy snow", 77: "Snow",
        80: "Showers", 81: "Showers", 82: "Heavy showers", 85: "Snow showers", 86: "Snow showers",
        95: "Thunderstorm", 96: "Thunderstorm", 99: "Thunderstorm"
    })[code] ?? ""

    readonly property string glyph: code === 0 || code === 1 ? (isDay ? "\u{F0599}" : "\u{F0594}")
        : code === 2 ? (isDay ? "\u{F0595}" : "\u{F0F31}")
        : code === 3 ? "\u{F0590}"
        : code === 45 || code === 48 ? "\u{F0591}"
        : code >= 51 && code <= 67 || code >= 80 && code <= 82 ? "\u{F0597}"
        : code >= 71 && code <= 77 || code === 85 || code === 86 ? "\u{F0598}"
        : code >= 95 ? "\u{F0593}" : "\u{F0590}"

    function refresh() {
        fetch.running = false
        fetch.command = ["curl", "-sf", "--max-time", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude
            + "&current=temperature_2m,weather_code,is_day&timezone=auto"]
        fetch.running = true
    }

    FileView {
        path: Quickshell.shellDir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const w = JSON.parse(text()).weather
                if (w?.latitude !== undefined) {
                    root.city = w.city
                    root.latitude = w.latitude
                    root.longitude = w.longitude
                }
            } catch (e) {}
            root.refresh()
        }
        onLoadFailed: root.refresh()
    }

    Process {
        id: fetch
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text).current
                    root.temperature = c.temperature_2m
                    root.code = c.weather_code
                    root.isDay = c.is_day === 1
                } catch (e) {}
            }
        }
    }

    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }
}
