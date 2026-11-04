// A segmented choice bound to one Config option: Config.set validates and saves on pick.
Choice {
    property string section
    property string key
    property var values: []
    property var labels: values.map(String)

    options: labels
    index: values.indexOf(Config[section]?.[key])
    extra: index < 0 && Config[section]?.[key] !== undefined ? Config[section][key] + " (custom)" : ""
    onPicked: i => Config.set(section, key, values[i])
}
