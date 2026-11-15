import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Menu Bar > the picked item's settings: only what that item really reads. Each copy of an item on the bar is an
// instance ("clock#2") with settings of its own; what it offers follows its item ("clock"). Its own options first
// (what the clock shows, the window title, the battery percentage, System info's readings), then the shared ones it
// understands (docs/bar.md): levels, icon and label, what the mouse does. Each bar.items row writes the whole
// bar.items object back (Config.set), so the bar follows at once.
SettingGroup {
    id: g
    title: "Selected item"

    required property var editor                         // the BarEditor: its `current` is the item shown here
    readonly property string cur: editor.current            // the instance: "clock", "clock#2"…
    readonly property string kind: BarItems.base(cur)       // its item: "clock"
    readonly property var info: BarItems.info(cur)
    readonly property var merged: BarItems.settings(cur)
    readonly property var mine: Config.bar.items?.[cur] ?? {}
    readonly property var base: BarItems.defs[kind]?.settings ?? {}

    // What each item draws with (bar/items/<id>/Item.qml): "mouse" = it takes click / right-click / scroll /
    // tooltip (BarItem actions), "icon" = a glyph of your own, "label" = a format around its value, "levels" =
    // warn / critical against a number it measures. An item not listed here (one of your own) gets them all.
    readonly property var kinds: ({
        apps: [], tray: [], workspaces: [], window: [],
        clock: ["mouse"], date: ["mouse"], battery: ["mouse"], status: ["mouse"], sysinfo: ["mouse"],
        notifications: ["mouse"], keyboard: ["mouse"], recording: ["mouse"], launcher: ["mouse"], controls: ["mouse"],
        bluetooth: ["icon", "mouse"], power: ["icon", "mouse"], "power-profile": ["icon", "mouse"],
        network: ["icon", "label", "mouse"], volume: ["icon", "label", "mouse"], brightness: ["icon", "label", "mouse"],
        media: ["icon", "label", "mouse"],
        cpu: ["levels", "icon", "label", "mouse"], gpu: ["levels", "icon", "label", "mouse"], memory: ["levels", "icon", "label", "mouse"],
        weather: ["levels", "icon", "label", "mouse"]
    })
    readonly property var has: kinds[kind] ?? ["levels", "icon", "label", "mouse"]
    // the reading a metric item shows (Metrics.registry), for its own warn / critical levels
    readonly property var metric: Metrics.registry[({ cpu: "cpu", gpu: "gpu", memory: "ram" })[kind] ?? ""] ?? null
    // where the rest of an item's options live
    readonly property var elsewhere: ({ apps: ["Dock", "dock"], workspaces: ["Workspaces", "workspaces"], weather: ["Weather", "weather"],
                                        notifications: ["Notifications", "notifications"], keyboard: ["Input", "input"] })

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

    // the first sentence of the item's README, when there is one
    FileView { id: readme; path: g.cur ? BarItems.dir + "/" + g.kind + "/README.md" : "" }
    readonly property string about: {
        const t = readme.path ? readme.text() : ""
        const p = t.split("\n\n").map(x => x.trim()).filter(x => x && x[0] !== "#")
        const s = p.length ? p[0].replace(/\n/g, " ") : "", end = s.indexOf(". ")
        const first = (end > 0 ? s.slice(0, end + 1) : s).replace((BarItems.defs[g.kind]?.name ?? "") + ": ", "")   // "System info: the one…" sits under its name
        return first.charAt(0).toUpperCase() + first.slice(1)
    }

    SettingRow {
        visible: g.cur === ""
        label: "No items on the bar"
        hint: "Add one above to set it up"
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        visible: g.cur !== ""

        // what it is, and a way back to its own defaults
        SettingRow {
            label: g.info.name
            hint: g.about
            PillButton {
                visible: g.elsewhere[g.kind] !== undefined
                text: (g.elsewhere[g.kind]?.[0] ?? "") + " settings"
                onClicked: SettingsApp.show(g.elsewhere[g.kind][1])
            }
            PillButton {
                visible: g.has.length > 0 || Object.keys(g.mine).length > 0   // nothing to reset on an item without options
                text: "Reset"; enabled: Object.keys(g.mine).length > 0
                Accessible.name: "Reset " + g.info.name
                onClicked: g.reset()
            }
        }
        SettingRow {   // only an item switched off in settings.json by hand: the bar skips it
            visible: g.mine.enabled === false
            label: "Hidden"
            hint: "Switched off in settings.json, so the bar leaves it out"
            Toggle { Accessible.name: "Show " + g.info.name; checked: false; onToggled: on => g.put("enabled", on ? undefined : false) }
        }

        // ---- its own options --------------------------------------------------------------------
        SettingsBarClock { visible: g.kind === "clock"; Layout.fillWidth: true; item: g }
        SettingRow {
            visible: g.kind === "window"
            label: "Window title"
            hint: "After the app's name"
            ConfigToggle { section: "bar"; key: "windowTitle" }
        }
        SettingRow {
            visible: g.kind === "battery" || g.kind === "status"
            label: "Battery percentage"
            hint: g.kind === "status" ? "Shared with the Battery item" : "Shared with Quick settings"
            ConfigChoice { section: "bar"; key: "batteryPercent"; values: ["inside", "beside", "off"]; labels: ["Inside", "Beside", "Off"] }
        }
        SettingsBarSysinfo { visible: g.kind === "sysinfo"; Layout.fillWidth: true; item: g }
        NumRow { visible: g.base.interval !== undefined; label: "Update every"; hint: "Seconds between readings"; key: "interval"; min: 1; own: g.base.interval }
        NumRow { visible: g.has.includes("levels"); label: "Warn at"; hint: g.kind === "weather" ? "Amber and a ! from this temperature" : "Amber and a ! from here"; key: "warn"; own: g.metric?.warn }
        NumRow { visible: g.has.includes("levels"); label: "Critical at"; hint: g.kind === "weather" ? "Red and !! from this temperature" : "Red and !! from here"; key: "critical"; own: g.metric?.critical }
        TextRow { visible: g.has.includes("icon"); label: "Icon"; hint: "One glyph in place of its own"; key: "icon"; fieldWidth: 70 }
        TextRow { visible: g.has.includes("label"); label: "Label"; hint: "Your text around {value}. Enter applies"; key: "format"; placeholder: "{value}" }

        SettingRow {   // an item with nothing to set
            visible: g.has.length === 0 && g.kind !== "window"
            label: "No options of its own"
            hint: g.elsewhere[g.kind] ? "They are on the " + g.elsewhere[g.kind][0] + " page" : "Its look follows the theme"
        }

        // ---- the mouse --------------------------------------------------------------------------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            visible: g.has.includes("mouse")
            Rectangle { Layout.fillWidth: true; Layout.leftMargin: 16; Layout.rightMargin: 16; implicitHeight: 1; color: Theme.stroke }
            Text {
                Layout.leftMargin: 16; Layout.topMargin: 14; Layout.bottomMargin: 2
                text: "Mouse"
                color: Theme.subtext
                font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
            }
            ActionRow { label: "Click"; key: "click" }
            ActionRow { label: "Right-click"; key: "rightClick" }
            ActionRow { label: "Scroll"; key: "scroll" }
            SettingRow {
                label: "Tooltip"
                Toggle { Accessible.name: "Tooltip"; checked: g.merged.tooltip !== false; onToggled: on => g.put("tooltip", on ? undefined : false) }
            }
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
    // a number: empty means the item's own value, shown as the placeholder
    component NumRow: SettingRow {
        id: nr
        property string key
        property real min: -1e9
        property var own
        TextField {
            id: nf
            width: 90
            Accessible.name: nr.label
            placeholder: nr.own === undefined || nr.own === null ? "" : String(nr.own)
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
