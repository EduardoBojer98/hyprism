import QtQuick

// A choice saved as an adjustment of the active theme (Config.appearance.custom, Themes.adjust):
// values[0] is the theme's own and removes the adjustment, so each theme keeps its own setting.
Choice {
    property string key
    property var values: []
    property var labels: []
    readonly property var mine: (Config.appearance.custom ?? {})[Config.appearance.theme] ?? {}
    options: labels
    index: mine[key] === undefined ? 0 : Math.max(0, values.indexOf(mine[key]))
    onPicked: i => Themes.adjust(key, i === 0 ? undefined : values[i])
}
