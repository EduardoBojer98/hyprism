// An on/off switch bound to one Config option.
Toggle {
    property string section
    property string key

    checked: Config[section]?.[key] === true
    onToggled: on => Config.set(section, key, on)
}
