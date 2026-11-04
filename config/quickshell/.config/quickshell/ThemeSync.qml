import Quickshell
import QtQuick

// Carries the active rice (Theme / Rices.qml) to the parts of the desktop Quickshell can't draw:
//   Hyprland   gaps, borders, rounding, shadow, blur, motion preset (live via hyprctl eval, saved to
//              hypr/settings/theme.lua, read by modules/look.lua and modules/animations.lua)
//   hyprlock   hypr/settings/hyprlock-theme.conf: colours, fonts, the rice's lock design
//   GTK        gsettings: light/dark, accent, icons, cursor, UI and mono fonts
//   Ghostty    ghostty/theme.conf: the rice's terminal palette and font, reloaded live
//   fuzzel     fuzzel/theme.ini (emoji picker)
//   wallpaper  the rice's own picture (scripts/rice-wallpaper), unless Settings > Rices > Wallpaper is off
// Qt/KDE apps keep following KDE's own settings, which this never writes.
// Also writes Config.keybinds to hypr/settings/keybinds.lua and Config.windows to hypr/settings/windows.lua.
Scope {
    id: root

    readonly property var rice: Theme.rice
    readonly property var h: rice.hypr
    readonly property bool light: Theme.light
    readonly property string iconTheme: Theme.iconTheme === "Papirus-Dark" && light ? "Papirus-Light" : Theme.iconTheme
    // only plain folder names reach the shell commands below
    readonly property string cursorTheme: /^[A-Za-z0-9._+ -]+$/.test(Config.appearance.cursorTheme) ? Config.appearance.cursorTheme : ""
    readonly property int cursorSize: Config.appearance.cursorSize
    readonly property bool animate: Theme.animate
    function hex(c) { return c.toString().slice(1, 7) }

    // Lock screen (Settings > Lock Screen): background and clock format; the design comes from the rice
    readonly property var lock: Config.lockscreen
    readonly property string lockConf: "# Written by Quickshell ThemeSync from the active rice (" + rice.name + ")\n"
        + "$accent = rgb(" + hex(Theme.accent.hslLightness < 0.45 ? "#f5f5f7" : Theme.accent) + ")\n$accent2 = rgb(" + hex(Theme.accent2) + ")\n"
        + "$text = rgb(" + hex(Theme.text) + ")\n$muted = rgb(" + hex(Theme.subtext) + ")\n"
        + "$ground = rgb(" + hex(Theme.base) + ")\n$surface = rgb(" + hex(Theme.surfaceColor) + ")\n"
        + "$fail = rgb(" + hex(Theme.error) + ")\n$rounding = " + Theme.radius + "\n"
        + "$wall = " + (/^[^\n#]+$/.test(lock.wallpaper) ? lock.wallpaper : "~/.config/hypr/settings/wallpaper")
        + "\n$blur = " + lock.blur + "\n$dim = " + lock.brightness
        + "\n$font = " + Theme.font.replace(/[\n#]/g, "") + "\n$display = " + Theme.displayFont + "\n$mono = " + Theme.monoFont
        + "\n$clock = " + (Config.bar.clock24 ? "%H:%M" : "%-I:%M") + "\n$hour = " + (Config.bar.clock24 ? "%H" : "%I")
        + "\nsource = ~/.config/hypr/lockscreens/" + rice.lock + ".conf"
    onLockConfChanged: debounce.restart()

    // Ghostty: the rice's palette (ghostty/themes/<Rice>) and its mono face
    readonly property string terminal: !Config.appearance.terminal ? ""
        : "theme = " + rice.term + "\nfont-family = \"\"\nfont-family = " + (rice.font.mono === "Martian Mono" ? "Martian Mono" : "JetBrainsMono Nerd Font")
          + "\nfont-family = JetBrainsMono Nerd Font"   // "" resets the list; Nerd Font stays as the icon fallback
          + "\nbackground-opacity = " + (Theme.glassy ? "0.86" : "1")   // see-through only in the glass rices

    // accent -> nearest GNOME accent-color value (GTK4/libadwaita apps), by hue; greys -> slate
    readonly property string gtkAccent: {
        const c = Theme.accent
        if (c.hslSaturation < 0.18) return "slate"
        const hue = c.hslHue * 360
        return hue < 15 || hue >= 345 ? "red" : hue < 40 ? "orange" : hue < 65 ? "yellow" : hue < 160 ? "green"
             : hue < 195 ? "teal" : hue < 250 ? "blue" : hue < 300 ? "purple" : "pink"
    }

    // The Hyprland side of the rice, as a Lua table (modules/look.lua: apply_theme)
    readonly property string hyprLua: `{ rice = "${rice.id}", gaps_in = ${h.gapsIn}, gaps_out = ${h.gapsOut}, border_size = ${h.border}, `
        + `rounding = ${h.rounding}, active = { ${h.active.map(x => `"${x}"`).join(", ")} }, inactive = "${h.inactive}", `
        + `shadow = "${h.shadow}", blur = ${h.blur}, motion = "${animate ? h.motion : "off"}", accent = "${hex(Theme.accent)}", `
        + `accent2 = "${hex(Theme.accent2)}", cursor = "${cursorTheme}", cursor_size = ${cursorSize} }`

    function apply() {
        SettingsApp.writeHyprFile("settings/theme.lua", "-- Written by Quickshell ThemeSync from the active rice\nreturn " + hyprLua)
        SettingsApp.writeHyprFile("settings/hyprlock-theme.conf", lockConf)
        Quickshell.execDetached(["hyprctl", "eval", "THEME = " + hyprLua + "; apply_theme()"])
        Quickshell.execDetached(["sh", "-c",
            "gsettings set org.gnome.desktop.interface color-scheme prefer-" + (light ? "light" : "dark")
            + "; gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3" + (light ? "" : "-dark")
            + "; gsettings set org.gnome.desktop.interface accent-color " + gtkAccent
            + "; gsettings set org.gnome.desktop.interface icon-theme '" + iconTheme.replace(/'/g, "") + "'"
            + "; gsettings set org.gnome.desktop.interface font-name '" + Theme.font.replace(/['\\\n]/g, "") + " 11'"
            + (cursorTheme ? "; gsettings set org.gnome.desktop.interface cursor-theme '" + cursorTheme + "'"
                + "; gsettings set org.gnome.desktop.interface cursor-size " + cursorSize : "")])
        // live for Hyprland and apps started from now on; env.lua reads theme.lua at the next login
        if (cursorTheme) Quickshell.execDetached(["hyprctl", "setcursor", cursorTheme, String(cursorSize)])
        const a = hex(Theme.accent)
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$HOME/.config/fuzzel\"; cat > \"$HOME/.config/fuzzel/theme.ini\" <<'QS_EOF'\n# Written by Quickshell ThemeSync from the active rice\n[colors]\n"
            + `background=${hex(Theme.surfaceColor)}f2\ntext=${hex(Theme.text)}ff\ninput=${hex(Theme.text)}ff\nprompt=${a}ff\nmatch=${a}ff\n`
            + `selection=${a}55\nselection-text=${hex(Theme.text)}ff\nselection-match=${hex(Theme.text)}ff\nborder=${a}ff\nQS_EOF`])
        Quickshell.execDetached(["sh", "-c", "cat > \"$HOME/.config/ghostty/theme.conf\" <<'QS_EOF'\n# Written by Quickshell ThemeSync from the active rice (empty: the config's own theme)\n"
            + terminal + "\nQS_EOF\npkill -USR2 -x ghostty || true"])   // SIGUSR2 = reload config
    }

    // The rice's own wallpaper, drawn once per rice into ~/.local/share/linux-setup/rices/
    property string lastWall: ""
    function applyWallpaper() {
        if (!Config.appearance.wallpaper || rice.wall === lastWall) return
        lastWall = rice.wall
        Quickshell.execDetached(["sh", "-c", "p=$(rice-wallpaper \"$1\") && qs ipc call wallpaper set \"$p\"", "sh", rice.wall])
    }
    Timer { id: wallDebounce; interval: 500; onTriggered: if (Config.loaded) root.applyWallpaper() }
    Connections { target: Config.appearance; function onRiceChanged() { root.lastWall = ""; wallDebounce.restart() } function onWallpaperChanged() { root.lastWall = ""; wallDebounce.restart() } }

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
    Timer { id: debounce; interval: 300; onTriggered: if (Config.loaded) root.apply() }
    onHyprLuaChanged: debounce.restart()
    onLightChanged: debounce.restart()
    onIconThemeChanged: debounce.restart()
    onTerminalChanged: debounce.restart()
    onGtkAccentChanged: debounce.restart()
}
