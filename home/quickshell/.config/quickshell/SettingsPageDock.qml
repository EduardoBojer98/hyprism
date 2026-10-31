import Quickshell
import QtQuick
import QtQuick.Layouts

// Desktop & Dock: the dock at the bottom of each screen, and its pinned apps (dock.pinned, app ids).
ColumnLayout {
    id: page
    spacing: 20

    property string query: ""
    readonly property var pinned: Config.dock.pinned
    readonly property var matches: {
        const q = query.trim().toLowerCase()
        if (!q) return []
        return DesktopEntries.applications.values
            .filter(e => !e.noDisplay && !pinned.includes(e.id) && (e.name.toLowerCase().includes(q) || e.id.toLowerCase().includes(q)))
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 8)
    }
    function add(id) { Config.set("dock", "pinned", pinned.concat([id])); query = ""; search.text = "" }
    function remove(id) { Config.set("dock", "pinned", pinned.filter(x => x !== id)) }

    SettingGroup {
        title: "Dock"
        SettingRow {
            label: "Icon size"
            ConfigChoice { section: "dock"; key: "iconSize"; values: [36, 44, 52, 60]; labels: ["Small", "Medium", "Large", "Huge"] }
        }
        SettingRow {
            label: "Hide automatically"
            hint: "Slides away until the pointer touches the bottom edge"
            ConfigToggle { section: "dock"; key: "autoHide" }
        }
        SettingRow {
            label: "Show open windows"
            hint: "Each window as its own tile, right of the pinned apps"
            ConfigToggle { section: "dock"; key: "showRunning" }
        }
        SettingRow {
            visible: Config.dock.showRunning
            label: "Window pictures"
            hint: "A picture of each window, live while the pointer is on the dock. Off: just the app icon"
            ConfigToggle { section: "dock"; key: "thumbnails" }
        }
        SettingRow {
            id: refreshRow
            readonly property var presets: [30, 60, 300, 900]
            property bool custom: !presets.includes(Config.dock.thumbRefresh)
            property string error: ""
            visible: Config.dock.showRunning && Config.dock.thumbnails
            label: "Refresh pictures"
            hint: error !== "" ? error : "How often the pictures update while the pointer is elsewhere"
            Choice {
                options: ["30 s", "1 min", "5 min", "15 min", "Custom"]
                index: refreshRow.custom ? 4 : refreshRow.presets.indexOf(Config.dock.thumbRefresh)
                onPicked: i => {
                    refreshRow.custom = i === 4
                    if (i < 4) refreshRow.error = Config.set("dock", "thumbRefresh", refreshRow.presets[i])
                }
            }
        }
        SettingRow {
            visible: refreshRow.visible && refreshRow.custom
            label: "Every (seconds)"
            hint: "10 to 86400, Enter to save"
            TextField {
                width: 96
                text: Config.dock.thumbRefresh
                onAccepted: refreshRow.error = Config.set("dock", "thumbRefresh", Math.round(Number(text)))
            }
        }
    }

    SettingGroup {
        title: "Pinned apps"
        Text {
            visible: page.pinned.length === 0
            Layout.fillWidth: true
            Layout.margins: 16
            text: "Nothing pinned. Search below to add an app."
            color: Theme.muted
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Repeater {
            model: page.pinned
            AppRow {
                required property string modelData
                required property int index
                entry: DesktopEntries.byId(modelData)
                fallback: modelData
                first: index === 0
                action: "Unpin"
                onTriggered: page.remove(modelData)
            }
        }
        SettingRow {
            label: "Add an app"
            hint: "Type part of the app's name"
            TextField {
                id: search
                width: 220
                placeholder: "e.g. Files"
                onTextChanged: page.query = text
                onAccepted: if (page.matches.length) page.add(page.matches[0].id)
            }
        }
        Repeater {
            model: page.matches
            AppRow {
                required property var modelData
                entry: modelData
                action: "Add"
                onTriggered: page.add(modelData.id)
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "In the dock: drag an icon sideways to reorder, right-click it to pin, unpin, minimise or quit."
        color: Theme.muted
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    ResetGroup { sections: ["dock"] }
}
