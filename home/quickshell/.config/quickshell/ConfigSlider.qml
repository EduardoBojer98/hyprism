import QtQuick

// A slider bound to one numeric Config option (from..to, rounded to step), its value written beside it.
Row {
    id: cs

    property string section
    property string key
    property real from: 0
    property real to: 1
    property real step: 0.01
    property var format: v => String(v)
    readonly property real value: Config[section]?.[key] ?? from

    spacing: 10

    Slider {
        width: 170
        height: 22
        anchors.verticalCenter: parent.verticalCenter
        value: (cs.value - cs.from) / (cs.to - cs.from)
        onMoved: v => {
            const n = Math.round((cs.from + v * (cs.to - cs.from)) / cs.step) * cs.step
            if (Math.abs(n - cs.value) > 1e-6) Config.set(cs.section, cs.key, Number(n.toFixed(3)))
        }
    }
    Text {
        width: 44
        anchors.verticalCenter: parent.verticalCenter
        text: cs.format(cs.value)
        color: Theme.subtext
        horizontalAlignment: Text.AlignRight
        font { family: Theme.font; pixelSize: 12; features: { "tnum": 1 } }
    }
}
