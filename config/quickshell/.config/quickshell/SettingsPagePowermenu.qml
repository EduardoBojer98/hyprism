import QtQuick
import QtQuick.Layouts

// Power Menu: pick its layout from pictures of the real menu, then choose its actions and their order by
// dragging chips, with a live preview. Saved in Config.powerMenu (layout, actions, confirm, details).
ColumnLayout {
    id: page
    spacing: 20

    readonly property var shown: PowerMenu.actions.map(a => a.id)
    readonly property var all: PowerMenu.allActions
    readonly property string themeStyle: Theme.current.power?.style ?? "tiles"
    readonly property var layouts: [
        { id: "theme",  name: "Theme's own", hint: "Whatever the theme draws: " + ({ tiles: "tiles", row: "a row", blocks: "blocks", list: "a list" })[themeStyle] },
        { id: "tiles",  name: "Tiles",       hint: "Icon tiles in a grid; compact rows on a narrow screen" },
        { id: "row",    name: "Row",         hint: "One line of round buttons, each named under it" },
        { id: "blocks", name: "Blocks",      hint: "Big blocks with their key, hard shadows" },
        { id: "list",   name: "List",        hint: "A numbered list in a mono font" },
    ]

    // `id` goes right before or after `target` (target "": at the end)
    function place(id, target, after) {
        if (id === target) return
        const list = shown.filter(x => x !== id)
        const i = target === "" ? list.length : list.indexOf(target)
        if (i < 0) return
        list.splice(i + (after ? 1 : 0), 0, id)
        Config.set("powerMenu", "actions", list)
    }
    function setShown(id, on) {
        if (!on && shown.length <= 1) return   // the menu keeps at least one action
        Config.set("powerMenu", "actions", on ? shown.concat([id]) : shown.filter(x => x !== id))
    }

    // a stand-in for PowerMenu that nothing can run: the previews draw the real body with it
    component Stub: QtObject {
        property string style: "tiles"
        property var actions: PowerMenu.actions
        property int selected: 0
        property string confirming: ""
        property string host: PowerMenu.host || "This computer"
        property string uptime: PowerMenu.uptime
        property bool details: Config.powerMenu.details
        function activate(i) {}
        function hide() {}
    }
    // the menu's card at its real size, scaled to `width`
    component Shot: Item {
        id: shot
        property alias style: stub.style
        readonly property real cardW: style === "blocks" ? 720 : style === "list" ? 480 : style === "row" ? Math.max(440, stub.actions.length * 104 + Theme.spaceXl * 2) : 600
        readonly property real s: Math.min(1, width / cardW)
        implicitHeight: card.height * s
        Stub { id: stub }
        Glass {
            id: card
            x: (shot.width - width * shot.s) / 2
            width: shot.cardW
            height: body.implicitHeight + Theme.spaceXl * 2
            scale: shot.s
            transformOrigin: Item.TopLeft
            strong: true
            radius: Theme.radiusPanel
            PowerMenuBody {
                id: body
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceXl }
                menu: stub
                closable: false
                enabled: false
            }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Opens from the Control Center's power button, the utility menu, or the Power key. Changes apply straight away."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontLabel }
    }

    SettingGroup {
        title: "Layout"
        SettingRow {
            label: "Menu layout"
            hint: page.layouts.find(l => l.id === Config.powerMenu.layout)?.hint ?? ""
        }
        GridLayout {   // each layout drawn with your actions in it
            Layout.fillWidth: true
            Layout.margins: 12
            Layout.topMargin: 0
            columns: page.width >= 720 ? 3 : 2
            columnSpacing: 12
            rowSpacing: 12
            Repeater {
                model: page.layouts
                Item {
                    id: lay
                    required property var modelData
                    readonly property bool chosen: Config.powerMenu.layout === modelData.id
                    function pick() { Config.set("powerMenu", "layout", modelData.id) }
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: layShot.height + 26
                    activeFocusOnTab: true
                    Keys.onReturnPressed: pick()
                    Keys.onSpacePressed: pick()
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: "Layout " + modelData.name
                    Accessible.checked: chosen
                    Accessible.onPressAction: pick()
                    Rectangle {
                        id: layShot
                        width: parent.width
                        height: 150
                        radius: Theme.radiusSmall + 2
                        color: layArea.containsMouse && !lay.chosen ? Theme.fillHover : Theme.fill
                        border { color: lay.chosen ? Theme.accent : layArea.containsMouse ? Theme.strokeStrong : Theme.stroke; width: lay.chosen ? 2 : 1 }
                        clip: true
                        Shot {
                            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
                            style: lay.modelData.id === "theme" ? page.themeStyle : lay.modelData.id
                        }
                    }
                    MouseArea { id: layArea; anchors.fill: layShot; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lay.pick() }
                    Text {
                        anchors { left: parent.left; top: layShot.bottom; topMargin: 6 }
                        text: lay.modelData.name
                        color: lay.chosen ? Theme.accent : Theme.text
                        font { family: Theme.font; pixelSize: Theme.fontLabel; weight: lay.chosen ? Font.DemiBold : Font.Normal }
                    }
                    FocusRing {}
                }
            }
        }
    }

    SettingGroup {
        title: "Actions"
        SettingRow {
            label: "In the menu"
            hint: "Drag to change the order; click one to take it out, or a + to bring it back"
        }
        Flow {
            Layout.fillWidth: true
            Layout.margins: 12
            Layout.topMargin: 0
            spacing: 6
            Repeater {
                // shown ones in their order, then the rest
                model: page.shown.concat(page.all.map(a => a.id).filter(x => !page.shown.includes(x)))
                DragItem {
                    id: chip
                    required property string modelData
                    readonly property var inf: page.all.find(a => a.id === modelData)
                    readonly property bool on: page.shown.includes(modelData)
                    readonly property bool here: modelData !== "hibernate" || Machine.canHibernate
                    width: chipRow.implicitWidth + 18
                    height: 30
                    key: "power"
                    payload: modelData
                    floatOn: page.parent
                    draggable: on
                    radius: Theme.radius === 0 ? 0 : 15
                    onClicked: page.setShown(modelData, !on)
                    Accessible.role: Accessible.CheckBox
                    Accessible.name: (on ? "" : "Add ") + inf.label
                    Accessible.description: on ? "Click to take out, drag to move" : ""
                    Accessible.checked: on
                    Accessible.onPressAction: page.setShown(modelData, !on)
                    Rectangle {
                        anchors.fill: parent
                        radius: chip.radius
                        color: chip.hovered ? Theme.fillHover : chip.on ? Theme.fill : "transparent"
                        border { color: chip.hovered ? Theme.strokeStrong : Theme.stroke; width: 1 }
                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6
                            Text { anchors.verticalCenter: parent.verticalCenter; text: chip.on ? chip.inf.icon : "\u{F0415}"
                                   color: chip.on && chip.here ? (chip.inf.danger ? Theme.error : Theme.accent) : Theme.muted
                                   font { family: Theme.iconFont; pixelSize: Theme.glyphS } }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: chip.inf.label; color: chip.on && chip.here ? Theme.text : Theme.subtext
                                   font { family: Theme.font; pixelSize: Theme.fontLabel } }
                            Text {   // chosen, but this computer can't hibernate, so the menu leaves it out
                                visible: !chip.here
                                anchors.verticalCenter: parent.verticalCenter
                                text: "not here"
                                color: Theme.muted
                                font { family: Theme.font; pixelSize: Theme.fontCaption }
                            }
                        }
                    }
                    DropSpot { enabled: chip.on && !chip.dragging; anchors.fill: parent; key: "power"; owner: chip; onPlaced: (id, after) => page.place(id, chip.modelData, after) }
                }
            }
        }
        Text {
            Layout.leftMargin: 12
            text: "Preview"
            color: Theme.subtext
            font { family: Theme.font; pixelSize: Theme.fontLabel; weight: Font.DemiBold }
        }
        Shot {
            Layout.fillWidth: true
            Layout.margins: 12
            Layout.topMargin: 0
            style: PowerMenu.style
        }
    }

    SettingGroup {
        title: "Behaviour"
        SettingRow {
            label: "Ask before Log out, Restart and Shut down"
            hint: Config.powerMenu.confirm ? "A second press (or click) runs it" : "They run on the first press"
            ConfigToggle { section: "powerMenu"; key: "confirm" }
        }
        SettingRow {
            label: "Computer name and uptime"
            hint: "Under the title"
            ConfigToggle { section: "powerMenu"; key: "details" }
        }
    }

    Text {
        Layout.fillWidth: true
        text: "Keys: arrows pick an action, Enter runs it; each action's letter or number runs it straight away; Escape closes."
        color: Theme.subtext
        wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }

    ResetGroup { sections: ["powerMenu"] }
}
