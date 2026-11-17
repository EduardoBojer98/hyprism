import QtQuick
import QtQuick.Layouts

// Control Center part: the small buttons (Focus, Night Light, Caffeine, Record, Screenshot ...), every cell the
// same size. Four or three to a row, whichever fills the last row more; a short last row is centred, never
// stretched. The lists they open (Caffeine's) sit underneath (ControlCenterDrops).
ColumnLayout {
    id: mod
    Layout.fillWidth: true
    property var host: null   // the panel it sits in (PanelState)
    property var ids: []      // the shown small tiles, in order
    spacing: ControlCenter.gap

    Item {
        id: grid
        Layout.fillWidth: true
        readonly property int count: mod.ids.length
        readonly property int gap: ControlCenter.gap
        // 5: 3+2, 6: 3+3, 7: 4+3, 9: 3+3+3, 10: 4+4+2; up to four in one row
        readonly property int perRow: count <= 4 ? Math.max(3, count) : (count % 3 || 3) / 3 > (count % 4 || 4) / 4 ? 3 : 4
        readonly property int rows: Math.ceil(count / perRow)
        readonly property real cellW: (width - (perRow - 1) * gap) / perRow
        readonly property int cellH: ControlCenter.style === "compact" ? Theme.ccToggle - 8 : Theme.ccToggle
        implicitHeight: rows * cellH + Math.max(0, rows - 1) * gap

        Repeater {
            model: mod.ids
            ControlCenterQuickToggle {
                required property string modelData
                required property int index
                readonly property var it: ControlCenter.items[modelData]
                readonly property int row: Math.floor(index / grid.perRow)
                readonly property int inRow: row < grid.rows - 1 ? grid.perRow : grid.count - row * grid.perRow
                x: (grid.width - inRow * grid.cellW - (inRow - 1) * grid.gap) / 2 + (index % grid.perRow) * (grid.cellW + grid.gap)
                y: row * (grid.cellH + grid.gap)
                width: grid.cellW
                height: grid.cellH
                host: mod.host
                glyph: it.glyph
                label: it.label
                status: it.status
                hint: it.hint ?? ""
                active: ControlCenter.isOn(modelData)
                expandable: it.list !== undefined
                isExpanded: mod.host.expanded === it.list
                onToggled: ControlCenter.activate(modelData)
                onExpand: mod.host.toggleExpanded(it.list)
            }
        }
    }

    ControlCenterDrops { host: mod.host; ids: mod.ids }
}
