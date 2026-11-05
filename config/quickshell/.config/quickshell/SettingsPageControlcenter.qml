import QtQuick
import QtQuick.Layouts

// Control Center: a picture of the panel to rearrange it. Drag sections up and down and hide them;
// inside a section, drag a tile to move it and click it to show or hide it.
// Saved in Config.controlCenter (sections / tiles / toggles / shortcuts orders and a hidden list).
ColumnLayout {
    id: page
    spacing: 20

    readonly property var hidden: Config.controlCenter.hidden
    // a shortcut and a section can share an id ("power"), so the group decides where to look
    function info(id, group) { return (group === "shortcuts" ? ControlCenter.shortcutInfo[id] : ControlCenter.itemInfo[id]) ?? { label: id, glyph: "" } }
    // dragging: `id` goes right before or after `target` in the same group
    function place(group, id, target, after) {
        if (id === target) return
        const list = ControlCenter.order(group).filter(x => x !== id)
        const i = list.indexOf(target)
        if (i < 0) return
        list.splice(i + (after ? 1 : 0), 0, id)
        Config.set("controlCenter", group, list)
    }
    function setShown(id, on) { Config.set("controlCenter", "hidden", on ? hidden.filter(x => x !== id) : hidden.concat([id])) }

    SettingGroup {
        title: "Style"
        SettingRow {
            label: "Panel style"
            hint: ({ panel: "Rounded tiles with fills and borders", compact: "Smaller tiles, tighter spacing", borderless: "Flat tiles, no outlines — clean and minimal" })[Config.controlCenter.style] ?? ""
            ConfigChoice { section: "controlCenter"; key: "style"; values: ["panel", "compact", "borderless"]; labels: ["Panel", "Compact", "Borderless"] }
        }
        SettingRow {
            label: "Width"
            hint: "Panel width in pixels"
            ConfigSlider { section: "controlCenter"; key: "width"; from: 280; to: 460; step: 10; format: v => v + " px" }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Arrange the Control Center the way you use it. Changes show up straight away."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontLabel }
    }

    // ---- the panel, drawn as a stack of its sections ------------------------------------------
    Rectangle {
        Layout.fillWidth: true
        Layout.maximumWidth: 560
        implicitHeight: stack.implicitHeight + 24
        radius: Theme.radiusPanel
        color: Theme.glassStrong
        border { color: Theme.stroke; width: 1 }

        ColumnLayout {
            id: stack
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 8

            Repeater {
                model: ControlCenter.order("sections")
                DragItem {
                    id: sec
                    required property string modelData
                    required property int index
                    readonly property var inf: page.info(modelData)
                    readonly property bool on: !page.hidden.includes(modelData)
                    Layout.fillWidth: true
                    implicitHeight: secCol.implicitHeight + 20
                    key: "sections"
                    payload: modelData
                    floatOn: page.parent
                    radius: Theme.radius
                  Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: sec.on ? Theme.fill : "transparent"
                    border { color: sec.on ? Theme.stroke : Theme.strokeStrong; width: 1 }
                    opacity: sec.on ? 1 : 0.6

                    ColumnLayout {
                        id: secCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: "\u{F01DD}"; color: Theme.muted; font { family: Theme.iconFont; pixelSize: 15 } }   // drag handle
                            Text { text: sec.inf.glyph; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: 15 } }
                            Text {
                                Layout.fillWidth: true
                                text: sec.inf.label + (sec.on ? "" : "  ·  hidden")
                                elide: Text.ElideRight
                                color: Theme.text
                                font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                            }
                            Toggle { checked: sec.on; onToggled: on => page.setShown(sec.modelData, on) }
                        }

                        // the section's tiles: drag to move, click to show or hide
                        Flow {
                            visible: sec.inf.group !== undefined && sec.on
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: sec.inf.group ? ControlCenter.order(sec.inf.group) : []
                                DragItem {
                                    id: chip
                                    required property string modelData
                                    readonly property var inf: page.info(modelData, sec.inf.group)
                                    readonly property bool on: !page.hidden.includes(modelData)
                                    readonly property bool here: ControlCenter.available(modelData)
                                    width: chipRow.implicitWidth + 16
                                    height: 32
                                    key: sec.inf.group
                                    payload: modelData
                                    floatOn: page.parent
                                    onClicked: page.setShown(modelData, !on)
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: chip.radius
                                        color: chip.on ? Theme.accentWash : chip.hovered ? Theme.fillHover : "transparent"
                                        border { color: chip.on ? Theme.accent : Theme.stroke; width: 1 }
                                        Row {
                                            id: chipRow
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text { anchors.verticalCenter: parent.verticalCenter; text: chip.inf.glyph; color: chip.on ? Theme.accent : Theme.subtext; font { family: Theme.iconFont; pixelSize: 13 } }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: chip.inf.label + (chip.here ? "" : " (not here)")
                                                color: chip.on ? Theme.text : Theme.subtext   // off: a plain chip; on: accent wash and edge
                                                font { family: Theme.font; pixelSize: Theme.fontLabel }
                                            }
                                        }
                                    }
                                    DropSpot { anchors.fill: parent; key: chip.key; owner: chip; onPlaced: (id, after) => page.place(sec.inf.group, id, chip.modelData, after) }
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

    Text {
        Layout.fillWidth: true
        text: "Drag a section or a tile to move it. Highlighted tiles are shown; click one to hide it. \"Not here\" tiles need hardware this computer doesn't have."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    SettingGroup {
        title: "Details"
        SettingRow {
            label: "CPU temperature in Power mode"
            hint: "Shown beside the power mode; click it for the hardware settings"
            ConfigToggle { section: "controlCenter"; key: "showHardware" }
        }
    }

    ResetGroup { sections: ["controlCenter"] }
}
