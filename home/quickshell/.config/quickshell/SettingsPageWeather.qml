import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Weather: the city the bar shows (Open-Meteo geocoding, no account) and what the forecast
// dropdown (click the temperature in the bar) contains. Saved in Config.weather; applied live.
ColumnLayout {
    id: page
    spacing: 20

    property var results: []

    function search(q) {
        geo.running = false
        geo.command = ["curl", "-sf", "--max-time", "8", "https://geocoding-api.open-meteo.com/v1/search?count=6&language=en&name=" + encodeURIComponent(q)]
        geo.running = true
    }

    Process {
        id: geo
        stdout: StdioCollector {
            onStreamFinished: { try { page.results = JSON.parse(text).results ?? [] } catch (e) { page.results = [] } }
        }
    }

    function choose(r) {
        Config.set("weather", "city", r.name)
        Config.set("weather", "latitude", r.latitude)
        Config.set("weather", "longitude", r.longitude)
        results = []
        field.text = ""
    }

    SettingGroup {
        SettingRow {
            label: "Current location"
            hint: Weather.ready ? Math.round(Weather.temperature) + "° · " + Weather.condition : "Loading…"
            Text { text: Weather.city; color: Theme.text; font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold } }
        }
        SettingRow {
            label: "Change city"
            Rectangle {
                width: 260; height: 30; radius: 10
                color: Theme.fill
                border { color: field.activeFocus ? Theme.accent : Theme.stroke; width: 1 }
                TextInput {
                    id: field
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 13 }
                    onAccepted: if (text.trim().length > 1) page.search(text.trim())
                    Text { visible: !field.text; text: "Type a city and press Enter"; color: Theme.muted; font: field.font; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    SettingGroup {
        title: "Forecast"
        SettingRow {
            label: "Days"
            hint: "How many days the dropdown lists"
            ConfigChoice { section: "weather"; key: "days"; values: [3, 5, 7, 10, 14]; labels: ["3", "5", "7", "10", "14"] }
        }
        SettingRow {
            label: "Next 12 hours"
            ConfigToggle { section: "weather"; key: "showHourly" }
        }
        SettingRow {
            label: "Details"
            hint: "Feels like, humidity, wind, UV index, sunrise and sunset"
            ConfigToggle { section: "weather"; key: "showDetails" }
        }
        SettingRow {
            label: "Units"
            ConfigChoice { section: "weather"; key: "units"; values: ["celsius", "fahrenheit"]; labels: ["°C, km/h", "°F, mph"] }
        }
    }

    SettingGroup {
        title: "Results"
        visible: page.results.length > 0
        Repeater {
            model: page.results
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: [modelData.admin1, modelData.country].filter(x => x).join(", ")
                PillButton { text: "Use"; primary: true; onClicked: page.choose(modelData) }
            }
        }
    }
    ResetGroup { sections: ["weather"] }
}
