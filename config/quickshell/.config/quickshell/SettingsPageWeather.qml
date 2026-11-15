import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Weather: the places (Open-Meteo geocoding, no account), which one is the default, and what the forecast
// panel (click the temperature in the bar) shows. Saved in Config.weather; applied live.
ColumnLayout {
    id: page
    spacing: 20

    property var results: []
    property string status: ""
    readonly property var places: Config.weather.locations ?? []
    readonly property var allDetails: ["feels", "humidity", "wind", "uv", "rain", "sun"]
    readonly property var detailNames: ["Feels like", "Humidity", "Wind", "UV index", "Rain chance", "Sunrise and sunset"]

    function search(q) {
        status = "Searching…"
        results = []
        geo.running = false
        geo.command = ["curl", "-sf", "--max-time", "8", "https://geocoding-api.open-meteo.com/v1/search?count=6&language=en&name=" + encodeURIComponent(q)]
        geo.running = true
    }

    Process {
        id: geo
        stdout: StdioCollector {
            onStreamFinished: {
                // curl -f prints nothing when the service is unreachable or errors
                if (!text.trim()) { page.results = []; page.status = "Couldn't reach the weather service"; return }
                try { page.results = JSON.parse(text).results ?? [] } catch (e) { page.results = [] }
                page.status = page.results.length ? "" : "No places found"
            }
        }
    }

    function save(list) {
        const err = Config.set("weather", "locations", list)
        if (err) status = err
    }
    function add(r) {
        if (places.some(p => p.latitude === r.latitude && p.longitude === r.longitude)) { status = r.name + " is already in the list"; return }
        save(places.concat([{ name: r.name, region: r.admin1 ?? "", country: r.country ?? "", latitude: r.latitude, longitude: r.longitude }]))
        results = []
        field.text = ""
    }
    function rename(i, name) {
        if (!name.trim()) return
        save(places.map((p, k) => k === i ? Object.assign({}, p, { name: name.trim() }) : p))
    }
    function move(i, d) {
        const l = Array.from(places), j = i + d
        if (j < 0 || j >= l.length) return
        l.splice(j, 0, l.splice(i, 1)[0])
        save(l)
    }
    function remove(i) { save(places.filter((p, k) => k !== i)) }
    function toggleDetail(id) {
        const on = Config.weather.details
        Config.set("weather", "details", allDetails.filter(d => d === id ? !on.includes(d) : on.includes(d)))
    }

    SettingGroup {
        title: "Places"
        SettingRow {
            label: "Add a place"
            hint: page.status !== "" ? page.status : "Type a city, press Enter, then pick it from the results"
            TextField {
                id: field
                placeholder: "City"
                onAccepted: if (text.trim().length > 1) page.search(text.trim())
            }
            PillButton { text: "Search"; onClicked: if (field.text.trim().length > 1) page.search(field.text.trim()) }
        }
        Repeater {
            model: page.results
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: [modelData.admin1, modelData.country].filter(x => x).join(", ")
                PillButton { text: "Add"; primary: true; onClicked: page.add(modelData) }
            }
        }
        SettingRow {
            visible: page.places.length === 0
            label: "No places yet"
            hint: "The weather panel and the bar stay empty until you add one"
        }
        Repeater {
            model: page.places
            SettingRow {
                id: row
                required property var modelData
                required property int index
                label: modelData.name
                hint: [index === 0 ? "Default (the bar shows this one)" : "", modelData.region, modelData.country].filter(x => x).join(" · ")
                TextField {
                    width: 150
                    placeholder: "Rename"
                    accessibleName: "Rename " + row.modelData.name
                    onAccepted: { page.rename(row.index, text); text = "" }
                }
                ArrowButton { glyph: "\u{F0143}"; tip: "Move up"; enabled: row.index > 0; onClicked: page.move(row.index, -1) }
                ArrowButton { glyph: "\u{F0140}"; tip: "Move down"; enabled: row.index < page.places.length - 1; onClicked: page.move(row.index, 1) }
                ArrowButton { glyph: "\u{F0156}"; tip: "Remove " + row.modelData.name; onClicked: page.remove(row.index) }
            }
        }
    }

    SettingGroup {
        title: "Forecast"
        SettingRow {
            label: "Days"
            hint: "Rows in the daily list; none hides it"
            ConfigChoice { section: "weather"; key: "days"; values: [0, 3, 5, 7, 10, 14]; labels: ["None", "3", "5", "7", "10", "14"] }
        }
        SettingRow {
            label: "Hours"
            hint: "Columns in the hourly strip; none hides it"
            ConfigChoice { section: "weather"; key: "hours"; values: [0, 6, 12, 24, 48]; labels: ["None", "6", "12", "24", "48"] }
        }
        SettingRow {
            label: "Units"
            ConfigChoice { section: "weather"; key: "units"; values: ["celsius", "fahrenheit"]; labels: ["°C, km/h", "°F, mph"] }
        }
        SettingRow {
            label: "Update every"
            hint: "Minutes between updates"
            ConfigChoice { section: "weather"; key: "refreshMin"; values: [10, 15, 30, 60]; labels: ["10", "15", "30", "60"] }
        }
    }

    SettingGroup {
        title: "Details under the current weather"
        Repeater {
            model: page.allDetails
            SettingRow {
                id: dr
                required property string modelData
                required property int index
                label: page.detailNames[index]
                Toggle {
                    checked: Config.weather.details.includes(dr.modelData)
                    onToggled: page.toggleDetail(dr.modelData)
                }
            }
        }
    }
    ResetGroup { sections: ["weather"] }
}
