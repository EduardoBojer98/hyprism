pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The themes: each one is a whole desktop design, not a colour scheme (docs/DESIGN.md).
// They are folders on disk (docs/THEMES.md); this file reads them and holds the rules for laying your changes over them. Theme.qml turns the active theme (and your Settings) into tokens every component reads;
// ThemeSync.qml carries it to Hyprland, hyprlock, GTK, Ghostty and the wallpaper. Switch: `theme NAME`.
//
// colour   ground (desktop/bar), surface (panels), raised (controls, hover), line, text, muted, faint,
//          accent, onAccent (text on an accent fill), accent2, ok / warn / err
// alt      the theme's other half: light for a dark theme, dark for a light one (dark, colour, hypr active /
//          inactive, term, wall). Settings > Appearance > Light or dark picks it (Config.appearance.mode)
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
// lock     clock style + align (ThemeSync writes the hyprlock layout); term: the terminal palette (background,
//          foreground, cursor, selection, 16 colours); wall: the wallpaper recipe or picture (theme-wallpaper)
Singleton {
    id: root
    // Every theme is a folder with a theme.json (docs/THEMES.md): the shipped ones in
    // ~/.local/share/hyprism/themes/<id>/ (the repo's themes/), yours in ~/.config/hyprism/themes/<id>/, which
    // win over a shipped one with the same id. Copy a folder, edit theme.json, and it is in the list.
    readonly property string shippedDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/hyprism/themes"
    readonly property string ownDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/hyprism/themes"
    property bool ready: false           // false for the first moments, while the folders are read
    property var builtIn: [safe]         // the folder themes; until they are read, only the one below
    readonly property var list: builtIn.concat(userList)
    readonly property var ids: list.map(r => r.id)
    // The one theme that lives in code, so the shell still starts when no theme folder can be read.
    // Every folder theme is laid over a copy of it, so a theme.json with a part missing still works.
    readonly property var safe: ({"name": "Safe mode", "about": "Shown only if no theme folder can be read", "order": 7, "dark": true, "colour": {"ground": "#0c0d08", "surface": "#15170e", "raised": "#1f2216", "line": "#3b3f22", "text": "#f3f6df", "muted": "#c2c69c", "faint": "#8a8e6a", "accent": "#e4ff1a", "onAccent": "#0c0d08", "accent2": "#ff6b0a", "ok": "#3ddc97", "warn": "#ffb547", "err": "#ff4f6d"}, "alt": {"dark": false, "term": {"palette": ["#181a0e", "#c22745", "#16794a", "#975b00", "#1f5fbf", "#8a2fb8", "#0b7a73", "#4f5238", "#767a5c", "#d63c59", "#1f8f5a", "#b14800", "#3274d4", "#9f45cc", "#138d85", "#eaecda"], "background": "#f5f6ea", "foreground": "#181a0e", "cursor": "#b14800", "cursorText": "#ffffff", "selection": "#f0d2b8", "selectionText": "#181a0e"}, "wall": "reactor-light", "colour": {"ground": "#f5f6ea", "surface": "#fdfdf7", "raised": "#eaecda", "line": "#cfd2b4", "text": "#181a0e", "muted": "#4f5238", "faint": "#767a5c", "accent": "#b14800", "onAccent": "#ffffff", "accent2": "#5f6e00", "ok": "#16794a", "warn": "#975b00", "err": "#c22745"}, "hypr": {"active": ["b14800ff", "5f6e00ff"], "inactive": "d9dbc6ff"}}, "font": {"ui": "Archivo", "display": "Martian Mono", "mono": "JetBrainsMono Nerd Font", "size": 13, "displayWeight": 500}, "shape": {"radius": 10, "radiusSmall": 6, "line": 1, "material": "solid"}, "bar": {"edge": "top", "size": 34, "floating": true, "segmented": false, "fill": "surface", "line": 1, "voice": "icons", "mono": false, "ws": "filled", "clock": "block", "decor": "", "sep": false, "start": ["controls", "launcher", "workspaces", "window"], "center": ["clock"], "end": ["weather", "media", "tray", "keyboard", "notifications", "status"]}, "dock": {"edge": "bottom", "shape": "tile", "hover": "lift", "mark": "bar", "fill": "surface"}, "popup": {"depth": "glow", "decor": "topline", "tiles": "solid"}, "motion": {"enter": 180, "exit": 110, "curve": [0.2, 0, 0, 1], "travel": 8, "scale": 0.97, "press": 0.96}, "launcher": {"placement": "center", "view": "home", "header": "query", "width": 680, "select": "inverse", "prompt": ""}, "notify": {"corner": "top-right", "kind": "card"}, "hypr": {"gapsIn": 6, "gapsOut": 12, "border": 2, "rounding": 10, "active": ["e4ff1aff", "ff6b0aff"], "inactive": "2a2c1cff", "shadow": "soft", "blur": false, "motion": "snappy"}, "lock": {"clock": "big", "align": "left"}, "term": {"palette": ["#1f2216", "#ff4f6d", "#3ddc97", "#e4ff1a", "#6fb3ff", "#d98aff", "#5ee0d6", "#c2c69c", "#8a8e6a", "#ff7a90", "#6ee8b2", "#efff6b", "#99c9ff", "#e5aaff", "#8aeae2", "#f3f6df"], "background": "#0c0d08", "foreground": "#f3f6df", "cursor": "#e4ff1a", "cursorText": "#0c0d08", "selection": "#3d4510", "selectionText": "#f3f6df"}, "wall": "reactor", "id": "safe"})
    function reload() { reader.running = false; reader.running = true }
    // `qs ipc call themes reload` after adding or editing a theme folder (the `theme` command does it for you)
    IpcHandler {
        target: "themes"
        function reload(): void { root.reload() }
        function list(): string { return root.list.map(t => t.id).join(" ") }
    }
    Process {
        id: reader
        running: true
        // one line per theme: "<id><TAB><folder><TAB><theme.json on one line>"; QML can't list a folder
        command: ["sh", "-c", 'for dir in "$@"; do for d in "$dir"/*/; do d=${d%/}; id=${d##*/}; case $id in _*|"*") continue;; esac; '
                              + '[ -f "$d/theme.json" ] && printf "%s\\t%s\\t%s\\n" "$id" "$d" "$(tr -d "\\n" < "$d/theme.json")"; done; done', "sh", root.shippedDir, root.ownDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = {}
                for (const line of text.split("\n")) {
                    const cut = line.split("\t")
                    if (cut.length < 3 || !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(cut[0])) continue
                    let raw
                    try { raw = JSON.parse(cut.slice(2).join("\t")) } catch (e) { console.warn("theme " + cut[0] + ": theme.json doesn't parse: " + e); continue }
                    const t = root.merge(JSON.parse(JSON.stringify(root.safe)), raw)   // checked part by part, like your own themes
                    t.id = cut[0]
                    t.folder = cut[1]
                    t.name = typeof raw.name === "string" && raw.name.trim() ? raw.name.trim().slice(0, 32) : cut[0]
                    t.about = typeof raw.about === "string" ? raw.about.slice(0, 200) : ""
                    t.order = typeof raw.order === "number" ? raw.order : 1000
                    found[cut[0]] = t                                                   // a later folder (yours) wins
                }
                const all = Object.values(found).sort((x, y) => x.order - y.order || x.name.localeCompare(y.name))
                if (all.length) root.builtIn = all
                else console.warn("no theme folders found in " + root.shippedDir + ": running in safe mode (./install.sh --only links)")
                root.ready = true
            }
        }
    }

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

    // every bar item: the folders in bar/items/ (BarItems), named and ordered for Settings > Menu Bar
    readonly property var barItems: BarItems.catalogue
    function barItem(id) { return barItems.find(i => i.id === id) ?? { id: id, name: id, glyph: "\u{F02D7}" } }
    readonly property int wallVersion: 9   // = VERSION in scripts/theme-wallpaper (the picture's file name)
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
        const r = resolve(from, a.custom, a.mode), base = r.user ? r.base : r.id
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
    function resolve(id, custom, mode) {
        const r = JSON.parse(JSON.stringify(get(id)))
        // light or dark: the other half swaps in, and the half it replaces becomes the alt (so a saved theme keeps both)
        if (r.alt && (mode === "light" && r.dark || mode === "dark" && !r.dark)) {
            const was = { dark: r.dark, term: r.term, wall: r.wall, colour: r.colour, hypr: { active: r.hypr.active, inactive: r.hypr.inactive } }
            r.dark = r.alt.dark; r.term = r.alt.term; r.wall = r.alt.wall
            r.colour = Object.assign({}, r.colour, r.alt.colour)
            r.hypr.active = r.alt.hypr.active; r.hypr.inactive = r.alt.hypr.inactive
            r.alt = was
        }
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
        const items = o.barItems, known = barItems.map(i => i.id), settled = BarItems.ready   // ids are unknown until the folders are read
        if (items && typeof items === "object")
            for (const k of ["start", "center", "end"])
                if (items[k] && typeof items[k].length === "number") r.bar[k] = Array.from(items[k]).filter((i, n, l) => (!settled || known.includes(i)) && l.indexOf(i) === n)
        if (o.dock === "bar") r.dock.edge = r.bar.edge
        else if (edges.includes(o.dock)) r.dock.edge = o.dock
        if (["dot", "line", "bar", "ring", "diamond"].includes(o.dockMark)) r.dock.mark = o.dockMark
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
