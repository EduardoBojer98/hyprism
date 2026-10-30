import Quickshell
import QtQuick

// Carries the shell's design tokens to the parts of the desktop Quickshell can't draw:
// Hyprland window borders and rounding (live, via hyprctl eval, saved to hypr/settings/theme.lua),
// the lock screen (hypr/hyprlock-theme.conf, read at next lock), and GTK (gsettings accent and
// icon theme). Qt/KDE apps keep following KDE's own settings, which this never writes.
Scope {
    id: root

    readonly property string accentHex: Theme.accent.toString().slice(1, 7)
    readonly property int rounding: Theme.radius
    readonly property string iconTheme: Theme.iconTheme

    // Catppuccin name -> nearest GNOME accent-color value (GTK4/libadwaita apps)
    readonly property var gtkAccent: ({ blue: "blue", lavender: "purple", mauve: "purple", pink: "pink",
        peach: "orange", yellow: "yellow", green: "green", teal: "teal", sky: "blue" })

    function apply() {
        const t = "{ accent = \"" + accentHex + "\", rounding = " + rounding + " }"
        SettingsApp.writeHyprFile("settings/theme.lua", "-- Written by Quickshell ThemeSync from Settings > Appearance\nreturn " + t)
        SettingsApp.writeHyprFile("hyprlock-theme.conf", "# Written by Quickshell ThemeSync from Settings > Appearance\n$accent = rgb(" + accentHex + ")\n$rounding = " + rounding)
        Quickshell.execDetached(["hyprctl", "eval", "THEME = " + t + "; apply_theme()"])
        Quickshell.execDetached(["sh", "-c",
            "gsettings set org.gnome.desktop.interface accent-color " + (gtkAccent[Config.appearance.accent] ?? "blue")
            + "; gsettings set org.gnome.desktop.interface icon-theme '" + iconTheme.replace(/'/g, "") + "'"])
    }

    // Debounced, and only once Config has loaded so defaults never overwrite saved values
    Timer { id: debounce; interval: 400; onTriggered: if (Config.loaded) root.apply() }
    onAccentHexChanged: debounce.restart()
    onRoundingChanged: debounce.restart()
    onIconThemeChanged: debounce.restart()
}
