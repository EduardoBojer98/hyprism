import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Icons: the icon theme for GTK apps and this session. The shell's own icons use Papirus-Dark
// (shell.qml pragma, applied at the next shell restart). Qt/KDE apps (Dolphin) follow KDE's
// icon setting, which this page never changes; it is already Papirus.
ColumnLayout {
    id: page
    spacing: 20
    property var themes: []

    Process {
        running: true
        command: ["sh", "-c", "for d in \"$HOME/.local/share/icons\"/* /usr/share/icons/*; do [ -f \"$d/index.theme\" ] && ! [ -d \"$d/cursors\" ] && basename \"$d\"; done | sort -u"]
        stdout: StdioCollector { onStreamFinished: page.themes = text.trim().split("\n").filter(t => t && t !== "default" && t !== "hicolor" && t !== "locolor") }
    }

    SettingGroup {
        SettingRow {
            label: "Icon theme"
            hint: "Papirus-Dark matches the dark glass look"
            Dropdown {
                width: 240
                options: page.themes
                current: Config.appearance.iconTheme
                onPicked: v => Config.set("appearance", "iconTheme", v)
            }
        }
    }
    ResetGroup { sections: ["appearance"]; keys: ["iconTheme"] }
}
