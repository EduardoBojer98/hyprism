pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Weather from Open-Meteo (free, no account), refreshed every 15 minutes: the bar shows the current
// temperature; clicking it opens the forecast under it (now, the next 12 hours, the next days).
// Place, number of days, units and which parts show come from Config.weather (Settings > Weather).
Singleton {
    id: root

    readonly property var c: Config.weather
    readonly property string city: c.city
    readonly property real latitude: c.latitude
    readonly property real longitude: c.longitude
    readonly property bool open: popup.open
    property real temperature: NaN
    property int code: -1
    property bool isDay: true
    property real feelsLike: NaN
    property int humidity: 0
    property real wind: 0
    property var hours: []      // [{ time, temp, code, rain, day }]
    property var days: []       // [{ date, code, max, min, rain, uv, sunrise, sunset }]
    property date updated
    readonly property bool ready: !isNaN(temperature)
    readonly property string windUnit: c.units === "fahrenheit" ? "mph" : "km/h"

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
    readonly property string condition: conditionOf(code)
    readonly property string glyph: glyphOf(code, isDay)

    function toggle() { popup.toggle() }
    function refresh() {
        fetch.running = false
        fetch.command = ["curl", "-sf", "--max-time", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
            + "&hourly=temperature_2m,weather_code,precipitation_probability,is_day&forecast_hours=12"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_max"
            + "&forecast_days=" + c.days
            + (c.units === "fahrenheit" ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "")
            + "&timezone=auto"]
        fetch.running = true
    }

    onLatitudeChanged: refreshSoon.restart()
    onLongitudeChanged: refreshSoon.restart()
    Connections {
        target: Config.weather
        function onDaysChanged() { refreshSoon.restart() }
        function onUnitsChanged() { refreshSoon.restart() }
    }
    Timer { id: refreshSoon; interval: 200; running: true; onTriggered: root.refresh() }
    Timer { interval: 15 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }

    Process {
        id: fetch
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text)
                    const n = d.current, h = d.hourly, y = d.daily
                    root.temperature = n.temperature_2m
                    root.code = n.weather_code
                    root.isDay = n.is_day === 1
                    root.feelsLike = n.apparent_temperature
                    root.humidity = n.relative_humidity_2m
                    root.wind = n.wind_speed_10m
                    root.hours = h.time.map((t, i) => ({ time: t.slice(11, 16), temp: h.temperature_2m[i], code: h.weather_code[i],
                                                         rain: h.precipitation_probability[i] ?? 0, day: h.is_day[i] === 1 }))
                    root.days = y.time.map((t, i) => ({ date: new Date(t + "T12:00"), code: y.weather_code[i],
                                                        max: y.temperature_2m_max[i], min: y.temperature_2m_min[i],
                                                        rain: y.precipitation_probability_max[i] ?? 0, uv: y.uv_index_max[i] ?? 0,
                                                        sunrise: (y.sunrise[i] ?? "").slice(11, 16), sunset: (y.sunset[i] ?? "").slice(11, 16) }))
                    root.updated = new Date()
                } catch (e) {}
            }
        }
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
        boxWidth: 340
        boxHeight: Math.min(body.implicitHeight + 24, popup.maxHeight)
        onOpened: if (Date.now() - root.updated.getTime() > 10 * 60 * 1000) root.refresh()

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusLarge + 4

            Flickable {
                anchors { fill: parent; margins: 12 }
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: body
                    width: parent.width
                    spacing: 8

                    // now: place, big temperature, condition, today's range
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text { text: root.city; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold } }
                            Text {
                                text: root.ready ? Math.round(root.temperature) + "°" : "–"
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 44; weight: Font.Light; features: { "tnum": 1 } }
                            }
                        }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            spacing: 2
                            Text { Layout.alignment: Qt.AlignRight; text: root.glyph; color: Theme.text; font { family: Theme.iconFont; pixelSize: 30 } }
                            Text { Layout.alignment: Qt.AlignRight; text: root.condition; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium } }
                            Text {
                                Layout.alignment: Qt.AlignRight
                                visible: root.days.length > 0
                                text: root.days.length ? `H ${Math.round(root.days[0].max)}°  L ${Math.round(root.days[0].min)}°` : ""
                                color: Theme.subtext
                                font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
                            }
                        }
                    }

                    // details: feels like, humidity, wind, UV, sun
                    GridLayout {
                        visible: root.c.showDetails && root.ready
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 6
                        rowSpacing: 6
                        Repeater {
                            model: root.days.length ? [
                                ["\u{F050F}", "Feels like", Math.round(root.feelsLike) + "°"],
                                ["\u{F058E}", "Humidity", root.humidity + "%"],
                                ["\u{F059D}", "Wind", Math.round(root.wind) + " " + root.windUnit],
                                ["\u{F0599}", "UV index", Math.round(root.days[0].uv)],
                                ["\u{F059C}", "Sunrise", root.days[0].sunrise],
                                ["\u{F059B}", "Sunset", root.days[0].sunset]
                            ] : []
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                implicitHeight: 48
                                radius: Theme.radius
                                color: Theme.fill
                                Column {
                                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                    spacing: 1
                                    Row {
                                        spacing: 4
                                        Text { text: modelData[0]; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: 11 } }
                                        Text { text: modelData[1]; color: Theme.subtext; font { family: Theme.font; pixelSize: 10; weight: Font.Medium } }
                                    }
                                    Text { text: modelData[2]; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold; features: { "tnum": 1 } } }
                                }
                            }
                        }
                    }

                    // next 12 hours
                    Rectangle {
                        visible: root.c.showHourly && root.hours.length > 0
                        Layout.fillWidth: true
                        implicitHeight: hourRow.implicitHeight + 16   // sized by its content so nothing gets clipped
                        radius: Theme.radius
                        color: Theme.fill
                        Flickable {
                            anchors { fill: parent; margins: 8 }
                            contentWidth: hourRow.implicitWidth
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            flickableDirection: Flickable.HorizontalFlick
                            Row {
                                id: hourRow
                                spacing: 0
                                Repeater {
                                    model: root.hours
                                    Column {
                                        required property var modelData
                                        required property int index
                                        width: 44
                                        spacing: 3
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: index === 0 ? "Now" : modelData.time.slice(0, 2); color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.glyphOf(modelData.code, modelData.day); color: Theme.text; font { family: Theme.iconFont; pixelSize: 17 } }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.rain >= 30 ? modelData.rain + "%" : " "
                                            color: Theme.accent2
                                            font { family: Theme.font; pixelSize: 9; weight: Font.DemiBold }
                                        }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: Math.round(modelData.temp) + "°"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } } }
                                    }
                                }
                            }
                        }
                    }

                    // next days: name, icon, rain chance, low, range bar, high
                    Rectangle {
                        id: dayBox
                        visible: root.days.length > 0
                        Layout.fillWidth: true
                        implicitHeight: dayList.implicitHeight + 8
                        radius: Theme.radius
                        color: Theme.fill
                        readonly property real lo: Math.min(...root.days.map(d => d.min))
                        readonly property real hi: Math.max(...root.days.map(d => d.max))
                        Column {
                            id: dayList
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4; leftMargin: 12; rightMargin: 12 }
                            Repeater {
                                model: root.days
                                Item {
                                    id: dayRow
                                    required property var modelData
                                    required property int index
                                    width: dayList.width
                                    height: 32
                                    Text {
                                        id: dayName
                                        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                                        width: 46
                                        text: dayRow.index === 0 ? "Today" : Qt.locale("en_GB").toString(dayRow.modelData.date, "ddd")
                                        color: Theme.text
                                        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium }
                                    }
                                    Text {
                                        id: dayIcon
                                        anchors { left: dayName.right; verticalCenter: parent.verticalCenter }
                                        width: 24
                                        text: root.glyphOf(dayRow.modelData.code, true)
                                        color: Theme.text
                                        font { family: Theme.iconFont; pixelSize: 16 }
                                    }
                                    Text {
                                        id: dayRain
                                        anchors { left: dayIcon.right; verticalCenter: parent.verticalCenter }
                                        width: 34
                                        text: dayRow.modelData.rain >= 20 ? dayRow.modelData.rain + "%" : ""
                                        color: Theme.accent2
                                        font { family: Theme.font; pixelSize: 10; weight: Font.DemiBold; features: { "tnum": 1 } }
                                    }
                                    Text {
                                        id: dayMin
                                        anchors { left: dayRain.right; verticalCenter: parent.verticalCenter }
                                        width: 32
                                        horizontalAlignment: Text.AlignRight
                                        text: Math.round(dayRow.modelData.min) + "°"
                                        color: Theme.subtext
                                        font { family: Theme.font; pixelSize: Theme.fontLabel; features: { "tnum": 1 } }
                                    }
                                    Rectangle {   // this day's range on the scale of the whole forecast
                                        id: track
                                        anchors { left: dayMin.right; leftMargin: 8; right: dayMax.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                        height: 4; radius: 2
                                        color: Theme.fill
                                        readonly property real span: Math.max(1, dayBox.hi - dayBox.lo)
                                        Rectangle {
                                            x: (dayRow.modelData.min - dayBox.lo) / track.span * track.width
                                            width: Math.max(height, (dayRow.modelData.max - dayRow.modelData.min) / track.span * track.width)
                                            height: parent.height; radius: 2
                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0; color: Theme.accent2 }
                                                GradientStop { position: 1; color: Theme.accent }
                                            }
                                        }
                                    }
                                    Text {
                                        id: dayMax
                                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                        width: 32
                                        horizontalAlignment: Text.AlignRight
                                        text: Math.round(dayRow.modelData.max) + "°"
                                        color: Theme.text
                                        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } }
                                    }
                                }
                            }
                        }
                    }

                    // footer
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Text {
                            Layout.fillWidth: true
                            text: root.ready ? "Updated " + Qt.formatTime(root.updated, "HH:mm") + " · Open-Meteo" : "Loading…"
                            color: Theme.muted
                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                        }
                        Chip { label: "Settings"; onClicked: { popup.hide(); SettingsApp.show("weather") } }
                    }
                }
            }
        }
    }
}
