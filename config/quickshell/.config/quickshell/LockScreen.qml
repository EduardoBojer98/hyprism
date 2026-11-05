pragma Singleton
import Quickshell
import QtQuick

// The lock screen's layout, in one place: the active theme's clock style and alignment (Themes.qml
// lock) with Settings > Lock Screen on top. `elements` describes it in hyprlock's terms (position from
// an edge, y up, sizes in points on a 1600x1000 screen); ThemeSync writes it to hyprlock as `conf`, and
// LockPreview draws the same list, so the preview and the real lock screen can't disagree.
Singleton {
    id: root

    readonly property var l: Config.lockscreen
    readonly property var def: Theme.current.lock
    readonly property string clock: l.clock === "theme" ? def.clock : l.clock      // big | stacked | terminal | readout | small
    readonly property string align: l.position === "theme" ? def.align : l.position // center | top | bottom | left
    readonly property bool h24: Config.bar.clock24
    // the text colour: the theme's own unless a light theme's dark text would sit on a dark picture
    readonly property bool darkInk: Theme.light && l.brightness >= 0.6
    readonly property color ink: darkInk ? Theme.text : Theme.onImage
    readonly property color inkMuted: darkInk ? Theme.subtext : Qt.alpha(Theme.onImage, 0.78)
    readonly property string avatarPath: l.avatar === "" ? "" : l.avatar.replace(/^~/, Quickshell.env("HOME"))

    // ---- the stack, top to bottom: avatar, greeting, clock, date, password, then widgets at the edge ----
    readonly property var stack: {
        const out = [], dw = Theme.displayWeight
        if (avatarPath) out.push({ role: "avatar", w: 96, hgt: 96 })
        if (l.greeting) out.push({ role: "greeting", size: 15, weight: Font.DemiBold, colour: "muted" })
        if (clock === "stacked") {
            out.push({ role: "hours", size: 140, weight: Math.max(dw, Font.Bold), display: true, colour: "text", tight: true })
            out.push({ role: "minutes", size: 140, weight: Math.max(dw, Font.Bold), display: true, colour: "accent", tight: true })
        } else if (clock === "terminal") {
            out.push({ role: "prompt", size: 15, mono: true, colour: "muted" })
            out.push({ role: "clock", size: 72, weight: Font.Bold, mono: true, colour: "accent" })
        } else if (clock === "readout") {
            out.push({ role: "seconds", size: 54, weight: Font.Light, mono: true, colour: "accent" })
        } else {
            out.push({ role: "clock", size: clock === "small" ? 60 : 112, weight: dw, display: true, colour: "text" })
        }
        if (l.date) out.push({ role: "date", size: 17, weight: Font.Medium, mono: clock === "terminal" || clock === "readout", colour: "muted", caps: clock === "readout" })
        out.push({ role: "gap", hgt: 26 })
        out.push({ role: "input", w: 300, hgt: 50 })
        return out
    }
    function heightOf(e) { return e.hgt ?? Math.round(e.size * 1.33 * (e.tight ? 0.92 : 1.18)) }

    readonly property var elements: {
        const total = stack.reduce((a, e) => a + heightOf(e), 0)
        let top = 0
        const out = []
        for (const e of stack) {
            const h = heightOf(e), m = Object.assign({}, e)
            if (e.role !== "gap") {
                if (align === "top") Object.assign(m, { h: "center", v: "top", x: 0, y: -(110 + top) })
                else if (align === "bottom") Object.assign(m, { h: "center", v: "bottom", x: 0, y: 110 + total - top - h })
                else Object.assign(m, { h: align === "left" ? "left" : "center", v: "center", x: align === "left" ? 140 : 0,
                                        y: Math.round(total / 2 - top - h / 2) })
                out.push(m)
            }
            top += h
        }
        // widgets: one line at the bottom edge (the top edge when the stack is at the bottom)
        if (l.widgets.includes("battery") || l.widgets.includes("media"))
            out.push({ role: "widgets", size: 12, weight: Font.Medium, colour: "muted", h: align === "left" ? "left" : "center",
                       v: align === "bottom" ? "top" : "bottom", x: align === "left" ? 140 : 0, y: align === "bottom" ? -36 : 36 })
        return out
    }

    // ---- what each role says, on the real lock screen (hyprlock) and in the preview ----------------
    readonly property string userName: Quickshell.env("USER") ?? ""
    function greetingText() { return "Welcome back, " + userName.charAt(0).toUpperCase() + userName.slice(1) }
    readonly property var dateFormat: ({ hl: "%A, %-d %B", qt: "dddd, d MMMM" })
    function previewText(role, now) {
        const t = f => Qt.formatTime(now, f)
        switch (role) {
        case "clock": return t(h24 ? "HH:mm" : "h:mm")
        case "seconds": return t(h24 ? "HH:mm:ss" : "h:mm:ss")
        case "hours": return t(h24 ? "HH" : "hh")
        case "minutes": return t("mm")
        case "date": return Qt.formatDate(now, dateFormat.qt)
        case "greeting": return greetingText()
        case "prompt": return "~ $ date +%R"
        case "widgets": return widgetText([Sys.hasBattery ? "bat " + Sys.batteryPct + "%" : "", Sys.track])
        }
        return ""
    }
    function widgetText(parts) { return parts.filter(x => x).join("   ·   ") }
    function hyprText(role) {
        switch (role) {
        case "clock": return "cmd[update:1000] date +\"" + (h24 ? "%H:%M" : "%-I:%M") + "\""
        case "seconds": return "cmd[update:1000] date +\"" + (h24 ? "%H:%M:%S" : "%-I:%M:%S") + "\""
        case "hours": return "cmd[update:1000] date +\"" + (h24 ? "%H" : "%I") + "\""
        case "minutes": return "cmd[update:1000] date +\"%M\""
        case "date": return "cmd[update:60000] date +\"" + dateFormat.hl + "\"" + (clock === "readout" ? " | tr a-z A-Z" : "")
        case "greeting": return greetingText()
        case "prompt": return "~ $ date +%R"
        case "widgets": {
            const bits = []
            if (l.widgets.includes("battery")) bits.push("b=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); [ -n \"$b\" ] && printf 'bat %s%%' \"$b\"")
            if (l.widgets.includes("media")) bits.push("m=$(playerctl metadata --format '{{title}} · {{artist}}' 2>/dev/null); [ -n \"$m\" ] && printf '   ·   %s' \"$m\"")
            return "cmd[update:5000] sh -c '" + bits.join("; ").replace(/'/g, "'\\''") + "'"
        }
        }
        return ""
    }

    // ---- hyprlock --------------------------------------------------------------------------------------
    function hex(c) { return c.toString().slice(1, 7) }
    function rgba(c, a) { return "rgba(" + [c.r, c.g, c.b].map(v => Math.round(v * 255)).join(", ") + ", " + a + ")" }
    function family(e) {   // hyprlock picks the face by its full name: "Outfit Light"
        const f = e.mono ? Theme.monoFont : e.display ? Theme.displayFont : Theme.font
        const w = ({ 300: " Light", 500: " Medium", 600: " SemiBold", 700: " Bold", 800: " ExtraBold", 900: " Black" })[e.weight ?? 400] ?? ""
        return f.endsWith(w.trim()) ? f : f + w
    }
    function colour(e) { return e.colour === "accent" ? "rgb(" + hex(Theme.accent) + ")" : e.colour === "muted" ? rgba(inkMuted, Number(inkMuted.a.toFixed(2))) : "rgb(" + hex(ink) + ")" }
    function place(e) {
        return "    position    = " + e.x + ", " + e.y + "\n    halign      = " + e.h + "\n    valign      = " + e.v + "\n"
    }
    readonly property string conf: {
        let s = "# The layout: LockScreen.qml (" + Theme.current.name + ", clock " + clock + ", " + align + ")\n"
        for (const e of elements) {
            if (e.role === "avatar") {
                s += "image {\n    monitor     =\n    path        = " + avatarPath + "\n    size        = " + e.w + "\n    rounding    = -1\n"
                   + "    border_size = 2\n    border_color = rgb(" + hex(Theme.accent) + ")\n" + place(e) + "}\n"
            } else if (e.role === "input") {
                s += "input-field {\n    monitor           =\n    size              = " + e.w + ", " + e.hgt + "\n"
                   + "    outline_thickness = " + Math.max(1, Theme.line) + "\n    rounding          = " + (Theme.radius >= 12 ? -1 : Theme.radius) + "\n"
                   + "    outer_color       = rgb(" + hex(Theme.accent) + ")\n    inner_color       = " + rgba(Theme.surfaceColor, 0.85) + "\n"
                   + "    font_color        = rgb(" + hex(Theme.text) + ")\n    font_family       = " + Theme.font + "\n"
                   + "    check_color       = rgb(" + hex(Theme.accent2) + ")\n    fail_color        = rgb(" + hex(Theme.error) + ")\n"
                   + "    placeholder_text  = <span foreground=\"##" + hex(Theme.subtext) + "\">Password" + (l.widgets.includes("layout") ? "  ·  $LAYOUT" : "") + "</span>\n"
                   + "    fail_text         = <i>$FAIL</i>\n    fade_on_empty     = false\n    dots_center       = true\n" + place(e) + "}\n"
            } else {
                s += "label {\n    monitor     =\n    text        = " + hyprText(e.role) + "\n    font_size   = " + e.size + "\n"
                   + "    font_family = " + family(e) + "\n    color       = " + colour(e) + "\n"
                   + (e.h === "left" ? "    text_align  = left\n" : "") + place(e) + "}\n"
            }
        }
        return s
    }
}
