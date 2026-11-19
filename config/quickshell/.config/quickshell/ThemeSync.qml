import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import "WindowFrames.js" as Frames

// Carries the active theme (Theme / Themes.qml) to the parts of the desktop Quickshell can't draw:
//   Hyprland   gaps, borders, rounding, shadow, blur, motion preset (live via hyprctl eval, saved to
//              hypr/settings/theme.lua, read by modules/look.lua and modules/animations.lua)
//   hyprlock   hypr/settings/hyprlock-theme.conf: colours, fonts, the theme's lock design
//   GTK        gsettings: light/dark, accent, icons, cursor, UI and mono fonts
//   Ghostty    ghostty/theme.conf: the theme's terminal palette and font, reloaded live
//   fuzzel     fuzzel/theme.ini (emoji picker)
//   Qt apps    qt6ct/colors/hyprism.conf, and qt6ct/qt6ct.conf unless it is yours (env.lua points Qt at qt6ct)
//   KDE apps   ~/.local/share/color-schemes/Hyprism.colors, picked by hyprism/kde/kdeglobals (env.lua, with qt6ct)
//   btop       btop/themes/hyprism.theme (btop.conf only if there is none: it is yours)
//   fish       hyprism/fish.fish: transient prompt and greeting (Config.terminal), sourced by fish/conf.d/tools.fish
//   prompt     hyprism/starship.toml: ~/.config/starship.toml with its palette block swapped for the theme's
//   wallpaper  the theme's own picture (scripts/theme-wallpaper), unless Settings > Themes > Wallpaper is off
// Qt apps without qt6ct installed keep following KDE's own settings, which this never writes.
// Also writes Config.keybinds to hypr/settings/keybinds.lua and Config.windows to hypr/settings/windows.lua.
Scope {
    id: root

    readonly property var current: Theme.current
    readonly property var h: current.hypr
    readonly property bool light: Theme.light
    readonly property string iconTheme: Theme.iconTheme === "Papirus" || (Theme.iconTheme === "Papirus-Dark" && light) ? (light ? "Papirus-Light" : "Papirus-Dark")
        : Theme.iconTheme === "breeze" && !light ? "breeze-dark" : Theme.iconTheme
    // only plain folder names reach the shell commands below (a missing one: apps fall back to the system's)
    readonly property string cursorTheme: /^[A-Za-z0-9._+ -]+$/.test(Theme.cursorTheme) ? Theme.cursorTheme : ""
    readonly property int cursorSize: Config.appearance.cursorSize
    readonly property bool animate: Theme.animate
    function hex(c) { return c.toString().slice(1, 7) }
    // a font name as it may go into a config line or a quoted shell word: letters, digits, space . _ + -
    function safeFont(f) { return /^[A-Za-z0-9 ._+-]+$/.test(f) ? f : "sans-serif" }

    // Lock screen (Settings > Lock Screen): colours and background, then the layout from LockScreen.qml
    readonly property var lock: Config.lockscreen
    readonly property string lockConf: "# Written by Quickshell ThemeSync from the active theme (" + current.name + ")\n"
        + "$accent = rgb(" + hex(Theme.accent.hslLightness < 0.45 ? Theme.onImage : Theme.accent) + ")\n$accent2 = rgb(" + hex(Theme.accent2) + ")\n"
        + "$text = rgb(" + hex(Theme.text) + ")\n$muted = rgb(" + hex(Theme.subtext) + ")\n"
        + "$ground = rgb(" + hex(Theme.base) + ")\n$surface = rgb(" + hex(Theme.surfaceColor) + ")\n"
        + "$fail = rgb(" + hex(Theme.error) + ")\n$rounding = " + Theme.radius + "\n"
        + "$wall = " + (/^~?[A-Za-z0-9 ._\/+-]+$/.test(lock.wallpaper) ? lock.wallpaper : "~/.config/hypr/settings/wallpaper")   // a plain path only
        + "\n$blur = " + lock.blur + "\n$dim = " + lock.brightness
        + "\n$font = " + safeFont(Theme.font) + "\n$display = " + safeFont(Theme.displayFont) + "\n$mono = " + safeFont(Theme.monoFont)
        + "\n\n" + LockScreen.conf
    onLockConfChanged: debounce.restart()

    // Ghostty: the theme's own terminal palette (theme.json "term") and its mono face
    function hexOk(c) { return /^#[0-9a-fA-F]{6}$/.test(c) }
    readonly property string palette: {
        const t = current.term ?? {}, lines = []
        for (const [key, name] of [["background", "background"], ["foreground", "foreground"], ["cursor", "cursor-color"], ["cursorText", "cursor-text"],
                                   ["selection", "selection-background"], ["selectionText", "selection-foreground"]])
            if (hexOk(t[key])) lines.push(name + " = " + t[key])
        ;(Array.isArray(t.palette) ? t.palette : []).slice(0, 16).forEach((c, i) => { if (hexOk(c)) lines.push("palette = " + i + "=" + c) })
        return lines.join("\n")
    }
    readonly property string terminal: !Config.appearance.terminal ? ""
        : palette + "\nfont-family = \"\"\nfont-family = " + (current.font.mono === "Martian Mono" ? "Martian Mono" : "JetBrainsMono Nerd Font")
          + "\nfont-family = JetBrainsMono Nerd Font"   // "" resets the list; Nerd Font stays as the icon fallback
          + "\nbackground-opacity = " + (Theme.glassy ? "0.86" : "1")   // see-through only in the glass themes
    // Settings > Appearance > Terminal: each pick, or the theme's term look when "theme" (only while Ghostty follows the theme)
    readonly property var tc: Config.terminal
    readonly property string termLook: {
        const t = current.term ?? {}, own = Config.appearance.terminal, lines = []
        const cursor = tc.cursor !== "theme" ? tc.cursor : own ? t.cursorStyle : null
        // shell integration would turn it into a bar at every prompt
        if (["block", "bar", "underline", "block_hollow"].includes(cursor)) lines.push("cursor-style = " + cursor, "shell-integration-features = no-cursor")
        const blink = tc.blink !== "theme" ? tc.blink === "on" : own ? t.blink : null
        if (typeof blink === "boolean") lines.push("cursor-style-blink = " + blink)
        const opacity = ({ solid: "1", soft: "0.92", clear: "0.8" })[tc.opacity]
        if (opacity) lines.push("background-opacity = " + opacity)
        const pad = ({ tight: [6, 4], normal: [12, 10], roomy: [20, 16] })[tc.padding] ?? (own && Array.isArray(t.padding) ? t.padding : null)
        if (pad) lines.push("window-padding-x = " + n(pad[0]), "window-padding-y = " + n(pad[1]))
        // the jump smear, then the typing effect (Ghostty chains custom shaders in order); its animation loop runs while a
        // terminal has focus, so only in full motion and on AC (like the moving window frame)
        if (tc.trail && Theme.motionLevel === "full" && !UPower.onBattery) {
            const dir = Quickshell.env("HOME") + "/.config/ghostty/shaders/"
            lines.push("custom-shader = " + dir + "hyprism-trail.glsl")
            if (["pulse", "sparks", "ghost", "ripple"].includes(tc.typing)) lines.push("custom-shader = " + dir + "hyprism-type-" + tc.typing + ".glsl")
        }
        return lines.join("\n")
    }
    // fish, read by fish/conf.d/tools.fish when a shell starts. CachyOS's config.fish (sourced after conf.d) redefines
    // fish_greeting as plain `fastfetch`, so until the first prompt `fastfetch` itself stands in for our greeting too.
    readonly property string greetingBody: tc.greeting === "off" ? "    true\n"
        : tc.greeting === "fastfetch" ? "    command -q fastfetch; and command fastfetch\n"
        // a random Pokémon in fastfetch's logo slot, one box size for all (scripts/pokemon-card); else the distro's logo
        : tc.greeting === "pokemon" ? "    command -q fastfetch; or return\n    set -l card (pokemon-card 2>/dev/null | string collect)\n"
            + "    if test -n \"$card\"\n        command fastfetch --logo-type data-raw --logo \"$card\"\n"
            + "    else\n        command fastfetch\n    end\n"
        // a bonsai grown fresh each time (cbonsai, print mode) holding a short fortune; without cbonsai just the fortune
        : tc.greeting === "bonsai" ? "    set -l msg\n    command -q fortune; and set msg (fortune -s -n 110 | string join ' ' | string trim)\n"
            + "    if command -q cbonsai\n        cbonsai --print --life 34 --multiplier 4 --base 1 (test -n \"$msg\"; and printf '%s\\n' --message $msg)\n"
            + "    else if test -n \"$msg\"\n        echo \"  $msg\"\n    end\n" : ""
    readonly property string fishConf: "# Written by Quickshell ThemeSync from Settings > Appearance > Terminal\n"
        + (tc.transientPrompt ? "functions -q enable_transience; and enable_transience\n" : "")
        + (greetingBody === "" ? "" : "function __hyprism_greeting\n" + greetingBody + "end\n"
           + "function fish_greeting; __hyprism_greeting; end\n"
           + "function fastfetch --wraps fastfetch; if set -q argv[1]; command fastfetch $argv; else; __hyprism_greeting; end; end\n"
           + "function __hyprism_greeting_done --on-event fish_prompt; functions -e fastfetch __hyprism_greeting_done; end\n")

    // accent -> nearest GNOME accent-color value (GTK4/libadwaita apps), by hue; greys -> slate
    readonly property string gtkAccent: {
        const c = Theme.accent
        if (c.hslSaturation < 0.18) return "slate"
        const hue = c.hslHue * 360
        return hue < 15 || hue >= 345 ? "red" : hue < 40 ? "orange" : hue < 65 ? "yellow" : hue < 160 ? "green"
             : hue < 195 ? "teal" : hue < 250 ? "blue" : hue < 300 ? "purple" : "pink"
    }

    // The Hyprland side of the theme, as a Lua table (modules/look.lua: apply_theme). Every string is quoted by
    // JSON.stringify (a valid Lua string) and numbers are forced to numbers, so a hand-edited or shared theme
    // can't put code into Hyprland's config.
    function q(v) { return JSON.stringify(String(v)) }
    function n(v) { const x = Number(v); return isFinite(x) ? x : 0 }
    // The focused window's frame: Config.windows.border = theme (the theme's own hypr.frame, accent when it has none) |
    // accent | gradient | neon | mono | rainbow | sunset | ocean | custom; the colours come from WindowFrames.js, which
    // the Settings previews share. A frame of two or more colours turns only when you ask (Config.windows.borderAnimate),
    // with motion Full, power mode not Silent and on AC (unless rainbowOnBattery); else it stands still at your angle.
    // Unfocused windows keep the theme's inactive colour.
    readonly property string frameStyle: { const s = Config.windows.border; return s !== "theme" ? s : (h.frame ?? "accent") }
    readonly property var borderActive: Frames.colours(frameStyle, { accent: "#" + hex(Theme.accent), accent2: "#" + hex(Theme.accent2),
        text: "#" + hex(Theme.text), light: Theme.light, own: h.active, custom: Config.windows.borderColors })
    readonly property bool borderLoops: borderActive.length > 1 && Config.windows.borderAnimate && Theme.motionLevel === "full"
                                        && PowerMode.profile !== 0 && (!UPower.onBattery || Config.windows.rainbowOnBattery)
    // neon: a glow in the frame's colour around the focused window (look.lua tints Hyprland's shadow); "" = the theme's shadow
    readonly property string glow: frameStyle === "neon" ? borderActive[0].slice(0, 6) : ""
    // Title bars (hyprbars, hypr/modules/plugins.lua): the theme's panel surface, its text and type; unfocused windows'
    // titles in the secondary text and their buttons in the raised tone. Height follows the theme's density
    // (Settings > Windows can pick a size instead).
    readonly property int barHeight: Math.round(28 * Math.sqrt(Theme.density))
    readonly property string hyprLua: `{ theme = ${q(current.id)}, gaps_in = ${n(h.gapsIn)}, gaps_out = ${n(h.gapsOut)}, border_size = ${n(h.border)}, `
        + `rounding = ${n(h.rounding)}, active = { ${borderActive.map(q).join(", ")} }, border_loop = ${borderLoops}, border_speed = ${n(Config.windows.rainbowSpeed)}, `
        + `border_angle = ${n(Config.windows.borderAngle)}, glow = ${q(glow)}, inactive = ${q(h.inactive)}, `
        + `shadow = ${q(h.shadow)}, blur = ${h.blur === true}, motion = ${q(Theme.hyprMotion)}, accent = ${q(hex(Theme.accent))}, `
        + `accent2 = ${q(hex(Theme.accent2))}, cursor = ${q(cursorTheme)}, cursor_size = ${n(cursorSize)}, `
        + `bar = ${q(hex(Theme.surfaceColor) + (Theme.glassy ? "e6" : "ff"))}, bar_text = ${q(hex(Theme.text) + "ff")}, `
        + `bar_text_dim = ${q(hex(Theme.subtext) + "ff")}, bar_buttons_dim = ${q(hex(Theme.raised) + "ff")}, `
        + `bar_font = ${q(safeFont(Theme.font))}, bar_height = ${n(barHeight)}, bar_blur = ${Theme.glassy} }`

    // Qt apps (qt6ct), btop and the starship prompt: texts built from the same tokens, written only when they change.
    // Colours are checked as #rrggbb before they go into a file.
    function hx(c) { const t = String(c); return hexOk(t) ? t.slice(1) : "808080" }
    function aarrggbb(c) { return "#ff" + hx(c) }
    // the 21 QPalette roles: WindowText Button Light Midlight Dark Mid Text BrightText ButtonText Base Window Shadow
    // Highlight HighlightedText Link LinkVisited AlternateBase NoRole ToolTipBase ToolTipText PlaceholderText
    function qtRoles(fg) {
        return [fg, Theme.raised, Qt.lighter(Theme.raised, 1.3), Qt.lighter(Theme.raised, 1.15), Qt.darker(Theme.surfaceColor, 1.4), Theme.stroke,
                fg, Theme.text, fg, Theme.surfaceColor, Theme.base, Qt.darker(Theme.base, 3), Theme.accent, Theme.accentText, Theme.accent2,
                Theme.accent2, Theme.raised, Theme.base, Theme.raised, Theme.text, Theme.subtext].map(aarrggbb).join(", ")
    }
    readonly property string qtColors: "[ColorScheme]\nactive_colors=" + qtRoles(Theme.text) + "\ndisabled_colors=" + qtRoles(Theme.muted)
        + "\ninactive_colors=" + qtRoles(Theme.text)
    // KDE apps (Dolphin, Kate, Okular) ignore qt6ct's palette: outside Plasma KDE's colour-scheme manager finds no
    // scheme and loads Breeze Light over it. This is a KDE scheme from the same tokens; env.lua makes KDE apps
    // pick it in Hyprland only (hyprism/kde/kdeglobals on XDG_CONFIG_DIRS), so Plasma keeps its own.
    // Surfaces as in GTK (panels' surface, not the ground). Colours are "r,g,b".
    function rgb(c) { const t = hx(c); return [0, 2, 4].map(i => parseInt(t.slice(i, i + 2), 16)).join(",") }
    readonly property string kdeColors: {
        const set = (name, bg, alt, fg, dim, act) => `[Colors:${name}]\n` + [["BackgroundNormal", bg], ["BackgroundAlternate", alt],
            ["ForegroundNormal", fg], ["ForegroundInactive", dim], ["ForegroundActive", act], ["ForegroundLink", Theme.accent2],
            ["ForegroundVisited", Theme.accent2], ["ForegroundNegative", Theme.error], ["ForegroundNeutral", Theme.warning],
            ["ForegroundPositive", Theme.success], ["DecorationFocus", Theme.accent], ["DecorationHover", Theme.accent]]
            .map(([k, c]) => k + "=" + rgb(c)).join("\n")
        const s = Theme.surfaceColor, r = Theme.raised, t = Theme.text, d = Theme.subtext, a = Theme.accent
        return "# Written by Quickshell ThemeSync from the active theme\n[General]\nColorScheme=Hyprism\nName=Hyprism\n\n"
            + [set("View", s, r, t, d, a), set("Window", s, r, t, d, a), set("Header", s, r, t, d, a), set("Button", r, s, t, d, a),
               set("Tooltip", r, s, t, d, a), set("Complementary", s, r, t, d, a),
               set("Selection", a, a, Theme.accentText, Theme.accentText, Theme.accentText)].join("\n\n")
    }
    readonly property string btopTheme: {
        const t = []
        const put = (k, c) => t.push(`theme[${k}]="#${hx(c)}"`)
        put("main_bg", Theme.base); put("main_fg", Theme.text); put("title", Theme.text); put("hi_fg", Theme.accent)
        put("selected_bg", Theme.accent); put("selected_fg", Theme.accentText); put("inactive_fg", Theme.muted)
        put("graph_text", Theme.subtext); put("meter_bg", Theme.raised); put("proc_misc", Theme.accent2)
        for (const b of ["cpu_box", "mem_box", "net_box", "proc_box", "div_line"]) put(b, Theme.stroke)
        // graphs running ok -> warn -> err; memory and network keep one hue each
        const ramp = { temp: null, cpu: null, used: null, process: null, free: Theme.success, cached: Theme.accent2, available: Theme.accent, download: Theme.accent, upload: Theme.accent2 }
        for (const [name, one] of Object.entries(ramp))
            [one ?? Theme.success, one ?? Theme.warning, one ?? Theme.error].forEach((c, i) => put(name + "_" + ["start", "mid", "end"][i], c))
        return "# Written by Quickshell ThemeSync from the active theme\n" + t.join("\n")
    }
    FileView { id: starshipSrc; path: Quickshell.env("HOME") + "/.config/starship.toml"; watchChanges: true; onFileChanged: reload(); onLoaded: debounce.restart() }
    readonly property string starshipToml: {
        const src = starshipSrc.text()
        if (src.indexOf("[palettes.hyprism]") < 0) return ""
        const block = "[palettes.hyprism]\n" + [["accent", Theme.accent], ["on_accent", Theme.accentText], ["accent2", Theme.accent2], ["raised", Theme.raised],
            ["ok", Theme.success], ["warn", Theme.warning], ["err", Theme.error], ["faint", Theme.muted]].map(([k, c]) => `${k} = "#${hx(c)}"`).join("\n") + "\n"
        return src.replace(/\[palettes\.hyprism\][\s\S]*$/, () => block)
    }
    property var written: ({})
    // write only when the text differs from what was last written (once per start at least)
    function put(rel, text, then) {
        if (text === "" || written[rel] === text) return
        written[rel] = text
        SettingsApp.writeConfigFile(rel, text, then)
    }
    onQtColorsChanged: debounce.restart()
    onKdeColorsChanged: debounce.restart()
    onBtopThemeChanged: debounce.restart()
    onStarshipTomlChanged: debounce.restart()

    function apply() {
        SettingsApp.writeHyprFile("settings/theme.lua", "-- Written by Quickshell ThemeSync from the active theme\nreturn " + hyprLua)
        SettingsApp.writeHyprFile("settings/hyprlock-theme.conf", lockConf)
        Quickshell.execDetached(["hyprctl", "eval", "THEME = " + hyprLua + "; apply_theme()"])
        // GTK: one gsettings call per key, each value its own argument (no shell, nothing to quote)
        const gtk = [["color-scheme", "prefer-" + (light ? "light" : "dark")], ["gtk-theme", "adw-gtk3" + (light ? "" : "-dark")],
                     ["accent-color", gtkAccent], ["icon-theme", /^[A-Za-z0-9._+ -]+$/.test(iconTheme) ? iconTheme : "Papirus-Dark"],
                     ["font-name", safeFont(Theme.font) + " 11"], ["monospace-font-name", safeFont(Theme.monoFont) + " 11"]]
            .concat(cursorTheme ? [["cursor-theme", cursorTheme], ["cursor-size", String(cursorSize)]] : [])
        Quickshell.execDetached(["sh", "-c", 'while [ $# -gt 1 ]; do gsettings set org.gnome.desktop.interface "$1" "$2"; shift 2; done', "sh"]
                                .concat(...gtk))
        // the theme's surfaces, text and exact accent for GTK 3 (adw-gtk3) and GTK 4 apps, in our own file
        // that gtk.css imports (gtk.css and colors.css belong to KDE, which rewrites them at its login; we only
        // add the import). Panels' surface, not the desktop ground: Poster's ground is dark under paper panels.
        const named = { accent_color: Theme.accent, accent_bg_color: Theme.accent, accent_fg_color: Theme.accentText,
                        window_bg_color: Theme.surfaceColor, window_fg_color: Theme.text, view_bg_color: Theme.surfaceColor,
                        view_fg_color: Theme.text, headerbar_bg_color: Theme.raised, headerbar_fg_color: Theme.text,
                        card_bg_color: Theme.raised, card_fg_color: Theme.text, popover_bg_color: Theme.surfaceColor,
                        popover_fg_color: Theme.text, dialog_bg_color: Theme.surfaceColor, dialog_fg_color: Theme.text,
                        // libadwaita 1.4+ sidebars (Nautilus, Settings-style apps): else its own blue-grey
                        sidebar_bg_color: Theme.raised, sidebar_fg_color: Theme.text, sidebar_backdrop_color: Theme.raised,
                        secondary_sidebar_bg_color: Theme.raised, secondary_sidebar_fg_color: Theme.text,
                        secondary_sidebar_backdrop_color: Theme.raised }
        const css = "/* Written by Quickshell ThemeSync from the active theme */\n"
            + Object.keys(named).map(k => `@define-color ${k} ${named[k]};`).join("\n") + "\n"
        for (const v of ["gtk-3.0", "gtk-4.0"])
            SettingsApp.writeConfigFile(v + "/hyprism.css", css,
                ["sh", "-c", 'f="$HOME/.config/$1/gtk.css"; grep -qF "@import \'hyprism.css\';" "$f" 2>/dev/null || printf "\\n%s\\n" "@import \'hyprism.css\';" >> "$f"', "sh", v])
        // live for Hyprland and apps started from now on; env.lua reads theme.lua at the next login
        if (cursorTheme) Quickshell.execDetached(["hyprctl", "setcursor", cursorTheme, String(cursorSize)])
        const a = hex(Theme.accent)
        SettingsApp.writeConfigFile("fuzzel/theme.ini", "# Written by Quickshell ThemeSync from the active theme\n[colors]\n"
            + `background=${hex(Theme.surfaceColor)}f2\ntext=${hex(Theme.text)}ff\ninput=${hex(Theme.text)}ff\nprompt=${a}ff\nmatch=${a}ff\n`
            + `selection=${a}55\nselection-text=${hex(Theme.text)}ff\nselection-match=${hex(Theme.text)}ff\nborder=${a}ff`)
        SettingsApp.writeConfigFile("ghostty/theme.conf", "# Written by Quickshell ThemeSync from the active theme (empty: the config's own theme)\n" + terminal + "\n" + termLook,
                                    ["pkill", "-USR2", "-x", "ghostty"])   // SIGUSR2 = reload config
        // qt6ct.conf is ours only if absent or marked by .hyprism; a user's own file is never touched
        put("qt6ct/colors/hyprism.conf", qtColors, ["sh", "-c", 'd="$HOME/.config/qt6ct"; if [ ! -e "$d/qt6ct.conf" ] || [ -e "$d/.hyprism" ]; then printf "[Appearance]\\ncolor_scheme_path=%s/colors/hyprism.conf\\ncustom_palette=true\\nicon_theme=%s\\nstandard_dialogs=default\\nstyle=Fusion\\n" "$d" "$1" > "$d/qt6ct.conf" && : > "$d/.hyprism"; fi',
                                                     "sh", /^[A-Za-z0-9._+ -]+$/.test(iconTheme) ? iconTheme : "Papirus-Dark"])
        // ~/.config-relative, like every write here; KDE looks for schemes in ~/.local/share/color-schemes
        put("../.local/share/color-schemes/Hyprism.colors", kdeColors)
        put("hyprism/kde/kdeglobals", "# Written by Quickshell ThemeSync: KDE apps in Hyprland use the Hyprism scheme\n[UiSettings]\nColorScheme=Hyprism")
        // btop.conf is yours: only when there is none, one line that picks the theme
        put("btop/themes/hyprism.theme", btopTheme, ["sh", "-c", 'f="$HOME/.config/btop/btop.conf"; [ -e "$f" ] || printf "color_theme = \\"hyprism\\"\\ntheme_background = False\\n" > "$f"'])
        put("hyprism/starship.toml", starshipToml)
        put("hyprism/fish.fish", fishConf)
    }

    // The theme's own wallpaper, drawn once per theme into ~/.cache/hyprism/wallpapers/
    property string lastWall: ""
    function applyWallpaper() {
        if (!Config.appearance.wallpaper || current.wall === lastWall) return
        lastWall = current.wall
        Quickshell.execDetached(["sh", "-c", "p=$(theme-wallpaper \"$1\") && qs ipc call wallpaper set \"$p\"", "sh", current.wall])
    }
    Timer { id: wallDebounce; interval: 500; onTriggered: if (Config.loaded && Themes.ready) root.applyWallpaper() }
    // First login: no wallpaper has been set yet, so draw the default theme's own (later logins keep what is set)
    Connections { target: Config; function onLoadedChanged() { if (Config.loaded && Config.wallpaper.current === "") wallDebounce.restart() } }
    // the theme folders arrive a moment after start: push the real theme then
    Connections { target: Themes; function onReadyChanged() { debounce.restart(); wallDebounce.restart() } }
    Connections { target: Config.appearance; function onThemeChanged() { root.lastWall = ""; wallDebounce.restart() } function onModeChanged() { wallDebounce.restart() } function onWallpaperChanged() { root.lastWall = ""; wallDebounce.restart() } }

    // Only key names Hyprland understands get through; anything else is dropped. `custom`: your shortcuts, each
    // running an action (binds.lua binds them to `qs ipc call actions run <id>`; the name is for the cheat sheet)
    function keybindsLua(o, custom, portal) {
        const lines = []
        for (const id of Object.keys(o).sort()) {
            if (!/^[a-z0-9-]+$/.test(id)) continue
            const k = String(o[id]?.keys ?? "")
            if (k === "") lines.push(`    ["${id}"] = false,`)
            else if (/^[A-Za-z0-9_+: ]+$/.test(k)) lines.push(`    ["${id}"] = "${k}",`)
        }
        const mine = Array.from(custom ?? []).filter(c => /^[A-Za-z0-9_+: ]+$/.test(c?.keys ?? "") && /^[a-z0-9][a-z0-9-]*$/.test(c?.action ?? ""))
            .map(c => `        { keys = "${c.keys}", action = "${c.action}", name = ${JSON.stringify(String(Actions.get(c.action)?.name ?? c.action).replace(/[\x00-\x1f"\\|]/g, ""))} },`)
        if (mine.length) lines.push("    custom = {\n" + mine.join("\n") + "\n    },")
        // keys for the shortcuts apps register through the portal (XDPH): binds.lua binds them to hl.dsp.global(name)
        const apps = Array.from(portal ?? []).filter(c => /^[A-Za-z0-9_+: ]+$/.test(c?.keys ?? "") && /^[A-Za-z0-9._:+@ -]{3,160}$/.test(c?.name ?? ""))
            .map(c => `        { keys = "${c.keys}", name = "${c.name}", label = ${JSON.stringify(String(c.label || c.name).replace(/[\x00-\x1f"\\|]/g, ""))} },`)
        if (apps.length) lines.push("    portal = {\n" + apps.join("\n") + "\n    },")
        return "-- Written by Quickshell from Settings > Keyboard Shortcuts (id = keys, false = off; custom = your shortcuts)\nreturn {\n" + lines.join("\n") + "\n}"
    }
    property string lastKeybinds: ""
    function applyKeybinds() {
        const text = keybindsLua(Config.keybinds.overrides, Config.keybinds.custom, Config.keybinds.portal)
        if (text === lastKeybinds) return
        const first = lastKeybinds === ""
        lastKeybinds = text
        SettingsApp.writeHyprFile("settings/keybinds.lua", text)
        if (!first) Quickshell.execDetached(["sh", "-c", "sleep 0.3; hyprctl reload"])
    }
    Timer { id: keyDebounce; interval: 300; onTriggered: if (Config.loaded && Themes.ready) root.applyKeybinds() }
    Connections { target: Config.keybinds; function onOverridesChanged() { keyDebounce.restart() } function onCustomChanged() { keyDebounce.restart() } function onPortalChanged() { keyDebounce.restart() } }
    Connections { target: Config; function onLoadedChanged() { keyDebounce.restart() } }

    // Window behaviour, animations and app rules: every option the schema allows, apps reduced to
    // the fields hypr/modules/windows.lua reads
    readonly property string windowsLua: {
        const w = Config.windows, t = {}
        // borderColors goes with the theme (hyprLua), not here
        for (const k of Object.keys(Config.schema.windows)) if (k !== "apps" && k !== "borderColors") t[k] = w[k]
        t.apps = (w.apps ?? []).filter(a => typeof a?.class === "string" && a.class !== "")
            .map(a => ({ class: a.class, open: String(a.open ?? "normal"), workspace: Number(a.workspace) || 0, pin: a.pin === true }))
        return SettingsApp.lua(t)
    }
    function applyWindows() {
        Quickshell.execDetached(["hyprctl", "eval", "WINDOWS = " + windowsLua.replace(/\n/g, " ") + "; apply_windows()"])
        SettingsApp.writeHyprFile("settings/windows.lua", "-- Written by Quickshell from Settings > Windows. Safe to edit by hand.\nreturn " + windowsLua)
    }
    Timer { id: winDebounce; interval: 300; onTriggered: if (Config.loaded && Themes.ready) root.applyWindows() }
    onWindowsLuaChanged: winDebounce.restart()
    Connections { target: Config; function onLoadedChanged() { winDebounce.restart() } }

    // Debounced, and only once Config has loaded so defaults never overwrite saved values
    Timer { id: debounce; interval: 300; onTriggered: if (Config.loaded && Themes.ready) root.apply() }
    onHyprLuaChanged: debounce.restart()
    Connections { target: Config; function onLoadedChanged() { debounce.restart() } }   // at login: the whole look once, even if nothing changed
    onLightChanged: debounce.restart()
    onIconThemeChanged: debounce.restart()
    onTerminalChanged: debounce.restart()
    onTermLookChanged: debounce.restart()
    onFishConfChanged: debounce.restart()
    onGtkAccentChanged: debounce.restart()
}
