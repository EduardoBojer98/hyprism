import QtQuick
import QtQuick.Layouts

// The menu bar's items, edited by hand: a copy of the bar in the theme's own colours with its three
// sections side by side. Drag an item to another place in the bar, drag one in from the tray of unused
// items below, drag one back to the tray (or press its ×) to take it off. Every change saves at once, for
// the active theme only (Themes.adjust "barItems"), and the real bar follows. "Apps" is the dock itself:
// adding it puts the dock in the bar; it leaves the bar only by moving the dock (Settings > Dock).
ColumnLayout {
    id: ed
    spacing: 14

    property Item floatOn                         // where a carried item floats (the Settings page's parent)
    readonly property var layout: Theme.barLayout
    readonly property var keys: ["start", "center", "end"]
    readonly property var names: ({ start: Theme.barVertical ? "Top" : "Left", center: "Middle", end: Theme.barVertical ? "Bottom" : "Right" })
    readonly property var used: [].concat(Array.from(layout.start), Array.from(layout.center), Array.from(layout.end))
    readonly property var unused: Themes.barItems.filter(it => !used.includes(it.id))
    // the bar's own look, so the copy reads like the real one
    readonly property color ground: ({ glass: Theme.glassStrong, surface: Theme.surfaceColor, ground: Theme.base, ink: Theme.text, none: Theme.base })[Theme.barStyle.fill] ?? Theme.surfaceColor
    readonly property color ink: Theme.barInk

    function lists() {
        return { start: Array.from(layout.start), center: Array.from(layout.center), end: Array.from(layout.end) }
    }
    readonly property bool edited: ((Config.appearance.custom ?? {})[Config.appearance.theme] ?? {}).barItems !== undefined
    function save(l) { Themes.adjust("barItems", l) }
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
        save(l)
        if (p.id === "apps" && !Theme.dockInBar) Themes.adjust("dock", "bar")
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
                    Layout.preferredWidth: modelData === "center" ? 2 : 3
                    Layout.fillHeight: true
                }
            }
        }
    }
    Text {
        Layout.fillWidth: true
        text: "Drag to move or reorder · drop on the tray to take an item off · Apps is the dock, placed on the Dock page · "
              + (ed.edited ? "your layout for " + Theme.current.name : "the layout " + Theme.current.name + " came with")
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    // ---- the tray of unused items ------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Math.max(56, tray.implicitHeight + 20)
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
        Flow {
            id: tray
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 6
            Repeater {
                model: ed.unused
                Chip {
                    required property var modelData
                    itemId: modelData.id
                    from: "tray"
                    onBar: false
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
        // on the bar: just the icon, like the real bar (its name shows on hover); in the tray: icon and name
        width: onBar ? 34 : label.implicitWidth + 40
        height: onBar ? 34 : 30
        radius: Theme.radiusSmall

        Rectangle {
            anchors.fill: parent
            radius: chip.radius
            color: chip.onBar ? Qt.alpha(ed.ink, chip.hovered ? 0.16 : 0.09) : (chip.hovered ? Theme.fillHover : Theme.raised)
            border { color: chip.onBar ? Qt.alpha(ed.ink, 0.2) : Theme.stroke; width: 1 }
            Row {
                anchors { left: parent.left; leftMargin: chip.onBar ? 10 : 8; verticalCenter: parent.verticalCenter }
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
                Text { anchors.centerIn: parent; text: "\u{F0156}"; color: "white"; font { family: Theme.iconFont; pixelSize: 10 } }
                MouseArea { anchors { fill: parent; margins: -3 } cursorShape: Qt.PointingHandCursor; onClicked: ed.drop({ id: chip.itemId, from: chip.from }, "tray", -1) }
            }
        }
        // on the tray a click adds it to the end of the bar's last section
        onClicked: if (!onBar) ed.drop({ id: itemId, from: "tray" }, "end", -1)
        DropSpot { anchors.fill: parent; key: "baritem"; owner: chip; enabled: chip.onBar && !chip.dragging; onPlaced: (p, after) => chip.droppedHere(p, after) }
    }
}
