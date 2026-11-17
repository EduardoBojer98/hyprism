import QtQuick
import QtQuick.Layouts

// Control Center part: the large tiles (Wi-Fi and Bluetooth unless Settings moves others here), two to a row;
// an odd last one takes the whole row. The lists they open sit underneath (ControlCenterDrops).
// A flyout shows one list (host.fixed: "wifi" or "bt") without the tiles (tiles: []).
ColumnLayout {
    id: mod
    Layout.fillWidth: true
    property var host: null   // the panel it sits in (PanelState): ControlCenter.view or a Flyout's
    property var tiles: []    // the Control Center passes its shown large tiles; a flyout shows none
    spacing: ControlCenter.gap

    GridLayout {
        visible: mod.tiles.length > 0
        Layout.fillWidth: true
        columns: 2
        columnSpacing: ControlCenter.gap
        rowSpacing: ControlCenter.gap
        Repeater {
            model: mod.tiles
            ControlCenterConnTile {
                required property string modelData
                required property int index
                readonly property var it: ControlCenter.items[modelData]
                Layout.columnSpan: index === mod.tiles.length - 1 && mod.tiles.length % 2 === 1 ? 2 : 1
                glyph: it.glyph
                title: it.label
                subtitle: it.action ? it.hint : it.status
                active: ControlCenter.isOn(modelData)
                expandable: it.list !== undefined
                isExpanded: mod.host.expanded === it.list
                onToggled: ControlCenter.activate(modelData)
                onExpand: mod.host.toggleExpanded(it.list)
            }
        }
    }

    ControlCenterDrops { host: mod.host; ids: mod.tiles.length > 0 ? mod.tiles : [mod.host.fixed] }
}
