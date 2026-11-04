import QtQuick
import QtQuick.Layouts

// Menu Bar: its design (a ready-made set of look options, or each option on its own), where each item
// sits (left, centre, right, or not shown), the clock's format and a few details (Config.bar).
// Every design works with any arrangement of items.
ColumnLayout {
    id: page
    spacing: 20

    // every item the bar can show (Bar.qml's widgets)
    readonly property var items: ({
        logo: { label: "System menu", glyph: "\u{F303}" },
        desktops: { label: "Desktops", glyph: "\u{F0570}" },
        app: { label: "App name", glyph: "\u{F05AF}" },
        weather: { label: "Weather", glyph: "\u{F0590}" },
        clock: { label: "Date and time", glyph: "\u{F0150}" },
        media: { label: "Now playing", glyph: "\u{F040A}" },
        tray: { label: "App icons (tray)", glyph: "\u{F0BAC}" },
        netspeed: { label: "Network speed", glyph: "\u{F01DA}" },
        cpu: { label: "CPU use", glyph: "\u{F0EE0}" },
        memory: { label: "Memory", glyph: "\u{F035B}" },
        temperatures: { label: "Temperatures", glyph: "\u{F050F}" },
        keyboard: { label: "Keyboard layout", glyph: "\u{F030C}" },
        status: { label: "Wi-Fi, sound, battery", glyph: "\u{F05A9}" },
        notifications: { label: "Notifications", glyph: "\u{F009C}" }
    })
    readonly property var zones: [["left", "Left"], ["center", "Centre"], ["right", "Right"]]
    readonly property var placed: Config.bar.left.concat(Config.bar.center, Config.bar.right)
    readonly property var unused: Object.keys(items).filter(id => !placed.includes(id))

    // Dragging: put `id` in `zone` ("left", "center", "right"; "" takes it out of the bar), before or
    // after the item `target`, or at the zone's end when there is no target.
    function place(id, zone, target, after) {
        if (id === target) return
        const lists = {}
        for (const z of ["left", "center", "right"]) lists[z] = Array.from(Config.bar[z]).filter(x => x !== id)
        if (zone) {
            const l = lists[zone], i = target ? l.indexOf(target) : -1
            if (i < 0) l.push(id); else l.splice(i + (after ? 1 : 0), 0, id)
        }
        for (const z of ["left", "center", "right"]) Config.set("bar", z, lists[z])
    }
    function remove(id) { place(id, "") }
    function add(id) { Config.set("bar", "right", [id].concat(Config.bar.right)) }

    // ---- design ----------------------------------------------------------------------------------
    readonly property var designs: [
        { id: "classic",  name: "Classic",  about: "A frosted strip across the top",
          set: { style: "strip", position: "top", size: 30, items: "plain", tint: "glass" } },
        { id: "floating", name: "Floating", about: "A glass pill clear of the edges",
          set: { style: "floating", position: "top", size: 32, items: "plain", tint: "glass" } },
        { id: "islands",  name: "Islands",  about: "Each part in its own pill",
          set: { style: "islands", position: "top", size: 32, items: "plain", tint: "glass" } },
        { id: "compact",  name: "Compact",  about: "Everything in one small centred pill",
          set: { style: "compact", position: "top", size: 28, items: "plain", tint: "solid" } },
        { id: "tabs",     name: "Tabs",     about: "Solid tabs hanging from the top edge",
          set: { style: "tabs", position: "top", size: 30, items: "plain", tint: "solid" } },
        { id: "chips",    name: "Chips",    about: "No bar, each item on its own tile",
          set: { style: "clear", position: "top", size: 32, items: "chips", tint: "glass" } },
        { id: "tinted",   name: "Tinted",   about: "Islands washed with the accent colour",
          set: { style: "islands", position: "top", size: 34, items: "chips", tint: "accent" } },
        { id: "bottom",   name: "Bottom",   about: "A floating bar at the bottom, the dock above it",
          set: { style: "floating", position: "bottom", size: 34, items: "plain", tint: "glass" } },
        { id: "neon",     name: "Neon",     about: "A dark pill with a glowing accent edge",
          set: { style: "floating", position: "top", size: 32, items: "plain", tint: "neon" } },
        { id: "neon-line", name: "Neon line", about: "A dark strip with a glowing line along its edge",
          set: { style: "strip", position: "top", size: 30, items: "plain", tint: "neon" } },
        { id: "neon-islands", name: "Neon islands", about: "Each part in its own glowing pill",
          set: { style: "islands", position: "top", size: 32, items: "plain", tint: "neon" } },
        { id: "neon-tabs", name: "Neon tabs", about: "Glowing tabs hanging from the top edge",
          set: { style: "tabs", position: "top", size: 30, items: "plain", tint: "neon" } },
        { id: "neon-dock", name: "Neon bottom", about: "One small glowing pill at the bottom, by the dock",
          set: { style: "compact", position: "bottom", size: 30, items: "plain", tint: "neon" } },
    ]

    SettingGroup {
        title: "Design"
        DesignGallery { id: gallery; section: "bar"; designs: page.designs }
    }

    SettingGroup {
        title: gallery.match ? "Customise" : "Customise · your own mix"
        SettingRow {
            label: "Shape"
            hint: ({ strip: "Edge to edge", floating: "One pill, clear of the edges", islands: "A pill for each side",
                     compact: "One pill only as wide as its items", tabs: "Tabs joined to the screen edge", clear: "No background" })[Config.bar.style]
            ConfigChoice { section: "bar"; key: "style"; values: ["strip", "floating", "islands", "compact", "tabs", "clear"]
                           labels: ["Strip", "Floating", "Islands", "Compact", "Tabs", "Clear"] }
        }
        SettingRow {
            label: "Position"
            hint: Config.bar.position === "bottom" ? "Menus open above it; the dock sits on top of it" : ""
            ConfigChoice { section: "bar"; key: "position"; values: ["top", "bottom"]; labels: ["Top", "Bottom"] }
        }
        SettingRow {
            label: "Height"
            ConfigChoice { section: "bar"; key: "size"; values: [26, 30, 34, 38]; labels: ["Slim", "Normal", "Tall", "Roomy"] }
        }
        SettingRow {
            label: "Items"
            hint: "Chips: each item on its own soft tile"
            ConfigChoice { section: "bar"; key: "items"; values: ["plain", "chips"]; labels: ["Plain", "Chips"] }
        }
        SettingRow {
            label: "Colour"
            ConfigChoice { section: "bar"; key: "tint"; values: ["glass", "solid", "accent", "neon"]; labels: ["Glass", "Solid", "Accent", "Neon"] }
        }
    }

    // ---- the bar, drawn as its three sides, then what's left out ---------------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: layout.implicitHeight + 24
        radius: Theme.radiusLarge + 4
        color: Theme.glassStrong
        border { color: Theme.stroke; width: 1 }

        ColumnLayout {
            id: layout
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: page.zones
                    Zone {
                        id: zoneBox
                        required property var modelData
                        required property int index
                        readonly property var list: Config.bar[modelData[0]]
                        Layout.preferredWidth: 1   // three equal sides
                        title: modelData[1]
                        zone: modelData[0]
                        empty: list.length === 0 ? "Drop items here" : ""
                        Repeater {
                            model: zoneBox.list
                            BarChip {
                                required property string modelData
                                itemId: modelData
                                zone: zoneBox.modelData[0]
                            }
                        }
                    }
                }
            }
            Zone {
                title: "Not shown · drag one into the bar, or click it to add it on the right"
                empty: page.unused.length === 0 ? "Everything is in the bar" : ""
                Repeater {
                    model: page.unused
                    BarChip {
                        required property string modelData
                        itemId: modelData
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Drag items to move them, within a side or to another one. Drop one on Not shown, or click it, to take it out of the bar."
        color: Theme.muted
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
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
            ConfigChoice { section: "bar"; key: "date"; values: ["full", "short", "none"]; labels: ["Fri 30 Oct", "30 Oct", "None"] }
        }
    }

    SettingGroup {
        title: "Details"
        SettingRow {
            label: "Window title"
            hint: "After the app's name"
            ConfigToggle { section: "bar"; key: "windowTitle" }
        }
        SettingRow {
            label: "Battery percentage"
            ConfigToggle { section: "bar"; key: "batteryPercent" }
        }
    }

    ResetGroup { sections: ["bar"] }

    // One side of the bar (or the unused items): a title over its items, which wrap
    component Zone: Rectangle {
        id: z
        property string title
        property string empty
        property string zone: ""    // "" = the items not shown
        default property alias items: flow.data
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        implicitHeight: zcol.implicitHeight + 20
        radius: Theme.radius
        color: Theme.fill
        border { color: Theme.stroke; width: 1 }
        DropSpot { anchors.fill: parent; key: "bar"; mode: "fill"; radius: z.radius; onPlaced: id => page.place(id, z.zone) }
        Column {
            id: zcol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 8
            Text {
                text: z.title
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
            }
            Text {
                visible: z.empty !== ""
                text: z.empty
                color: Theme.muted
                font { family: Theme.font; pixelSize: Theme.fontLabel }
            }
            Flow { id: flow; width: parent.width; spacing: 6 }
        }
    }

    // One item: in the bar (highlighted) or not. Drag it anywhere; click to take it out or add it.
    component BarChip: DragItem {
        id: c
        property string itemId
        property string zone: ""    // "" = not shown
        readonly property bool on: zone !== ""
        readonly property var info: page.items[itemId] ?? { label: itemId, glyph: "" }
        key: "bar"
        payload: itemId
        floatOn: page.parent
        width: row.implicitWidth + 16
        height: 32
        onClicked: on ? page.remove(itemId) : page.add(itemId)
        Rectangle {
            anchors.fill: parent
            radius: c.radius
            color: c.on ? Theme.accentWash : c.hovered ? Theme.fillHover : "transparent"
            border { color: c.on ? Theme.accent : Theme.stroke; width: 1 }
            Row {
                id: row
                anchors.centerIn: parent
                spacing: 6
                Text { anchors.verticalCenter: parent.verticalCenter; text: c.info.glyph; color: c.on ? Theme.text : Theme.muted; font { family: Theme.iconFont; pixelSize: 13 } }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: c.info.label
                    color: c.on ? Theme.text : Theme.subtext
                    font { family: Theme.font; pixelSize: 12 }
                }
            }
        }
        DropSpot { anchors.fill: parent; key: "bar"; owner: c; onPlaced: (id, after) => page.place(id, c.zone, c.zone ? c.itemId : "", after) }
    }
}
