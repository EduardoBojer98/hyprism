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

    // thresholds.<id>.warn / .critical and onlyAbove.<id>: empty removes the entry (the reading's own level applies)
    function setLevel(map, id, sub, text) {
        const all = JSON.parse(JSON.stringify(item.merged[map] ?? {}))
        const v = text.trim() === "" ? undefined : Number(text)
        if (sub === "") { if (v === undefined) delete all[id]; else all[id] = v }
        else {
            const o = all[id] ?? {}
            if (v === undefined) delete o[sub]; else o[sub] = v
            if (Object.keys(o).length) all[id] = o; else delete all[id]
        }
        item.put(map, Object.keys(all).length ? all : undefined)
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
    // one group per category (Metrics.categories, in order), each a heading and its readings' chips
    Column {
        Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16
        spacing: 10
        Repeater {
            model: Metrics.categories
            Column {
                id: catGroup
                required property string modelData
                readonly property var ids: Metrics.ids.filter(id => Metrics.registry[id].category === catGroup.modelData)
                width: parent.width
                spacing: 6
                Text {
                    text: catGroup.modelData
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
                }
                Flow {
                    width: catGroup.width
                    spacing: 4
                    Repeater {
                        model: catGroup.ids
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
    Text {
        Layout.fillWidth: true; Layout.margins: 16; Layout.bottomMargin: 4
        visible: si.picked.length > 0
        text: "Levels per reading. Warn: amber and a !. Critical: red and !!. Only above: hide it below that number. Empty: the reading's own. Press Enter to apply"
        color: Theme.subtext; wrapMode: Text.Wrap
        font { family: Theme.font; pixelSize: Theme.fontCaption }
    }
    Repeater {
        model: si.picked.filter(id => Metrics.registry[id] !== undefined)
        RowLayout {
            id: lv
            required property string modelData
            readonly property var entry: Metrics.registry[modelData]
            Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; Layout.bottomMargin: 4
            spacing: 6
            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: lv.entry.name; color: Theme.text; font { family: Theme.font; pixelSize: Theme.fontLabel } }
            LevelField { rid: lv.modelData; map: "thresholds"; sub: "warn"; label: "warn"; shown: lv.entry.warn }
            LevelField { rid: lv.modelData; map: "thresholds"; sub: "critical"; label: "critical"; shown: lv.entry.critical }
            LevelField { rid: lv.modelData; map: "onlyAbove"; sub: ""; label: "only above"; shown: undefined }
        }
    }

    // one number of a reading; it follows the file while not being typed in
    component LevelField: TextField {
        id: lf
        property string rid
        property string map
        property string sub
        property string label
        property var shown                       // the reading's own level, shown as the hint
        readonly property var stored: sub === "" ? si.item.merged[map]?.[rid] : si.item.merged[map]?.[rid]?.[sub]
        width: 70
        placeholder: shown === undefined ? label : String(shown)
        Accessible.name: (Metrics.registry[rid]?.name ?? rid) + " " + label
        invalid: text.trim() !== "" && isNaN(Number(text))
        onAccepted: if (!invalid) si.setLevel(map, rid, sub, text)
        Binding on text { value: lf.stored === undefined ? "" : String(lf.stored); when: !lf.children[0].activeFocus; restoreMode: Binding.RestoreNone }
    }
}
