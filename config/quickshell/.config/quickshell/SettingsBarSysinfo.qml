import QtQuick
import QtQuick.Layouts

// The System info item's own settings: which readings, in which order, compact or detailed, the trend hint.
// Shown under the shared item settings; `item` is that SettingsBarItem (its merged settings and put()).
ColumnLayout {
    id: si
    required property var item
    spacing: 0
    readonly property var picked: Array.from(item.merged.metrics ?? [])
    function toggle(id) { item.put("metrics", picked.includes(id) ? picked.filter(m => m !== id) : picked.concat([id])) }
    function move(id, d) {
        const l = picked.slice(), at = l.indexOf(id), to = at + d
        if (to < 0 || to >= l.length) return
        l.splice(at, 1); l.splice(to, 0, id)
        item.put("metrics", l)
    }

    SettingRow {
        label: "Mode"
        hint: "Compact: icon and number. Detailed: the name too"
        Choice { options: ["Compact", "Detailed"]; index: si.item.merged.mode === "detailed" ? 1 : 0; Accessible.name: "Mode"
                 onPicked: i => si.item.put("mode", i === 1 ? "detailed" : "compact") }
    }
    SettingRow {
        label: "Trend in tooltip"
        Toggle { checked: si.item.merged.sparkline !== false; Accessible.name: "Trend in tooltip"; onToggled: on => si.item.put("sparkline", on) }
    }
    Text {
        Layout.fillWidth: true; Layout.margins: 16; Layout.bottomMargin: 4
        text: "Readings: click to switch one on or off. A computer without one skips it."
        color: Theme.subtext; wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
    Flow {
        Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
        spacing: 4
        Repeater {
            model: Metrics.ids
            Chip {
                required property string modelData
                icon: Metrics.registry[modelData].glyph ?? ""
                label: Metrics.registry[modelData].name
                active: si.picked.includes(modelData)
                Accessible.name: label
                onClicked: si.toggle(modelData)
            }
        }
    }
    Text {
        Layout.margins: 16; Layout.bottomMargin: 4
        text: "Order, first to last"
        color: Theme.subtext
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
    Flow {
        Layout.fillWidth: true; Layout.margins: 16; Layout.topMargin: 0
        spacing: 8
        Repeater {
            model: si.picked
            Row {
                required property string modelData
                spacing: 2
                PillButton { text: "‹"; Accessible.name: "Move " + modelData + " earlier"; onClicked: si.move(modelData, -1) }
                Text { anchors.verticalCenter: parent.verticalCenter; leftPadding: 4; rightPadding: 4; text: Metrics.registry[modelData]?.name ?? modelData
                       color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel } }
                PillButton { text: "›"; Accessible.name: "Move " + modelData + " later"; onClicked: si.move(modelData, 1) }
            }
        }
    }
}
