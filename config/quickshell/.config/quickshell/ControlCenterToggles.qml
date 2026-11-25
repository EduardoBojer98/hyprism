import QtQuick
import QtQuick.Layouts

// Control Center part: the small buttons (Focus, Night Light, Caffeine, Record, Screenshot ...), every cell the
// same size. Four or three to a row, whichever fills the last row more; a short last row is centred, never
// stretched. The lists they open (Caffeine's) sit underneath (ControlCenterDrops).
// The layout reshapes the grid: two wide tiles with a subtitle to a row (cards); a bento of the first one as a 2x2
// block, four beside it, then rows of four whose short last row stretches (bento); two `[x] name` columns (hud).
ColumnLayout {
    id: mod
    Layout.fillWidth: true
    property var host: null   // the panel it sits in (PanelState)
    property var ids: []      // the shown small tiles, in order
    spacing: ControlCenter.gap

    ControlCenterSliderHead { visible: !ControlCenter.cards; title: "Switches" }

    Item {
        id: grid
        Layout.fillWidth: true
        readonly property int count: mod.ids.length
        readonly property int gap: ControlCenter.gap
        readonly property int colGap: gap
        // 5: 3+2, 6: 3+3, 7: 4+3, 9: 3+3+3, 10: 4+4+2; up to four in one row
        readonly property bool bento: ControlCenter.bento && count >= 5   // fewer: one plain row
        readonly property int perRow: ControlCenter.hud ? 3 : ControlCenter.cards ? 2
                                    : bento ? 4 : count <= 4 ? Math.max(3, count) : (count % 3 || 3) / 3 > (count % 4 || 4) / 4 ? 3 : 4
        readonly property int rows: bento ? 2 + Math.ceil((count - 5) / 4) : Math.ceil(count / perRow)
        readonly property real cellW: (width - (perRow - 1) * colGap) / perRow
        readonly property int cellH: ControlCenter.hud ? Math.max(Theme.hit, Theme.fontLabel * 4)
                                   : ControlCenter.cards ? Theme.ccTile - Theme.spaceS
                                   : ControlCenter.style === "compact" ? Theme.ccToggle - 8 : Theme.ccToggle
        // a tile's [column, row, columns wide, rows tall]
        function cell(i) {
            if (!bento) return [i % perRow, Math.floor(i / perRow), 1, 1]
            if (i === 0) return [0, 0, 2, 2]
            if (i <= 4) return [2 + (i - 1) % 2, Math.floor((i - 1) / 2), 1, 1]
            const c = (i - 5) % 4
            return [c, 2 + Math.floor((i - 5) / 4), i === count - 1 ? 4 - c : 1, 1]
        }
        implicitHeight: rows * cellH + Math.max(0, rows - 1) * gap
        // one label size for every tile: the longest name decides, so no tile reads smaller than its neighbour
        FontMetrics { id: fm; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold } }
        readonly property int labelSize: {
            const widest = Math.max(1, ...mod.ids.map(id => fm.advanceWidth(ControlCenter.items[id]?.label ?? "")))
            return Math.max(Theme.fontCaption - 2, Math.min(Theme.fontCaption, Math.floor(Theme.fontCaption * (cellW - Theme.spaceXs * 2) / widest)))
        }

        Repeater {
            model: mod.ids
            ControlCenterQuickToggle {
                required property string modelData
                required property int index
                readonly property var it: ControlCenter.items[modelData] ?? ({ glyph: "", label: "", status: "" })   // your action tiles: for a moment at start
                readonly property var c: grid.cell(index)
                readonly property int inRow: c[1] < grid.rows - 1 || grid.bento || ControlCenter.hud ? grid.perRow : grid.count - c[1] * grid.perRow
                x: (grid.width - inRow * grid.cellW - (inRow - 1) * grid.colGap) / 2 + c[0] * (grid.cellW + grid.colGap)
                y: c[1] * (grid.cellH + grid.gap)
                width: c[2] * grid.cellW + (c[2] - 1) * grid.colGap
                height: c[3] * grid.cellH + (c[3] - 1) * grid.gap
                big: c[3] > 1
                host: mod.host
                glyph: it.glyph
                label: it.label
                labelSize: grid.labelSize
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
