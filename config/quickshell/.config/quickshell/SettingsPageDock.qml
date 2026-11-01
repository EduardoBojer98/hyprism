import Quickshell
import QtQuick
import QtQuick.Layouts

// Dock: its design (a ready-made set of look options, or each option on its own), how it behaves, and
// its pinned apps (dock.pinned, app ids). Every design works with any apps and settings below.
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

    readonly property var designs: [
        { id: "glass",   name: "Glass",   about: "A rounded glass island",
          set: { style: "glass", tint: "glass", indicator: "dot", hover: "plate" } },
        { id: "magnify", name: "Magnify", about: "A pill whose icons grow under the pointer",
          set: { style: "pill", tint: "glass", indicator: "dot", hover: "grow" } },
        { id: "panel",   name: "Panel",   about: "A solid panel along the bottom edge",
          set: { style: "panel", tint: "solid", indicator: "line", hover: "plate" } },
        { id: "shelf",   name: "Shelf",   about: "Icons standing on a glass shelf",
          set: { style: "shelf", tint: "glass", indicator: "line", hover: "lift" } },
        { id: "floating", name: "Floating icons", about: "Only the icons, growing on hover",
          set: { style: "clear", tint: "glass", indicator: "dot", hover: "grow" } },
        { id: "accent",  name: "Accent",  about: "A pill tinted with the accent colour",
          set: { style: "pill", tint: "accent", indicator: "line", hover: "lift" } },
    ]

    SettingGroup {
        title: "Design"
        DesignGallery { id: gallery; section: "dock"; designs: page.designs }
    }

    SettingGroup {
        title: gallery.match ? "Customise" : "Customise · your own mix"
        SettingRow {
            label: "Shape"
            ConfigChoice { section: "dock"; key: "style"; values: ["glass", "pill", "panel", "shelf", "clear"]
                           labels: ["Glass", "Pill", "Panel", "Shelf", "Clear"] }
        }
        SettingRow {
            label: "Colour"
            ConfigChoice { section: "dock"; key: "tint"; values: ["glass", "solid", "accent"]; labels: ["Glass", "Solid", "Accent"] }
        }
        SettingRow {
            label: "Open apps"
            hint: "The mark under an app with windows open; the focused one is in the accent colour"
            ConfigChoice { section: "dock"; key: "indicator"; values: ["dot", "line", "none"]; labels: ["Dot", "Line", "None"] }
        }
        SettingRow {
            label: "Pointing at an icon"
            ConfigChoice { section: "dock"; key: "hover"; values: ["plate", "grow", "lift"]; labels: ["Tile behind", "Grow", "Lift"] }
        }
    }

    SettingGroup {
        title: "Behaviour"
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
        text: "In the dock: drag an icon sideways to reorder, right-click it to pin, unpin, minimise or quit."
        color: Theme.muted
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    ResetGroup { sections: ["dock"] }
}
