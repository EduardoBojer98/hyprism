import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Weather: choose the city the bar shows (Open-Meteo geocoding, no account). Saved in
// quickshell/settings.json; the bar refreshes immediately.
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

    FileView {
        id: settingsFile
        path: Quickshell.shellDir + "/settings.json"
        printErrors: false
    }

    function choose(r) {
        let data = {}
        try { data = JSON.parse(settingsFile.text()) } catch (e) {}
        data.weather = { city: r.name, latitude: r.latitude, longitude: r.longitude }
        settingsFile.setText(JSON.stringify(data, null, 2) + "\n")
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
}
