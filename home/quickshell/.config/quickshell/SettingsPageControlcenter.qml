import QtQuick
import QtQuick.Layouts

// Control Center: a picture of the panel to rearrange it. Sections go up and down and can be hidden;
// inside a section, click a tile to show or hide it and use the arrows to move it.
// Saved in Config.controlCenter (sections / tiles / toggles / shortcuts orders and a hidden list).
ColumnLayout {
    id: page
    spacing: 20

    readonly property var hidden: Config.controlCenter.hidden
    // a shortcut and a section can share an id ("power"), so the group decides where to look
    function info(id, group) { return (group === "shortcuts" ? ControlCenter.shortcutInfo[id] : ControlCenter.itemInfo[id]) ?? { label: id, glyph: "" } }
    function move(group, id, by) {
        const list = ControlCenter.order(group)
        const i = list.indexOf(id), j = i + by
        if (j < 0 || j >= list.length) return
        list.splice(i, 1); list.splice(j, 0, id)
        Config.set("controlCenter", group, list)
    }
    function setShown(id, on) { Config.set("controlCenter", "hidden", on ? hidden.filter(x => x !== id) : hidden.concat([id])) }

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
        radius: Theme.radiusLarge + 4
        color: Theme.glassStrong
        border { color: Theme.stroke; width: 1 }

        ColumnLayout {
            id: stack
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 8

            Repeater {
                model: ControlCenter.order("sections")
                Rectangle {
                    id: sec
                    required property string modelData
                    required property int index
                    readonly property var inf: page.info(modelData)
                    readonly property bool on: !page.hidden.includes(modelData)
                    Layout.fillWidth: true
                    implicitHeight: secCol.implicitHeight + 20
                    radius: Theme.radius
                    color: on ? Theme.fill : "transparent"
                    border { color: on ? Theme.stroke : Theme.strokeStrong; width: 1 }
                    opacity: on ? 1 : 0.6

                    ColumnLayout {
                        id: secCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text { text: sec.inf.glyph; color: Theme.subtext; font { family: Theme.iconFont; pixelSize: 15 } }
                            Text {
                                Layout.fillWidth: true
                                text: sec.inf.label + (sec.on ? "" : "  ·  hidden")
                                elide: Text.ElideRight
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 13; weight: Font.DemiBold }
                            }
                            ArrowButton { glyph: "\u{F0143}"; tip: "Move up"; enabled: sec.index > 0; onClicked: page.move("sections", sec.modelData, -1) }
                            ArrowButton { glyph: "\u{F0140}"; tip: "Move down"; enabled: sec.index < ControlCenter.order("sections").length - 1; onClicked: page.move("sections", sec.modelData, 1) }
                            Toggle { checked: sec.on; onToggled: on => page.setShown(sec.modelData, on) }
                        }

                        // the section's tiles: click to show or hide, arrows to move
                        Flow {
                            visible: sec.inf.group !== undefined && sec.on
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: sec.inf.group ? ControlCenter.order(sec.inf.group) : []
                                Rectangle {
                                    id: chip
                                    required property string modelData
                                    required property int index
                                    readonly property var inf: page.info(modelData, sec.inf.group)
                                    readonly property bool on: !page.hidden.includes(modelData)
                                    readonly property bool here: ControlCenter.available(modelData)
                                    readonly property int count: ControlCenter.order(sec.inf.group).length
                                    width: chipRow.implicitWidth + 16
                                    height: 32
                                    radius: Theme.radiusSmall + 2
                                    color: on ? Theme.accentWash : chipArea.containsMouse ? Theme.fillHover : "transparent"
                                    border { color: on ? Theme.accent : Theme.stroke; width: 1 }

                                    Row {
                                        id: chipRow
                                        anchors.centerIn: parent
                                        spacing: 6
                                        ArrowButton { small: true; anchors.verticalCenter: parent.verticalCenter; glyph: "\u{F0141}"; tip: "Earlier"; opacity: chipArea.containsMouse || hovered ? (enabled ? 1 : 0.3) : 0; enabled: chip.index > 0; onClicked: page.move(sec.inf.group, chip.modelData, -1) }
                                        Text { anchors.verticalCenter: parent.verticalCenter; text: chip.inf.glyph; color: chip.on ? Theme.text : Theme.muted; font { family: Theme.iconFont; pixelSize: 13 } }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: chip.inf.label + (chip.here ? "" : " (not here)")
                                            color: chip.on ? Theme.text : Theme.muted
                                            font { family: Theme.font; pixelSize: 12; strikeout: !chip.on }
                                        }
                                        ArrowButton { small: true; anchors.verticalCenter: parent.verticalCenter; glyph: "\u{F0142}"; tip: "Later"; opacity: chipArea.containsMouse || hovered ? (enabled ? 1 : 0.3) : 0; enabled: chip.index < chip.count - 1; onClicked: page.move(sec.inf.group, chip.modelData, 1) }
                                    }
                                    MouseArea {
                                        id: chipArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        z: -1   // under the arrows
                                        onClicked: page.setShown(chip.modelData, !chip.on)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Highlighted tiles are shown; click one to hide it. Hover a tile for arrows to move it. \"Not here\" tiles need hardware this computer doesn't have."
        color: Theme.muted
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
