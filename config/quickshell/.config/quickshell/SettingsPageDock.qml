import Quickshell
import QtQuick
import QtQuick.Layouts

// Dock: on or off, where it sits and on which monitors, how it behaves, and its pinned apps
// (dock.pinned, app ids). Its look comes from the theme; every option works in every theme, and a dock
// on the same edge as the bar sits beside it.
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
    // dragging: `id` before or after `target` (the dock itself reorders the same way)
    function place(id, target, after) {
        if (id === target) return
        const list = pinned.filter(x => x !== id), i = list.indexOf(target)
        if (i < 0) return
        list.splice(i + (after ? 1 : 0), 0, id)
        Config.set("dock", "pinned", list)
    }




    SettingGroup {
        title: "Place"
        SettingRow {
            label: "Show the dock"
            ConfigToggle { section: "dock"; key: "enabled" }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: "Position"
            hint: Theme.dockInBar ? "Inside the menu bar, as its Apps item" + (Config.dock.position === "theme" ? " (the theme puts the dock on the bar's edge)" : "")
                : Theme.dockEdge === Theme.barEdge ? "Beside the bar, which is on the same edge" : "The " + Theme.current.name + " theme's is " + (Theme.dockStyle.edge === Theme.barEdge ? "inside the bar" : Theme.dockStyle.edge)
            ConfigChoice { section: "dock"; key: "position"; values: ["theme", "bar", "bottom", "left", "right", "top"]; labels: ["Theme's", "In the bar", "Bottom", "Left", "Right", "Top"] }
        }
        SettingRow {
            visible: Config.dock.enabled
            label: "Size"
            hint: "Room around the icons"
            ConfigChoice { section: "dock"; key: "size"; values: ["compact", "regular", "roomy"]; labels: ["Compact", "Regular", "Roomy"] }
        }
        Repeater {
            model: Config.dock.enabled ? Quickshell.screens : []
            SettingRow {
                required property var modelData
                label: "On " + modelData.name
                hint: modelData.width + " × " + modelData.height
                Toggle {
                    checked: !Config.dock.hiddenOn.includes(modelData.name)
                    onToggled: on => Config.set("dock", "hiddenOn", on ? Config.dock.hiddenOn.filter(n => n !== modelData.name)
                                                                        : Array.from(Config.dock.hiddenOn).concat([modelData.name]))
                }
            }
        }
    }

    SettingGroup {
        visible: Config.dock.enabled
        title: "Behaviour"
        SettingRow {
            label: "Icon size"
            ConfigChoice { section: "dock"; key: "iconSize"; values: [36, 44, 52, 60]; labels: ["Small", "Medium", "Large", "Huge"] }
        }
        SettingRow {
            label: "Hide automatically"
            hint: "Slides away until the pointer touches its edge; stays on an empty desktop"
            ConfigToggle { section: "dock"; key: "autoHide" }
        }
        SettingRow {
            label: "Combine open apps with their icons"
            hint: Config.dock.combine ? "Like Windows' combined taskbar: an open app shares its icon; hover it for its windows"
                                      : "Off: pinned apps are launchers, every open window is its own tile after them"
            ConfigToggle { section: "dock"; key: "combine" }
        }
        SettingRow {
            visible: Config.dock.combine
            label: "Window previews on hover"
            hint: "A live picture of each window; click one to bring it up, middle-click to close it"
            ConfigToggle { section: "dock"; key: "previews" }
        }
        SettingRow {
            label: "Show open apps"
            hint: Config.dock.combine ? "Open apps that aren't pinned join after the pinned ones" : "Each window as its own tile, after the pinned apps"
            ConfigToggle { section: "dock"; key: "showRunning" }
        }
        SettingRow {
            visible: Config.dock.showRunning && !Config.dock.combine
            label: "Window pictures"
            hint: "A picture of each window, live while the pointer is on the dock. Off: just the app icon"
            ConfigToggle { section: "dock"; key: "thumbnails" }
        }
        SettingRow {
            id: refreshRow
            readonly property var presets: [30, 60, 300, 900]
            property bool custom: !presets.includes(Config.dock.thumbRefresh)
            property string error: ""
            visible: Config.dock.showRunning && Config.dock.thumbnails && !Config.dock.combine
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
        title: "Pinned apps · drag to reorder"
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
            DragItem {
                id: pin
                required property string modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 46
                key: "pinned"
                payload: modelData
                floatOn: page.parent
                radius: Theme.radius
                AppRow {
                    anchors.fill: parent
                    entry: DesktopEntries.byId(pin.modelData)
                    fallback: pin.modelData
                    first: pin.index === 0 || pin.dragging
                    action: "Unpin"
                    onTriggered: page.remove(pin.modelData)
                }
                DropSpot { anchors.fill: parent; key: "pinned"; vertical: true; owner: pin; onPlaced: (id, after) => page.place(id, pin.modelData, after) }
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
        text: "In the dock: drag an icon along it to reorder, right-click it to pin, unpin, minimise or quit."
        color: Theme.muted
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    ResetGroup { sections: ["dock"] }
}
