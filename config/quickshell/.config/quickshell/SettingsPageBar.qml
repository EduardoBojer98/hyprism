import Quickshell
import QtQuick
import QtQuick.Layouts

// Menu Bar: where the bar sits, its size and shape, which monitors have one, and which items each of
// its three sections holds. "Theme's" keeps the active theme's own (Themes.qml bar); every option
// works in every theme and on every edge. Changes apply live.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var b: Config.bar
    readonly property var layout: Theme.barLayout          // what the bar shows now
    readonly property var sections: [
        { key: "start", name: page.vertical ? "Top" : "Left" },
        { key: "center", name: "Middle" },
        { key: "end", name: page.vertical ? "Bottom" : "Right" }
    ]
    readonly property bool vertical: Theme.barVertical

    // edit the item lists: the first change copies the theme's own layout so there is something to edit
    function lists() {
        const l = page.layout
        return { start: Array.from(l.start), center: Array.from(l.center), end: Array.from(l.end) }
    }
    function save(l) {
        for (const k of ["start", "center", "end"]) Config.set("bar", k, l[k])
        if (!page.b.custom) Config.set("bar", "custom", true)
    }
    function move(section, i, d) {   // d: -1 earlier, +1 later
        const l = lists(), a = l[section], j = i + d
        if (j < 0 || j >= a.length) return
        ;[a[i], a[j]] = [a[j], a[i]]
        save(l)
    }
    function moveTo(section, i, target) {
        const l = lists(), id = l[section].splice(i, 1)[0]
        l[target].push(id)
        save(l)
    }
    function remove(section, i) { const l = lists(); l[section].splice(i, 1); save(l) }
    function add(section, id) { const l = lists(); l[section].push(id); save(l) }
    readonly property var unused: Themes.barItems.filter(it => ![...page.layout.start, ...page.layout.center, ...page.layout.end].includes(it.id))

    SettingGroup {
        title: "Place"
        SettingRow {
            label: "Position"
            hint: "The " + Theme.current.name + " theme puts it at the " + Theme.barStyle.edge
            ConfigChoice { section: "bar"; key: "position"; values: ["theme", "top", "bottom", "left", "right"]; labels: ["Theme's", "Top", "Bottom", "Left", "Right"] }
        }
        SettingRow {
            label: "Size"
            hint: Theme.barSize + " px across" + (page.b.size === 0 ? " (the theme's)" : "")
            ConfigChoice { section: "bar"; key: "size"; values: [0, 26, 34, 44, 56]; labels: ["Theme's", "Slim", "Regular", "Tall", "Huge"] }
        }
        SettingRow {
            label: "Shape"
            hint: "Floating keeps a gap to the screen edges"
            ConfigChoice { section: "bar"; key: "floating"; values: ["theme", "floating", "attached"]; labels: ["Theme's", "Floating", "Attached"] }
        }
        SettingRow {
            visible: Theme.barFloating
            label: "Gap"
            hint: "Around the floating bar"
            ConfigSlider { section: "bar"; key: "margin"; from: 0; to: 40; step: 1; format: v => v + " px" }
        }
    }

    SettingGroup {
        title: "Monitors"
        Repeater {
            model: Quickshell.screens
            SettingRow {
                required property var modelData
                label: modelData.name
                hint: modelData.width + " × " + modelData.height + (modelData.model ? " · " + modelData.model : "")
                Toggle {
                    checked: !page.b.hiddenOn.includes(modelData.name)
                    onToggled: on => Config.set("bar", "hiddenOn", on ? page.b.hiddenOn.filter(n => n !== modelData.name)
                                                                        : Array.from(page.b.hiddenOn).concat([modelData.name]))
                }
            }
        }
    }

    // ---- items: three lists, each item can move up / down, to another section, or go -------------------
    Repeater {
        model: page.sections
        SettingGroup {
            id: group
            required property var modelData
            readonly property var ids: Array.from(page.layout[modelData.key])
            title: modelData.name + (page.b.custom ? "" : " · the theme's")

            Text {
                visible: group.ids.length === 0
                Layout.fillWidth: true
                leftPadding: Theme.spaceM; topPadding: Theme.spaceS; bottomPadding: Theme.spaceS
                text: "Empty"
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontLabel }
            }
            Repeater {
                model: group.ids
                SettingRow {
                    id: row
                    required property string modelData
                    required property int index
                    readonly property var info: Themes.barItem(modelData)
                    label: info.name
                    Row {
                        spacing: 4
                        Text {   // the item's icon, so the list reads like the bar
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            text: row.info.glyph
                            color: Theme.subtext
                            font { family: Theme.iconFont; pixelSize: Theme.iconSmall }
                        }
                        ArrowButton { glyph: page.vertical ? "\u{F0143}" : "\u{F0141}"; tip: "Earlier"; small: true; opacity: row.index > 0 ? 1 : 0.3
                                      onClicked: page.move(group.modelData.key, row.index, -1) }
                        ArrowButton { glyph: page.vertical ? "\u{F0140}" : "\u{F0142}"; tip: "Later"; small: true; opacity: row.index < group.ids.length - 1 ? 1 : 0.3
                                      onClicked: page.move(group.modelData.key, row.index, 1) }
                        Repeater {   // to the other two sections
                            model: page.sections.filter(s => s.key !== group.modelData.key)
                            PillButton {
                                required property var modelData
                                text: "To " + modelData.name.toLowerCase()
                                onClicked: page.moveTo(group.modelData.key, row.index, modelData.key)
                            }
                        }
                        ArrowButton { glyph: "\u{F0156}"; tip: "Remove"; small: true; onClicked: page.remove(group.modelData.key, row.index) }
                    }
                }
            }
            SettingRow {
                visible: page.unused.length > 0
                label: "Add an item"
                Dropdown {
                    width: 220
                    options: page.unused.map(it => it.name)
                    current: "Choose an item"
                    onPicked: name => { const it = page.unused.find(x => x.name === name); if (it) page.add(group.modelData.key, it.id) }
                }
            }
        }
    }

    SettingGroup {
        title: "Clock"
        SettingRow {
            label: "24-hour time"
            hint: Config.bar.clock24 ? "14:40" : "2:40 PM"
            ConfigToggle { section: "bar"; key: "clock24" }
        }
        SettingRow {
            label: "Show seconds"
            ConfigToggle { section: "bar"; key: "seconds" }
        }
        SettingRow {
            label: "Date"
            hint: "Beside the time, where there's room"
            ConfigChoice { section: "bar"; key: "date"; values: ["full", "short", "none"]; labels: ["Fri 30 Oct", "30 Oct", "None"] }
        }
        SettingRow {
            label: "Window title"
            hint: "After the app's name in the Active window item"
            ConfigToggle { section: "bar"; key: "windowTitle" }
        }
    }

    // Reset: the theme's place, shape and items again (and the clock's defaults)
    ResetGroup { sections: ["bar"] }
}
