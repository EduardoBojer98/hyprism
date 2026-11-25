.pragma library
// Screen snapping for Settings > Displays (Displays.qml): screens touch edge to edge and never overlap, like the
// display settings of other systems. Rects are logical pixels { x, y, w, h }. Tested by tests/display-snap.sh.

// Where a screen of `size` ({ w, h }) dropped at x,y goes: against a side of one of `rects`, sharing at least a
// stretch of edge (so the pointer can cross), overlapping none; along that edge it lines up with the other
// screen's ends or centre within `pull`. No other screens, or no free side: where it was dropped.
function snapPosition(size, x, y, rects, pull) {
    const w = size.w, h = size.h
    if (!rects.length) return { x: Math.round(x), y: Math.round(y) }
    const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v))
    const near = (v, targets) => {
        let best = v, d = Infinity
        for (const t of targets) { const dt = Math.abs(t - v); if (dt <= pull && dt < d) { best = t; d = dt } }
        return best
    }
    let best = null
    for (const c of rects) {
        const ky = Math.min(100, h, c.h), kx = Math.min(100, w, c.w)
        const ay = Math.round(clamp(near(y, [c.y, c.y + c.h - h, c.y + (c.h - h) / 2]), c.y - h + ky, c.y + c.h - ky))
        const ax = Math.round(clamp(near(x, [c.x, c.x + c.w - w, c.x + (c.w - w) / 2]), c.x - w + kx, c.x + c.w - kx))
        for (const p of [{ x: c.x + c.w, y: ay }, { x: c.x - w, y: ay }, { x: ax, y: c.y + c.h }, { x: ax, y: c.y - h }]) {
            if (rects.some(q => p.x < q.x + q.w && q.x < p.x + w && p.y < q.y + q.h && q.y < p.y + h)) continue
            const d = Math.hypot(p.x - x, p.y - y)
            if (!best || d < best.d) best = { x: p.x, y: p.y, d: d }
        }
    }
    return best ? { x: best.x, y: best.y } : { x: Math.round(x), y: Math.round(y) }
}

// rects: { name: { x, y, w, h } }. `anchor` stays put; every other screen, nearest first, moves the least it must
// to touch the ones already placed. Returns { name: { x, y } } for all of them.
function settle(rects, anchor) {
    const names = Object.keys(rects)
    if (!names.includes(anchor)) anchor = names[0]
    const out = {}
    if (!anchor) return out
    const mid = r => ({ x: r.x + r.w / 2, y: r.y + r.h / 2 }), ma = mid(rects[anchor])
    const dist = n => { const m = mid(rects[n]); return Math.hypot(m.x - ma.x, m.y - ma.y) }
    const placed = [Object.assign({}, rects[anchor])]
    out[anchor] = { x: rects[anchor].x, y: rects[anchor].y }
    for (const n of names.filter(n => n !== anchor).sort((p, q) => dist(p) - dist(q))) {
        const r = rects[n], p = snapPosition(r, r.x, r.y, placed, 0)
        out[n] = p
        placed.push({ x: p.x, y: p.y, w: r.w, h: r.h })
    }
    return out
}
