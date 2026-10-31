// Last group on a Settings page: puts the page's Config section(s) back to their defaults.
SettingGroup {
    property var sections: []
    property var keys                // optional: only these keys, for a page that shares its section

    SettingRow {
        label: "Reset to defaults"
        hint: "Only the options on this page"
        PillButton { text: "Reset"; onClicked: { for (const s of sections) Config.reset(s, keys) } }
    }
}
