import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Menu Bar > Item settings: the settings every bar item understands (docs/bar.md), for one item picked in the
// editor or from the list. Each row writes the whole bar.items object back (Config.set), so the bar follows at once.
SettingGroup {
    id: g
    title: "Item settings"

    required property var editor                         // the BarEditor: its layout lists the items, its `selected` is the pick
    readonly property var ids: [].concat(Array.from(editor.layout.start), Array.from(editor.layout.center), Array.from(editor.layout.end))
    readonly property string cur: ids.includes(editor.selected) ? editor.selected : (ids[0] ?? "")
    readonly property var merged: BarItems.settings(cur)
    readonly property var mine: Config.bar.items?.[cur] ?? {}
    readonly property var base: BarItems.defs[cur]?.settings ?? {}

    // empty / undefined removes the key (the item's default applies again); an empty entry goes away too
    function put(key, value) {
        const all = JSON.parse(JSON.stringify(Config.bar.items ?? {})), o = all[cur] ?? {}
        if (value === undefined || value === "") delete o[key]; else o[key] = value
        if (Object.keys(o).length) all[cur] = o; else delete all[cur]
        Config.set("bar", "items", all)
    }
    function reset() {
        const all = JSON.parse(JSON.stringify(Config.bar.items ?? {}))
        delete all[cur]
        Config.set("bar", "items", all)
    }

    // first paragraph of the item's README, when there is one
    FileView { id: readme; path: g.cur ? BarItems.dir + "/" + g.cur + "/README.md" : "" }
    readonly property string about: {
        const t = readme.path ? readme.text() : ""
        const p = t.split("\n\n").map(x => x.trim()).filter(x => x && x[0] !== "#")
        return p.length ? p[0].replace(/\n/g, " ") : ""
    }

    SettingRow {
        label: "Item"
        hint: g.about || "Pick an item here, or click one in the bar above"
        Dropdown {
            Accessible.name: "Item to edit"
            options: g.ids.map(i => Themes.barItem(i).name)
            current: Themes.barItem(g.cur).name
            onPicked: v => g.editor.selected = g.ids.find(i => Themes.barItem(i).name === v) ?? g.cur
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: g.cur !== ""

        SettingRow {
            label: "Enabled"
            hint: "Off hides it everywhere"
            Toggle { Accessible.name: "Enabled"; checked: g.merged.enabled !== false; onToggled: on => g.put("enabled", on) }
        }
        TextRow { label: "Icon"; hint: "One glyph instead of its own"; key: "icon"; fieldWidth: 70 }
        TextRow { label: "Label format"; hint: "Text with {value} and {word}. Press Enter to apply"; key: "format"; placeholder: "{value}" }
        ActionRow { label: "Click"; key: "click" }
        ActionRow { label: "Right-click"; key: "rightClick" }
        ActionRow { label: "Scroll"; key: "scroll" }
        SettingRow {
            label: "Tooltip"
            Toggle { Accessible.name: "Tooltip"; checked: g.merged.tooltip !== false; onToggled: on => g.put("tooltip", on) }
        }
        NumRow { label: "Warn at"; hint: "Amber and a ! from here. Empty: the item's own"; key: "warn" }
        NumRow { label: "Critical at"; hint: "Red and !! from here. Empty: the item's own"; key: "critical" }
        NumRow { visible: g.base.interval !== undefined; label: "Update every"; hint: "Seconds between readings"; key: "interval"; min: 1 }
        SettingsBarSysinfo { visible: g.cur === "sysinfo"; Layout.fillWidth: true; item: g }
        SettingRow {
            label: "Reset this item"
            hint: "Back to its own settings"
            PillButton { text: "Reset"; enabled: Object.keys(g.mine).length > 0; Accessible.name: "Reset this item"; onClicked: g.reset() }
        }
    }

    // a text value of one setting, applied on Enter; follows the file while not being typed in
    component TextRow: SettingRow {
        id: tr
        property string key
        property string placeholder
        property int fieldWidth: 220
        TextField {
            id: field
            width: tr.fieldWidth; placeholder: tr.placeholder
            Accessible.name: tr.label
            onAccepted: g.put(tr.key, text.trim())
            Binding on text { value: String(g.merged[tr.key] ?? ""); when: !field.children[0].activeFocus; restoreMode: Binding.RestoreNone }
        }
    }
    // a number: empty means the item's own value; the item's default shows as the placeholder
    component NumRow: SettingRow {
        id: nr
        property string key
        property real min: -1e9
        TextField {
            id: nf
            width: 90
            Accessible.name: nr.label
            placeholder: String(g.base[nr.key] ?? "")
            invalid: text.trim() !== "" && (isNaN(Number(text)) || Number(text) < nr.min)
            onAccepted: if (!invalid) g.put(nr.key, text.trim() === "" ? undefined : Number(text))
            Binding on text { value: g.mine[nr.key] === undefined ? "" : String(g.mine[nr.key]); when: !nf.children[0].activeFocus; restoreMode: Binding.RestoreNone }
        }
    }
    // what a click / right-click / scroll does: one of BarActions.names, or a command of your own
    component ActionRow: SettingRow {
        id: ar
        property string key
        property bool custom: false
        readonly property string value: String(g.merged[key] ?? "default")
        readonly property bool isRun: value.startsWith("run:")
        readonly property string more: "Custom command…"
        Connections { target: g; function onCurChanged() { ar.custom = false } }
        Dropdown {
            Accessible.name: ar.label
            options: BarActions.names.concat([ar.more])
            current: ar.custom || ar.isRun ? ar.more : ar.value
            showCustom: !ar.custom && !ar.isRun
            onPicked: v => { ar.custom = v === ar.more; if (!ar.custom) g.put(ar.key, v === "default" ? undefined : v) }
        }
        TextField {
            id: cmd
            visible: ar.custom || ar.isRun
            width: 170; placeholder: "command"
            Accessible.name: ar.label + " command"
            onAccepted: g.put(ar.key, text.trim() ? "run:" + text.trim() : undefined)
            Binding on text { value: ar.isRun ? ar.value.slice(4) : ""; when: !cmd.children[0].activeFocus; restoreMode: Binding.RestoreNone }
        }
    }
}
