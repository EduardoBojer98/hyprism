import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Icons: the icon theme for GTK apps and this session. The shell's own icons use Papirus-Dark
// (shell.qml pragma, applied at the next shell restart). Qt/KDE apps (Dolphin) follow KDE's
// icon setting, which this page never changes; it is already Papirus.
// "Add theme" installs a downloaded theme for you only (~/.local/bin/theme-add).
ColumnLayout {
    id: page
    spacing: 20
    property var themes: []
    property string status: ""

    Process {
        id: lister
        running: true
        command: ["sh", "-c", "for d in \"$HOME/.local/share/icons\"/* \"$HOME/.icons\"/* /usr/share/icons/*; do [ -f \"$d/index.theme\" ] && ! [ -d \"$d/cursors\" ] && basename \"$d\"; done | sort -u"]
        stdout: StdioCollector { onStreamFinished: page.themes = text.trim().split("\n").filter(t => t && t !== "default" && t !== "hicolor" && t !== "locolor") }
    }
    ThemeAdder {
        id: adder
        kind: "icons"
        onDone: (names, error) => {
            page.status = error || "Added " + names.join(", ")
            if (names.length) { Config.set("appearance", "iconTheme", names[0]); lister.running = true }
        }
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
        SettingRow {
            label: "Add a theme"
            hint: page.status !== "" ? page.status : "A downloaded .tar.gz, .tar.xz or .zip (e.g. from store.kde.org or gnome-look.org), or an unpacked folder"
            PillButton { text: "From file…"; onClicked: adder.pickFile() }
            PillButton { text: "From folder…"; onClicked: adder.pickFolder() }
        }
    }
    ResetGroup { sections: ["appearance"]; keys: ["iconTheme"] }
}
