import QtQuick
import QtQuick.Layouts

// The menu bar's items, edited by hand: a small copy of the bar in its own colours, and under it the bar's
// three sections as lists. Drag an item to another place, drag one in from "Add to the bar" (or click it), drag
// one back there (or press its ×) to take it off, or its eye to hide it in place; by keyboard, Alt+arrows move the focused item and Delete takes
// it off. Every change saves at once and the real bar follows. By default it edits the one layout every screen
// and theme shares (Theme.setLayout); with `screen` set it edits that screen's own list (Config.bar.monitors).
// "Apps" is the dock itself: adding it puts the dock in the bar; it leaves the bar only by moving the dock
// (Settings > Dock). Every other item can be added again and again: each copy is an instance with settings of its
// own ("clock", "clock#2", BarItems.newId); a copy's settings go when it leaves the last list it was on.
ColumnLayout {
    id: ed
    spacing: 10

    property Item floatOn                         // where a carried item floats (the Settings page's parent)
    property string selected                      // the item whose settings the page shows; a click on the bar picks it
    property string screen                        // "" = every screen; a screen's name = that screen's own list
    property string focusId                       // after a keyboard move the rebuilt item takes the focus back
    readonly property var own: screen !== "" ? Config.bar.monitors?.[screen] : undefined
    readonly property bool onScreen: own !== undefined && own !== null && typeof own === "object"
    readonly property var layout: onScreen ? { start: Array.from(own.start ?? []), center: Array.from(own.center ?? []), end: Array.from(own.end ?? []) }
                                           : Theme.barLayout
    readonly property var keys: ["start", "center", "end"]
    readonly property var names: ({ start: Theme.barVertical ? "Top" : "Left", center: "Middle", end: Theme.barVertical ? "Bottom" : "Right" })
    readonly property var used: [].concat(Array.from(layout.start), Array.from(layout.center), Array.from(layout.end))
    // the item the settings below are for: the pick, or the bar's first item
    readonly property string current: used.includes(selected) ? selected : (used[0] ?? "")
    // "Add to the bar": every item, always (one already on the bar is added as a new copy); the dock only once
    readonly property var unused: Themes.barItems.filter(it => it.id !== "apps" || !used.includes("apps"))
    // the tray, one group per category that still has unused items (an item's category is in its defaults.json)
    readonly property var unusedGroups: BarItems.categories.concat(unused.map(it => it.category).filter(c => !BarItems.categories.includes(c)))
        .map(c => ({ name: c, items: unused.filter(it => it.category === c) })).filter(g => g.items.length)
    // the bar's own look, so the copy reads like the real one
    readonly property color ground: ({ glass: Theme.glassStrong, surface: Theme.surfaceColor, ground: Theme.base, ink: Theme.text, none: Theme.base })[Theme.barStyle.fill] ?? Theme.surfaceColor
    readonly property color ink: Theme.barInk
    readonly property int rowHeight: Math.max(34, Theme.hit)

    function lists() {
        return { start: Array.from(layout.start), center: Array.from(layout.center), end: Array.from(layout.end) }
    }
    // every id on any list (the shared one and each screen's own): a new copy takes none of them
    function taken() {
        const all = [].concat(Array.from(Theme.barLayout.start), Array.from(Theme.barLayout.center), Array.from(Theme.barLayout.end))
        for (const m of Object.values(Config.bar.monitors ?? {}))
            if (m && typeof m === "object") for (const k of keys) all.push(...Array.from(m[k] ?? []))
        return all
    }
    // the id an item from the tray gets on this list
    function fresh(id) { return BarItems.newId(id, used, taken()) }
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
        if (p.from === "tray") p = { id: fresh(p.id), from: "tray" }
        else {
            const at = l[p.from].indexOf(p.id)
            if (at < 0) return
            l[p.from].splice(at, 1)
            if (p.from === section && index > at) index--
        }
        if (section === "tray") {
            save(l)
            if (p.id.includes("#") && !taken().includes(p.id) && Config.bar.items?.[p.id] !== undefined) {   // a copy gone for good
                const all = JSON.parse(JSON.stringify(Config.bar.items)); delete all[p.id]
                Config.set("bar", "items", all)
            }
            return
        }
        if (index < 0 || index > l[section].length) index = l[section].length
        l[section].splice(index, 0, p.id)
        save(l, p.id === "apps" && !Theme.dockInBar ? { dock: "bar" } : undefined)
    }
    // keyboard: one step up or down its section, or to the end / start of the section beside it
    function step(id, from, d) {
        const at = layout[from].indexOf(id)
        focusId = id
        if (at + d >= 0 && at + d < layout[from].length) drop({ id: id, from: from }, from, at + d + (d > 0 ? 1 : 0))
    }
    function hop(id, from, d) {
        const to = keys[keys.indexOf(from) + d]
        if (!to) return
        focusId = id
        drop({ id: id, from: from }, to, d > 0 ? 0 : -1)
    }

    // ---- a small copy of the bar: where each item sits, the picked one marked ------------------------
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 34
        radius: Theme.barFloating ? Math.min(Theme.radiusLarge, 17) : Theme.radiusSmall
        color: ed.ground
        border { color: Theme.stroke; width: 1 }
        clip: true
        Accessible.ignored: true
        Repeater {
            model: ed.keys
            Row {
                required property string modelData
                anchors.verticalCenter: parent.verticalCenter
                x: modelData === "start" ? 12 : modelData === "center" ? (parent.width - width) / 2 : parent.width - width - 12
                spacing: 2
                Repeater {
                    model: ed.layout[parent.modelData]
                    Item {
                        required property string modelData
                        readonly property bool picked: modelData === ed.current
                        width: 24; height: 26
                        Text {
                            anchors.centerIn: parent
                            text: BarItems.info(parent.modelData).glyph
                            color: parent.picked ? Theme.accent : Qt.alpha(ed.ink, 0.8)
                            font { family: Theme.iconFont; pixelSize: Theme.glyphS }
                        }
                        Rectangle {
                            visible: parent.picked
                            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                            width: 14; height: 2; radius: 1
                            color: Theme.accent
                        }
                    }
                }
            }
        }
    }

    // ---- the three sections, side by side and equally wide ------------------------------------------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Repeater {
            model: ed.keys
            Zone {
                required property string modelData
                section: modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1      // equal shares: never sized by the items inside
                Layout.fillHeight: true
            }
        }
    }
    Text {
        Layout.fillWidth: true
        text: "Drag to arrange; the eye hides an item but keeps its place. Keyboard: Alt+arrows move, H hides, Delete takes it off."
              + (ed.onScreen ? " Editing " + ed.screen + " only."
                 : Theme.hasLayout ? "" : " This is " + Theme.current.name + "'s own bar until your first change.")
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    // ---- the items not on the bar ------------------------------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: tray.implicitHeight + 24
        radius: Theme.radius
        color: trayDrop.active ? Theme.accentWash : "transparent"
        border { color: Theme.accent; width: trayDrop.active ? 1 : 0 }
        Rectangle { visible: !trayDrop.active; anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Theme.stroke }
        DropSpot { id: trayDrop; anchors.fill: parent; key: "baritem"; mode: "fill"; onPlaced: p => ed.drop(p, "tray", -1) }
        Column {
            id: tray
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 10
            Text {
                width: tray.width
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                text: "<b>Add to the bar</b>&nbsp;&nbsp;<font color='" + Theme.subtext + "'>"
                      + "Click one to add it at the end, or drag it into place. One already on the bar is added again, with its own settings" + "</font>"
                color: Theme.text
                font { family: Theme.font; pixelSize: Theme.fontLabel }
            }
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
                        font { family: Theme.font; pixelSize: Theme.fontCaption }
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
    // one section of the bar: its name, its items top to bottom, and a drop area that takes items at its end
    component Zone: Rectangle {
        id: zone
        property string section
        readonly property var ids: Array.from(ed.layout[section])
        radius: Theme.radiusSmall
        color: zoneDrop.active ? Theme.accentWash : Theme.fill
        border { color: Theme.accent; width: zoneDrop.active ? 1 : 0 }
        implicitWidth: 0
        implicitHeight: list.y + Math.max(list.implicitHeight, ed.rowHeight * 2) + 8
        DropSpot { id: zoneDrop; anchors.fill: parent; key: "baritem"; mode: "fill"; onPlaced: p => ed.drop(p, zone.section, -1) }
        Text {
            id: head
            anchors { left: parent.left; top: parent.top; leftMargin: 10; topMargin: 8 }
            text: ed.names[zone.section]
            color: Theme.text
            font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
        }
        Text {
            anchors { right: parent.right; rightMargin: 10; baseline: head.baseline }
            visible: zone.ids.length > 0
            text: zone.ids.length
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption; features: { "tnum": 1 } }
        }
        Text {   // an empty section: where it is and how it fills
            visible: zone.ids.length === 0
            anchors { left: parent.left; right: parent.right; top: list.top; margins: 8 }
            height: ed.rowHeight * 2
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            text: "Empty\nDrag an item here"
            lineHeight: 1.2
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontCaption }
        }
        Column {
            id: list
            anchors { left: parent.left; right: parent.right; top: head.bottom; margins: 6; topMargin: 8 }
            spacing: 4
            Repeater {
                model: zone.ids
                Chip {
                    required property string modelData
                    required property int index
                    width: list.width
                    itemId: modelData
                    from: zone.section
                    onDroppedHere: (p, after) => ed.drop(p, zone.section, index + (after ? 1 : 0))
                }
            }
        }
    }

    // hidden: still in its place on the bar, but the bar leaves it out (bar.items[id].enabled = false)
    function isHidden(id) { return Config.bar.items?.[id]?.enabled === false }
    function setHidden(id, hide) {
        const all = JSON.parse(JSON.stringify(Config.bar.items ?? {})), o = all[id] ?? {}
        if (hide) o.enabled = false; else delete o.enabled
        if (Object.keys(o).length) all[id] = o; else delete all[id]
        Config.set("bar", "items", all)
    }

    // one item: on the bar a full-width row (handle, icon, name, eye, ×); in the tray a pill with a +
    component Chip: DragItem {
        id: chip
        property string itemId
        property string from
        property bool onBar: true
        readonly property var info: BarItems.info(itemId)
        readonly property bool picked: onBar && itemId === ed.current
        readonly property bool removable: onBar && itemId !== "apps"
        readonly property bool hiddenItem: onBar && ed.isHidden(itemId)
        // the row's hover from a handler: the buttons' own MouseAreas can't take it away (a MouseArea hover did,
        // so the × hid itself as the pointer reached it, then came back: a flicker)
        readonly property bool over: rowHover.hovered
        readonly property bool showButtons: onBar && (over || picked || activeFocus === true)
        HoverHandler { id: rowHover }
        signal droppedHere(var p, bool after)
        key: "baritem"
        payload: ({ id: itemId, from: from })
        floatOn: ed.floatOn
        width: onBar ? 120 : pill.implicitWidth + 24
        height: onBar ? ed.rowHeight : Math.max(30, Theme.hit)
        radius: onBar ? Math.max(0, Theme.radiusSmall - 2) : Theme.radiusSmall

        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: onBar ? info.name + ", " + ed.names[from] + (picked ? ", selected" : "") : "Add " + info.name
        Accessible.onPressAction: chip.clicked()
        onActiveFocusChanged: if (activeFocus && onBar) ed.selected = itemId
        Component.onCompleted: if (onBar && itemId === ed.focusId) { forceActiveFocus(); ed.focusId = "" }
        Keys.onPressed: e => {
            const alt = e.modifiers & Qt.AltModifier
            if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) chip.clicked()
            else if (!onBar) return
            else if ((e.key === Qt.Key_Delete || e.key === Qt.Key_Backspace) && removable) {
                const l = ed.layout[from], at = l.indexOf(itemId)   // the focus moves on to its neighbour
                ed.focusId = l[at + 1] ?? l[at - 1] ?? ""
                ed.drop({ id: itemId, from: from }, "tray", -1)
            }
            else if (e.key === Qt.Key_H && !alt) ed.setHidden(itemId, !hiddenItem)
            else if (alt && e.key === Qt.Key_Up) ed.step(itemId, from, -1)
            else if (alt && e.key === Qt.Key_Down) ed.step(itemId, from, 1)
            else if (alt && e.key === Qt.Key_Left) ed.hop(itemId, from, -1)
            else if (alt && e.key === Qt.Key_Right) ed.hop(itemId, from, 1)
            else if (e.key === Qt.Key_Down) chip.nextItemInFocusChain(true).forceActiveFocus()
            else if (e.key === Qt.Key_Up) chip.nextItemInFocusChain(false).forceActiveFocus()
            else return
            e.accepted = true
        }

        Rectangle {
            anchors.fill: parent
            radius: chip.radius
            color: chip.picked ? Theme.accentWash : chip.over ? Theme.fillHover : chip.onBar ? Theme.raised : "transparent"
            border { color: chip.picked ? Theme.accent : Theme.stroke; width: chip.picked ? 2 : 1 }
            Rectangle {   // keyboard focus
                anchors { fill: parent; margins: -3 }
                visible: chip.activeFocus === true   // undefined while a rebuilt row is torn down
                radius: chip.radius > 0 ? chip.radius + 3 : 0
                color: "transparent"
                border { color: Theme.accent; width: 2 }
            }

            // on the bar
            Text {   // the handle: it can be picked up
                id: handle
                visible: chip.onBar
                anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
                text: "\u{F01DD}"
                color: Qt.alpha(Theme.text, chip.over ? 0.5 : 0.28)
                font { family: Theme.iconFont; pixelSize: Theme.glyphS }
            }
            Text {
                id: glyph
                visible: chip.onBar
                anchors { left: handle.right; leftMargin: 4; verticalCenter: parent.verticalCenter }
                width: 18
                horizontalAlignment: Text.AlignHCenter
                text: chip.info.glyph
                color: chip.picked ? Theme.accent : Theme.text
                opacity: chip.hiddenItem ? 0.4 : 1
                font { family: Theme.iconFont; pixelSize: Theme.glyphS }
            }
            Text {
                visible: chip.onBar
                anchors { left: glyph.right; leftMargin: 8; right: eye.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
                elide: Text.ElideRight
                text: chip.info.name + (chip.hiddenItem ? " · hidden" : "")
                color: chip.hiddenItem ? Theme.subtext : Theme.text
                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: chip.picked ? Font.DemiBold : Font.Normal }
            }
            Rectangle {   // hide it without taking it off: it keeps its place and settings (shown while hidden, so you can bring it back)
                id: eye
                visible: chip.onBar
                anchors { right: chip.removable ? cross.left : parent.right; rightMargin: chip.removable ? 2 : 4; verticalCenter: parent.verticalCenter }
                width: 24; height: 24; radius: Math.min(12, Theme.radiusSmall)
                color: eyeArea.containsMouse ? Theme.fillHover : "transparent"
                opacity: chip.showButtons || chip.hiddenItem ? 1 : 0
                Text {
                    anchors.centerIn: parent
                    text: chip.hiddenItem ? "\u{F0209}" : "\u{F0208}"   // eye-off / eye
                    color: eyeArea.containsMouse || chip.hiddenItem ? Theme.text : Theme.subtext
                    font { family: Theme.iconFont; pixelSize: Theme.glyphS }
                }
                MouseArea {
                    id: eyeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: (chip.hiddenItem ? "Show " : "Hide ") + chip.info.name
                    onClicked: ed.setHidden(chip.itemId, !chip.hiddenItem)
                }
                ToolTipText { shown: eyeArea.containsMouse; text: chip.hiddenItem ? "Show it on the bar" : "Hide it (keeps its place)" }
            }
            Rectangle {   // take it off the bar without dragging
                id: cross
                visible: chip.removable
                anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
                width: 24; height: 24; radius: Math.min(12, Theme.radiusSmall)
                color: crossArea.containsMouse ? Qt.alpha(Theme.error, 0.18) : "transparent"
                opacity: chip.showButtons ? 1 : 0
                Text {
                    anchors.centerIn: parent
                    text: "\u{F0156}"
                    color: crossArea.containsMouse ? Theme.error : Theme.subtext
                    font { family: Theme.iconFont; pixelSize: Theme.glyphS }
                }
                MouseArea {
                    id: crossArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    Accessible.role: Accessible.Button
                    Accessible.name: "Take " + chip.info.name + " off the bar"
                    onClicked: ed.drop({ id: chip.itemId, from: chip.from }, "tray", -1)
                }
            }

            // in the tray
            Row {
                id: pill
                visible: !chip.onBar
                anchors.centerIn: parent
                spacing: 6
                Text { anchors.verticalCenter: parent.verticalCenter; text: "\u{F0415}"; color: Theme.accent; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
                Text { anchors.verticalCenter: parent.verticalCenter; text: chip.info.glyph; color: Theme.text; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
                Text { anchors.verticalCenter: parent.verticalCenter; text: chip.info.name; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel } }
            }
        }
        // on the bar a click picks it for its settings; in the tray it adds it to the end of the bar's last section
        onClicked: {
            const id = onBar ? itemId : ed.fresh(itemId)
            if (!onBar) { ed.focusId = activeFocus ? id : ""; ed.drop({ id: itemId, from: "tray" }, "end", -1) }
            ed.selected = id
        }
        DropSpot { anchors.fill: parent; key: "baritem"; owner: chip; vertical: true; enabled: chip.onBar && !chip.dragging; onPlaced: (p, after) => chip.droppedHere(p, after) }
    }
}
