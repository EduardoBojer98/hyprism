import Quickshell
import QtQuick
import QtQuick.Layouts
import "bar/items/clock/format.js" as Format

// A clock's own settings: what it shows of the time and the date, in which order, or a Qt pattern of your own,
// with a live preview of exactly what the bar draws (both use bar/items/clock/format.js). Each copy of the clock
// keeps its own (bar.items.<instance>); `item` is the SettingsBarItem (its merged settings and put()).
ColumnLayout {
    id: ck
    required property var item
    spacing: 0
    readonly property var c: item.merged
    // the same defaults the bar uses: the large display face shows the time alone unless asked
    readonly property var defaults: ({ h24: Config.bar.clock24, seconds: Config.bar.seconds, date: Theme.barStyle.clock !== "display" || item.merged.time === false })
    readonly property bool typing: customField.children[0].activeFocus === true
    // while the pattern is being typed the preview follows the field; otherwise what is saved
    readonly property var fmt: Format.patterns(typing ? Object.assign({}, c, { custom: customField.text }) : c, defaults)
    readonly property string built: Format.patterns(Object.assign({}, c, { custom: "" }), defaults).all
    readonly property bool timeOn: c.time !== false
    readonly property bool dateOn: c.date ?? defaults.date
    readonly property var seps: ["  ", " · ", " | ", ", "]
    SystemClock { id: tick; precision: SystemClock.Seconds }

    SettingRow {
        label: "Preview"
        hint: ck.fmt.custom ? "Your own format" : "As this clock shows it"
        Rectangle {
            implicitWidth: Math.max(140, preview.implicitWidth + 28)
            implicitHeight: Theme.controlHeight + 4
            radius: Theme.radiusSmall
            color: Theme.fill
            border { color: Theme.stroke; width: 1 }
            Accessible.role: Accessible.StaticText
            Accessible.name: "Preview: " + preview.text
            Text {
                id: preview
                anchors.centerIn: parent
                text: ck.fmt.all === "" ? "Nothing to show" : (Qt.formatDateTime(tick.date, ck.fmt.all) || "")   // nothing while torn down
                color: ck.fmt.all === "" ? Theme.subtext : Theme.text
                font { family: Theme.barStyle.mono ? Theme.monoFont : Theme.font; pixelSize: Theme.fontLabel + 1; weight: Font.Medium; features: { "tnum": 1 } }
            }
        }
    }

    // the choices; a pattern of your own wins over them, so they rest while it is set
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        enabled: !ck.fmt.custom
        opacity: enabled ? 1 : 0.45
        SettingRow {
            label: "Time"
            Toggle { checked: ck.timeOn; onToggled: on => ck.item.put("time", on ? undefined : false) }
        }
        SettingRow {
            visible: ck.timeOn
            label: "24-hour"
            hint: (ck.c.h24 ?? ck.defaults.h24) ? "14:40" : "2:40 PM"
            Toggle { checked: ck.c.h24 ?? ck.defaults.h24; onToggled: on => ck.item.put("h24", on) }
        }
        SettingRow {
            visible: ck.timeOn
            label: "Seconds"
            Toggle { checked: ck.c.seconds ?? ck.defaults.seconds; onToggled: on => ck.item.put("seconds", on) }
        }
        SettingRow {
            label: "Date"
            Toggle { checked: ck.dateOn; onToggled: on => ck.item.put("date", on) }
        }
        PartRow { label: "Weekday"; key: "weekday"; values: ["none", "short", "long"]; options: ["None", "Sun", "Sunday"] }
        SettingRow {
            visible: ck.dateOn
            label: "Day"
            Toggle { checked: ck.c.day !== false; onToggled: on => ck.item.put("day", on ? undefined : false) }
        }
        PartRow { label: "Month"; key: "month"; values: ["none", "short", "long", "number"]; options: ["None", "Nov", "November", "11"] }
        SettingRow {
            visible: ck.dateOn
            label: "Year"
            Toggle { checked: ck.c.year === true; onToggled: on => ck.item.put("year", on ? true : undefined) }
        }
        SettingRow {
            visible: ck.timeOn && ck.dateOn
            label: "Order"
            Choice {
                options: ["Date first", "Time first"]
                index: ck.c.first === "time" ? 1 : 0
                onPicked: i => ck.item.put("first", i === 1 ? "time" : undefined)
            }
        }
        SettingRow {
            visible: ck.timeOn && ck.dateOn
            label: "Between them"
            Choice {
                readonly property string sep: typeof ck.c.separator === "string" ? ck.c.separator : "  "
                options: ["Space", "Dot", "Line", "Comma"]
                index: Math.max(0, ck.seps.indexOf(sep))
                extra: ck.seps.includes(sep) ? "" : "“" + sep + "”"      // one typed into settings.json by hand
                onPicked: i => { if (i < ck.seps.length) ck.item.put("separator", i === 0 ? undefined : ck.seps[i]) }
            }
        }
    }

    SettingRow {
        label: "Own format"
        hint: "A Qt date pattern. It replaces the choices above; Enter applies, empty goes back to them"
        TextField {
            id: customField
            width: 220
            placeholder: ck.built
            Accessible.name: "Own format"
            onAccepted: ck.item.put("custom", text.trim())
            Binding on text { value: typeof ck.c.custom === "string" ? ck.c.custom : ""; when: !ck.typing; restoreMode: Binding.RestoreNone }
        }
    }
    Text {
        Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.bottomMargin: 10
        text: "d 5 · dd 05 · ddd Sun · dddd Sunday · M 11 · MMM Nov · MMMM November · yy 26 · yyyy 2026 · "
              + "HH 24-hour · h 12-hour · mm minutes · ss seconds · AP AM/PM · 'text' as written"
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    // one part of the date with a few forms
    component PartRow: SettingRow {
        id: pr
        property string key
        property var values
        property var options
        visible: ck.dateOn
        Choice {
            options: pr.options
            index: Math.max(0, pr.values.indexOf(ck.c[pr.key] ?? "short"))
            onPicked: i => ck.item.put(pr.key, pr.values[i] === "short" ? undefined : pr.values[i])
        }
    }
}
