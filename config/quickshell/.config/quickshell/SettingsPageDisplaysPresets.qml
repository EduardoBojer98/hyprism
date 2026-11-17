import QtQuick
import QtQuick.Layouts

// Settings > Displays > Presets: quick layouts for the screens plugged in now, and your saved ones (apply,
// rename, delete, default star, switch automatically). Everything goes through Displays.qml, so applying one
// gets the same keep-or-revert countdown as the Apply button.
SettingGroup {
    id: group
    title: "Presets"

    property string message: ""        // why the last action was refused
    property string renaming: ""       // id of the preset being renamed

    function run(why) { message = why }

    SettingRow {
        label: "Quick layouts"
        hint: Displays.builtInPresets.length ? "Made from the screens plugged in now" : "Plug in another screen to switch layouts"
        RowLayout {
            spacing: Theme.spaceS
            Repeater {
                model: Displays.builtInPresets
                PillButton { required property var modelData; text: modelData.name; onClicked: group.run(Displays.applyMode(modelData.how)) }
            }
            PillButton { text: "Identify"; onClicked: Displays.identify() }
        }
    }

    Repeater {
        model: Displays.presets
        SettingRow {
            id: row
            required property var modelData
            readonly property bool ok: Displays.available(modelData)
            readonly property bool editing: group.renaming === modelData.id
            label: (Config.displays.defaultPreset === modelData.id ? "★ " : "") + modelData.name
            hint: ok ? (modelData.auto ? "Applies itself when exactly these screens are connected" : "The switch makes it apply itself when exactly its screens are connected")
                     : "Needs " + Displays.missing(modelData).join(", ")
            RowLayout {
                spacing: Theme.spaceS
                TextField {
                    visible: row.editing
                    Layout.preferredWidth: 160
                    accessibleName: "New name for " + row.modelData.name
                    Component.onCompleted: text = row.modelData.name
                    onAccepted: { group.run(Displays.rename(row.modelData.id, text)); group.renaming = "" }
                }
                Toggle {
                    visible: !row.editing
                    accessibleName: "Switch to " + row.modelData.name + " automatically"
                    checked: row.modelData.auto
                    onToggled: on => group.run(Displays.setAuto(row.modelData.id, on))
                }
                PillButton { visible: !row.editing; text: Config.displays.defaultPreset === row.modelData.id ? "Default ✓" : "Make default"; onClicked: group.run(Displays.setDefault(row.modelData.id)) }
                PillButton { visible: !row.editing; text: "Rename"; onClicked: group.renaming = row.modelData.id }
                PillButton { visible: !row.editing; text: "Delete"; onClicked: group.run(Displays.remove(row.modelData.id)) }
                PillButton { visible: !row.editing; text: "Apply"; primary: true; enabled: row.ok; onClicked: group.run(Displays.applyPreset(row.modelData.id)) }
            }
        }
    }

    SettingRow {
        label: "Save the layout on screen now"
        hint: group.message
        RowLayout {
            spacing: Theme.spaceS
            TextField { id: name; Layout.preferredWidth: 180; placeholder: "Preset name"; onAccepted: save.clicked() }
            PillButton {
                id: save
                text: "Save current as preset"
                onClicked: { group.run(Displays.saveCurrent(name.text)); if (!group.message) name.text = "" }
            }
        }
    }
}
