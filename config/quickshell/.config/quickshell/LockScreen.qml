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
    readonly property string align: l.position === "theme" ? def.align : l.position // split | center | top | bottom | left
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
    // text over the picture itself, even beside the blocks scene's panel (the battery in the corner)
    readonly property color pictureInk: Theme.light && l.brightness >= 0.6 ? Theme.text : Theme.onImage
    readonly property color inkMuted: darkInk ? Theme.subtext : Qt.alpha(Theme.onImage, 0.86)
    // text straight on the picture gets a soft dark shadow, so it reads over bright and busy spots too
    readonly property bool shadowed: !darkInk
    readonly property string avatarPath: l.avatar === "" ? "" : l.avatar.replace(/^~/, Quickshell.env("HOME"))

    // ---- the stack, top to bottom: the clock group (greeting, clock, date), then the sign-in group (picture,
    // name, password, Caps Lock hint). "split" puts the clock group at the top and the sign-in group low down,
    // the other positions keep them in one column. Widgets sit at the screen's edges. ----
    function stackFor(clock) {
        const out = [], dw = Theme.displayWeight, c = "clock", si = "sign", boot = scene === "boot"
        if (boot) out.push({ role: "boot", size: 14, mono: true, colour: "muted", lines: 4, group: c }, { role: "gap", hgt: 22, group: c })
        if (l.greeting || scene === "soft") out.push({ role: "greeting", size: scene === "soft" ? 20 : 15, weight: Font.DemiBold, colour: "muted", group: c })
        if (clock === "stacked") {
            out.push({ role: "hours", size: 140, weight: Math.max(dw, Font.Bold), display: true, colour: "text", tight: true, group: c })
            out.push({ role: "minutes", size: 140, weight: Math.max(dw, Font.Bold), display: true, colour: "accent", tight: true, group: c })
        } else if (clock === "terminal") {
            out.push({ role: "prompt", size: 17, mono: true, colour: "muted", group: c })
            out.push({ role: "clock", size: 88, weight: Font.Bold, mono: true, colour: "accent", group: c })
        } else if (clock === "readout") {
            out.push({ role: "seconds", size: 54, weight: Font.Light, mono: true, colour: "accent", group: c })
        } else {
            out.push({ role: "clock", size: clock === "small" ? 60 : 112, weight: dw, display: true, colour: "text", group: c })
        }
        if (l.date) out.push({ role: "date", size: 17, weight: Font.Medium, mono: clock === "terminal" || clock === "readout", colour: "muted", caps: clock === "readout", group: c })
        out.push({ role: "gap", hgt: 30, group: c })
        // you: your picture (or your initial on a disc) and your name; boot's login: line already says who
        if (avatarPath) out.push({ role: "avatar", w: 88, hgt: 88, group: si })
        else if (l.user && !boot) out.push({ role: "initial", w: 88, hgt: 88, size: 30, weight: Font.DemiBold, colour: "plain", group: si })
        if (l.user && !boot) out.push({ role: "name", size: 15, weight: Font.DemiBold, colour: "text", group: si })
        if ((avatarPath || l.user) && !boot) out.push({ role: "gap", hgt: 10, group: si })
        out.push(boot ? { role: "input", w: 140, hgt: 34, prefix: 128, group: si } : { role: "input", w: 300, hgt: 50, group: si })
        // boot: the layout as one more log line (hyprlock centres a placeholder, far from "password:")
        if (boot && l.widgets.includes("layout")) out.push({ role: "kbd", size: 14, mono: true, colour: "muted", group: si })
        out.push({ role: "gap", hgt: 8, group: si })
        out.push({ role: "caps", size: 12, weight: Font.DemiBold, mono: boot, colour: "warn", group: si })   // empty unless Caps Lock is on
        return out
    }
    function heightOf(e) { return e.hgt ?? Math.round(e.size * 1.33 * (e.tight ? 0.92 : 1.18) * (e.lines ?? 1)) }

    // the blocks scene's composition, in % of the screen from its bottom-left corner: a solid panel behind
    // the stack, an accent and an accent2 block over its edge, and a text-coloured rule down that edge
    function blocksFor(align) {
        if (scene !== "blocks") return []
        const x0 = align === "left" ? 0 : 28
        return [{ x: x0, y: 0, w: 44, h: 100, colour: "surface" },
                { x: x0 + 35, y: 0, w: 14, h: 34, colour: "accent" },
                { x: x0 + 39, y: 76, w: 9, h: 14, colour: "accent2" },
                { x: x0 + 44, y: 0, w: 0.6, h: 100, colour: "text" }]
    }
    readonly property var blocks: blocksFor(align)

    // the layout for a clock style and a position (Settings > Lock Screen draws every choice with it)
    function layout(clock, align) {
        const stack = stackFor(clock), split = align === "split"
        const sum = list => list.reduce((a, e) => a + heightOf(e), 0)
        const total = sum(stack), signTotal = sum(stack.filter(e => e.group === "sign"))
        const left = align === "left", hx = left ? "left" : "center", x0 = left ? 140 : 0
        let top = 0, signTop = 0
        const out = []
        for (const e of stack) {
            const h = heightOf(e), m = Object.assign({}, e), low = split && e.group === "sign"
            if (e.role !== "gap") {
                if (split && !low) Object.assign(m, { h: "center", v: "top", x: 0, y: -(90 + top) })
                else if (low) Object.assign(m, { h: "center", v: "bottom", x: 0, y: 150 + signTotal - signTop - h })
                else if (align === "top") Object.assign(m, { h: "center", v: "top", x: 0, y: -(110 + top) })
                else if (align === "bottom") Object.assign(m, { h: "center", v: "bottom", x: 0, y: 110 + total - top - h })
                else Object.assign(m, { h: hx, v: "center", x: x0, y: Math.round(total / 2 - top - h / 2) })
                if (e.prefix) {   // boot: "password:" and the field on one line, as a group
                    const lft = m.h === "left", lead = lft ? m.x : m.x - (e.prefix + e.w) / 2
                    out.push(Object.assign({}, m, { role: "pwlabel", size: 14, mono: true, colour: "muted", hgt: undefined, prefix: undefined,
                                                    x: lft ? lead : lead + 50 }))   // shortcut: 50 = half of "password:" at 14 pt mono
                    m.x = lft ? lead + e.prefix : lead + e.prefix + e.w / 2
                }
                if (e.role === "input" && scene === "blocks")   // the hard shadow: a text-coloured block behind, down and right
                    out.push({ role: "shape", w: e.w, hgt: e.hgt, colour: "text", h: m.h, v: m.v, x: m.x + 8, y: m.y - 8 })
                if (e.role === "initial") {   // a disc, your initial centred on it
                    out.push(Object.assign({}, m, { role: "shape", round: true, colour: scene === "blocks" ? "accent" : "pill" }))
                    const lh = Math.round(e.size * 1.33 * 1.18), d = Math.round((e.hgt - lh) / 2)
                    Object.assign(m, { hgt: undefined, w: undefined, y: m.v === "top" ? m.y - d : m.v === "bottom" ? m.y + d : m.y })
                    if (m.h === "left") m.x += Math.round(e.w / 2 - e.size * 0.45)   // shortcut: ~ half a capital's width
                }
                out.push(m)
            }
            top += h
            if (e.group === "sign") signTop += h
        }
        const edge = { h: left ? "left" : "center", v: align === "bottom" ? "top" : "bottom", x: x0 }
        // now playing: soft draws it as a pill at the edge; the other scenes put it on the edge line
        if (scene === "soft" && l.widgets.includes("media")) {
            const y = align === "bottom" ? -56 : 56
            out.push(Object.assign({ role: "shape", w: 340, hgt: 44, colour: "pill", round: true }, edge, { y: y }))
            out.push(Object.assign({ role: "media", size: 11, weight: Font.Medium, colour: "plain" }, edge, { x: edge.x + (edge.h === "left" ? 22 : 0), y: y + (align === "bottom" ? -13 : 13) }))
        } else if (l.widgets.includes("media"))
            out.push(Object.assign({ role: "media", size: 13, weight: Font.Medium, colour: "muted", mono: scene === "boot" }, edge, { y: align === "bottom" ? -36 : 36 }))
        // the battery in the top-right corner, where a status bar keeps it
        if (l.widgets.includes("battery"))
            out.push({ role: "battery", size: 13, weight: Font.DemiBold, mono: true, colour: "picture", h: "right", v: "top", x: -36, y: -28 })
        return out
    }
    readonly property var elements: layout(clock, align)

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
        case "battery": return Sys.hasBattery ? Sys.batteryGlyph + "  " + Sys.batteryPct + "%" : ""
        case "name": return niceName
        case "initial": return niceName.charAt(0)
        case "caps": return capsText
        }
        return ""
    }
    // the playing track into $m, title · artist, at most 48 letters. Not playerctl --format: its {{ }}
    // is hyprlang's expression syntax, and the label would show hyprlock's "Sample Text"
    readonly property string nowPlaying: "m=$(playerctl metadata title 2>/dev/null); a=$(playerctl metadata artist 2>/dev/null); "
        + "[ -n \"$a\" ] && m=\"$m · $a\"; m=$(printf %s \"$m\" | awk '{ print substr($0, 1, 48) }'); "
    readonly property string capsText: scene === "boot" ? "warning: caps lock is on" : "Caps Lock is on"
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
        // soft's pill always says something; the edge line stays empty with nothing playing
        case "media": return "cmd[update:2000] " + nowPlaying + (scene === "soft" ? "printf '\u266A  %s' \"${m:-Nothing playing}\"" : "[ -n \"$m\" ] && printf '\u266A  %s' \"$m\"")
        case "battery": return "cmd[update:5000] d=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1); [ -n \"$d\" ] && { b=$(cat \"$d/capacity\"); s=$(cat \"$d/status\"); "
            + "if [ \"$s\" = Charging ]; then g='\u{F0084}'; elif [ \"$b\" -gt 90 ]; then g='\u{F0079}'; elif [ \"$b\" -gt 60 ]; then g='\u{F0080}'; "
            + "elif [ \"$b\" -gt 35 ]; then g='\u{F007E}'; elif [ \"$b\" -gt 15 ]; then g='\u{F007B}'; else g='\u{F008E}'; fi; printf '%s  %s%%' \"$g\" \"$b\"; }"
        // your full name from the account (GECOS), else the login name
        case "name": return "cmd[update:0] n=$(getent passwd \"$(id -un)\" | cut -d: -f5 | cut -d, -f1); printf '%s' \"${n:-$(id -un)}\""
        case "initial": return niceName.charAt(0).replace(/[^A-Za-z0-9]/, "")
        // the keyboard's Caps Lock light, read twice a second (hyprlock has no caps lock variable for labels)
        case "caps": return "cmd[update:500] grep -qs 1 /sys/class/leds/*capslock/brightness && printf '%s' '" + capsText + "'"
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
    // text colours by name: plain is the theme's text, for text on a pill or disc rather than on the picture
    // (warn: a light theme's dark amber is lost on a dark picture, so there it is the picture's light text)
    function inkOf(name) { return ({ accent: accent, muted: inkMuted, plain: Theme.text, picture: pictureInk, warn: darkInk || !Theme.light ? Theme.warning : Theme.onImage })[name] ?? ink }
    function colour(e) { const c = inkOf(e.colour); return c.a < 1 ? rgba(c, Number(c.a.toFixed(2))) : "rgb(" + hex(c) + ")" }
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
        // motion: a soft fade in and out, and the field's colour change eased; none in reduced motion
        s += Theme.moves ? "animations {\n    enabled = true\n    bezier = soft, 0.25, 0.1, 0.25, 1\n    animation = fadeIn, 1, 4, soft\n"
                         + "    animation = fadeOut, 1, 3, soft\n    animation = inputFieldColors, 1, 3, soft\n    animation = inputFieldDots, 1, 2, soft\n}\n"
                         : "animations {\n    enabled = false\n}\n"
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
                   + "    capslock_color    = rgb(" + hex(Theme.warning) + ")\n"
                   + "    placeholder_text  = <span foreground=\"##" + hex(boot ? ink : Theme.subtext) + "\">" + (boot ? "_" : "Enter password" + lay) + "</span>\n"
                   + "    fail_text         = " + (boot ? "denied ($ATTEMPTS)" : "$FAIL") + "\n    fail_timeout      = 2500\n    fade_on_empty     = false\n"
                   + (boot ? "    dots_center       = false\n    dots_text_format  = *\n    dots_spacing      = 0.1\n    dots_size         = 0.5\n"
                           : "    dots_center       = true\n    dots_size         = 0.24\n    dots_spacing      = 0.4\n    dots_rounding     = -1\n")
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
