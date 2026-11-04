import QtQuick
import QtQuick.Layouts

// Calendar: what the calendar under the clock marks. Public holidays come from date.nager.at
// (free, no account) for the chosen country; observances and moon phases are computed locally.
// Saved in Config.calendar; applied live.
ColumnLayout {
    id: page
    spacing: 20

    Component.onCompleted: Calendar.loadCountries()
    readonly property var countries: Calendar.countries
    function countryName(code) { return countries.find(c => c.countryCode === code)?.name ?? code }

    SettingGroup {
        title: "Events"
        SettingRow {
            label: "Public holidays"
            hint: "Days off in your country, shown in red"
            ConfigToggle { section: "calendar"; key: "holidays" }
        }
        SettingRow {
            visible: Config.calendar.holidays
            label: "Country"
            hint: page.countries.length ? "" : "Holiday list unavailable offline (it loads once with internet)"
            Dropdown {
                width: 220
                options: page.countries.length ? page.countries.map(c => c.name) : [Config.calendar.country]
                current: page.countryName(Config.calendar.country)
                onPicked: v => Config.set("calendar", "country", page.countries.find(c => c.name === v)?.countryCode ?? Config.calendar.country)
            }
        }
        SettingRow {
            visible: Config.calendar.holidays
            label: "Names in the local language"
            hint: "e.g. Божић instead of Christmas Day"
            ConfigToggle { section: "calendar"; key: "localNames" }
        }
        SettingRow {
            label: "Global observances"
            hint: "Valentine's Day, Earth Day, Halloween, New Year's Eve and other worldwide days"
            ConfigToggle { section: "calendar"; key: "observances" }
        }
        SettingRow {
            label: "Moon phases"
            hint: "New moon, quarters and full moon"
            ConfigToggle { section: "calendar"; key: "moon" }
        }
    }

    SettingGroup {
        title: "Layout"
        SettingRow {
            label: "Week starts on"
            ConfigChoice { section: "calendar"; key: "firstDay"; values: ["monday", "sunday"]; labels: ["Monday", "Sunday"] }
        }
        SettingRow {
            label: "Week numbers"
            hint: "ISO week number beside each row"
            ConfigToggle { section: "calendar"; key: "weekNumbers" }
        }
    }

    ResetGroup { sections: ["calendar"] }
}
