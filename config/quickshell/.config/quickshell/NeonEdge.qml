import QtQuick
import QtQuick.Effects

// A neon outline for any surface: a gradient ring from the theme's accent to its second accent,
// with a soft glow in the accent (docs/DESIGN.md, "Neon themes"). Fills its parent; give it the
// parent's corner radius. Per-corner radii for shapes that are square on a screen edge (bar tabs).
//   NeonEdge { radius: parent.radius }
Canvas {
    id: edge
    property real radius: 0
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
    property real line: 1.5
    property bool glow: true
    property real angle: 45           // gradient direction, like the window border

    anchors.fill: parent

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const h = line / 2, w = width - line, ht = height - line
        if (w <= 0 || ht <= 0) return
        const lim = r => Math.max(0, Math.min(r - h, w / 2, ht / 2))
        const tl = lim(topLeftRadius), tr = lim(topRightRadius), br = lim(bottomRightRadius), bl = lim(bottomLeftRadius)
        const a = angle * Math.PI / 180, cx = width / 2, cy = height / 2, d = Math.max(width, height) / 2
        const g = ctx.createLinearGradient(cx - Math.cos(a) * d, cy - Math.sin(a) * d, cx + Math.cos(a) * d, cy + Math.sin(a) * d)
        g.addColorStop(0, String(Theme.accent))
        g.addColorStop(1, String(Theme.accent2))
        ctx.strokeStyle = g
        ctx.lineWidth = line
        ctx.beginPath()
        ctx.moveTo(h + tl, h)
        ctx.arcTo(h + w, h, h + w, h + ht, tr)
        ctx.arcTo(h + w, h + ht, h, h + ht, br)
        ctx.arcTo(h, h + ht, h, h, bl)
        ctx.arcTo(h, h, h + w, h, tl)
        ctx.closePath()
        ctx.stroke()
    }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onTopLeftRadiusChanged: requestPaint()
    onBottomLeftRadiusChanged: requestPaint()
    Connections {
        target: Theme
        function onAccentChanged() { edge.requestPaint() }
        function onAccent2Changed() { edge.requestPaint() }
    }

    layer.enabled: glow && visible
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Theme.accent
        shadowOpacity: 0.75
        shadowBlur: 0.55
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }
}
