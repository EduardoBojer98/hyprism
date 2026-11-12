import Quickshell
import Quickshell.Io
import QtQuick

// Carries the active theme (Theme / Themes.qml) to the parts of the desktop Quickshell can't draw:
//   Hyprland   gaps, borders, rounding, shadow, blur, motion preset (live via hyprctl eval, saved to
//              hypr/settings/theme.lua, read by modules/look.lua and modules/animations.lua)
//   hyprlock   hypr/settings/hyprlock-theme.conf: colours, fonts, the theme's lock design
//   GTK        gsettings: light/dark, accent, icons, cursor, UI and mono fonts
//   Ghostty    ghostty/theme.conf: the theme's terminal palette and font, reloaded live
//   fuzzel     fuzzel/theme.ini (emoji picker)
//   Qt apps    qt6ct/colors/hyprism.conf, and qt6ct/qt6ct.conf unless it is yours (env.lua points Qt at qt6ct)
//   btop       btop/themes/hyprism.theme (btop.conf only if there is none: it is yours)
//   prompt     hyprism/starship.toml: ~/.config/starship.toml with its palette block swapped for the theme's
//   wallpaper  the theme's own picture (scripts/theme-wallpaper), unless Settings > Themes > Wallpaper is off
// Qt apps without qt6ct installed keep following KDE's own settings, which this never writes.
// Also writes Config.keybinds to hypr/settings/keybinds.lua and Config.windows to hypr/settings/windows.lua.
Scope {
    id: root

    readonly property var current: Theme.current
    readonly property var h: current.hypr
    readonly property bool light: Theme.light
    readonly property string iconTheme: Theme.iconTheme === "Papirus-Dark" && light ? "Papirus-Light" : Theme.iconTheme
    // only plain folder names reach the shell commands below
    readonly property string cursorTheme: /^[A-Za-z0-9._+ -]+$/.test(Config.appearance.cursorTheme) ? Config.appearance.cursorTheme : ""
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
    readonly property string hyprLua: `{ theme = ${q(current.id)}, gaps_in = ${n(h.gapsIn)}, gaps_out = ${n(h.gapsOut)}, border_size = ${n(h.border)}, `
        + `rounding = ${n(h.rounding)}, active = { ${h.active.map(q).join(", ")} }, inactive = ${q(h.inactive)}, `
        + `shadow = ${q(h.shadow)}, blur = ${h.blur === true}, motion = ${q(Theme.motionLevel === "full" ? h.motion : Theme.motionLevel === "reduced" ? "instant" : "off")}, accent = ${q(hex(Theme.accent))}, `
        + `accent2 = ${q(hex(Theme.accent2))}, cursor = ${q(cursorTheme)}, cursor_size = ${n(cursorSize)} }`

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
                        popover_fg_color: Theme.text, dialog_bg_color: Theme.surfaceColor, dialog_fg_color: Theme.text }
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
        SettingsApp.writeConfigFile("ghostty/theme.conf", "# Written by Quickshell ThemeSync from the active theme (empty: the config's own theme)\n" + terminal,
                                    ["pkill", "-USR2", "-x", "ghostty"])   // SIGUSR2 = reload config
        // qt6ct.conf is ours only if absent or marked by .hyprism; a user's own file is never touched
        put("qt6ct/colors/hyprism.conf", qtColors, ["sh", "-c", 'd="$HOME/.config/qt6ct"; if [ ! -e "$d/qt6ct.conf" ] || [ -e "$d/.hyprism" ]; then printf "[Appearance]\\ncolor_scheme_path=%s/colors/hyprism.conf\\ncustom_palette=true\\nicon_theme=%s\\nstandard_dialogs=default\\nstyle=Fusion\\n" "$d" "$1" > "$d/qt6ct.conf" && : > "$d/.hyprism"; fi',
                                                     "sh", /^[A-Za-z0-9._+ -]+$/.test(iconTheme) ? iconTheme : "Papirus-Dark"])
        // btop.conf is yours: only when there is none, one line that picks the theme
        put("btop/themes/hyprism.theme", btopTheme, ["sh", "-c", 'f="$HOME/.config/btop/btop.conf"; [ -e "$f" ] || printf "color_theme = \\"hyprism\\"\\ntheme_background = False\\n" > "$f"'])
        put("hyprism/starship.toml", starshipToml)
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

    // Only key names Hyprland understands get through; anything else is dropped
    function keybindsLua(o) {
        const lines = []
        for (const id of Object.keys(o).sort()) {
            if (!/^[a-z0-9-]+$/.test(id)) continue
            const k = String(o[id]?.keys ?? "")
            if (k === "") lines.push(`    ["${id}"] = false,`)
            else if (/^[A-Za-z0-9_+: ]+$/.test(k)) lines.push(`    ["${id}"] = "${k}",`)
        }
        return "-- Written by Quickshell from Settings > Keyboard Shortcuts (id = keys, false = off)\nreturn {\n" + lines.join("\n") + "\n}"
    }
    property string lastKeybinds: ""
    function applyKeybinds() {
        const text = keybindsLua(Config.keybinds.overrides)
        if (text === lastKeybinds) return
        const first = lastKeybinds === ""
        lastKeybinds = text
        SettingsApp.writeHyprFile("settings/keybinds.lua", text)
        if (!first) Quickshell.execDetached(["sh", "-c", "sleep 0.3; hyprctl reload"])
    }
    Timer { id: keyDebounce; interval: 300; onTriggered: if (Config.loaded && Themes.ready) root.applyKeybinds() }
    Connections { target: Config.keybinds; function onOverridesChanged() { keyDebounce.restart() } }
    Connections { target: Config; function onLoadedChanged() { keyDebounce.restart() } }

    // Window behaviour, animations and app rules: every option the schema allows, apps reduced to
    // the fields hypr/modules/windows.lua reads
    readonly property string windowsLua: {
        const w = Config.windows, t = {}
        for (const k of Object.keys(Config.schema.windows)) if (k !== "apps") t[k] = w[k]
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
    onGtkAccentChanged: debounce.restart()
}
