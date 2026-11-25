import QtQuick
import QtQuick.Layouts

// Control Center: arrange it beside a live preview of the panel. Drag sections up and down and switch them off;
// drag a tile between Large and Small to change its size, or within a row to move it; click a tile to show or
// hide it. Saved in Config.controlCenter (sections / tiles / sliders / toggles orders and a hidden list).
ColumnLayout {
    id: page
    spacing: 20

    readonly property var hidden: Config.controlCenter.hidden
    readonly property bool wide: width >= 720
    readonly property PanelState preview: PanelState {}   // the preview's own state: nothing in it opens

    // `id` goes right before or after `target` in `group` (target "": at the end). Large and small tiles share
    // their ids, so a tile dropped on the other group leaves its old one.
    function place(group, id, target, after) {
        if (id === target) return
        const list = ControlCenter.order(group).filter(x => x !== id)
        const i = target === "" ? list.length : list.indexOf(target)
        if (i < 0) return
        list.splice(i + (after ? 1 : 0), 0, id)
        const other = group === "tiles" ? "toggles" : group === "toggles" ? "tiles" : ""
        if (other !== "") Config.set("controlCenter", other, ControlCenter.order(other).filter(x => x !== id))
        Config.set("controlCenter", group, list)
    }
    function setShown(id, on) { Config.set("controlCenter", "hidden", on ? hidden.filter(x => x !== id) : hidden.concat([id])) }
    // a hidden tile you bring back joins the end of the shown ones, where you'll see it
    function add(group, id) { place(group, id, "", false); setShown(id, true) }
    // the page's scroll view, so the preview can stay in sight while you work down a long list
    property Item flick: null
    Component.onCompleted: { let p = parent; while (p && p.contentY === undefined) p = p.parent; flick = p }

    Text {
        Layout.fillWidth: true
        text: "Pick a layout to start from, then make it yours below. The preview is the real panel; changes apply straight away."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontLabel }
    }

    // ---- the gallery: the layouts that ship, the ones you kept, and yours while it matches none ----------
    readonly property var kept: Config.controlCenter.layouts ?? {}
    readonly property var cards: (ControlCenter.activeLayout === "" ? [{ id: "", name: "Yours", about: "Not kept yet: keep it below", layout: Config.controlCenter }] : [])
        .concat(ControlCenter.presets)
        .concat(Object.keys(kept).map(n => ({ id: n, name: n, about: "A layout you kept", layout: kept[n], mine: true })))
    property string keepMessage

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        Text {
            text: "Layouts"
            leftPadding: 4
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
        }
        GridLayout {
            id: gallery
            Layout.fillWidth: true
            columns: Math.min(page.cards.length, Math.max(2, Math.floor((width + columnSpacing) / (100 + columnSpacing))))
            columnSpacing: 12
            rowSpacing: 14
            Repeater {
                model: page.cards
                LayoutCard {}
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: page.keepMessage || (ControlCenter.activeLayout === "" ? "Keep your arrangement to come back to it after trying another" : "Change anything below; a layout you change becomes yours")
                color: page.keepMessage ? Theme.error : Theme.subtext
                wrapMode: Text.Wrap
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
            TextField { id: keepName; Layout.preferredWidth: 150; placeholder: "Layout name"; accessibleName: "Name for this layout"; invalid: page.keepMessage !== ""; onAccepted: keepBtn.clicked() }
            PillButton { id: keepBtn; text: "Keep"; primary: ControlCenter.activeLayout === ""; onClicked: page.keep(keepName.text.trim()) }
        }
    }
    function keep(name) {
        if (name === "" || name.length > 30) { keepMessage = "Give it a name of up to 30 characters."; return }
        if (ControlCenter.presets.some(p => p.name.toLowerCase() === name.toLowerCase())) { keepMessage = "That name is built in."; return }
        keepMessage = ControlCenter.keepLayout(name) ?? ""
        if (!keepMessage) keepName.text = ""
    }

    component LayoutCard: Item {
        id: card
        required property var modelData
        readonly property bool chosen: ControlCenter.activeLayout === modelData.id
        function pick() { if (!chosen) ControlCenter.applyLayout(modelData.layout) }
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        implicitHeight: shot.height + caption.implicitHeight + 10
        activeFocusOnTab: true
        Keys.onReturnPressed: pick()
        Keys.onSpacePressed: pick()
        Accessible.role: Accessible.RadioButton
        Accessible.name: "Layout " + modelData.name
        Accessible.checked: chosen
        Accessible.onPressAction: pick()

        Rectangle {
            id: shot
            width: parent.width
            height: width * 1.3
            radius: Theme.radius
            color: cardArea.containsMouse && !card.chosen ? Theme.fillHover : Theme.fill
            border { color: card.chosen ? Theme.accent : cardArea.containsMouse ? Theme.strokeStrong : Theme.stroke; width: card.chosen ? 2 : 1 }
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
            ControlCenterThumb {
                anchors { fill: parent; margins: 10 }
                snap: ControlCenter.resolve(card.modelData.layout)
            }
            Rectangle {   // the chosen one's check
                visible: card.chosen
                anchors { right: parent.right; top: parent.top; margins: 8 }
                width: 22; height: 22; radius: 11
                color: Theme.accent
                Text { anchors.centerIn: parent; text: "\u{F012C}"; color: Theme.accentText; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
            }
        }
        MouseArea { id: cardArea; anchors.fill: shot; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: card.pick() }
        Rectangle {   // forget a kept layout
            visible: card.modelData.mine === true && (cardArea.containsMouse || forget.containsMouse)
            anchors { left: shot.left; top: shot.top; margins: 8 }
            width: 22; height: 22; radius: 11
            color: forget.containsMouse ? Theme.error : Theme.glassStrong
            border { color: Theme.stroke; width: 1 }
            Text { anchors.centerIn: parent; text: "\u{F0156}"; color: forget.containsMouse ? Theme.accentText : Theme.text; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
            MouseArea { id: forget; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        Accessible.role: Accessible.Button; Accessible.name: "Forget layout " + card.modelData.name
                        onClicked: ControlCenter.forgetLayout(card.modelData.id) }
        }
        Column {
            id: caption
            anchors { left: parent.left; right: parent.right; top: shot.bottom; topMargin: 8 }
            spacing: 2
            Text {
                width: parent.width
                text: card.modelData.name
                elide: Text.ElideRight
                color: card.chosen ? Theme.accent : Theme.text
                font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
            }
            Text {
                width: parent.width
                text: card.modelData.about
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
        }
        FocusRing {}
    }

    Item {   // wide: the editor, the preview beside it; narrow: the preview under it
        Layout.fillWidth: true
        implicitHeight: page.wide ? Math.max(editor.implicitHeight, previewCol.implicitHeight) : editor.implicitHeight + 20 + previewCol.implicitHeight

        // ---- the editor: sections, and the tiles inside them ------------------------------------------
        SettingGroup {
            id: editor
            title: "Layout"
            width: page.wide ? parent.width - previewCol.width - 24 : parent.width

            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 8
                spacing: 6

                Repeater {
                    model: ControlCenter.order("sections")
                    DragItem {
                        id: sec
                        required property string modelData
                        readonly property var inf: ControlCenter.info(modelData)
                        readonly property bool on: !page.hidden.includes(modelData)
                        // large and small tiles take each other's tiles; the Sound card's sliders keep to themselves
                        readonly property string chipKey: inf.group === "sliders" ? "cc-slider" : "cc-tile"
                        Layout.fillWidth: true
                        implicitHeight: secCol.implicitHeight + 20
                        key: "sections"
                        payload: modelData
                        floatOn: page.parent
                        radius: Theme.radiusSmall + 2
                        Rectangle {
                            anchors.fill: parent
                            radius: sec.radius
                            color: sec.hovered ? Theme.fillHover : "transparent"
                            ColumnLayout {
                                id: secCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                                spacing: 8
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Text { text: "\u{F01DD}"; color: Theme.muted; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }   // drag handle
                                    Text { text: sec.inf.glyph; color: sec.on ? Theme.accent : Theme.muted; font { family: Theme.iconFont; pixelSize: Theme.glyph } }
                                    Column {
                                        Layout.fillWidth: true
                                        Text {
                                            width: parent.width
                                            text: sec.inf.label
                                            elide: Text.ElideRight
                                            color: sec.on ? Theme.text : Theme.subtext
                                            font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                                        }
                                        Text {
                                            width: parent.width
                                            text: sec.on ? sec.inf.about ?? "" : "Hidden"
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                            color: Theme.subtext
                                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                                        }
                                    }
                                    Toggle { checked: sec.on; accessibleName: "Show " + sec.inf.label; onToggled: on => page.setShown(sec.modelData, on) }
                                }

                                // its tiles: drag to move (between Large and Small too), click to show or hide
                                Item {
                                    visible: sec.inf.group !== undefined && sec.on
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 26
                                    implicitHeight: Math.max(chips.implicitHeight, 34)
                                    DropSpot {   // the row's end, and an empty row
                                        anchors.fill: parent
                                        key: sec.chipKey
                                        mode: "fill"
                                        onPlaced: id => page.place(sec.inf.group, id, "", false)
                                    }
                                    Text {
                                        visible: chips.count === 0
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Drag a tile here"
                                        color: Theme.muted
                                        font { family: Theme.font; pixelSize: Theme.fontCaption }
                                    }
                                    Flow {
                                        id: chips
                                        readonly property alias count: chipRep.count
                                        width: parent.width
                                        spacing: 6
                                        Repeater {
                                            id: chipRep
                                            model: sec.inf.group ? ControlCenter.order(sec.inf.group).filter(x => !page.hidden.includes(x)).concat(ControlCenter.order(sec.inf.group).filter(x => page.hidden.includes(x))) : []
                                            DragItem {
                                                id: chip
                                                required property string modelData
                                                readonly property var inf: ControlCenter.info(modelData)
                                                readonly property bool on: !page.hidden.includes(modelData)
                                                readonly property bool here: ControlCenter.available(modelData)
                                                width: chipRow.implicitWidth + 18
                                                height: 30
                                                key: sec.chipKey
                                                payload: modelData
                                                floatOn: page.parent
                                                draggable: on   // a hidden tile is added with a click; then it can move
                                                radius: Theme.radius === 0 ? 0 : 15
                                                onClicked: on ? page.setShown(modelData, false) : page.add(sec.inf.group, modelData)
                                                Accessible.role: Accessible.CheckBox
                                                Accessible.name: (on ? "" : "Add ") + inf.label
                                                Accessible.description: on ? "Click to hide, drag to move" : ""
                                                Accessible.checked: on
                                                Accessible.onPressAction: page.setShown(modelData, !on)
                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: chip.radius
                                                    readonly property bool lit: chip.on && chip.here   // shown and has the hardware: it is in the panel
                                                    // shown: a quiet filled chip, its icon in the accent; hidden: an outline to add it back
                                                    color: chip.hovered ? Theme.fillHover : chip.on ? Theme.fill : "transparent"
                                                    border { color: chip.hovered ? Theme.strokeStrong : Theme.stroke; width: 1 }
                                                    Row {
                                                        id: chipRow
                                                        anchors.centerIn: parent
                                                        spacing: 6
                                                        Text { anchors.verticalCenter: parent.verticalCenter; text: chip.on ? chip.inf.glyph : "\u{F0415}"; color: chip.on && chip.here ? Theme.accent : Theme.muted; font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: chip.inf.label
                                                            color: chip.on && chip.here ? Theme.text : Theme.subtext
                                                            font { family: Theme.font; pixelSize: Theme.fontLabel }
                                                        }
                                                        Text {   // shown, but this computer lacks the hardware, so the panel leaves it out
                                                            visible: !chip.here
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: "not here"
                                                            color: Theme.muted
                                                            font { family: Theme.font; pixelSize: Theme.fontCaption }
                                                        }
                                                    }
                                                }
                                                DropSpot { enabled: chip.on && !chip.dragging; anchors.fill: parent; key: chip.key; owner: chip; onPlaced: (id, after) => page.place(sec.inf.group, id, chip.modelData, after) }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        DropSpot { anchors.fill: parent; key: "sections"; vertical: true; owner: sec; onPlaced: (id, after) => page.place("sections", id, sec.modelData, after) }
                    }
                }
            }
        }

        // ---- the preview: the real panel body, drawn here and not clickable --------------------------------
        ColumnLayout {
            id: previewCol
            x: page.wide ? parent.width - width : (parent.width - width) / 2
            // wide: rides down beside the editor as you scroll, never past its end
            readonly property real scrolled: page.flick ? (page.flick.contentY, parent.y, page.y, page.flick.contentY - parent.mapToItem(page.flick.contentItem, 0, 0).y + 16) : 0
            y: page.wide ? Math.max(0, Math.min(scrolled, parent.height - height)) : editor.height + 20
            width: page.wide ? Math.min(ControlCenter.customWidth, page.width * 0.46) : Math.min(ControlCenter.customWidth, page.width)
            spacing: 8
            Text {
                text: "Preview"
                leftPadding: 4
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
            }
            Item {
                id: frame
                readonly property real s: Math.min(1, previewCol.width / ControlCenter.customWidth)
                Layout.fillWidth: true
                implicitHeight: panel.height * s
                Glass {
                    id: panel
                    width: ControlCenter.customWidth
                    height: body.implicitHeight + ControlCenter.pad * 2
                    scale: frame.s
                    transformOrigin: Item.TopLeft
                    strong: true
                    radius: ControlCenter.panelRadius
                    border.width: ControlCenter.style === "borderless" ? 0 : 1
                    ControlCenterBody {
                        id: body
                        host: page.preview
                        enabled: false
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: ControlCenter.pad }
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                text: "Media shows only while something plays. Tiles marked \"not here\" need hardware this computer doesn't have."
                color: Theme.subtext
                wrapMode: Text.Wrap
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
        }
    }

    SettingGroup {
        title: "Look"
        SettingRow {
            label: "Panel style"
            hint: ({ panel: "Tiles on soft fills, the panel's large corners", compact: "Smaller tiles and tighter spacing", borderless: "Flat tiles with hairline edges, no panel border" })[Config.controlCenter.style] ?? ""
        }
        RowLayout {   // each style drawn with your layout in it
            Layout.fillWidth: true
            Layout.margins: 12
            Layout.topMargin: 0
            spacing: 12
            Repeater {
                model: [{ id: "panel", name: "Panel" }, { id: "compact", name: "Compact" }, { id: "borderless", name: "Borderless" }]
                Item {
                    id: st
                    required property var modelData
                    readonly property bool chosen: ControlCenter.style === modelData.id
                    function pick() { Config.set("controlCenter", "style", modelData.id) }
                    Layout.fillWidth: true
                    implicitHeight: stShot.height + 26
                    activeFocusOnTab: true
                    Keys.onReturnPressed: pick()
                    Keys.onSpacePressed: pick()
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: "Panel style " + modelData.name
                    Accessible.checked: chosen
                    Accessible.onPressAction: pick()
                    Rectangle {
                        id: stShot
                        width: parent.width
                        height: Math.min(150, width * 0.75)
                        radius: Theme.radiusSmall + 2
                        color: stArea.containsMouse && !st.chosen ? Theme.fillHover : Theme.fill
                        border { color: st.chosen ? Theme.accent : stArea.containsMouse ? Theme.strokeStrong : Theme.stroke; width: st.chosen ? 2 : 1 }
                        clip: true
                        ControlCenterThumb {   // only the top of the panel: enough to see the corners and spacing
                            x: 14; y: 12
                            width: parent.width - 28
                            height: width * 1.6
                            snap: Object.assign(ControlCenter.current(), { style: st.modelData.id })
                        }
                    }
                    MouseArea { id: stArea; anchors.fill: stShot; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: st.pick() }
                    Text {
                        anchors { left: parent.left; top: stShot.bottom; topMargin: 6 }
                        text: st.modelData.name
                        color: st.chosen ? Theme.accent : Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: st.chosen ? Font.DemiBold : Font.Normal }
                    }
                    FocusRing {}
                }
            }
        }
        SettingRow {
            label: "Width"
            hint: "The flyouts of the bar's items take it too"
            ConfigSlider { section: "controlCenter"; key: "width"; from: 280; to: 460; step: 10; format: v => v + " px" }
        }
        SettingRow {
            label: "CPU temperature in Power mode"
            hint: "Shown beside the power mode; click it for the hardware settings"
            ConfigToggle { section: "controlCenter"; key: "showHardware" }
        }
    }

    ResetGroup { sections: ["controlCenter"] }
}
