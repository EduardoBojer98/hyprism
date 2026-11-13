import QtQuick
import qs

// System info: the readings you picked (settings: metrics), in your order. Each is a small indicator of its
// own, so each has its own level colours; the tooltip gives the longer lines and recent trends.
// A reading this computer doesn't have is skipped. Click opens the system panel.
BarItem {
    id: root
    required property var bar
    readonly property var cfg: bar.cfg
    // only names the registry knows, each once
    // Array.from, not Array.isArray: a list read from settings.json at start is a Qt list, not a JS array, and
    // isArray said no, so after every shell start the item had no readings and hid itself
    readonly property var chosen: Array.from(new Set(Array.from(cfg.metrics ?? []).filter(id => Metrics.registry[id] !== undefined)))
    readonly property bool detailed: cfg.mode === "detailed"
    function above(id) {   // "only show above a level": hidden below it
        const floor = cfg.onlyAbove?.[id]
        return typeof floor !== "number" || Metrics.value(id) >= floor
    }

    actions: cfg
    vertical: bar.vertical
    spacing: 10
    pad: 4
    shown: chosen.some(id => Metrics.has(id) && above(id))
    active: Sensors.open
    opens: "system"
    onPressed: Sensors.toggle()
    tip: chosen.filter(id => Metrics.has(id))
               .map(id => Metrics.detail(id) + (cfg.sparkline !== false && Metrics.spark(id) !== "" ? "   " + Metrics.spark(id) : "")).join("\n")

    Repeater {
        model: root.chosen
        BarMetric {
            required property string modelData
            bar: root.bar
            metric: modelData
            interactive: false                       // the whole item is the button
            pad: 2
            shown: Metrics.has(modelData) && root.above(modelData)
            tip: ""
            // Icons (compact): symbol and number, in every bar voice. Labels (detailed): short name and number.
            asWords: root.detailed
            format: root.cfg.formats?.[modelData] ?? ""
            icon: root.cfg.icons?.[modelData] ?? ""
            warnAt: root.cfg.thresholds?.[modelData]?.warn ?? entry?.warn
            criticalAt: root.cfg.thresholds?.[modelData]?.critical ?? entry?.critical
        }
    }
}
