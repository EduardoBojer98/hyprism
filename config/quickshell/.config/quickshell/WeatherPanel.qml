import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// The forecast panel (Weather.qml puts it in a popup): place chips, now, chosen details, the hours with a
// temperature line and rain chance, the days with range bars, and the state of the data. Looking at another
// place here is not saved; Settings > Weather sets the places and the default (the first).
ColumnLayout {
    id: panel
    // rain in the second accent when it is a cool colour; a warm one (Monolith's orange) reads as an alarm, so then the "ok" colour
    readonly property color rain: Theme.accent2.hslHue > 0.15 && Theme.accent2.hslHue < 0.85 ? Theme.accent2 : Theme.ok
    signal settings()

    readonly property var f: Weather.view
    readonly property var place: Weather.places[Math.min(Weather.viewIndex, Weather.places.length - 1)] ?? null
    readonly property int hourW: Theme.spaceXl + Theme.spaceL
    spacing: Theme.spaceS
    width: 328

    function tile(id) {
        const d = f.days[0]
        return id === "feels" ? ["\u{F050F}", "Feels like", Math.round(f.feelsLike) + "°"]
             : id === "humidity" ? ["\u{F058E}", "Humidity", f.humidity + "%"]
             : id === "wind" ? ["\u{F059D}", "Wind", Math.round(f.wind) + " " + Weather.windUnit]
             : id === "uv" ? ["\u{F0599}", "UV index", d ? Math.round(d.uv) : "–"]
             : id === "rain" ? ["\u{F0597}", "Rain", d ? d.rain + "%" : "–"]
             : id === "sun" ? ["\u{F059C}", "Sun", d ? d.sunrise + "–" + d.sunset : "–"] : null
    }

    // no place yet
    ColumnLayout {
        visible: !Weather.hasPlace
        Layout.fillWidth: true
        Layout.topMargin: Theme.spaceL
        spacing: Theme.spaceS
        Text { Layout.alignment: Qt.AlignHCenter; text: "\u{F0590}"; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: Theme.iconLarge } }
        Text { Layout.alignment: Qt.AlignHCenter; text: "No place yet"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold } }
        Text { Layout.alignment: Qt.AlignHCenter; text: "Add a city to see its forecast."; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontSize } }
        PillButton { Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: Theme.spaceM; text: "Add a place in Settings"; primary: true; onClicked: panel.settings() }
    }

    // place chips (several places)
    Flow {
        visible: Weather.places.length > 1
        Layout.fillWidth: true
        spacing: Theme.spaceXs
        Repeater {
            model: Weather.places
            Chip {
                required property var modelData
                required property int index
                label: modelData.name
                active: index === Weather.viewIndex
                onClicked: Weather.viewIndex = index
            }
        }
    }

    // loading: a skeleton of the panel
    ColumnLayout {
        visible: Weather.hasPlace && !f && Weather.loading
        Layout.fillWidth: true
        spacing: Theme.spaceS
        Accessible.name: "Loading the forecast"
        Repeater {
            model: [Theme.fontHero + Theme.spaceM, Theme.rowHeight * 2, Theme.rowHeight * 2, Theme.rowHeight * 3]
            Rectangle {
                required property real modelData
                Layout.fillWidth: true
                implicitHeight: modelData
                radius: Theme.radius
                color: Theme.fill
                SequentialAnimation on opacity {
                    running: Theme.animate
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.5; duration: 700 }
                    NumberAnimation { to: 1; duration: 700 }
                }
            }
        }
    }

    // error with nothing to show
    ColumnLayout {
        visible: Weather.hasPlace && !f && !Weather.loading
        Layout.fillWidth: true
        Layout.topMargin: Theme.spaceM
        spacing: Theme.spaceS
        Text { Layout.alignment: Qt.AlignHCenter; text: "Couldn't load the forecast"; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold } }
        Text { Layout.alignment: Qt.AlignHCenter; text: "Check the connection and try again."; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontSize } }
        PillButton { Layout.alignment: Qt.AlignHCenter; Layout.bottomMargin: Theme.spaceM; text: "Try again"; onClicked: Weather.refresh() }
    }

    // now
    RowLayout {
        visible: !!f
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spaceXs
        Layout.rightMargin: Theme.spaceXs
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: panel.place ? [panel.place.name, panel.place.region].filter(x => x).join(", ") : ""
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold }
            }
            Text {
                text: f ? Math.round(f.temperature) + "°" : ""
                color: Theme.text
                font { family: Theme.displayFont; pixelSize: Theme.fontHero; weight: Theme.displayWeight; features: { "tnum": 1 } }
            }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 2
            Text { Layout.alignment: Qt.AlignRight; text: f ? Weather.glyphOf(f.code, f.isDay) : ""; color: Theme.text; font { family: Theme.iconFont; pixelSize: Theme.iconLarge + 6 } }
            Text { Layout.alignment: Qt.AlignRight; text: f ? Weather.conditionOf(f.code) : ""; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium } }
            Text {
                Layout.alignment: Qt.AlignRight
                // feels-like goes here only when it isn't one of the readings below
                text: f ? [Array.from(Config.weather.details ?? []).includes("feels") ? "" : "Feels like " + Math.round(f.feelsLike) + "°",
                           f.days.length ? "H " + Math.round(f.days[0].max) + "°  L " + Math.round(f.days[0].min) + "°" : ""].filter(x => x).join("  ·  ") : ""
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
            }
        }
    }

    // chosen details
    GridLayout {
        visible: !!f && Weather.c.details.length > 0
        Layout.fillWidth: true
        columns: 3
        columnSpacing: Theme.spaceS
        rowSpacing: Theme.spaceS
        Repeater {
            model: f ? Weather.c.details.map(panel.tile).filter(t => t) : []
            Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: tileText.implicitHeight + Theme.spaceS * 2
                radius: Theme.radius
                color: Theme.fill
                Column {
                    id: tileText
                    anchors { left: parent.left; right: parent.right; leftMargin: Theme.spaceM; rightMargin: Theme.spaceXs; verticalCenter: parent.verticalCenter }
                    spacing: 1
                    Row {
                        spacing: Theme.spaceXs
                        Text { text: modelData[0]; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: Theme.fontCaption } }
                        Text { text: modelData[1]; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.Medium } }
                    }
                    Text { width: parent.width; elide: Text.ElideRight; text: modelData[2]; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold; features: { "tnum": 1 } } }
                }
            }
        }
    }

    // the hours: temperature line, rain chance under it
    Rectangle {
        visible: !!f && f.hours.length > 0
        Layout.fillWidth: true
        implicitHeight: strip.contentHeight + Theme.spaceM
        radius: Theme.radius
        color: Theme.fill
        Flickable {
            id: strip
            anchors { fill: parent; margins: Theme.spaceS }
            contentWidth: hourRow.width
            contentHeight: hourRow.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.HorizontalFlick
            Item {
                id: hourRow
                readonly property var hs: f ? f.hours : []
                readonly property real lo: hs.length ? Math.min(...hs.map(h => h.temp)) : 0
                readonly property real hi: hs.length ? Math.max(...hs.map(h => h.temp)) : 0
                readonly property real graphTop: Theme.fontCaption + Theme.iconSmall + Theme.spaceM + Theme.fontLabel
                readonly property real graphH: Theme.fontLabel * 2
                function yOf(t) { return graphTop + (hi - t) / Math.max(1, hi - lo) * graphH }
                width: hs.length * panel.hourW
                readonly property bool anyRain: hs.some(h => h.rain >= 5)
                height: graphTop + graphH + Theme.spaceXs + (anyRain ? Theme.spaceL + Theme.fontCaption + Theme.spaceXs : 0)

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeColor: Theme.accent
                        strokeWidth: 2
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        joinStyle: ShapePath.RoundJoin
                        PathPolyline {
                            path: hourRow.hs.map((h, i) => Qt.point((i + 0.5) * panel.hourW, hourRow.yOf(h.temp)))
                        }
                    }
                }
                Repeater {
                    model: hourRow.hs
                    Item {
                        id: hr
                        required property var modelData
                        required property int index
                        x: index * panel.hourW
                        width: panel.hourW
                        height: hourRow.height
                        Text { anchors { horizontalCenter: parent.horizontalCenter; top: parent.top } text: hr.index === 0 ? "Now" : hr.modelData.time.slice(0, 2); color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } } }
                        Text { anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Theme.fontCaption + Theme.spaceXs } text: Weather.glyphOf(hr.modelData.code, hr.modelData.day); color: Theme.text; font { family: Theme.iconFont; pixelSize: Theme.iconSmall } }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: hourRow.yOf(hr.modelData.temp) - height - Theme.spaceXs
                            text: Math.round(hr.modelData.temp) + "°"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.Medium; features: { "tnum": 1 } }
                        }
                        Rectangle { x: parent.width / 2 - 3; y: hourRow.yOf(hr.modelData.temp) - 3; width: 6; height: 6; radius: 3; color: Theme.accent }
                        Rectangle {   // rain chance: a bar under the line, the figure when it matters
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.fontCaption + Theme.spaceXs }
                            width: 4; height: Math.max(2, hr.modelData.rain / 100 * Theme.spaceL)
                            radius: 2
                            color: panel.rain
                            visible: hr.modelData.rain >= 5
                        }
                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom }
                            text: hr.modelData.rain >= 20 ? hr.modelData.rain + "%" : ""
                            color: panel.rain
                            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold; features: { "tnum": 1 } }
                        }
                    }
                }
            }
        }
    }

    // the days: name, icon, rain chance, low, range bar on the scale of the whole forecast, high
    Rectangle {
        id: dayBox
        readonly property var ds: f ? f.days.slice(0, Weather.c.days) : []
        visible: ds.length > 0
        Layout.fillWidth: true
        implicitHeight: dayList.implicitHeight + Theme.spaceS * 2
        radius: Theme.radius
        color: Theme.fill
        readonly property real lo: ds.length ? Math.min(...ds.map(d => d.min)) : 0
        readonly property real hi: ds.length ? Math.max(...ds.map(d => d.max)) : 0
        Column {
            id: dayList
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS; leftMargin: Theme.spaceM; rightMargin: Theme.spaceM }
            Repeater {
                model: dayBox.ds
                Item {
                    id: dayRow
                    required property var modelData
                    required property int index
                    width: dayList.width
                    height: Theme.fontLabel + Theme.spaceM * 2
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
                        text: Weather.glyphOf(dayRow.modelData.code, true)
                        color: Theme.text
                        font { family: Theme.iconFont; pixelSize: Theme.iconSmall }
                    }
                    Text {
                        id: dayRain
                        anchors { left: dayIcon.right; verticalCenter: parent.verticalCenter }
                        width: 34
                        text: dayRow.modelData.rain >= 20 ? dayRow.modelData.rain + "%" : ""
                        color: panel.rain
                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold; features: { "tnum": 1 } }
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
                    Rectangle {
                        id: track
                        anchors { left: dayMin.right; leftMargin: Theme.spaceS; right: dayMax.left; rightMargin: Theme.spaceS; verticalCenter: parent.verticalCenter }
                        height: 4; radius: 2
                        color: Theme.fillActive
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

    // footer: how fresh the data is, who it comes from
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.spaceXs
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                visible: !!f
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: Weather.stale ? "Couldn't update · last " + Qt.formatTime(Weather.updated, "HH:mm")
                    : Weather.loading ? "Updating…" : "Updated " + Qt.formatTime(Weather.updated, "HH:mm")
                color: Weather.stale ? Theme.warning : Theme.muted
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
            Text { text: "Weather: Open-Meteo"; color: Theme.muted; font { family: Theme.font; pixelSize: Theme.fontCaption } }
        }
        Chip { label: "Settings"; onClicked: panel.settings() }
    }
}
