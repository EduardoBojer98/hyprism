import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

// Workspaces: dynamic (made when needed on the screen you're on) or fixed (always there, each on its screen).
// In fixed mode, drag a workspace onto a screen to keep it there (or click it to move it to the next screen).
// Config.workspaces; SettingsSync writes hypr/settings/workspaces.lua and reloads Hyprland.
ColumnLayout {
    id: page
    spacing: 20

    readonly property var c: Config.workspaces
    readonly property bool fixed: c.mode === "fixed"
    // "" = any screen, every connected screen, then screens given workspaces that aren't connected now
    readonly property var connected: Hyprland.monitors.values.map(m => m.name)
    readonly property var columns: [""].concat(connected, Object.values(c.screens).filter((s, i, all) => s && !connected.includes(s) && all.indexOf(s) === i))
    function label(name) {
        if (name === "") return "Any screen"
        if (!connected.includes(name)) return name + " (not connected)"
        const m = Hyprland.monitors.values.find(x => x.name === name)
        return name.startsWith("eDP") ? "Laptop" : ((m?.model || m?.description || name).split(" ")[0] || name)
    }
    function screenOf(n) { return c.screens[String(n)] ?? "" }
    function assign(n, screen) {
        const s = Object.assign({}, c.screens)
        if (screen) s[String(n)] = screen; else delete s[String(n)]
        Config.set("workspaces", "screens", s)
    }
    function cycle(n) {   // the keyboard and click way: on to the next column
        const i = columns.indexOf(screenOf(n))
        assign(n, columns[(i + 1) % columns.length])
    }

    SettingGroup {
        title: "Workspaces"
        SettingRow {
            label: "Kind"
            hint: page.fixed ? "Always there, each on the screen you give it below" : "Made when you go to one, on the screen you're working on; gone when empty"
            ConfigChoice { section: "workspaces"; key: "mode"; values: ["dynamic", "fixed"]; labels: ["Dynamic", "Fixed"] }
        }
        SettingRow {
            visible: page.fixed
            label: "How many"
            hint: "Super+1 … Super+0 go to them; Super+Shift+number sends a window there"
            Choice {
                accessibleName: "How many workspaces"
                options: ["2", "3", "4", "5", "6", "7", "8", "9", "10"]
                index: Math.max(0, page.c.count - 2)
                onPicked: i => Config.set("workspaces", "count", i + 2)
            }
        }
    }

    SettingGroup {
        title: "Which screen"
        visible: page.fixed

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 12
            spacing: 12

            Repeater {
                model: page.columns
                Rectangle {
                    id: column
                    required property string modelData
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    implicitHeight: Math.max(150, chips.implicitHeight + 56)
                    radius: Theme.radius
                    color: drop.containsDrag ? Theme.accentWash : Theme.fill
                    border { color: drop.containsDrag ? Theme.accent : Theme.stroke; width: drop.containsDrag ? 2 : 1 }

                    Text {
                        id: head
                        anchors { left: parent.left; top: parent.top; margins: 12 }
                        text: page.label(column.modelData)
                        color: column.modelData ? Theme.text : Theme.subtext
                        font { family: Theme.font; pixelSize: Theme.fontSize; weight: Font.DemiBold }
                    }

                    DropArea {
                        id: drop
                        anchors.fill: parent
                        keys: ["workspace"]
                        onDropped: drag => page.assign(drag.source.number, column.modelData)
                    }

                    Flow {
                        id: chips
                        anchors { left: parent.left; right: parent.right; top: head.bottom; margins: 12 }
                        spacing: 8
                        Repeater {
                            model: Array.from({ length: page.c.count }, (_, i) => i + 1).filter(n => page.screenOf(n) === column.modelData)
                            Rectangle {
                                id: chip
                                required property int modelData
                                readonly property int number: modelData
                                width: 44; height: 44
                                radius: Theme.radiusSmall ?? 6
                                color: area.drag.active ? Theme.accent : Theme.fillHover
                                border { color: area.containsMouse || activeFocus ? Theme.accent : Theme.stroke; width: 1 }
                                Drag.active: area.drag.active
                                Drag.keys: ["workspace"]
                                Drag.source: chip
                                Drag.hotSpot.x: width / 2
                                Drag.hotSpot.y: height / 2
                                activeFocusOnTab: true
                                Accessible.role: Accessible.Button
                                Accessible.name: "Workspace " + number + " on " + page.label(column.modelData) + ": press to move it to the next screen"
                                Accessible.onPressAction: page.cycle(number)
                                Keys.onSpacePressed: page.cycle(number)
                                Keys.onReturnPressed: page.cycle(number)

                                Text {
                                    anchors.centerIn: parent
                                    text: chip.number
                                    color: area.drag.active ? Theme.onAccent : Theme.text
                                    font { family: Theme.font; pixelSize: Theme.fontSize + 2; weight: Font.DemiBold }
                                }
                                MouseArea {
                                    id: area
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                    drag.target: chip
                                    property point start
                                    onPressed: start = Qt.point(chip.x, chip.y)
                                    onReleased: {
                                        const moved = Math.abs(chip.x - start.x) + Math.abs(chip.y - start.y) > 4
                                        if (moved) chip.Drag.drop(); else page.cycle(chip.number)
                                        chip.x = start.x; chip.y = start.y   // the list redraws it in its new column
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
        visible: page.fixed
        text: "Drag a number onto a screen, or click it to move it to the next one. Each screen starts on its lowest number. A screen that isn't connected keeps its numbers for when it comes back."
        wrapMode: Text.WordWrap
        color: Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
}
