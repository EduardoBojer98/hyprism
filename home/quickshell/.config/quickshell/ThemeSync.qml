import Quickshell
import QtQuick

// Carries the shell's design tokens to the parts of the desktop Quickshell can't draw:
// Hyprland window borders (accent or rotating rainbow, width) and rounding (live, via hyprctl eval, saved to hypr/settings/theme.lua),
// the lock screen (hypr/settings/hyprlock-theme.conf, read at next lock), and GTK (gsettings light/dark,
// accent and icon theme). Qt/KDE apps keep following KDE's own settings, which this never writes.
// Also writes Config.keybinds to hypr/settings/keybinds.lua and reloads Hyprland.
Scope {
    id: root

    readonly property string accentHex: Theme.accent.toString().slice(1, 7)
    readonly property int rounding: Theme.radius
    readonly property string iconTheme: Theme.iconTheme
    readonly property string border: Config.appearance.border
    readonly property int borderSpin: Theme.animate ? Config.appearance.borderSpin : 0
    readonly property int borderSize: Config.appearance.borderSize
    readonly property int gaps: Config.appearance.gaps
    readonly property bool light: Theme.light

    // accent -> nearest GNOME accent-color value (GTK4/libadwaita apps), by hue; greys -> slate
    readonly property string gtkAccent: {
        const c = Theme.accent
        if (c.hslSaturation < 0.18) return "slate"
        const h = c.hslHue * 360
        return h < 15 || h >= 345 ? "red" : h < 40 ? "orange" : h < 65 ? "yellow" : h < 160 ? "green"
             : h < 195 ? "teal" : h < 250 ? "blue" : h < 300 ? "purple" : "pink"
    }

    function apply() {
        const t = `{ accent = "${accentHex}", rounding = ${rounding}, border = "${border}", border_spin = ${borderSpin}, border_size = ${borderSize}, gaps = ${gaps} }`
        SettingsApp.writeHyprFile("settings/theme.lua", "-- Written by Quickshell ThemeSync from Settings > Appearance\nreturn " + t)
        SettingsApp.writeHyprFile("settings/hyprlock-theme.conf", "# Written by Quickshell ThemeSync from Settings > Appearance\n$accent = rgb(" + accentHex + ")\n$rounding = " + rounding)
        Quickshell.execDetached(["hyprctl", "eval", "THEME = " + t + "; apply_theme()"])
        Quickshell.execDetached(["sh", "-c",
            "gsettings set org.gnome.desktop.interface color-scheme prefer-" + (light ? "light" : "dark")
            + "; gsettings set org.gnome.desktop.interface accent-color " + gtkAccent
            + "; gsettings set org.gnome.desktop.interface icon-theme '" + iconTheme.replace(/'/g, "") + "'"])
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

    // Debounced, and only once Config has loaded so defaults never overwrite saved values
    Timer { id: debounce; interval: 400; onTriggered: if (Config.loaded) root.apply() }
    onAccentHexChanged: debounce.restart()
    onRoundingChanged: debounce.restart()
    onLightChanged: debounce.restart()
    onIconThemeChanged: debounce.restart()
    onBorderChanged: debounce.restart()
    onBorderSpinChanged: debounce.restart()
    onBorderSizeChanged: debounce.restart()
    onGapsChanged: debounce.restart()
}
