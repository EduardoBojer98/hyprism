import QtQuick
import QtQuick.Layouts

// Menu Bar: where each item sits (left, centre, right, or not shown), the clock's format and a few
// details (Config.bar).
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

    // The three zones read as one line with a divider between them, so moving an item past the end
    // of a zone carries it into the next one.
    function move(id, by) {
        const line = Config.bar.left.concat(["|"], Config.bar.center, ["|"], Config.bar.right)
        const i = line.indexOf(id), j = i + by
        if (j < 0 || j >= line.length) return
        line[i] = line[j]; line[j] = id
        save(line)
    }
    function remove(id) { save(Config.bar.left.concat(["|"], Config.bar.center, ["|"], Config.bar.right).filter(x => x !== id)) }
    function add(id) { Config.set("bar", "right", [id].concat(Config.bar.right)) }
    function save(line) {
        const parts = line.join(",").split("|").map(p => p.split(",").filter(x => x))
        Config.set("bar", "left", parts[0]); Config.set("bar", "center", parts[1]); Config.set("bar", "right", parts[2])
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
                        id: zone
                        required property var modelData
                        required property int index
                        readonly property var list: Config.bar[modelData[0]]
                        Layout.preferredWidth: 1   // three equal sides
                        title: modelData[1]
                        empty: list.length === 0 ? "Empty" : ""
                        Repeater {
                            model: zone.list
                            BarChip {
                                required property string modelData
                                required property int index
                                info: page.items[modelData] ?? { label: modelData, glyph: "" }
                                on: true
                                // the bar's first item can't go further left, its last further right
                                first: zone.index === 0 && index === 0
                                last: zone.index === 2 && index === zone.list.length - 1
                                onEarlier: page.move(modelData, -1)
                                onLater: page.move(modelData, 1)
                                onToggle: page.remove(modelData)
                            }
                        }
                    }
                }
            }
            Zone {
                title: "Not shown · click one to add it on the right"
                empty: page.unused.length === 0 ? "Everything is in the bar" : ""
                Repeater {
                    model: page.unused
                    BarChip {
                        required property string modelData
                        info: page.items[modelData]
                        on: false
                        onToggle: page.add(modelData)
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Hover an item for arrows to move it; moving past the end of a side carries it into the next one. Click an item to take it out of the bar."
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
        default property alias items: flow.data
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        implicitHeight: zcol.implicitHeight + 20
        radius: Theme.radius
        color: Theme.fill
        border { color: Theme.stroke; width: 1 }
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

    // One item: in the bar (highlighted, arrows on hover, click to take out) or not (click to add)
    component BarChip: Rectangle {
        id: c
        property var info
        property bool on
        property bool first: false
        property bool last: false
        signal earlier()
        signal later()
        signal toggle()
        width: row.implicitWidth + 16
        height: 32
        radius: Theme.radiusSmall + 2
        color: on ? Theme.accentWash : area.containsMouse ? Theme.fillHover : "transparent"
        border { color: on ? Theme.accent : Theme.stroke; width: 1 }
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 6
            ArrowButton { visible: c.on; small: true; anchors.verticalCenter: parent.verticalCenter; glyph: "\u{F0141}"; tip: "Earlier"; opacity: area.containsMouse || hovered ? (enabled ? 1 : 0.3) : 0; enabled: !c.first; onClicked: c.earlier() }
            Text { anchors.verticalCenter: parent.verticalCenter; text: c.info.glyph; color: c.on ? Theme.text : Theme.muted; font { family: Theme.iconFont; pixelSize: 13 } }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: c.info.label
                color: c.on ? Theme.text : Theme.subtext
                font { family: Theme.font; pixelSize: 12 }
            }
            ArrowButton { visible: c.on; small: true; anchors.verticalCenter: parent.verticalCenter; glyph: "\u{F0142}"; tip: "Later"; opacity: area.containsMouse || hovered ? (enabled ? 1 : 0.3) : 0; enabled: !c.last; onClicked: c.later() }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: -1   // under the arrows
            onClicked: c.toggle()
        }
    }
}
