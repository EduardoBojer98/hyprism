pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Weather from Open-Meteo (free, no account): one request for every saved place, refreshed every
// Config.weather.refreshMin minutes. The last answer is kept in ~/.cache/hyprism/weather.json and shown (marked
// stale) when offline or right after a restart. The bar shows the first place, the default; clicking it opens the
// panel (WeatherPanel.qml), which can look at the others without saving the choice.
Singleton {
    id: root

    readonly property var c: Config.weather
    readonly property var places: c.locations ?? []
    readonly property bool hasPlace: places.length > 0
    readonly property bool open: popup.open
    property var forecasts: []          // one per place: { temperature, code, isDay, feelsLike, humidity, wind, hours, days }
    property int viewIndex: 0           // the chip the panel shows (not saved)
    property bool loading: false
    property bool failed: false         // the last request did not get through
    property bool stale: false          // what is shown comes from the cache
    property date updated               // when the shown data was fetched
    readonly property bool ready: forecasts.length > 0 && !isNaN(forecasts[0].temperature)
    readonly property var view: forecasts[Math.min(viewIndex, forecasts.length - 1)] ?? null
    readonly property string windUnit: c.units === "fahrenheit" ? "mph" : "km/h"

    // the default place (the first) feeds the bar, the dock tile and the launcher
    readonly property string city: places[0]?.name ?? ""
    readonly property real temperature: forecasts[0]?.temperature ?? NaN
    readonly property int code: forecasts[0]?.code ?? -1
    readonly property bool isDay: forecasts[0]?.isDay ?? true
    readonly property real feelsLike: forecasts[0]?.feelsLike ?? NaN
    readonly property string condition: conditionOf(code)
    readonly property string glyph: glyphOf(code, isDay)

    function conditionOf(k) {
        return ({
            0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Overcast", 45: "Fog", 48: "Fog",
            51: "Drizzle", 53: "Drizzle", 55: "Drizzle", 61: "Rain", 63: "Rain", 65: "Heavy rain",
            66: "Freezing rain", 67: "Freezing rain", 71: "Snow", 73: "Snow", 75: "Heavy snow", 77: "Snow",
            80: "Showers", 81: "Showers", 82: "Heavy showers", 85: "Snow showers", 86: "Snow showers",
            95: "Thunderstorm", 96: "Thunderstorm", 99: "Thunderstorm"
        })[k] ?? ""
    }
    function glyphOf(k, day) {
        return k === 0 || k === 1 ? (day ? "\u{F0599}" : "\u{F0594}")
            : k === 2 ? (day ? "\u{F0595}" : "\u{F0F31}")
            : k === 3 ? "\u{F0590}"
            : k === 45 || k === 48 ? "\u{F0591}"
            : k >= 51 && k <= 67 || k >= 80 && k <= 82 ? "\u{F0597}"
            : k >= 71 && k <= 77 || k === 85 || k === 86 ? "\u{F0598}"
            : k >= 95 ? "\u{F0593}" : "\u{F0590}"
    }

    function toggle() { popup.toggle() }
    function show(i) { viewIndex = i ?? 0; popup.show() }

    readonly property string url: !hasPlace ? "" : "https://api.open-meteo.com/v1/forecast?latitude="
        + places.map(p => p.latitude).join(",") + "&longitude=" + places.map(p => p.longitude).join(",")
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
        + (c.hours > 0 ? "&hourly=temperature_2m,weather_code,precipitation_probability,is_day&forecast_hours=" + c.hours : "")
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_max"
        + "&forecast_days=" + Math.max(1, c.days)   // today's range, sun and UV feed the details even with no daily list
        + (c.units === "fahrenheit" ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "")
        + "&timezone=auto"

    // Output: "<FRESH|STALE> <fetched at, epoch>", the request's URL, then Open-Meteo's JSON. With $2 = fetch the
    // request is made first; if it fails, the cached file is what comes back (STALE).
    readonly property string script: 'd="$HOME/.cache/hyprism"; f="$d/weather.json"; mkdir -p "$d"; s=STALE; '
        + 'if [ "$2" = fetch ] && curl -sf --max-time 10 "$1" -o "$f.tmp" && [ -s "$f.tmp" ]; then '
        + '{ echo "$1"; cat "$f.tmp"; } > "$f"; s=FRESH; fi; rm -f "$f.tmp"; '
        + '[ -f "$f" ] && echo "$s $(stat -c %Y "$f")" && cat "$f"'

    function refresh() {
        if (!hasPlace) { forecasts = []; return }
        loading = true
        fetch.running = false
        fetch.command = ["sh", "-c", script, "weather", url, "fetch"]
        fetch.running = true
    }
    function parse(text) {
        const nl = text.indexOf("\n"), nl2 = text.indexOf("\n", nl + 1)
        if (nl < 0 || nl2 < 0) return false
        const head = text.slice(0, nl).split(" ")
        if (text.slice(nl + 1, nl2) !== url) return false   // a cache for other places or units
        try {
            const d = JSON.parse(text.slice(nl2 + 1))
            root.forecasts = (Array.isArray(d) ? d : [d]).map(p => {
                const n = p.current, h = p.hourly, y = p.daily
                return {
                    temperature: n.temperature_2m, code: n.weather_code, isDay: n.is_day === 1,
                    feelsLike: n.apparent_temperature, humidity: n.relative_humidity_2m, wind: n.wind_speed_10m,
                    hours: !h ? [] : h.time.map((t, i) => ({ time: t.slice(11, 16), temp: h.temperature_2m[i], code: h.weather_code[i],
                                                             rain: h.precipitation_probability[i] ?? 0, day: h.is_day[i] === 1 })),
                    days: y.time.map((t, i) => ({ date: new Date(t + "T12:00"), code: y.weather_code[i],
                                                  max: y.temperature_2m_max[i], min: y.temperature_2m_min[i],
                                                  rain: y.precipitation_probability_max[i] ?? 0, uv: y.uv_index_max[i] ?? 0,
                                                  sunrise: (y.sunrise[i] ?? "").slice(11, 16), sunset: (y.sunset[i] ?? "").slice(11, 16) }))
                }
            })
            root.stale = head[0] !== "FRESH"
            root.updated = new Date(Number(head[1]) * 1000)
            return true
        } catch (e) { return false }
    }

    onUrlChanged: { viewIndex = 0; refreshSoon.restart() }
    property bool started: false
    Timer {
        id: refreshSoon
        interval: 200
        running: true
        onTriggered: {
            if (!root.started && root.hasPlace) {   // show the last answer at once; the fresh one follows
                root.started = true
                cached.command = ["sh", "-c", root.script, "weather", root.url, "load"]
                cached.running = true
            }
            root.refresh()
        }
    }
    Timer { interval: Math.max(5, root.c.refreshMin) * 60 * 1000; running: root.hasPlace; repeat: true; onTriggered: root.refresh() }

    Process {
        id: fetch
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                const ok = root.parse(text)
                root.failed = !ok || root.stale
                if (!ok) root.forecasts = []
            }
        }
    }

    Process {
        id: cached
        stdout: StdioCollector { onStreamFinished: if (!root.ready) root.parse(text) }
    }

    IpcHandler {
        target: "weather"
        function toggle(): void { root.toggle() }
    }

    // ---- forecast popup, under the bar like the calendar ----------------------------------------
    CursorPopup {
        id: popup
        name: "weather"
        placement: "top"
        boxWidth: 360
        boxHeight: Math.min(panel.implicitHeight + Theme.spaceL * 2, popup.maxHeight)
        onOpened: if (Date.now() - root.updated.getTime() > 10 * 60 * 1000 || root.stale) root.refresh()

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusPanel

            WeatherPanel {
                id: panel
                anchors { fill: parent; margins: Theme.spaceL }
                onSettings: { popup.hide(); SettingsApp.show("weather") }
            }
        }
    }
}
