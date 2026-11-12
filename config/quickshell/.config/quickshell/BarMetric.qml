import QtQuick

// One system reading in the bar (Metrics.registry): its glyph, its short text, its warn / critical levels and a
// tooltip with the longer line and the recent trend. While it exists it asks Metrics to measure that reading.
BarIndicator {
    id: m
    property string metric: ""
    property bool sparkline: true            // the recent trend in the tooltip
    readonly property var entry: Metrics.registry[metric] ?? null

    property string asked: ""
    property bool built: false               // `bar` and `metric` are both set only once the item is complete
    function ask() {
        if (!built) return
        if (asked !== "") Metrics.unwant([asked])
        asked = entry ? metric : ""
        if (asked !== "") Metrics.want([asked], Number(cfg.interval) || 2)
    }
    Component.onCompleted: { built = true; ask() }
    onMetricChanged: ask()
    Component.onDestruction: if (asked !== "") Metrics.unwant([asked])

    shown: entry !== null && Metrics.has(metric)     // a computer without this reading shows nothing
    textual: true
    showValue: true
    glyph: entry?.glyph ?? ""
    word: entry?.word ?? ""
    value: Metrics.text(metric)
    level: Metrics.value(metric)
    warnAt: cfg.warn ?? entry?.warn
    criticalAt: cfg.critical ?? entry?.critical
    tip: Metrics.detail(metric) + (sparkline && Metrics.spark(metric) !== "" ? "\n" + Metrics.spark(metric) : "")
}
