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

    Text {
        Layout.fillWidth: true
        text: "Arrange the Control Center the way you use it. The preview is the real panel; changes apply straight away."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontLabel }
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
                                    Text { text: "\u{F01DD}"; color: Theme.muted; font { family: Theme.iconFont; pixelSize: 15 } }   // drag handle
                                    Text { text: sec.inf.glyph; color: sec.on ? Theme.accent : Theme.muted; font { family: Theme.iconFont; pixelSize: 16 } }
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
                                            model: sec.inf.group ? ControlCenter.order(sec.inf.group) : []
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
                                                radius: Theme.radius === 0 ? 0 : 15
                                                onClicked: page.setShown(modelData, !on)
                                                Accessible.role: Accessible.CheckBox
                                                Accessible.name: inf.label
                                                Accessible.checked: on
                                                Accessible.onPressAction: page.setShown(modelData, !on)
                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: chip.radius
                                                    color: chip.on ? Theme.accentWash : chip.hovered ? Theme.fillHover : "transparent"
                                                    border { color: chip.on ? Qt.alpha(Theme.accent, 0.7) : Theme.stroke; width: 1 }
                                                    Row {
                                                        id: chipRow
                                                        anchors.centerIn: parent
                                                        spacing: 6
                                                        Text { anchors.verticalCenter: parent.verticalCenter; text: chip.on ? chip.inf.glyph : "\u{F0209}"; color: chip.on ? Theme.accent : Theme.muted; font { family: Theme.iconFont; pixelSize: 13 } }
                                                        Text {
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            text: chip.inf.label + (chip.here ? "" : " (not on this computer)")
                                                            color: chip.on ? Theme.text : Theme.subtext
                                                            font { family: Theme.font; pixelSize: Theme.fontLabel; strikeout: !chip.on }
                                                        }
                                                    }
                                                }
                                                DropSpot { anchors.fill: parent; key: chip.key; owner: chip; onPlaced: (id, after) => page.place(sec.inf.group, id, chip.modelData, after) }
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
            y: page.wide ? 0 : editor.height + 20
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
                text: "Media shows only while something plays. Tiles marked \"not on this computer\" need hardware this one doesn't have."
                color: Theme.subtext
                wrapMode: Text.Wrap
                font { family: Theme.font; pixelSize: Theme.fontCaption }
            }
        }
    }

    SettingGroup {
        title: "Look"
        SettingRow {   // the defaults show every tile (Reset below); this is the short one
            label: "Essentials"
            hint: "Compact, with only the buttons most people use; your own tiles stay"
            PillButton { text: "Use"; onClicked: page.essentials() }
        }
        SettingRow {
            label: "Panel style"
            hint: ({ panel: "Tiles on soft fills, the panel's large corners", compact: "Smaller tiles and tighter spacing", borderless: "Flat tiles with hairline edges, no panel border" })[Config.controlCenter.style] ?? ""
            ConfigChoice { section: "controlCenter"; key: "style"; values: ["panel", "compact", "borderless"]; labels: ["Panel", "Compact", "Borderless"] }
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

    function essentials() {
        const keep = ["focus", "nightlight", "caffeine", "darkmode", "micmute", "airplane", "record", "screenshot"]
        Config.reset("controlCenter")
        Config.set("controlCenter", "style", "compact")
        Config.set("controlCenter", "hidden", ControlCenter.defaults.toggles.filter(id => !keep.includes(id) && !id.startsWith("action:")))
    }

    ResetGroup { sections: ["controlCenter"] }
}
