import QtQuick

// Named sizes over a slider for any size between (Settings > Dock size; the bar's size uses the same look).
// A preset lights only when the value is exactly its own; clicking one moves the slider there, dragging the slider
// picks a size of your own and no preset stays lit. `value` in, `picked(v)` out (whole numbers, from..to).
//   PresetSlider { values: [36, 44, 52]; labels: ["S", "M", "L"]; from: 24; to: 72; value: x; onPicked: v => save(v) }
Column {
    id: ps
    property var values: []
    property var labels: values.map(String)
    property int from: 0
    property int to: 100
    property int value: from
    property string unit: "px"
    property string accessibleName: ""
    readonly property bool custom: values.indexOf(value) < 0
    signal picked(int value)

    spacing: 8

    Choice {
        id: presets
        options: ps.labels
        index: ps.values.indexOf(ps.value)
        accessibleName: ps.accessibleName
        onPicked: i => ps.picked(ps.values[i])
    }
    Slider {
        width: presets.width
        height: Math.max(22, Theme.hit)
        accessibleName: ps.accessibleName + (ps.unit ? " in " + ps.unit : "")
        Accessible.description: ps.value + (ps.unit ? " " + ps.unit : "")
        value: (ps.value - ps.from) / (ps.to - ps.from)
        onMoved: v => { const n = Math.round(ps.from + v * (ps.to - ps.from)); if (n !== ps.value) ps.picked(n) }
    }
}
