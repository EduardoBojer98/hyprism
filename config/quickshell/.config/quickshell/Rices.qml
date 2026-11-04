pragma Singleton
import Quickshell
import QtQuick

// The rices: each one is a whole desktop design, not a colour scheme (docs/DESIGN.md).
// Data only. Theme.qml turns the active rice into tokens every component reads; ThemeSync.qml carries
// it to Hyprland, hyprlock, GTK, Ghostty and the wallpaper. Switch: `rice NAME` or Settings > Rices.
//
// colour  ground (desktop/bar), surface (panels), raised (controls, hover), line, text, muted, faint,
//         accent, onAccent (text on an accent fill), accent2, ok / warn / err
// font    ui, display (clocks, greetings, big numbers), mono; size = body px
// shape   radius / radiusSmall px, line = panel border px; material: solid | glass
// bar     kind: text | rail | readout | pills | taskbar | poster | menubar | gnome | letterbox | island | corner | line | halo
//         edge: top | bottom | left | right; size px; ws: workspace indicator style
// launcher  placement + view + header (Launcher.qml draws them)
// notify  corner + kind (bubble, card, toast, paper, line, block, tag, subtitle)
// hypr    gaps in/out, border px, rounding, active/inactive border colours, shadow, blur, motion preset
// lock    hypr/lockscreens/<lock>.conf; term: ghostty theme; wall: scripts/rice-wallpaper design id
Singleton {
    readonly property var list: [
        {
            id: "pebble", name: "Pebble", about: "Soft and round: three floating pills, stretching dots, a floating dock, glass",
            dark: true,
            colour: { ground: "#16141f", surface: "#221f2e", raised: "#2d2a3b", line: "#3a3650", text: "#ece8f6", muted: "#b9b3cc", faint: "#7f7895",
                      accent: "#ff9e7a", onAccent: "#1a1220", accent2: "#9ad1c0", ok: "#7fdc9a", warn: "#ffd27a", err: "#ff6b8a" },
            font: { ui: "Outfit", display: "Outfit", mono: "JetBrainsMono Nerd Font", size: 14, displayWeight: Font.Medium },
            shape: { radius: 18, radiusSmall: 12, line: 1, material: "glass" },
            bar: { kind: "pills", edge: "top", size: 34, ws: "dots" },
            launcher: { placement: "center", view: "grid", header: "none", width: 620 },
            dock: true, notify: { corner: "top-right", kind: "bubble" },
            hypr: { gapsIn: 7, gapsOut: 14, border: 2, rounding: 18, active: ["ff9e7acc", "9ad1c0cc"], inactive: "3a365000",
                    shadow: "soft", blur: true, motion: "spring" },
            lock: "pebble", term: "Pebble", wall: "pebble"
        },
        {
            id: "monolith", name: "Monolith", about: "The desktop as a terminal: bottom text bar, a command strip, hard 2px frames",
            dark: true,
            colour: { ground: "#0b0c0a", surface: "#121411", raised: "#1c1f1a", line: "#2a2d27", text: "#d7ddcc", muted: "#8b9480", faint: "#5f6858",
                      accent: "#b6ff3b", onAccent: "#0b0c0a", accent2: "#ff5f2e", ok: "#5ad1c2", warn: "#ffb547", err: "#ff5f5f" },
            font: { ui: "JetBrainsMono Nerd Font", display: "JetBrainsMono Nerd Font", mono: "JetBrainsMono Nerd Font", size: 13, displayWeight: Font.Bold },
            shape: { radius: 0, radiusSmall: 0, line: 1, material: "solid" },
            bar: { kind: "text", edge: "bottom", size: 26, ws: "filled" },
            launcher: { placement: "strip", view: "inline", header: "none", width: 0 },
            dock: false, notify: { corner: "bottom-right", kind: "line" },
            hypr: { gapsIn: 1, gapsOut: 2, border: 2, rounding: 0, active: ["b6ff3bff"], inactive: "2a2d27ff", shadow: "none", blur: false, motion: "instant" },
            lock: "terminal", term: "Monolith", wall: "monolith"
        },
        {
            id: "console", name: "Console", about: "No bar: an amber readout along the top edge and corner brackets, all in mono",
            dark: true,
            colour: { ground: "#05080f", surface: "#0a101c", raised: "#141c2c", line: "#3a2e12", text: "#e9dcc0", muted: "#c19b52", faint: "#6d5a33",
                      accent: "#ffb000", onAccent: "#05080f", accent2: "#ff6a3d", ok: "#66d19e", warn: "#ff7a45", err: "#ff4d5e" },
            font: { ui: "Martian Mono", display: "Martian Mono", mono: "Martian Mono", size: 12, displayWeight: Font.Light },
            shape: { radius: 0, radiusSmall: 0, line: 1, material: "solid" },
            bar: { kind: "readout", edge: "top", size: 24, ws: "text" },
            launcher: { placement: "center", view: "list", header: "query", width: 680 },
            dock: false, notify: { corner: "top-right", kind: "tag" },
            hypr: { gapsIn: 4, gapsOut: 10, border: 1, rounding: 0, active: ["ffb000ff"], inactive: "1d1a12ff", shadow: "none", blur: false, motion: "crisp" },
            lock: "console", term: "Console", wall: "console"
        },
        {
            id: "workstation", name: "Workstation", about: "Familiar: a bottom taskbar with Start, search, running apps and a two-line clock",
            dark: true,
            colour: { ground: "#0f1419", surface: "#1a2028", raised: "#222a34", line: "#2a3340", text: "#e6edf3", muted: "#9aa6b2", faint: "#6b7785",
                      accent: "#3b82f6", onAccent: "#ffffff", accent2: "#60a5fa", ok: "#22c55e", warn: "#f59e0b", err: "#ef4444" },
            font: { ui: "IBM Plex Sans", display: "IBM Plex Sans", mono: "JetBrainsMono Nerd Font", size: 13, displayWeight: Font.Medium },
            shape: { radius: 8, radiusSmall: 6, line: 1, material: "solid" },
            bar: { kind: "taskbar", edge: "bottom", size: 46, ws: "small" },
            launcher: { placement: "corner", view: "start", header: "none", width: 560 },
            dock: false, notify: { corner: "bottom-right", kind: "toast" },
            hypr: { gapsIn: 3, gapsOut: 6, border: 1, rounding: 8, active: ["3b82f6ff"], inactive: "2a3340ff", shadow: "soft", blur: false, motion: "ease" },
            lock: "center", term: "Workstation", wall: "workstation"
        },
        {
            id: "poster", name: "Poster", about: "Loud and flat: huge workspace numbers, hard offset shadows, a half-screen launcher",
            dark: false,
            colour: { ground: "#141414", surface: "#f4f1ea", raised: "#e6e1d6", line: "#141414", text: "#141414", muted: "#4a4740", faint: "#7d786d",
                      accent: "#ff3b1f", onAccent: "#f4f1ea", accent2: "#2d5bff", ok: "#1a7f37", warn: "#b35c00", err: "#c4161c" },
            font: { ui: "Archivo", display: "Archivo Black", mono: "JetBrainsMono Nerd Font", size: 14, displayWeight: Font.Black },
            shape: { radius: 0, radiusSmall: 0, line: 3, material: "solid" },
            bar: { kind: "poster", edge: "top", size: 48, ws: "blocks" },
            launcher: { placement: "half", view: "list", header: "query", width: 0 },
            dock: false, notify: { corner: "bottom-left", kind: "block" },
            hypr: { gapsIn: 8, gapsOut: 16, border: 3, rounding: 0, active: ["f4f1eaff"], inactive: "3a3a3aff", shadow: "hard", blur: false, motion: "slam" },
            lock: "stacked", term: "Poster", wall: "poster"
        },
        {
            id: "glass", name: "Glass", about: "The classic: a translucent menu bar, a glass dock, rounded windows",
            dark: true,
            colour: { ground: "#141821", surface: "#1c1f28", raised: "#272b36", line: "#30343f", text: "#f3f4f8", muted: "#a7abb8", faint: "#6e7282",
                      accent: "#5b9cff", onAccent: "#ffffff", accent2: "#8f86ff", ok: "#63d17a", warn: "#f7c85b", err: "#ff5f57" },
            font: { ui: "IBM Plex Sans", display: "IBM Plex Sans", mono: "JetBrainsMono Nerd Font", size: 13, displayWeight: Font.Light },
            shape: { radius: 12, radiusSmall: 8, line: 1, material: "glass" },
            bar: { kind: "menubar", edge: "top", size: 30, ws: "numbers" },
            launcher: { placement: "center", view: "list", header: "none", width: 680 },
            dock: true, notify: { corner: "top-right", kind: "card" },
            hypr: { gapsIn: 5, gapsOut: 10, border: 1, rounding: 12, active: ["ffffff40"], inactive: "ffffff10", shadow: "soft", blur: true, motion: "ease" },
            lock: "glass", term: "Glass", wall: "glass"
        },
        {
            id: "canvas", name: "Canvas", about: "Classic GNOME manners: black top bar, centred clock, rounded quick settings",
            dark: true,
            colour: { ground: "#1d1d20", surface: "#2e2e32", raised: "#3d3d42", line: "#3a3a3e", text: "#ffffff", muted: "#c0c0c4", faint: "#8a8a90",
                      accent: "#3584e4", onAccent: "#ffffff", accent2: "#9141ac", ok: "#33d17a", warn: "#f6d32d", err: "#e01b24" },
            font: { ui: "Cantarell", display: "Cantarell", mono: "JetBrainsMono Nerd Font", size: 14, displayWeight: Font.Bold },
            shape: { radius: 14, radiusSmall: 10, line: 0, material: "solid" },
            bar: { kind: "gnome", edge: "top", size: 30, ws: "dots" },
            launcher: { placement: "fullscreen", view: "grid", header: "none", width: 760 },
            dock: false, notify: { corner: "top-center", kind: "card" },
            hypr: { gapsIn: 4, gapsOut: 8, border: 0, rounding: 14, active: ["3584e4ff"], inactive: "00000000", shadow: "soft", blur: false, motion: "ease" },
            lock: "center", term: "Canvas", wall: "canvas"
        },
        {
            id: "atlas", name: "Atlas", about: "Swiss discipline: a black rail on the right, square blocks, heavy numerals, signal red",
            dark: false,
            colour: { ground: "#f2f2f0", surface: "#ffffff", raised: "#e8e8e5", line: "#111111", text: "#111111", muted: "#4b4b4b", faint: "#8a8a8a",
                      accent: "#e30613", onAccent: "#ffffff", accent2: "#111111", ok: "#0a7d3b", warn: "#a35b00", err: "#a3001b" },
            font: { ui: "Archivo", display: "Archivo", mono: "JetBrainsMono Nerd Font", size: 14, displayWeight: Font.ExtraBold },
            shape: { radius: 0, radiusSmall: 0, line: 2, material: "solid" },
            bar: { kind: "rail", edge: "right", size: 72, ws: "squares" },
            launcher: { placement: "column", view: "list", header: "query", width: 520 },
            dock: false, notify: { corner: "top-right", kind: "block" },
            hypr: { gapsIn: 8, gapsOut: 16, border: 2, rounding: 0, active: ["111111ff"], inactive: "c8c8c4ff", shadow: "none", blur: false, motion: "snappy" },
            lock: "stacked", term: "Atlas", wall: "atlas"
        },
        {
            id: "noir", name: "Noir", about: "The screen as a film: letterbox bands, serif credits, notifications as subtitles",
            dark: true,
            colour: { ground: "#0d0d0d", surface: "#121110", raised: "#1c1a18", line: "#2e2a26", text: "#e9e4da", muted: "#b8b0a2", faint: "#77705f",
                      accent: "#f2d48a", onAccent: "#0d0d0d", accent2: "#c95a3a", ok: "#8fbf8a", warn: "#e07a4a", err: "#e05a5a" },
            font: { ui: "IBM Plex Sans", display: "Fraunces", mono: "JetBrainsMono Nerd Font", size: 13, displayWeight: Font.Light },
            shape: { radius: 0, radiusSmall: 0, line: 1, material: "solid" },
            bar: { kind: "letterbox", edge: "top", size: 40, ws: "roman" },
            launcher: { placement: "fullscreen", view: "list", header: "query", width: 640 },
            dock: false, notify: { corner: "bottom-center", kind: "subtitle" },
            hypr: { gapsIn: 6, gapsOut: 12, border: 1, rounding: 0, active: ["f2d48a99"], inactive: "2e2a26ff", shadow: "none", blur: false, motion: "fade" },
            lock: "noir", term: "Noir", wall: "noir"
        },
        {
            id: "garden", name: "Garden", about: "One island does everything: apps, workspaces and the clock in a pale capsule",
            dark: true,
            colour: { ground: "#141c16", surface: "#1d2a20", raised: "#263529", line: "#2f4234", text: "#eef2e6", muted: "#b5c2ab", faint: "#7d8b74",
                      accent: "#9fd18b", onAccent: "#18221a", accent2: "#e8efe0", ok: "#7fd1b0", warn: "#e8b85a", err: "#ff7a6b" },
            font: { ui: "Outfit", display: "Outfit", mono: "JetBrainsMono Nerd Font", size: 14, displayWeight: Font.DemiBold },
            shape: { radius: 14, radiusSmall: 10, line: 1, material: "solid" },
            bar: { kind: "island", edge: "bottom", size: 56, ws: "tiles" },
            launcher: { placement: "island", view: "grid", header: "none", width: 600 },
            dock: false, notify: { corner: "top-right", kind: "card" },
            hypr: { gapsIn: 6, gapsOut: 12, border: 1, rounding: 14, active: ["9fd18bff"], inactive: "2f4234ff", shadow: "soft", blur: false, motion: "spring" },
            lock: "minimal", term: "Garden", wall: "garden"
        },
        {
            id: "zen", name: "Zen", about: "Almost nothing: no bar, a small clock and dots in the corner, wide calm gaps",
            dark: true,
            colour: { ground: "#111113", surface: "#19191c", raised: "#232327", line: "#26262a", text: "#e8e8ea", muted: "#a0a0a6", faint: "#68686e",
                      accent: "#e8e8ea", onAccent: "#111113", accent2: "#a0a0a6", ok: "#7bc89a", warn: "#e0b45e", err: "#e57373" },
            font: { ui: "IBM Plex Sans", display: "IBM Plex Sans", mono: "JetBrainsMono Nerd Font", size: 13, displayWeight: Font.Light },
            shape: { radius: 10, radiusSmall: 6, line: 0, material: "solid" },
            bar: { kind: "corner", edge: "bottom", size: 0, ws: "dots" },
            launcher: { placement: "center", view: "list", header: "none", width: 520 },
            dock: false, notify: { corner: "top-center", kind: "line" },
            hypr: { gapsIn: 10, gapsOut: 28, border: 0, rounding: 10, active: ["e8e8ea00"], inactive: "00000000", shadow: "none", blur: false, motion: "ease" },
            lock: "minimal", term: "Zen", wall: "zen"
        },
        {
            id: "mist", name: "Mist", about: "Light and monochrome: one thin top line with workspace ticks and the time",
            dark: false,
            colour: { ground: "#f3f3f1", surface: "#fafaf9", raised: "#ececea", line: "#e2e2df", text: "#1a1a1a", muted: "#5c5c58", faint: "#9a9a95",
                      accent: "#1a1a1a", onAccent: "#fafaf9", accent2: "#5c5c58", ok: "#2f7a4f", warn: "#97610b", err: "#b3261e" },
            font: { ui: "IBM Plex Sans", display: "IBM Plex Sans", mono: "JetBrainsMono Nerd Font", size: 13, displayWeight: Font.Normal },
            shape: { radius: 6, radiusSmall: 4, line: 1, material: "solid" },
            bar: { kind: "line", edge: "top", size: 26, ws: "ticks" },
            launcher: { placement: "center", view: "list", header: "none", width: 560 },
            dock: false, notify: { corner: "top-right", kind: "card" },
            hypr: { gapsIn: 6, gapsOut: 12, border: 1, rounding: 6, active: ["1a1a1aff"], inactive: "e2e2dfff", shadow: "none", blur: false, motion: "ease" },
            lock: "center", term: "Mist", wall: "mist"
        },
        {
            id: "halo", name: "Halo", about: "One small floating pill at the bottom: workspaces and the time, the rest on demand",
            dark: true,
            colour: { ground: "#0e0f12", surface: "#17181c", raised: "#212329", line: "#2a2c33", text: "#eceef2", muted: "#a3a7b1", faint: "#6a6e78",
                      accent: "#8ab4ff", onAccent: "#0e0f12", accent2: "#c6d6ff", ok: "#7fd1a0", warn: "#e8c06a", err: "#f07a7a" },
            font: { ui: "Outfit", display: "Outfit", mono: "JetBrainsMono Nerd Font", size: 14, displayWeight: Font.Light },
            shape: { radius: 16, radiusSmall: 10, line: 1, material: "solid" },
            bar: { kind: "halo", edge: "bottom", size: 38, ws: "dots" },
            launcher: { placement: "center", view: "list", header: "none", width: 560 },
            dock: false, notify: { corner: "top-center", kind: "card" },
            hypr: { gapsIn: 6, gapsOut: 14, border: 1, rounding: 16, active: ["8ab4ff99"], inactive: "2a2c3300", shadow: "soft", blur: false, motion: "spring" },
            lock: "minimal", term: "Halo", wall: "halo"
        }
    ]
    readonly property var ids: list.map(r => r.id)
    readonly property int wallVersion: 4   // = VERSION in scripts/rice-wallpaper (the picture's file name)
    function get(id) { return list.find(r => r.id === id) ?? list[0] }

    // Your adjustments to a rice (Settings > Rices > Adjust), saved per rice in
    // Config.appearance.custom[id] and laid over its defaults. Each key and what it changes:
    readonly property var adjustable: ({
        accent:   "colour.accent (and the window border)",   accent2: "colour.accent2",
        radius:   "shape.radius, radiusSmall and window rounding",
        gapsIn:   "hypr.gapsIn",   gapsOut: "hypr.gapsOut",   border: "hypr.border (window frame px)",
        barSize:  "bar.size",      font: "font.ui",          size: "font.size (body px)",
        motion:   "hypr.motion",   shadow: "hypr.shadow",     blur: "hypr.blur"
    })
    function resolve(id, custom) {
        const r = JSON.parse(JSON.stringify(get(id)))
        // text on an accent fill must reach WCAG AA (4.5:1); if the rice's own choice doesn't, take the better of dark/light
        if (contrast(r.colour.onAccent, r.colour.accent) < 4.5) r.colour.onAccent = textOn(r.colour.accent, r.colour)
        const o = Object.assign({}, (custom ?? {})[r.id] ?? {})
        const ok = v => v !== undefined && v !== null && v !== ""
        const hexOk = v => typeof v === "string" && /^#[0-9a-fA-F]{6}$/.test(v)
        const num = (v, lo, hi) => typeof v === "number" && v >= lo && v <= hi
        for (const [k, test] of [["accent", hexOk], ["accent2", hexOk], ["radius", v => num(v, 0, 40)], ["gapsIn", v => num(v, 0, 60)],
                                 ["gapsOut", v => num(v, 0, 80)], ["border", v => num(v, 0, 10)], ["barSize", v => num(v, 16, 96)],
                                 ["size", v => num(v, 9, 24)], ["font", v => typeof v === "string" && /^[^'\n#]+$/.test(v)],
                                 ["motion", v => ["instant", "crisp", "snappy", "slam", "ease", "spring", "fade"].includes(v)],
                                 ["shadow", v => ["none", "soft", "paper", "hard"].includes(v)], ["blur", v => typeof v === "boolean"]])
            if (ok(o[k]) && !test(o[k])) delete o[k]   // a bad value is ignored, the rice's own stays
        if (ok(o.accent)) {
            r.colour.accent = o.accent
            r.colour.onAccent = textOn(o.accent, r.colour)
            const alpha = r.hypr.active[0].length === 8 ? r.hypr.active[0].slice(6) : "ff"
            r.hypr.active = [o.accent.slice(1, 7) + alpha].concat(r.hypr.active.slice(1))
        }
        if (ok(o.accent2)) {
            r.colour.accent2 = o.accent2
            if (r.hypr.active.length > 1) r.hypr.active[1] = o.accent2.slice(1, 7) + r.hypr.active[1].slice(6)
        }
        if (ok(o.radius)) { r.shape.radius = o.radius; r.shape.radiusSmall = Math.round(o.radius * 0.65); r.hypr.rounding = o.radius }
        if (ok(o.gapsIn)) r.hypr.gapsIn = o.gapsIn
        if (ok(o.gapsOut)) r.hypr.gapsOut = o.gapsOut
        if (ok(o.border)) r.hypr.border = o.border
        if (ok(o.barSize) && r.bar.size > 0) r.bar.size = o.barSize
        if (ok(o.font)) r.font.ui = o.font
        if (ok(o.size)) r.font.size = o.size
        if (ok(o.motion)) r.hypr.motion = o.motion
        if (ok(o.shadow)) r.hypr.shadow = o.shadow
        if (ok(o.blur)) r.hypr.blur = o.blur
        return r
    }
    // WCAG relative luminance and contrast ratio
    function luminance(hex) {
        const c = Qt.color(hex), f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b)
    }
    function contrast(a, b) { const x = luminance(a), y = luminance(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05) }
    // dark or light text on a fill, whichever contrasts more: the rice's dark ground if it's dark, else near-black
    function textOn(hex, colour) {
        const dark = Qt.color(colour.ground).hslLightness < 0.3 ? colour.ground : "#141414"
        return contrast(dark, hex) >= contrast("#ffffff", hex) ? dark : "#ffffff"
    }
}
