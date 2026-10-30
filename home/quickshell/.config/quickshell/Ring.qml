import QtQuick

// Ring gauge for a live value, with the number inside. Colour stays white until the value
// crosses warn (amber) or alert (red).
Item {
    id: ring

    property real value: NaN
    property real min: 30
    property real max: 100
    property real warn: 80
    property real alert: 90
    property real shown: value
    Behavior on shown { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
    readonly property color tone: value >= alert ? Theme.red : value >= warn ? Theme.yellow : Theme.text

    implicitWidth: 32
    implicitHeight: 32

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            const r = width / 2 - 2
            const t = isNaN(ring.shown) ? 0 : Math.max(0, Math.min(1, (ring.shown - ring.min) / (ring.max - ring.min)))
            ctx.reset()
            ctx.lineWidth = 2.5
            ctx.lineCap = "round"
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.14)
            ctx.beginPath(); ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI); ctx.stroke()
            ctx.strokeStyle = ring.tone
            ctx.beginPath(); ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + t * 2 * Math.PI); ctx.stroke()
        }
    }
    onShownChanged: canvas.requestPaint()
    onToneChanged: canvas.requestPaint()

    Text {
        anchors.centerIn: parent
        text: isNaN(ring.value) ? "–" : Math.round(ring.value) + "°"
        color: ring.tone
        font { family: Theme.font; pixelSize: 11; weight: Font.DemiBold; features: { "tnum": 1 } }
    }
}
