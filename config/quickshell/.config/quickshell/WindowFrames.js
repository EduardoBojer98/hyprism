.pragma library
// The focused window's frame, by style (Config.windows.border): the colours Hyprland draws, as "rrggbbaa".
// Used by ThemeSync.qml (sends them to hypr/modules/look.lua) and Settings > Windows (the previews), so a
// preview is the frame you get.
//   accent    the accent             gradient  accent to the second accent, at your angle
//   neon      the accent, with a glow of the same colour around the focused window (ThemeSync: glow)
//   mono      the text colour         rainbow / sunset / ocean   multi-stop palettes, tuned to light or dark
//   custom    your two or three colours (Config.windows.borderColors)
// t: { accent, accent2, text: "#rrggbb", light: bool, own: the theme's hypr.active list, custom: ["#rrggbb", …] }
var styles = ["theme", "accent", "gradient", "neon", "mono", "rainbow", "sunset", "ocean", "custom"]
var names = ["Theme's", "Accent", "Gradient", "Neon", "Mono", "Rainbow", "Sunset", "Ocean", "Your colours"]

function hexOk(c) { return /^#[0-9a-fA-F]{6}$/.test(String(c)) }
function six(c) { return hexOk(c) ? String(c).slice(1).toLowerCase() : "808080" }

// h 0..360, s and l 0..1 -> "rrggbb"
function hsl(h, s, l) {
    const k = n => (n + h / 30) % 12, a = s * Math.min(l, 1 - l)
    const f = n => Math.round(255 * (l - a * Math.max(-1, Math.min(k(n) - 3, 9 - k(n), 1))))
    return [0, 8, 4].map(n => f(n).toString(16).padStart(2, "0")).join("")
}
// hues spread over a palette; muted so it reads as a finish, not neon. Deeper on light halves so it holds on paper
function wheel(hues, s, light) { return hues.map(d => hsl(d, s, light ? 0.46 : 0.62) + "ff") }

function colours(style, t) {
    const a = six(t.accent) + "ff"
    if (style === "accent" || style === "neon") return [a]
    if (style === "gradient") return [a, six(t.accent2) + "ff"]
    if (style === "mono") return [six(t.text) + "ff"]
    if (style === "rainbow") {
        // the first stop repeats at the end so the turning loop has no seam
        const stops = wheel([0, 40, 95, 165, 215, 270, 320], 0.58, t.light)
        return stops.concat([stops[0]])
    }
    if (style === "sunset") return wheel([40, 12, 340, 290], 0.72, t.light)
    if (style === "ocean") return wheel([165, 190, 215, 240], 0.6, t.light)
    if (style === "custom") {
        const mine = Array.from(t.custom ?? []).filter(hexOk).slice(0, 3).map(c => six(c) + "ff")
        return mine.length ? mine : [a]
    }
    // the theme's own: its hypr.active list, checked; the accent when it has none
    const own = Array.from(t.own ?? []).filter(c => /^[0-9a-fA-F]{8}$/.test(String(c)))
    return own.length ? own : [a]
}

// for Qt (previews): "rrggbbaa" -> "#aarrggbb"
function qt(c) { return "#" + c.slice(6, 8) + c.slice(0, 6) }
