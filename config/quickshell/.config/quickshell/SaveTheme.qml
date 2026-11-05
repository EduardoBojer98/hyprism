import QtQuick

// Save every change made to the active theme (colours and shape on Appearance, the bar's place and items,
// the dock's place) as a theme of your own (Themes.saveAs). It shows up in the Themes gallery; the theme
// you started from goes back to how it shipped. On one of your own themes it can also update that one.
SettingRow {
    id: st
    readonly property var t: Theme.current
    readonly property int changes: Object.keys((Config.appearance.custom ?? {})[Config.appearance.theme] ?? {}).length
    label: "Save as a theme"
    hint: changes === 0 ? "Change anything for " + t.name + " first; then keep it as your own theme"
        : changes + " change(s) to " + t.name + (t.user ? "" : "; " + t.name + " goes back to how it shipped")
    Row {
        spacing: 8
        TextField { id: name; width: 170; placeholder: st.t.user ? st.t.name + " 2" : "My " + st.t.name; enabled: st.changes > 0; onAccepted: save.clicked() }
        PillButton { id: save; text: "Save new"; primary: true; enabled: st.changes > 0
                     onClicked: { Themes.saveAs(name.text.trim() || name.placeholder); name.text = "" } }
        PillButton { visible: st.t.user === true; text: "Update " + st.t.name; enabled: st.changes > 0
                     onClicked: Themes.saveAs(st.t.name, Config.appearance.theme) }
    }
}
