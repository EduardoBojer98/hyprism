import QtQuick

// Named sizes over a slider for any value between them, as one control (Settings > Menu Bar > Size).
// A chip lights only while the value is exactly its size; a click on one moves the slider there, and dragging
// the slider leaves the chips dark and keeps the number you slid to.
//   PresetSlider { values: [26, 34, 44, 56]; options: ["Slim", "Regular", "Tall", "Huge"]; from: 24; to: 56
//                  value: Theme.barSize; unit: "px"; accessibleName: "Bar size"; onPicked: v => save(v) }
Column {
    id: ps
    property var values: []            // the named sizes
    property var options: []           // their names, in the same order
    property real from: 0              // the slider's ends
    property real to: 100
    property real step: 1              // what a slide rounds to
    property real value: from          // the current value (bind it to the setting)
    property string unit: ""           // read out with the value: "34 px"
    property string accessibleName: ""
    signal picked(real value)          // a chip or the slider chose a new value: save it

    spacing: 8

    Choice {
        id: chips
        options: ps.options
        index: ps.values.indexOf(ps.value)        // -1 (none lit) for a value of your own
        accessibleName: ps.accessibleName
        onPicked: i => ps.picked(ps.values[i])
    }
    Slider {
        width: Math.max(chips.width, 160)
        height: Math.max(22, Theme.hit)
        accessibleName: ps.accessibleName + (ps.unit ? " in " + ps.unit : "")
        Accessible.description: ps.value + (ps.unit ? " " + ps.unit : "")
        value: (ps.value - ps.from) / (ps.to - ps.from)
        onMoved: v => {
            const n = Math.round((ps.from + v * (ps.to - ps.from)) / ps.step) * ps.step
            if (n !== ps.value) ps.picked(n)
        }
    }
}
