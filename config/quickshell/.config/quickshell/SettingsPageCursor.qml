import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Cursor: theme and size for Hyprland, GTK and new apps (ThemeSync applies it live with
// hyprctl setcursor + gsettings; hypr/modules/env.lua reads it at login). Apps that are already
// open keep their old cursor until they restart. KDE keeps its own cursor setting.
ColumnLayout {
    id: page
    spacing: 20
    property var themes: []
    property string status: ""

    Process {
        id: lister
        running: true
        command: ["sh", "-c", "for d in \"$HOME/.local/share/icons\"/* \"$HOME/.icons\"/* /usr/share/icons/*; do [ -d \"$d/cursors\" ] && basename \"$d\"; done | sort -u"]
        stdout: StdioCollector { onStreamFinished: page.themes = ["default"].concat(text.trim().split("\n").filter(t => t && t !== "default")) }
    }
    ThemeAdder {
        id: adder
        kind: "cursors"
        onDone: (names, error) => {
            page.status = error || "Added " + names.join(", ")
            if (names.length) { Config.set("appearance", "cursorTheme", names[0]); lister.running = true }
        }
    }

    SettingGroup {
        SettingRow {
            label: "Cursor theme"
            hint: Theme.cursorTheme === "default" ? (Config.appearance.cursorTheme === "theme" ? Theme.current.name + " uses your system's cursor" : "default is your system's cursor")
                : !page.themes.includes(Theme.cursorTheme) ? Theme.cursorTheme + " isn't installed, so apps use the default cursor (Add theme… below)"
                : Config.appearance.cursorTheme === "theme" ? Theme.current.name + " uses " + Theme.cursorTheme : ""
            Dropdown {
                width: 240
                options: ["Theme's own"].concat(page.themes)
                current: Config.appearance.cursorTheme === "theme" ? "Theme's own" : Config.appearance.cursorTheme
                onPicked: v => Config.set("appearance", "cursorTheme", v === "Theme's own" ? "theme" : v)
            }
        }
        SettingRow {
            label: "Size"
            Dropdown {
                width: 120
                options: ["24", "32", "40", "48"]
                current: String(Config.appearance.cursorSize)
                onPicked: v => Config.set("appearance", "cursorSize", Number(v))
            }
        }
        SettingRow {
            label: "Add a theme"
            hint: page.status !== "" ? page.status : "A downloaded .tar.gz, .tar.xz or .zip (e.g. from store.kde.org or gnome-look.org), or an unpacked folder"
            PillButton { text: "From file…"; onClicked: adder.pickFile() }
            PillButton { text: "From folder…"; onClicked: adder.pickFolder() }
        }
    }
    ResetGroup { sections: ["appearance"]; keys: ["cursorTheme", "cursorSize"] }
}
