pragma Singleton
import Quickshell
import QtQuick

// The themes: each one is a whole desktop design, not a colour scheme (docs/DESIGN.md).
// Data only. Theme.qml turns the active theme (and your Settings) into tokens every component reads;
// ThemeSync.qml carries it to Hyprland, hyprlock, GTK, Ghostty and the wallpaper. Switch: `theme NAME`.
//
// colour   ground (desktop/bar), surface (panels), raised (controls, hover), line, text, muted, faint,
//          accent, onAccent (text on an accent fill), accent2, ok / warn / err
// font     ui, display (clocks, big numbers), mono; size = body px
// shape    radius / radiusSmall px, line = panel border px; material: solid | glass
// bar      the theme's own bar; Settings > Menu Bar can override edge, size, floating and the items.
//          edge top|bottom|left|right, size px, floating (away from the edges), segmented (one pill per
//          section), fill glass|surface|ground|ink|none, line (edge line px), voice icons|mixed (icon + value)|words|caps,
//          mono (status in the mono face), ws (workspace style, BarWs.qml), clock plain|accent|display,
//          decor (brackets), sep (a rule between items), start / center / end: the items (BarWidget.qml ids)
// dock     edge (the theme's place for it; the same edge as the bar puts it inside the bar),
//          shape pill|tile|block, hover lift|grow|plate, mark line|dot|bar, fill glass|surface|ink
// popup    depth soft (blurred shadow) | hard (offset block shadow) | glow (accent haze) | none (frame only);
//          decor brackets (accent corner marks on every panel) | topline (an accent line along the top);
//          tiles solid (Control Center toggles that are on: an accent block) | wash (an accent tint)
// motion   how panels open: enter / exit ms, curve (cubic bezier), travel px from the trigger side,
//          scale (start size), press (scale while a button is held). Settings > Themes > Animations
//          can reduce it (fade only) or turn it off.
// launcher placement + view (home: suggestions first) + header (query: the query set large) + select (wash: a tint,
//          inverse: a solid accent row) + prompt (a typed prompt instead of the lens); notify corner + kind
// hypr     gaps in/out, border px, rounding, active/inactive border colours, shadow, blur, motion preset
// lock     clock style + align (ThemeSync writes the hyprlock layout); term: Ghostty theme; wall: theme-wallpaper id
Singleton {
    // the six shipped themes, then your own (Settings > Appearance > Theme builder)
    readonly property var list: builtIn.concat(userList)
    readonly property var builtIn: [
        {
            id: "pebble", name: "Pebble", about: "Soft and round: floating glass pills, stretching dots, a pill dock that lifts its icons",
            dark: true,
            colour: { ground: "#16141f", surface: "#221f2e", raised: "#2d2a3b", line: "#3a3650", text: "#ece8f6", muted: "#b9b3cc", faint: "#7f7895",
                      accent: "#ff9e7a", onAccent: "#1a1220", accent2: "#9ad1c0", ok: "#7fdc9a", warn: "#ffd27a", err: "#ff6b8a" },
            font: { ui: "Outfit", display: "Outfit", mono: "JetBrainsMono Nerd Font", size: 14, displayWeight: Font.Medium },
            shape: { radius: 18, radiusSmall: 12, line: 1, material: "glass" },
            bar: { edge: "top", size: 36, floating: true, segmented: true, fill: "glass", line: 0, voice: "icons", mono: false, ws: "dots", clock: "plain", decor: "", sep: false,
                   start: ["launcher", "workspaces"], center: ["clock"], end: ["media", "tray", "keyboard", "notifications", "status"] },
            dock: { edge: "bottom", shape: "pill", hover: "lift", mark: "line", fill: "glass" },
            popup: { depth: "soft", decor: "", tiles: "solid" },
            motion: { enter: 240, exit: 150, curve: [0.3, 1.25, 0.5, 1], travel: 10, scale: 0.94, press: 0.95 },
            launcher: { placement: "center", view: "home", header: "none", width: 640, select: "wash", prompt: "" },
            notify: { corner: "top-right", kind: "bubble" },
            hypr: { gapsIn: 7, gapsOut: 14, border: 2, rounding: 18, active: ["ff9e7acc", "9ad1c0cc"], inactive: "3a365000",
                    shadow: "soft", blur: true, motion: "spring" },
            lock: { clock: "big", align: "center" }, term: "Pebble", wall: "pebble"
        },
        {
            id: "monolith", name: "Monolith", about: "The desktop as tmux: one status line with your apps, icon + value readouts, an inverse lime clock, panels like focused panes",
            dark: true,
            colour: { ground: "#0b0c0a", surface: "#11130f", raised: "#1b1e18", line: "#30352b", text: "#d7ddcc", muted: "#8b9480", faint: "#5f6858",
                      accent: "#b6ff3b", onAccent: "#0b0c0a", accent2: "#ff5f2e", ok: "#5ad1c2", warn: "#ffb547", err: "#ff5f5f" },
            font: { ui: "JetBrainsMono Nerd Font", display: "JetBrainsMono Nerd Font", mono: "JetBrainsMono Nerd Font", size: 13, displayWeight: Font.Bold },
            shape: { radius: 0, radiusSmall: 0, line: 1, material: "solid" },
            bar: { edge: "bottom", size: 28, floating: false, segmented: false, fill: "surface", line: 1, voice: "mixed", mono: true, ws: "filled", clock: "block", decor: "", sep: true,
                   start: ["workspaces", "apps"], center: [], end: ["media", "tray", "keyboard", "cpu", "memory", "status", "notifications", "clock"] },
            dock: { edge: "bottom", shape: "block", hover: "plate", mark: "bar", fill: "surface" },
            popup: { depth: "none", decor: "topline", tiles: "solid" },
            motion: { enter: 90, exit: 60, curve: [0.2, 0, 0, 1], travel: 0, scale: 1, press: 1 },
            launcher: { placement: "strip", view: "inline", header: "none", width: 0, select: "inverse", prompt: "❯" },
            notify: { corner: "bottom-right", kind: "line" },
            hypr: { gapsIn: 1, gapsOut: 2, border: 2, rounding: 0, active: ["b6ff3bff"], inactive: "2a2d27ff", shadow: "none", blur: false, motion: "instant" },
            lock: { clock: "terminal", align: "left" }, term: "Monolith", wall: "monolith"
        },
        {
            id: "console", name: "Console", about: "An amber HUD: a framed caps readout, corner brackets on every panel, a phosphor glow, panels that snap on",
            dark: true,
            colour: { ground: "#05080f", surface: "#0a0f1a", raised: "#131a28", line: "#5a4418", text: "#e9dcc0", muted: "#c19b52", faint: "#6d5a33",
                      accent: "#ffb000", onAccent: "#05080f", accent2: "#ff6a3d", ok: "#66d19e", warn: "#ff7a45", err: "#ff4d5e" },
            font: { ui: "Martian Mono", display: "Martian Mono", mono: "Martian Mono", size: 12, displayWeight: Font.Light },
            shape: { radius: 0, radiusSmall: 0, line: 1, material: "solid" },
            bar: { edge: "top", size: 30, floating: false, segmented: false, fill: "ground", line: 1, voice: "mixed", mono: true, caps: true, ws: "text", clock: "accent", decor: "brackets", sep: true,
                   start: ["launcher", "workspaces", "window"], center: ["clock"], end: ["cpu", "memory", "status", "keyboard", "tray", "notifications"] },
            dock: { edge: "bottom", shape: "block", hover: "plate", mark: "bar", fill: "surface" },
            popup: { depth: "glow", decor: "brackets", tiles: "solid" },
            motion: { enter: 140, exit: 80, curve: [0.15, 0, 0.1, 1], travel: 4, scale: 0.98, press: 0.98 },
            launcher: { placement: "center", view: "home", header: "query", width: 700, select: "inverse", prompt: "▸" },
            notify: { corner: "top-right", kind: "tag" },
            hypr: { gapsIn: 4, gapsOut: 10, border: 1, rounding: 0, active: ["ffb000ff"], inactive: "1d1a12ff", shadow: "none", blur: false, motion: "crisp" },
            lock: { clock: "readout", align: "center" }, term: "Console", wall: "console"
        },
        {
            id: "poster", name: "Poster", about: "Loud and flat: a paper bar, huge workspace numbers, hard offset shadows, panels that slam in",
            dark: false,
            colour: { ground: "#141414", surface: "#f4f1ea", raised: "#e6e1d6", line: "#141414", text: "#141414", muted: "#4a4740", faint: "#7d786d",
                      accent: "#ff3b1f", onAccent: "#f4f1ea", accent2: "#2d5bff", ok: "#1a7f37", warn: "#b35c00", err: "#c4161c" },
            font: { ui: "Archivo", display: "Archivo Black", mono: "JetBrainsMono Nerd Font", size: 14, displayWeight: Font.Black },
            shape: { radius: 0, radiusSmall: 0, line: 3, material: "solid" },
            bar: { edge: "top", size: 52, floating: false, segmented: false, fill: "surface", line: 3, voice: "icons", mono: false, ws: "blocks", clock: "display", decor: "", sep: false,
                   start: ["workspaces", "window"], center: [], end: ["media", "tray", "keyboard", "status", "notifications", "clock"] },
            dock: { edge: "bottom", shape: "block", hover: "lift", mark: "bar", fill: "surface" },
            popup: { depth: "hard", decor: "", tiles: "solid" },
            motion: { enter: 200, exit: 110, curve: [0.16, 1, 0.3, 1], travel: 28, scale: 1, press: 0.96 },
            launcher: { placement: "half", view: "home", header: "query", width: 0, select: "inverse", prompt: "" },
            notify: { corner: "bottom-left", kind: "block" },
            hypr: { gapsIn: 8, gapsOut: 16, border: 3, rounding: 0, active: ["f4f1eaff"], inactive: "3a3a3aff", shadow: "hard", blur: false, motion: "slam" },
            lock: { clock: "stacked", align: "left" }, term: "Poster", wall: "poster"
        },
        {
            id: "glass", name: "Glass", about: "Liquid glass: a floating glass bar, rimmed panels with soft depth, an electric blue to violet glow on windows",
            dark: true,
            colour: { ground: "#0f131c", surface: "#1a1f2b", raised: "#262c3a", line: "#323a4c", text: "#f4f6fb", muted: "#a9b0c2", faint: "#6f7891",
                      accent: "#5b9cff", onAccent: "#ffffff", accent2: "#8f86ff", ok: "#63d17a", warn: "#f7c85b", err: "#ff5f57" },
            font: { ui: "IBM Plex Sans", display: "IBM Plex Sans", mono: "JetBrainsMono Nerd Font", size: 13, displayWeight: Font.Light },
            shape: { radius: 16, radiusSmall: 10, line: 1, material: "glass" },
            bar: { edge: "top", size: 36, floating: true, segmented: false, fill: "glass", line: 0, voice: "icons", mono: false, ws: "numbers", clock: "plain", decor: "", sep: false,
                   start: ["launcher", "workspaces", "window"], center: ["clock"], end: ["media", "tray", "keyboard", "notifications", "status"] },
            dock: { edge: "bottom", shape: "tile", hover: "grow", mark: "dot", fill: "glass" },
            popup: { depth: "soft", decor: "", tiles: "wash" },
            motion: { enter: 220, exit: 140, curve: [0.23, 1, 0.32, 1], travel: 6, scale: 0.97, press: 0.97 },
            launcher: { placement: "center", view: "home", header: "none", width: 680, select: "wash", prompt: "" },
            notify: { corner: "top-right", kind: "card" },
            hypr: { gapsIn: 6, gapsOut: 12, border: 2, rounding: 16, active: ["5b9cffdd", "8f86ffdd"], inactive: "ffffff14", shadow: "soft", blur: true, motion: "ease" },
            lock: { clock: "big", align: "top" }, term: "Glass", wall: "glass"
        },
        {
            id: "atlas", name: "Atlas", about: "Swiss discipline: a black strip on top, heavy numerals, red squares, a black dock, everything on the grid",
            dark: false,
            colour: { ground: "#f2f2f0", surface: "#ffffff", raised: "#e8e8e5", line: "#111111", text: "#111111", muted: "#4b4b4b", faint: "#8a8a8a",
                      accent: "#e30613", onAccent: "#ffffff", accent2: "#111111", ok: "#0a7d3b", warn: "#a35b00", err: "#a3001b" },
            font: { ui: "Archivo", display: "Archivo", mono: "JetBrainsMono Nerd Font", size: 14, displayWeight: Font.ExtraBold },
            shape: { radius: 0, radiusSmall: 0, line: 2, material: "solid" },
            bar: { edge: "top", size: 44, floating: false, segmented: false, fill: "ink", line: 0, voice: "icons", mono: false, ws: "squares", clock: "display", decor: "", sep: false,
                   start: ["clock", "workspaces", "window"], center: [], end: ["media", "tray", "notifications", "keyboard", "status", "date"] },
            dock: { edge: "bottom", shape: "block", hover: "plate", mark: "bar", fill: "ink" },
            popup: { depth: "none", decor: "", tiles: "solid" },
            motion: { enter: 160, exit: 100, curve: [0.23, 1, 0.32, 1], travel: 14, scale: 1, press: 0.97 },
            launcher: { placement: "center", view: "home", header: "query", width: 640, select: "inverse", prompt: "" },
            notify: { corner: "top-right", kind: "block" },
            hypr: { gapsIn: 8, gapsOut: 16, border: 2, rounding: 0, active: ["111111ff"], inactive: "c8c8c4ff", shadow: "none", blur: false, motion: "snappy" },
            lock: { clock: "stacked", align: "left" }, term: "Atlas", wall: "atlas"
        }
    ]
    readonly property var ids: list.map(r => r.id)

    // Your own themes: Config.appearance.userThemes = { "custom-<name>": { name, base: "<theme id>", <any part of a
    // theme, e.g. colour: { accent: "#..." }, bar: { edge: "bottom" }> } }. Each is its base theme with your parts laid
    // over it; a part with the wrong type or a bad colour is ignored, so a hand edit can't break the desktop.
    readonly property var userList: Object.entries(Config.appearance.userThemes ?? {}).map(([id, u]) => makeUser(id, u)).filter(t => t)
    function makeUser(id, u) {
        if (!/^custom-[a-z0-9-]{1,40}$/.test(id) || typeof u !== "object" || !u) return null
        const base = builtIn.find(b => b.id === u.base) ?? builtIn[0]
        const t = merge(JSON.parse(JSON.stringify(base)), u)
        t.id = id
        t.name = typeof u.name === "string" && u.name.trim() ? u.name.trim().slice(0, 32) : "My theme"
        t.about = "Your own theme, made from " + base.name
        t.base = base.id
        t.user = true
        return t
    }
    function merge(into, over) {
        for (const k of Object.keys(over ?? {})) {
            if (["id", "name", "about", "base", "user"].includes(k)) continue
            const b = into[k], v = over[k]
            if (b === undefined || v === null || v === undefined) continue
            if (Array.isArray(b)) {
                if (Array.isArray(v) && v.every(x => typeof x === typeof (b[0] ?? x))) into[k] = v
            } else if (typeof b === "object") {
                if (typeof v === "object" && !Array.isArray(v)) merge(b, v)
            } else if (typeof v === typeof b) {
                if (typeof b === "string" && /^#[0-9a-fA-F]{6}$/.test(b) && !/^#[0-9a-fA-F]{6}$/.test(v)) continue   // colours stay colours
                into[k] = v
            }
        }
        return into
    }

    // every bar item (BarWidget.qml), in the order Settings > Menu Bar offers them
    readonly property var barItems: [
        { id: "apps",          name: "Apps (dock)",        glyph: "\u{F0A1F}" },
        { id: "launcher",      name: "Apps button",        glyph: "\u{F003B}" },
        { id: "workspaces",    name: "Workspaces",         glyph: "\u{F0570}" },
        { id: "window",        name: "Active window",      glyph: "\u{F05AF}" },
        { id: "clock",         name: "Clock",              glyph: "\u{F0954}" },
        { id: "date",          name: "Date",               glyph: "\u{F00ED}" },
        { id: "media",         name: "Media player",       glyph: "\u{F075A}" },
        { id: "tray",          name: "System tray",        glyph: "\u{F0D5E}" },
        { id: "keyboard",      name: "Keyboard layout",    glyph: "\u{F030C}" },
        { id: "notifications", name: "Notifications",      glyph: "\u{F009C}" },
        { id: "status",        name: "Quick settings",     glyph: "\u{F0493}" },
        { id: "network",       name: "Network",            glyph: "\u{F05A9}" },
        { id: "bluetooth",     name: "Bluetooth",          glyph: "\u{F00AF}" },
        { id: "volume",        name: "Volume",             glyph: "\u{F057E}" },
        { id: "brightness",    name: "Brightness",         glyph: "\u{F00DF}" },
        { id: "battery",       name: "Battery",            glyph: "\u{F0079}" },
        { id: "power-profile", name: "Power profile",      glyph: "\u{F0E0E}" },
        { id: "cpu",           name: "CPU usage",          glyph: "\u{F0EE0}" },
        { id: "memory",        name: "Memory usage",       glyph: "\u{F035B}" },
        { id: "gpu",           name: "GPU usage",          glyph: "\u{F08AE}" },
        { id: "recording",     name: "Recording",          glyph: "\u{F044A}" },
        { id: "power",         name: "Power menu",         glyph: "\u{F0425}" }
    ]
    function barItem(id) { return barItems.find(i => i.id === id) ?? { id: id, name: id, glyph: "\u{F02D7}" } }
    readonly property int wallVersion: 5   // = VERSION in scripts/theme-wallpaper (the picture's file name)
    function get(id) { return list.find(r => r.id === id) ?? list[0] }

    // Your adjustments to a theme (Settings > Themes > Adjust), saved per theme in
    // Config.appearance.custom[id] and laid over its defaults. Each key and what it changes:
    readonly property var adjustable: ({
        accent:   "colour.accent (and the window border)",   accent2: "colour.accent2",
        radius:   "shape.radius, radiusSmall and window rounding",
        gapsIn:   "hypr.gapsIn",   gapsOut: "hypr.gapsOut",   border: "hypr.border (window frame px)",
        font: "font.ui",          size: "font.size (body px)",
        motion:   "hypr.motion",   shadow: "hypr.shadow",     blur: "hypr.blur",
        // Settings > Menu Bar and Dock: where this theme's bar and dock go and what the bar holds
        barEdge:  "bar.edge",      barSize: "bar.size (px)",   barFloating: "bar.floating",
        barItems: "bar.start / center / end ({ start: [...], center: [...], end: [...] })",
        dock:     "dock.edge: bar (inside the bar), bottom, left, right or top"
    })
    // write one adjustment for the active theme (undefined removes it); "" when saved, else why not
    function adjust(key, value) {
        const all = JSON.parse(JSON.stringify(Config.appearance.custom ?? {})), id = Config.appearance.theme
        const o = all[id] ?? {}
        if (value === undefined || value === null) delete o[key]; else o[key] = value
        if (Object.keys(o).length) all[id] = o; else delete all[id]
        return Config.set("appearance", "custom", all)
    }

    // Save the active theme with all your adjustments as a theme of your own (Config.appearance.userThemes),
    // stored as only the parts that differ from its base. `into` = an existing own theme to overwrite.
    // The adjustments move into it, so the theme you started from goes back to how it was.
    function saveAs(name, into) {
        const a = Config.appearance, from = a.theme
        const r = resolve(from, a.custom), base = r.user ? r.base : r.id
        const parts = diff(r, resolve(base, {}))
        for (const k of ["id", "name", "about", "base", "user"]) delete parts[k]
        const all = JSON.parse(JSON.stringify(a.userThemes ?? {}))
        let id = into
        if (!id) {
            const slug = "custom-" + (String(name).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 32) || "theme")
            id = slug
            for (let n = 2; all[id] || builtIn.some(b => b.id === id); n++) id = slug + "-" + n
        }
        all[id] = Object.assign({ name: String(name).trim() || all[id]?.name || "My theme", base: base }, parts)
        Config.set("appearance", "userThemes", all)
        const custom = JSON.parse(JSON.stringify(a.custom ?? {}))
        delete custom[from]; delete custom[id]
        Config.set("appearance", "custom", custom)
        Config.set("appearance", "theme", id)
        return id
    }
    // the parts of `a` that differ from `b` (objects compared key by key, lists and values whole)
    function diff(a, b) {
        const out = {}
        for (const k of Object.keys(a)) {
            const x = a[k], y = b?.[k]
            if (JSON.stringify(x) === JSON.stringify(y)) continue
            if (x && typeof x === "object" && !Array.isArray(x) && y && typeof y === "object") out[k] = diff(x, y)
            else out[k] = x
        }
        return out
    }
    function resolve(id, custom) {
        const r = JSON.parse(JSON.stringify(get(id)))
        // text on an accent fill must reach WCAG AA (4.5:1); if the theme's own choice doesn't, take the better of dark/light
        if (contrast(r.colour.onAccent, r.colour.accent) < 4.5) r.colour.onAccent = textOn(r.colour.accent, r.colour)
        const o = Object.assign({}, (custom ?? {})[r.id] ?? {})
        const ok = v => v !== undefined && v !== null && v !== ""
        const hexOk = v => typeof v === "string" && /^#[0-9a-fA-F]{6}$/.test(v)
        const num = (v, lo, hi) => typeof v === "number" && v >= lo && v <= hi
        for (const [k, test] of [["accent", hexOk], ["accent2", hexOk], ["radius", v => num(v, 0, 40)], ["gapsIn", v => num(v, 0, 60)],
                                 ["gapsOut", v => num(v, 0, 80)], ["border", v => num(v, 0, 10)],
                                 ["size", v => num(v, 9, 24)], ["font", v => typeof v === "string" && /^[^'\n#]+$/.test(v)],
                                 ["motion", v => ["instant", "crisp", "snappy", "slam", "ease", "spring", "fade"].includes(v)],
                                 ["shadow", v => ["none", "soft", "paper", "hard"].includes(v)], ["blur", v => typeof v === "boolean"]])
            if (ok(o[k]) && !test(o[k])) delete o[k]   // a bad value is ignored, the theme's own stays
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
        if (ok(o.font)) r.font.ui = o.font
        if (ok(o.size)) r.font.size = o.size
        if (ok(o.motion)) r.hypr.motion = o.motion
        if (ok(o.shadow)) r.hypr.shadow = o.shadow
        if (ok(o.blur)) r.hypr.blur = o.blur
        // the bar and dock (Settings > Menu Bar / Dock), checked the same way
        const edges = ["top", "bottom", "left", "right"], side = e => e === "left" || e === "right"
        if (edges.includes(o.barEdge) && o.barEdge !== r.bar.edge) {
            // a theme's own size suits its own edge: a rail turned into a strip gets a strip's height and back
            if (side(o.barEdge) !== side(r.bar.edge)) r.bar.size = side(o.barEdge) ? Math.max(r.bar.size, 44) : Math.min(r.bar.size, 44)
            r.bar.edge = o.barEdge
        }
        if (num(o.barSize, 20, 96)) r.bar.size = o.barSize
        if (typeof o.barFloating === "boolean") r.bar.floating = o.barFloating
        const items = o.barItems, known = barItems.map(i => i.id)
        if (items && typeof items === "object")
            for (const k of ["start", "center", "end"])
                if (items[k] && typeof items[k].length === "number") r.bar[k] = Array.from(items[k]).filter((i, n, l) => known.includes(i) && l.indexOf(i) === n)
        if (o.dock === "bar") r.dock.edge = r.bar.edge
        else if (edges.includes(o.dock)) r.dock.edge = o.dock
        return r
    }
    // WCAG relative luminance and contrast ratio
    function luminance(hex) {
        const c = Qt.color(hex), f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b)
    }
    function contrast(a, b) { const x = luminance(a), y = luminance(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05) }
    // dark or light text on a fill, whichever contrasts more: the theme's dark ground if it's dark, else near-black
    function textOn(hex, colour) {
        const dark = Qt.color(colour.ground).hslLightness < 0.3 ? colour.ground : "#141414"
        return contrast(dark, hex) >= contrast("#ffffff", hex) ? dark : "#ffffff"
    }
}
