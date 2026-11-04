import Quickshell
import QtQuick

// Carries the shell's design tokens to the parts of the desktop Quickshell can't draw:
// Hyprland window borders (accent or rotating rainbow, width) and rounding (live, via hyprctl eval, saved to hypr/settings/theme.lua),
// the lock screen (hypr/settings/hyprlock-theme.conf: colours, design, background; read at next lock), and GTK (gsettings light/dark,
// accent, icon and cursor theme), fuzzel (fuzzel/theme.ini) and Ghostty (ghostty/theme.conf: the theme's terminal colours, reloaded live).
// Qt/KDE apps keep following KDE's own settings, which this never writes.
// Also writes Config.keybinds to hypr/settings/keybinds.lua and reloads Hyprland.
// And Config.windows (Settings > Windows) to hypr/settings/windows.lua, applied live.
Scope {
    id: root

    readonly property string accentHex: Theme.accent.toString().slice(1, 7)
    readonly property string accent2Hex: Theme.accent2.toString().slice(1, 7)
    readonly property int rounding: Theme.radius
    readonly property string iconTheme: Theme.iconTheme
    // only plain folder names reach the shell commands below
    readonly property string cursorTheme: /^[A-Za-z0-9._+ -]+$/.test(Config.appearance.cursorTheme) ? Config.appearance.cursorTheme : ""
    readonly property int cursorSize: Config.appearance.cursorSize
    readonly property string border: Config.appearance.border
    readonly property int borderSpin: Theme.animate ? Config.appearance.borderSpin : 0
    readonly property int borderSize: Config.appearance.borderSize
    readonly property int gaps: Config.appearance.gaps
    readonly property bool light: Theme.light
    // Lock screen (Settings > Appearance > Lock Screen): design file, background and clock format
    readonly property var lock: Config.lockscreen
    readonly property string lockConf: "# Written by Quickshell ThemeSync from Settings > Appearance\n$accent = rgb(" + accentHex + ")\n$accent2 = rgb(" + accent2Hex + ")\n$rounding = " + rounding
        + "\n$wall = " + (/^[^\n#]+$/.test(lock.wallpaper) ? lock.wallpaper : "~/.config/hypr/settings/wallpaper")
        + "\n$blur = " + lock.blur + "\n$dim = " + lock.brightness + "\n$font = " + Config.appearance.font.replace(/[\n#]/g, "")
        + "\n$clock = " + (Config.bar.clock24 ? "%H:%M" : "%-I:%M") + "\n$hour = " + (Config.bar.clock24 ? "%H" : "%I")
        + "\nsource = ~/.config/hypr/lockscreens/" + lock.design + ".conf"
    onLockConfChanged: debounce.restart()
    // Ghostty's built-in theme matching the shell theme, on a darker shade of the glass base
    readonly property string terminal: !Config.appearance.terminal ? ""
        : "theme = " + Theme.th.term[light ? 1 : 0] + "\nbackground = " + (light ? Theme.base : Theme.tinted(0.7, 1)).toString().slice(1, 7)

    // accent -> nearest GNOME accent-color value (GTK4/libadwaita apps), by hue; greys -> slate
    readonly property string gtkAccent: {
        const c = Theme.accent
        if (c.hslSaturation < 0.18) return "slate"
        const h = c.hslHue * 360
        return h < 15 || h >= 345 ? "red" : h < 40 ? "orange" : h < 65 ? "yellow" : h < 160 ? "green"
             : h < 195 ? "teal" : h < 250 ? "blue" : h < 300 ? "purple" : "pink"
    }

    function apply() {
        const t = `{ accent = "${accentHex}", accent2 = "${accent2Hex}", rounding = ${rounding}, border = "${border}", border_spin = ${borderSpin}, border_size = ${borderSize}, gaps = ${gaps}, cursor = "${cursorTheme}", cursor_size = ${cursorSize} }`
        SettingsApp.writeHyprFile("settings/theme.lua", "-- Written by Quickshell ThemeSync from Settings > Appearance\nreturn " + t)
        SettingsApp.writeHyprFile("settings/hyprlock-theme.conf", lockConf)
        Quickshell.execDetached(["hyprctl", "eval", "THEME = " + t + "; apply_theme()"])
        Quickshell.execDetached(["sh", "-c",
            "gsettings set org.gnome.desktop.interface color-scheme prefer-" + (light ? "light" : "dark")
            + "; gsettings set org.gnome.desktop.interface accent-color " + gtkAccent
            + "; gsettings set org.gnome.desktop.interface icon-theme '" + iconTheme.replace(/'/g, "") + "'"
            + (cursorTheme ? "; gsettings set org.gnome.desktop.interface cursor-theme '" + cursorTheme + "'"
                + "; gsettings set org.gnome.desktop.interface cursor-size " + cursorSize : "")])
        // live for Hyprland and apps started from now on; env.lua reads theme.lua at the next login
        if (cursorTheme) Quickshell.execDetached(["hyprctl", "setcursor", cursorTheme, String(cursorSize)])
        const hex = c => c.toString().slice(1, 7)
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.config/fuzzel\"; cat > \"$HOME/.config/fuzzel/theme.ini\" <<'QS_EOF'\n# Written by Quickshell ThemeSync from Settings > Appearance\n[colors]\n"
            + `background=${hex(Theme.base)}f2\ntext=${hex(Theme.text)}ff\ninput=${hex(Theme.text)}ff\nprompt=${accentHex}ff\nmatch=${accentHex}ff\n`
            + `selection=${accentHex}55\nselection-text=${hex(Theme.text)}ff\nselection-match=${hex(Theme.text)}ff\nborder=${accentHex}ff\nQS_EOF`])
        Quickshell.execDetached(["sh", "-c", "cat > \"$HOME/.config/ghostty/theme.conf\" <<'QS_EOF'\n# Written by Quickshell ThemeSync from Settings > Appearance (empty: the config's own theme)\n"
            + terminal + "\nQS_EOF\npkill -USR2 -x ghostty || true"])   // SIGUSR2 = reload config
    }

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
    Timer { id: keyDebounce; interval: 300; onTriggered: if (Config.loaded) root.applyKeybinds() }
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
    Timer { id: winDebounce; interval: 300; onTriggered: if (Config.loaded) root.applyWindows() }
    onWindowsLuaChanged: winDebounce.restart()
    Connections { target: Config; function onLoadedChanged() { winDebounce.restart() } }

    // Debounced, and only once Config has loaded so defaults never overwrite saved values
    Timer { id: debounce; interval: 400; onTriggered: if (Config.loaded) root.apply() }
    onAccentHexChanged: debounce.restart()
    onRoundingChanged: debounce.restart()
    onLightChanged: debounce.restart()
    onIconThemeChanged: debounce.restart()
    onCursorThemeChanged: debounce.restart()
    onCursorSizeChanged: debounce.restart()
    onBorderChanged: debounce.restart()
    onBorderSpinChanged: debounce.restart()
    onBorderSizeChanged: debounce.restart()
    onGapsChanged: debounce.restart()
    onTerminalChanged: debounce.restart()
}
