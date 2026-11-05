pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Calendar under the clock (click the date and time in the bar, `qs ipc call calendar toggle`):
// today in large type, the month grid with dots on days that have events, and the selected day's
// events plus what's coming up. Events come from Settings > Calendar: public holidays for a country
// (date.nager.at, cached in ~/.cache/quickshell per year), worldwide observances and moon phases.
// Scroll or the arrows change month; Today jumps back.
Singleton {
    id: root

    readonly property bool open: popup.open
    readonly property var c: Config.calendar
    readonly property var locale: Qt.locale("en_GB")   // English names
    property date month: new Date()        // any day in the month shown
    property date selected: new Date()
    property date now: new Date()
    property var holidays: ({})            // "2026-01-07" -> ["Christmas Day"]
    property var loadedYears: ({})         // "RS-2026" -> true
    property var countries: []             // [{ countryCode, name }] for Settings

    function toggle() { popup.toggle() }
    function shift(n) { month = new Date(month.getFullYear(), month.getMonth() + n, 1) }
    function goToday() { now = new Date(); month = now; selected = now }

    function key(d) { return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}` }
    function sameDay(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate() }
    function addDays(d, n) { return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n) }
    function daysBetween(a, b) { return Math.round((new Date(b.getFullYear(), b.getMonth(), b.getDate()) - new Date(a.getFullYear(), a.getMonth(), a.getDate())) / 86400000) }
    // ISO 8601 week number
    function weekOf(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7))
        return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7)
    }

    // worldwide days on fixed dates (MM-DD)
    readonly property var observances: ({
        "01-01": "New Year's Day", "02-14": "Valentine's Day", "03-08": "International Women's Day",
        "03-17": "St Patrick's Day", "04-01": "April Fools' Day", "04-22": "Earth Day",
        "05-01": "International Workers' Day", "06-05": "World Environment Day", "09-21": "International Day of Peace",
        "10-31": "Halloween", "12-24": "Christmas Eve", "12-25": "Christmas Day", "12-31": "New Year's Eve",
    })

    // moon quarter that falls on this day, if any (mean synodic month; within about half a day)
    function moonOn(d) {
        const syn = 29.530588853, ref = Date.UTC(2000, 0, 6, 18, 14) / 86400000
        const day = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime() / 86400000
        const frac = x => ((x - ref) / syn % 1 + 1) % 1
        const p0 = frac(day), p1 = frac(day + 1)
        const names = [[0, "New moon", "\u{F0F64}"], [0.25, "First quarter", "\u{F0F61}"], [0.5, "Full moon", "\u{F0F62}"], [0.75, "Last quarter", "\u{F0F63}"]]
        for (const [q, name, glyph] of names)
            if (q === 0 ? p1 < p0 : p0 <= q && q < p1) return { title: name, glyph: glyph }
        return null
    }

    // [{ title, kind: "holiday" | "day" | "moon", glyph? }] for one date
    function eventsOn(d) {
        const out = []
        if (c.holidays) for (const t of holidays[key(d)] ?? []) out.push({ title: t, kind: "holiday" })
        if (c.observances) {
            const t = observances[key(d).slice(5)]
            if (t && !out.some(e => e.title === t)) out.push({ title: t, kind: "day" })
        }
        if (c.moon) { const m = moonOn(d); if (m) out.push({ title: m.title, kind: "moon", glyph: m.glyph }) }
        return out
    }
    function tone(kind) { return kind === "holiday" ? Theme.accent : Theme.subtext }   // a day off in the accent; observances and the moon quiet (red is not an error here)

    // the first event from today on, for Spotlight's home view
    readonly property var next: {
        holidays; c.holidays; c.observances; c.moon
        for (let i = 0; i <= 60; i++) {
            const d = addDays(now, i), e = eventsOn(d)
            if (e.length) return Object.assign({ date: d, days: i }, e[0])
        }
        return null
    }

    // the next few days with events after the selected one (two months ahead at most)
    readonly property var upcoming: {
        holidays; c.holidays; c.observances; c.moon   // re-run when sources change
        const out = []
        for (let i = 1; i <= 60 && out.length < 4; i++) {
            const d = addDays(selected, i)
            for (const e of eventsOn(d)) if (out.length < 4) out.push(Object.assign({ date: d }, e))
        }
        return out
    }

    // ---- holidays: one cached file per country and year --------------------------------------
    function loadYear(y) {
        if (!c.holidays || !c.country) return
        const k = `${c.country}-${y}`
        if (loadedYears[k]) return
        const l = Object.assign({}, loadedYears); l[k] = true; loadedYears = l
        const p = fetcher.createObject(root, { year: y, country: c.country })
        p.running = true
    }
    function reloadHolidays() { holidays = ({}); loadedYears = ({}); loadYear(month.getFullYear()); loadYear(new Date().getFullYear()) }
    onMonthChanged: { loadYear(month.getFullYear()); if (month.getMonth() === 11) loadYear(month.getFullYear() + 1) }
    Connections {
        target: Config.calendar
        function onCountryChanged() { root.reloadHolidays() }
        function onLocalNamesChanged() { root.reloadHolidays() }
        function onHolidaysChanged() { root.reloadHolidays() }
    }
    Component {
        id: fetcher
        Process {
            id: proc
            property int year
            property string country
            command: ["sh", "-c", "d=\"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell\"; f=\"$d/holidays-$1-$2.json\"; mkdir -p \"$d\"; [ -s \"$f\" ] || curl -sf --max-time 8 \"https://date.nager.at/api/v3/PublicHolidays/$2/$1\" -o \"$f\"; cat \"$f\" 2>/dev/null",
                      "sh", country, String(year)]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const h = Object.assign({}, root.holidays)
                        for (const x of JSON.parse(text)) {
                            const name = root.c.localNames ? x.localName : x.name
                            h[x.date] = (h[x.date] ?? []).filter(n => n !== name).concat([name])
                        }
                        root.holidays = h
                    } catch (e) {   // offline and nothing cached yet: try again next time
                        const l = Object.assign({}, root.loadedYears); delete l[`${proc.country}-${proc.year}`]; root.loadedYears = l
                    }
                    proc.destroy()
                }
            }
        }
    }
    function loadCountries() {
        if (countries.length) return
        countryReader.running = true
    }
    Process {
        id: countryReader
        command: ["sh", "-c", "d=\"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell\"; f=\"$d/holiday-countries.json\"; mkdir -p \"$d\"; [ -s \"$f\" ] || curl -sf --max-time 8 https://date.nager.at/api/v3/AvailableCountries -o \"$f\"; cat \"$f\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.countries = JSON.parse(text).sort((a, b) => a.name.localeCompare(b.name)) } catch (e) {} }
        }
    }
    Component.onCompleted: reloadHolidays()

    IpcHandler {
        target: "calendar"
        function toggle(): void { root.toggle() }
    }

    // ---- the popup -------------------------------------------------------------------------------
    CursorPopup {
        id: popup
        name: "calendar"
        placement: "top"
        boxWidth: 340
        boxHeight: Math.min(body.implicitHeight + Theme.spaceL * 2, popup.maxHeight)
        onOpened: root.goToday()

        Glass {
            anchors.fill: parent
            strong: true
            radius: Theme.radiusPanel
            WheelHandler { onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1) }

            Column {
                id: body
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceL }
                spacing: Theme.spaceM

                // today, large
                Row {
                    spacing: Theme.spaceM
                    Text {
                        text: root.now.getDate()
                        color: Theme.accent
                        font { family: Theme.displayFont; pixelSize: Theme.fontHero; weight: Theme.displayWeight; features: { "tnum": 1 } }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        Text { text: root.locale.toString(root.now, "dddd"); color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontTitle; weight: Font.DemiBold } }
                        Text {
                            text: root.locale.toString(root.now, "MMMM yyyy") + "  ·  Week " + root.weekOf(root.now)
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
                        }
                    }
                }

                // month and navigation
                Item {
                    width: parent.width; height: Theme.controlHeight
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.locale.standaloneMonthName(root.month.getMonth()) + " " + root.month.getFullYear()
                        color: Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                    }
                    Row {
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        spacing: Theme.spaceXs
                        Chip { icon: "\u{F0141}"; onClicked: root.shift(-1) }
                        Chip { label: "Today"; onClicked: root.goToday() }
                        Chip { icon: "\u{F0142}"; onClicked: root.shift(1) }
                    }
                }

                // weekday names, then six weeks; an optional week-number column on the left
                Column {
                    id: grid
                    width: parent.width
                    spacing: 2
                    readonly property int firstDay: root.c.firstDay === "sunday" ? 0 : 1
                    readonly property real numW: root.c.weekNumbers ? 26 : 0
                    readonly property real cellW: (width - numW) / 7
                    readonly property date start: {
                        const f = new Date(root.month.getFullYear(), root.month.getMonth(), 1)
                        return root.addDays(f, -((f.getDay() - firstDay + 7) % 7))
                    }

                    Row {
                        Item { width: grid.numW; height: 20 }
                        Repeater {
                            model: 7
                            Text {
                                required property int index
                                readonly property int dow: (index + grid.firstDay) % 7
                                width: grid.cellW; height: 20
                                horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                text: root.locale.dayName(dow, Locale.ShortFormat).slice(0, 2)
                                color: dow === 0 || dow === 6 ? Theme.muted : Theme.subtext
                                font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                            }
                        }
                    }
                    Repeater {
                        model: 6
                        Row {
                            id: week
                            required property int index
                            readonly property date first: root.addDays(grid.start, index * 7)
                            Text {
                                visible: root.c.weekNumbers
                                width: grid.numW; height: 36
                                horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter
                                text: root.weekOf(root.addDays(week.first, 3))
                                color: Theme.muted
                                font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
                            }
                            Repeater {
                                model: 7
                                Item {
                                    id: cell
                                    required property int index
                                    readonly property date day: root.addDays(week.first, index)
                                    readonly property bool inMonth: day.getMonth() === root.month.getMonth()
                                    readonly property bool isToday: root.sameDay(day, root.now)
                                    readonly property bool isSelected: root.sameDay(day, root.selected)
                                    readonly property bool weekend: day.getDay() === 0 || day.getDay() === 6
                                    readonly property var events: { root.holidays; root.c.holidays; root.c.observances; root.c.moon; return root.eventsOn(day) }
                                    width: grid.cellW; height: 36

                                    Rectangle {   // today: accent disc; selected: ring; hover: soft plate
                                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 1 }
                                        width: 30; height: 30; radius: 15
                                        color: cell.isToday ? Theme.accent : dayArea.containsMouse ? Theme.fillHover : "transparent"
                                        border { color: cell.isSelected && !cell.isToday ? Theme.accent : "transparent"; width: 1.5 }
                                    }
                                    Text {
                                        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 1 }
                                        height: 30; verticalAlignment: Text.AlignVCenter
                                        text: cell.day.getDate()
                                        color: cell.isToday ? Theme.accentText : !cell.inMonth ? Theme.muted
                                             : cell.events.some(e => e.kind === "holiday") ? Theme.error
                                             : cell.weekend ? Theme.subtext : Theme.text
                                        opacity: cell.inMonth || cell.isToday ? 1 : 0.6
                                        font { family: Theme.font; pixelSize: Theme.fontSize; weight: cell.isToday ? Font.Bold : Font.Normal; features: { "tnum": 1 } }
                                    }
                                    Row {   // one dot per event, up to three
                                        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 1 }
                                        spacing: 2
                                        Repeater {
                                            model: cell.events.slice(0, 3)
                                            Rectangle {
                                                required property var modelData
                                                width: 4; height: 4; radius: 2
                                                color: root.tone(modelData.kind)
                                                opacity: cell.inMonth ? 1 : 0.5
                                            }
                                        }
                                    }
                                    MouseArea {
                                        id: dayArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.selected = cell.day; if (!cell.inMonth) root.month = cell.day }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle { width: parent.width; height: 1; color: Theme.stroke }

                // the selected day
                Column {
                    width: parent.width
                    spacing: 6
                    readonly property var events: { root.holidays; root.c.holidays; root.c.observances; root.c.moon; return root.eventsOn(root.selected) }
                    Row {
                        width: parent.width
                        Text {
                            width: parent.width - rel.implicitWidth
                            text: root.locale.toString(root.selected, "dddd d MMMM")
                            elide: Text.ElideRight
                            color: Theme.text
                            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
                        }
                        Text {
                            id: rel
                            readonly property int n: root.daysBetween(root.now, root.selected)
                            text: n === 0 ? "Today" : n === 1 ? "Tomorrow" : n === -1 ? "Yesterday" : n > 0 ? `In ${n} days` : `${-n} days ago`
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                        }
                    }
                    Text {
                        visible: parent.events.length === 0
                        text: "No events"
                        color: Theme.muted
                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                    }
                    Repeater {
                        model: parent.events
                        EventRow { required property var modelData; event: modelData }
                    }
                }

                // coming up after it
                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.upcoming.length > 0
                    Text { text: "Coming up"; color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
                    Repeater {
                        model: root.upcoming
                        EventRow { required property var modelData; event: modelData; showDate: true }
                    }
                }

                Item {
                    width: parent.width; height: Theme.controlHeight
                    Chip {
                        anchors.right: parent.right
                        icon: "\u{F0493}"; label: "Calendar settings"
                        onClicked: { popup.hide(); SettingsApp.show("calendar") }
                    }
                }
            }
        }
    }

    // a coloured mark (dot, or the moon's phase), the title, and the date when listed ahead
    component EventRow: Row {
        property var event
        property bool showDate: false
        width: parent ? parent.width : 0
        spacing: 8
        Item {
            width: 12; height: 18
            Rectangle { visible: !event.glyph; anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: root.tone(event.kind) }
            Text { visible: !!event.glyph; anchors.centerIn: parent; text: event.glyph ?? ""; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: 12 } }
        }
        Text {
            width: parent.width - 20 - (dateText.visible ? dateText.implicitWidth + 8 : 0)
            height: 18; verticalAlignment: Text.AlignVCenter
            text: event.title
            elide: Text.ElideRight
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Text {
            id: dateText
            visible: showDate
            height: 18; verticalAlignment: Text.AlignVCenter
            text: event.date ? root.locale.toString(event.date, "ddd d MMM") : ""
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
        }
    }
}
