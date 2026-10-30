import QtQuick

// Wi-Fi signal for the bar: a dot and two bands fanning up, lit up to the signal strength,
// the rest dimmed. strength < 0 = not connected (all dim).
Canvas {
    id: glyph
    property real strength: -1          // 0-1
    property color tone: Theme.text
    readonly property int level: strength < 0 ? 0 : strength > 0.66 ? 3 : strength > 0.33 ? 2 : 1

    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    width: 17; height: 13
    onLevelChanged: requestPaint()
    onToneChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const cx = width / 2, cy = height - 0.5
        const from = -Math.PI * 3 / 4, to = -Math.PI / 4
        // [inner radius, outer radius] for the dot and the two bands
        const bands = [[0, 4.2], [6, 8.6], [10.4, 13]]
        bands.forEach((b, i) => {
            ctx.fillStyle = i < level ? tone : Qt.alpha(tone, 0.28)
            ctx.beginPath()
            ctx.arc(cx, cy, b[1], from, to, false)
            if (b[0] > 0) ctx.arc(cx, cy, b[0], to, from, true)
            else ctx.lineTo(cx, cy)
            ctx.closePath()
            ctx.fill()
        })
    }
}
