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
    // Settings > Lock Screen "Colours from its picture" (WallpaperColours.qml), else the desktop's
    readonly property color accent: WallpaperColours.lockAccent ? Qt.color(WallpaperColours.lockAccent) : Theme.accent
    readonly property color accent2: WallpaperColours.lockAccent2 ? Qt.color(WallpaperColours.lockAccent2) : Theme.accent2
    readonly property var def: Theme.current.lock
    readonly property string clock: l.clock === "theme" ? def.clock : l.clock      // big | stacked | terminal | readout | small
    readonly property string align: l.position === "theme" ? def.align : l.position // center | top | bottom | left
    readonly property bool h24: Config.bar.clock24
    // theme.json lock.scene, the composition around the clock:
    //   soft    a time-of-day greeting, a soft shadowed password pill and a now-playing pill
    //   blocks  a solid panel with colour blocks behind the stack, a square field with a hard shadow
    //   boot    a boot log that types in (still in reduced motion), then login: and password: lines
    readonly property string scene: def.scene ?? ""
    // the text colour: the theme's own unless a light theme's dark text would sit on a dark picture
    // (on the blocks scene's solid panel it is always the theme's own)
    readonly property bool darkInk: scene === "blocks" || Theme.light && l.brightness >= 0.6
    readonly property color ink: darkInk ? Theme.text : Theme.onImage
    readonly property color inkMuted: darkInk ? Theme.subtext : Qt.alpha(Theme.onImage, 0.86)
    // text straight on the picture gets a soft dark shadow, so it reads over bright and busy spots too
    readonly property bool shadowed: !darkInk
    readonly property string avatarPath: l.avatar === "" ? "" : l.avatar.replace(/^~/, Quickshell.env("HOME"))

    // ---- the stack, top to bottom: avatar, greeting, clock, date, password, then widgets at the edge ----
    readonly property var stack: {
        const out = [], dw = Theme.displayWeight
        if (avatarPath) out.push({ role: "avatar", w: 96, hgt: 96 })
        if (scene === "boot") out.push({ role: "boot", size: 14, mono: true, colour: "muted", lines: 4 }, { role: "gap", hgt: 22 })
        if (l.greeting || scene === "soft") out.push({ role: "greeting", size: scene === "soft" ? 20 : 15, weight: Font.DemiBold, colour: "muted" })
        if (clock === "stacked") {
            out.push({ role: "hours", size: 140, weight: Math.max(dw, Font.Bold), display: true, colour: "text", tight: true })
            out.push({ role: "minutes", size: 140, weight: Math.max(dw, Font.Bold), display: true, colour: "accent", tight: true })
        } else if (clock === "terminal") {
            out.push({ role: "prompt", size: 17, mono: true, colour: "muted" })
            out.push({ role: "clock", size: 88, weight: Font.Bold, mono: true, colour: "accent" })
        } else if (clock === "readout") {
            out.push({ role: "seconds", size: 54, weight: Font.Light, mono: true, colour: "accent" })
        } else {
            out.push({ role: "clock", size: clock === "small" ? 60 : 112, weight: dw, display: true, colour: "text" })
        }
        if (l.date) out.push({ role: "date", size: 17, weight: Font.Medium, mono: clock === "terminal" || clock === "readout", colour: "muted", caps: clock === "readout" })
        out.push({ role: "gap", hgt: 26 })
        out.push(scene === "boot" ? { role: "input", w: 140, hgt: 34, prefix: 128 } : { role: "input", w: 300, hgt: 50 })
        // boot: the layout as one more log line (hyprlock centres a placeholder, far from "password:")
        if (scene === "boot" && l.widgets.includes("layout")) out.push({ role: "kbd", size: 14, mono: true, colour: "muted" })
        return out
    }
    function heightOf(e) { return e.hgt ?? Math.round(e.size * 1.33 * (e.tight ? 0.92 : 1.18) * (e.lines ?? 1)) }

    // the blocks scene's composition, in % of the screen from its bottom-left corner: a solid panel behind
    // the stack, an accent and an accent2 block over its edge, and a text-coloured rule down that edge
    readonly property var blocks: {
        if (scene !== "blocks") return []
        const x0 = align === "left" ? 0 : 28
        return [{ x: x0, y: 0, w: 44, h: 100, colour: "surface" },
                { x: x0 + 35, y: 0, w: 14, h: 34, colour: "accent" },
                { x: x0 + 39, y: 76, w: 9, h: 14, colour: "accent2" },
                { x: x0 + 44, y: 0, w: 0.6, h: 100, colour: "text" }]
    }

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
                if (e.prefix) {   // boot: "password:" and the field on one line, as a group
                    const left = m.h === "left", lead = left ? m.x : m.x - (e.prefix + e.w) / 2
                    out.push(Object.assign({}, m, { role: "pwlabel", size: 14, mono: true, colour: "muted", hgt: undefined,
                                                    x: left ? lead : lead + 50 }))   // shortcut: 50 = half of "password:" at 14 pt mono
                    m.x = left ? lead + e.prefix : lead + e.prefix + e.w / 2
                }
                if (e.role === "input" && scene === "blocks")   // the hard shadow: a text-coloured block behind, down and right
                    out.push({ role: "shape", w: e.w, hgt: e.hgt, colour: "text", h: m.h, v: m.v, x: m.x + 8, y: m.y - 8 })
                out.push(m)
            }
            top += h
        }
        const edge = { h: align === "left" ? "left" : "center", v: align === "bottom" ? "top" : "bottom", x: align === "left" ? 140 : 0 }
        // soft: a now-playing pill at the bottom edge, the battery line under it
        if (scene === "soft") {
            const y = align === "bottom" ? -72 : 72
            out.push(Object.assign({ role: "shape", w: 340, hgt: 44, colour: "pill", round: true }, edge, { y: y }))
            out.push(Object.assign({ role: "media", size: 11, weight: Font.Medium, colour: "text" }, edge, { x: edge.x + (edge.h === "left" ? 22 : 0), y: y + (align === "bottom" ? -13 : 13) }))
        }
        // widgets: one line at the bottom edge (the top edge when the stack is at the bottom)
        if (l.widgets.includes("battery") || l.widgets.includes("media") && scene !== "soft")
            out.push(Object.assign({ role: "widgets", size: 13, weight: Font.Medium, colour: "muted" }, edge, { y: align === "bottom" ? -36 : 36 }))
        return out
    }

    // ---- what each role says, on the real lock screen (hyprlock) and in the preview ----------------
    readonly property string userName: Quickshell.env("USER") ?? ""
    readonly property string niceName: userName.charAt(0).toUpperCase() + userName.slice(1)
    // soft: a time-of-day greeting, with your name when Greeting is on; otherwise "Welcome back, <name>"
    function greetingText(now) {
        if (scene !== "soft") return "Welcome back, " + niceName
        const h = (now ?? new Date()).getHours()
        return (h < 5 ? "Good evening" : h < 12 ? "Good morning" : h < 18 ? "Good afternoon" : "Good evening") + (l.greeting ? ", " + niceName : "")
    }
    readonly property var bootLines: ["[ ok ] started hyprlock", "[ ok ] grabbed keyboard and pointer", "[ ok ] session locked", "login: " + userName]
    // hyprlock: the log types in, one letter per 20 ms, from 600 ms after the first run (hyprlock runs it before
    // its first frame, then fades in). update:60000:1 lets SIGUSR2 re-run it; the first run (a new hyprlock,
    // $PPID) starts one loop that signals that hyprlock for ~4 s.
    // (hyprlock drops a signal that lands mid-refresh, so one shot per run would stall; and it reads the
    // command's output pipes to the end, so the loop closes every inherited descriptor.)
    // Reduced or no motion: the whole log at once. No # (a config comment) and no $name that is a variable here.
    readonly property string bootCmd: {
        const log = "t=$(printf '%s\\n' '" + bootLines.slice(0, 3).join("' '") + "'; printf 'login: %s' \"$(id -un)\"); "
        if (!Theme.moves) return "cmd[update:0] " + log + "printf '%s' \"$t\""
        return "cmd[update:60000:1] k=${XDG_RUNTIME_DIR:-/tmp}/hyprism-lockboot; n=$(date +%s%3N); read -r p s <\"$k\" 2>/dev/null; "
            + "if [ \"$p\" != \"$PPID\" ]; then s=$((n + 600)); echo \"$PPID $s\" >\"$k\"; "
            + "setsid -f sh -c 'for f in /proc/self/fd/*; do n=$(basename $f); [ $n -gt 2 ] && eval \"exec $n>&-\"; done; i=0; while [ $i -lt 60 ]; do sleep 0.07; kill -USR2 $1 || break; i=$((i + 1)); done' - \"$PPID\" </dev/null >/dev/null 2>&1; fi; " + log
            + "c=$(( (n - s) / 20 )); [ \"$c\" -lt 0 ] && c=0; [ \"$c\" -lt \"$(printf %s \"$t\" | wc -c)\" ] && t=$(printf '%s' \"$t\" | head -c \"$c\"); printf '%s' \"$t\""
    }
    readonly property var dateFormat: ({ hl: "%A, %-d %B", qt: "dddd, d MMMM" })
    function previewText(role, now) {
        const t = f => Qt.formatTime(now, f)
        switch (role) {
        case "clock": return t(h24 ? "HH:mm" : "h:mm")
        case "seconds": return t(h24 ? "HH:mm:ss" : "h:mm:ss")
        case "hours": return t(h24 ? "HH" : "hh")
        case "minutes": return t("mm")
        case "date": return Qt.formatDate(now, dateFormat.qt)
        case "greeting": return greetingText(now)
        case "prompt": return "~ $ date +%R"
        case "boot": return bootLines.join("\n")
        case "pwlabel": return "password:"
        case "kbd": return "layout: " + (Keyboard.layouts[Keyboard.active]?.name ?? Keyboard.short)
        case "media": return "\u266A  " + (Sys.track || "Nothing playing")
        case "widgets": return widgetText([Sys.hasBattery ? "bat " + Sys.batteryPct + "%" : "", scene === "soft" ? "" : Sys.track])
        }
        return ""
    }
    // the playing track into $m, title · artist, at most 48 letters. Not playerctl --format: its {{ }}
    // is hyprlang's expression syntax, and the label would show hyprlock's "Sample Text"
    readonly property string nowPlaying: "m=$(playerctl metadata title 2>/dev/null); a=$(playerctl metadata artist 2>/dev/null); "
        + "[ -n \"$a\" ] && m=\"$m · $a\"; m=$(printf %s \"$m\" | awk '{ print substr($0, 1, 48) }'); "
    function widgetText(parts) { return parts.filter(x => x).join("   ·   ") }
    function hyprText(role) {
        switch (role) {
        case "clock": return "cmd[update:1000] date +\"" + (h24 ? "%H:%M" : "%-I:%M") + "\""
        case "seconds": return "cmd[update:1000] date +\"" + (h24 ? "%H:%M:%S" : "%-I:%M:%S") + "\""
        case "hours": return "cmd[update:1000] date +\"" + (h24 ? "%H" : "%I") + "\""
        case "minutes": return "cmd[update:1000] date +\"%M\""
        case "date": return "cmd[update:60000] date +\"" + dateFormat.hl + "\"" + (clock === "readout" ? " | tr a-z A-Z" : "")
        case "greeting": return scene === "soft"
            ? "cmd[update:60000] h=$(date +%-H); if [ \"$h\" -lt 5 ] || [ \"$h\" -ge 18 ]; then g=evening; elif [ \"$h\" -lt 12 ]; then g=morning; else g=afternoon; fi; printf 'Good %s" + (l.greeting ? ", " + niceName.replace(/[^A-Za-z0-9 ._-]/g, "") : "") + "' \"$g\""
            : greetingText()
        case "prompt": return "~ $ date +%R"
        case "boot": return bootCmd
        case "pwlabel": return "password:"
        // hyprlock fills $LAYOUT in before running it; a plain label can keep "error" from before the keymap came
        case "kbd": return "cmd[update:1000] printf '%s' 'layout: $LAYOUT'"
        case "media": return "cmd[update:2000] " + nowPlaying + "printf '\u266A  %s' \"${m:-Nothing playing}\""
        case "widgets": {
            const bits = []
            if (l.widgets.includes("battery")) bits.push("b=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); [ -n \"$b\" ] && printf 'bat %s%%' \"$b\"")
            if (l.widgets.includes("media") && scene !== "soft") bits.push(nowPlaying + "[ -n \"$m\" ] && printf '   ·   %s' \"$m\"")
            return "cmd[update:5000] sh -c '" + bits.join("; ").replace(/'/g, "'\\''") + "'"
        }
        }
        return ""
    }

    // ---- hyprlock --------------------------------------------------------------------------------------
    function hex(c) { return c.toString().slice(1, 7) }
    function rgba(c, a) { return "rgba(" + [c.r, c.g, c.b].map(v => Math.round(v * 255)).join(", ") + ", " + a + ")" }
    // hyprlock picks the face by its full name: "Outfit Light". A family whose own name ends in the weight
    // ("Archivo Black") gets a trailing comma, or Pango reads it as Archivo at weight Black and draws it regular.
    function family(e) {
        const f = e.mono ? Theme.monoFont : e.display ? Theme.displayFont : Theme.font
        const w = ({ 300: " Light", 500: " Medium", 600: " SemiBold", 700: " Bold", 800: " ExtraBold", 900: " Black" })[e.weight ?? 400] ?? ""
        return w && f.endsWith(w) ? f + "," : f + w
    }
    function colour(e) { return e.colour === "accent" ? "rgb(" + hex(accent) + ")" : e.colour === "muted" ? rgba(inkMuted, Number(inkMuted.a.toFixed(2))) : "rgb(" + hex(ink) + ")" }
    // a shape's fill by name (blocks, the soft media pill, the blocks field's shadow), here and in LockPreview
    function tone(name) {
        return ({ surface: Theme.surfaceColor, accent: accent, accent2: accent2, text: Theme.text,
                  pill: Qt.alpha(Theme.surfaceColor, 0.72) })[name] ?? Theme.surfaceColor
    }
    function place(e) {
        return "    position    = " + e.x + ", " + e.y + "\n    halign      = " + e.h + "\n    valign      = " + e.v + "\n"
    }
    readonly property string conf: {
        let s = "# The layout: LockScreen.qml (" + Theme.current.name + ", clock " + clock + ", " + align + ")\n"
        for (const b of blocks)
            s += "shape {\n    monitor     =\n    size        = " + b.w + "%, " + b.h + "%\n    color       = rgb(" + hex(tone(b.colour)) + ")\n"
               + "    rounding    = 0\n    position    = " + b.x + "%, " + b.y + "%\n    halign      = left\n    valign      = bottom\n}\n"
        for (const e of elements) {
            if (e.role === "shape") {
                const c = tone(e.colour)
                s += "shape {\n    monitor     =\n    size        = " + e.w + ", " + e.hgt + "\n    color       = " + rgba(c, Number(c.a.toFixed(2))) + "\n"
                   + "    rounding    = " + (e.round ? -1 : 0) + "\n" + (e.round ? "    shadow_passes = 2\n    shadow_size = 6\n" : "") + place(e) + "}\n"
            } else if (e.role === "avatar") {
                s += "image {\n    monitor     =\n    path        = " + avatarPath + "\n    size        = " + e.w + "\n    rounding    = -1\n"
                   + "    border_size = 2\n    border_color = rgb(" + hex(accent) + ")\n" + place(e) + "}\n"
            } else if (e.role === "input") {
                // boot: bare, a star per letter after "password:"; soft: no outline, a soft shadow; blocks: a thick text frame
                const boot = scene === "boot", soft = scene === "soft", blk = scene === "blocks"
                const lay = !boot && l.widgets.includes("layout") ? "  ·  $LAYOUT" : ""
                s += "input-field {\n    monitor           =\n    size              = " + e.w + ", " + e.hgt + "\n"
                   + "    outline_thickness = " + (boot || soft ? 0 : blk ? 3 : Math.max(1, Theme.line)) + "\n"
                   + "    rounding          = " + (blk || boot ? 0 : soft || Theme.radius >= 12 ? -1 : Theme.radius) + "\n"
                   + "    outer_color       = rgb(" + hex(blk ? Theme.text : accent) + ")\n"
                   + "    inner_color       = " + (boot ? "rgba(0, 0, 0, 0)" : rgba(Theme.surfaceColor, blk ? 1 : soft ? 0.78 : 0.85)) + "\n"
                   + "    font_color        = rgb(" + hex(boot ? ink : Theme.text) + ")\n    font_family       = " + (boot ? Theme.monoFont : Theme.font) + "\n"
                   + "    check_color       = rgb(" + hex(accent2) + ")\n    fail_color        = rgb(" + hex(Theme.error) + ")\n"
                   + "    placeholder_text  = <span foreground=\"##" + hex(boot ? ink : Theme.subtext) + "\">" + (boot ? "_" : "Password" + lay) + "</span>\n"
                   + "    fail_text         = <i>$FAIL</i>\n    fade_on_empty     = false\n"
                   + (boot ? "    dots_center       = false\n    dots_text_format  = *\n    dots_spacing      = 0.1\n    dots_size         = 0.5\n"
                           : "    dots_center       = true\n")
                   + (soft ? "    shadow_passes     = 2\n    shadow_size       = 8\n" : "") + place(e) + "}\n"
            } else {
                s += "label {\n    monitor     =\n    text        = " + hyprText(e.role) + "\n    font_size   = " + e.size + "\n"
                   + "    font_family = " + family(e) + "\n    color       = " + colour(e) + "\n"
                   + (e.h === "left" ? "    text_align  = left\n" : "")
                   + (shadowed ? "    shadow_passes = 3\n    shadow_size = 4\n    shadow_color = rgba(0, 0, 0, 0.8)\n    shadow_boost = 1.4\n" : "") + place(e) + "}\n"
            }
        }
        return s
    }
}
