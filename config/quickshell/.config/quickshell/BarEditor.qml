import QtQuick
import QtQuick.Layouts

// The menu bar's items, edited by hand: a copy of the bar in the theme's own colours with its three
// sections side by side. Drag an item to another place in the bar, drag one in from the tray of unused
// items below (or click it), drag one back to the tray (or press its ×) to take it off. Every change saves at
// once and the real bar follows. By default it edits the one layout every screen and theme shares (Theme.setLayout);
// with `screen` set it edits that screen's own list (Config.bar.monitors). "Apps" is the dock itself: adding it
// puts the dock in the bar; it leaves the bar only by moving the dock (Settings > Dock).
ColumnLayout {
    id: ed
    spacing: 14

    property Item floatOn                         // where a carried item floats (the Settings page's parent)
    property string selected                      // the item whose settings the page shows; a click on the bar picks it
    property string screen                        // "" = every screen; a screen's name = that screen's own list
    readonly property var own: screen !== "" ? Config.bar.monitors?.[screen] : undefined
    readonly property bool onScreen: own !== undefined && own !== null && typeof own === "object"
    readonly property var layout: onScreen ? { start: Array.from(own.start ?? []), center: Array.from(own.center ?? []), end: Array.from(own.end ?? []) }
                                           : Theme.barLayout
    readonly property var keys: ["start", "center", "end"]
    readonly property var names: ({ start: Theme.barVertical ? "Top" : "Left", center: "Middle", end: Theme.barVertical ? "Bottom" : "Right" })
    readonly property var used: [].concat(Array.from(layout.start), Array.from(layout.center), Array.from(layout.end))
    readonly property var unused: Themes.barItems.filter(it => !used.includes(it.id))
    // the tray, one group per category that still has unused items (an item's category is in its defaults.json)
    readonly property var unusedGroups: BarItems.categories.concat(unused.map(it => it.category).filter(c => !BarItems.categories.includes(c)))
        .map(c => ({ name: c, items: unused.filter(it => it.category === c) })).filter(g => g.items.length)
    // the bar's own look, so the copy reads like the real one
    readonly property color ground: ({ glass: Theme.glassStrong, surface: Theme.surfaceColor, ground: Theme.base, ink: Theme.text, none: Theme.base })[Theme.barStyle.fill] ?? Theme.surfaceColor
    readonly property color ink: Theme.barInk

    function lists() {
        return { start: Array.from(layout.start), center: Array.from(layout.center), end: Array.from(layout.end) }
    }
    // extra: geometry that goes with the change (the dock into the bar); it is global even on a screen's own list
    function save(l, extra) {
        if (!onScreen) { Theme.setLayout(Object.assign({}, l, extra ?? {})); return }
        const all = JSON.parse(JSON.stringify(Config.bar.monitors ?? {})); all[screen] = l
        Config.set("bar", "monitors", all)
        if (extra) Theme.setLayout(extra)
    }
    // payload: { id, from: section key or "tray" }; drop it into `section` at `index` (-1: the end)
    function drop(p, section, index) {
        if (p.id === "apps" && section === "tray") return   // the dock: moved on the Dock page
        const l = lists()
        if (p.from !== "tray") {
            const at = l[p.from].indexOf(p.id)
            if (at < 0) return
            l[p.from].splice(at, 1)
            if (p.from === section && index > at) index--
        }
        if (section === "tray") { save(l); return }
        if (index < 0 || index > l[section].length) index = l[section].length
        l[section].splice(index, 0, p.id)
        save(l, p.id === "apps" && !Theme.dockInBar ? { dock: "bar" } : undefined)
    }

    // ---- the bar ------------------------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: zones.implicitHeight + 16   // grows as a section's items wrap to more rows
        radius: Theme.barFloating ? Math.min(Theme.radiusLarge, 22) : Theme.radiusSmall
        color: ed.ground
        border { color: Theme.stroke; width: Math.max(1, Theme.line) }

        RowLayout {
            id: zones
            anchors { fill: parent; margins: 8 }
            spacing: 8
            Repeater {
                model: ed.keys
                Zone {
                    required property string modelData
                    section: modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 40 + ed.layout[modelData].length * 64   // a busy zone gets more room, an empty one little
                    Layout.fillHeight: true
                }
            }
        }
    }
    Text {
        Layout.fillWidth: true
        text: "Drag items to move them; drop one on the tray to take it off. Click one for its settings.\n"
              + (ed.onScreen ? "Editing the bar on " + ed.screen + " only."
                 : "Editing the bar on every screen" + (Theme.hasLayout ? ", in every theme." : ": for now it is " + Theme.current.name + "'s own, your first change makes it yours."))
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    // ---- the tray of unused items ------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Math.max(56, tray.implicitHeight + 24)
        radius: Theme.radius
        color: trayDrop.active ? Theme.accentWash : Theme.fill
        border { color: trayDrop.active ? Theme.accent : Theme.stroke; width: 1 }
        DropSpot { id: trayDrop; anchors.fill: parent; key: "baritem"; mode: "fill"; onPlaced: p => ed.drop(p, "tray", -1) }
        Text {
            visible: ed.unused.length === 0
            anchors.centerIn: parent
            text: "Every item is on the bar"
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        Column {
            id: tray
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 12
            Repeater {
                model: ed.unusedGroups
                Column {
                    id: group
                    required property var modelData
                    width: tray.width
                    spacing: 6
                    Text {
                        text: group.modelData.name
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                    }
                    Flow {
                        width: group.width
                        spacing: 6
                        Repeater {
                            model: group.modelData.items
                            Chip {
                                required property var modelData
                                itemId: modelData.id
                                from: "tray"
                                onBar: false
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- pieces ------------------------------------------------------------------------------------
    // one section of the bar: a drop area that takes items at its end, with its items in order
    component Zone: Rectangle {
        id: zone
        property string section
        readonly property var ids: Array.from(ed.layout[section])
        radius: Math.max(0, Theme.radiusSmall - 2)
        color: zoneDrop.active ? Qt.alpha(Theme.accent, 0.18) : Qt.alpha(ed.ink, 0.05)
        border { color: zoneDrop.active ? Theme.accent : Qt.alpha(ed.ink, 0.16); width: 1 }
        implicitHeight: Math.max(56, flow.implicitHeight + 24)
        DropSpot { id: zoneDrop; anchors.fill: parent; key: "baritem"; mode: "fill"; onPlaced: p => ed.drop(p, zone.section, -1) }
        Text {
            anchors { left: parent.left; top: parent.top; leftMargin: 6; topMargin: 2 }
            text: ed.names[zone.section]
            color: Qt.alpha(ed.ink, 0.55)
            font { family: Theme.font; pixelSize: Theme.fontCaption - 1 }
        }
        Flow {   // many items wrap to more rows and the zone grows, so every item stays in view
            id: flow
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 18; leftMargin: 6; rightMargin: 6 }
            spacing: 4
            Repeater {
                model: zone.ids
                Chip {
                    required property string modelData
                    required property int index
                    itemId: modelData
                    from: zone.section
                    onDroppedHere: (p, after) => ed.drop(p, zone.section, index + (after ? 1 : 0))
                }
            }
        }
    }

    // one item: its icon and short name; carried by the mouse, a drop target for "before / after" itself
    component Chip: DragItem {
        id: chip
        property string itemId
        property string from
        property bool onBar: true
        readonly property var info: Themes.barItem(itemId)
        signal droppedHere(var p, bool after)
        key: "baritem"
        payload: ({ id: itemId, from: from })
        floatOn: ed.floatOn
        // on the bar: the icon with its short name under it; in the tray: icon and name side by side
        width: onBar ? 60 : label.implicitWidth + 40
        height: onBar ? 46 : 30
        radius: Theme.radiusSmall

        Rectangle {
            anchors.fill: parent
            radius: chip.radius
            color: chip.onBar ? Qt.alpha(ed.ink, chip.hovered ? 0.16 : 0.09) : (chip.hovered ? Theme.fillHover : Theme.raised)
            border { color: chip.onBar && chip.itemId === ed.selected ? Theme.accent : chip.onBar ? Qt.alpha(ed.ink, 0.2) : Theme.stroke; width: chip.onBar && chip.itemId === ed.selected ? 2 : 1 }
            Text {   // on the bar the name sits under the icon, so cpu and memory can be told apart
                visible: chip.onBar
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: 4; leftMargin: 2; rightMargin: 2 }
                horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                text: chip.info.name; color: Qt.alpha(ed.ink, 0.75)
                font { family: Theme.font; pixelSize: Theme.fontCaption - 2 }
            }
            Row {
                anchors { left: chip.onBar ? undefined : parent.left; horizontalCenter: chip.onBar ? parent.horizontalCenter : undefined; top: chip.onBar ? parent.top : undefined; topMargin: 6; leftMargin: 8; verticalCenter: chip.onBar ? undefined : parent.verticalCenter }
                spacing: 6
                Text { anchors.verticalCenter: parent.verticalCenter; text: chip.info.glyph; color: chip.onBar ? ed.ink : Theme.text; font { family: Theme.iconFont; pixelSize: 14 } }
                Text { id: label; visible: !chip.onBar; anchors.verticalCenter: parent.verticalCenter; text: chip.info.name; color: chip.onBar ? ed.ink : Theme.text
                       font { family: Theme.font; pixelSize: Theme.fontCaption + 1; weight: Font.Medium } }
            }
            ToolTipText { shown: chip.onBar && chip.hovered && !chip.dragging; text: chip.info.name }
            Rectangle {   // take it off the bar without dragging: a small badge in the corner
                visible: chip.onBar && chip.hovered && !chip.dragging && chip.itemId !== "apps"
                anchors { right: parent.right; top: parent.top; margins: -5 }
                width: 16; height: 16; radius: 8
                color: Theme.error
                Text { anchors.centerIn: parent; text: "\u{F0156}"; color: Theme.errorText; font { family: Theme.iconFont; pixelSize: 10 } }
                MouseArea { anchors { fill: parent; margins: -3 } Accessible.role: Accessible.Button; Accessible.name: "Take off the bar"; cursorShape: Qt.PointingHandCursor; onClicked: ed.drop({ id: chip.itemId, from: chip.from }, "tray", -1) }
            }
        }
        // on the tray a click adds it to the end of the bar's last section
        onClicked: if (onBar) ed.selected = itemId; else ed.drop({ id: itemId, from: "tray" }, "end", -1)
        DropSpot { anchors.fill: parent; key: "baritem"; owner: chip; enabled: chip.onBar && !chip.dragging; onPlaced: (p, after) => chip.droppedHere(p, after) }
    }
}
