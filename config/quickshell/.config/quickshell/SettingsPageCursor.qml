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
    property string status: ""

    ThemeAdder {
        id: adder
        kind: "cursors"
        onDone: (names, error) => {
            page.status = error || "Added " + names.join(", ")
            if (names.length) { Config.set("appearance", "cursorTheme", names[0]); cards.reload() }
        }
    }

    SettingGroup {
        title: "Cursor theme"
        Text {
            readonly property string why: Theme.cursorTheme !== "default" && cards.list.length && !cards.themes.includes(Theme.cursorTheme)
                ? Theme.cursorTheme + " isn't installed, so apps use the default cursor (Add a theme below). " : ""
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 0
            text: why + "The pointer in Hyprland, GTK and new apps; open apps change when they restart"
            color: Theme.subtext
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        ThemeCards { id: cards; kind: "cursors"; key: "cursorTheme"; own: Theme.current.cursor || "default" }
        SettingRow {
            label: "Add a theme"
            hint: page.status !== "" ? page.status : "A downloaded .tar.gz, .tar.xz or .zip (e.g. from store.kde.org or gnome-look.org), or an unpacked folder"
            PillButton { text: "From file…"; onClicked: adder.pickFile() }
            PillButton { text: "From folder…"; onClicked: adder.pickFolder() }
        }
    }
    SettingGroup {
        SettingRow {
            label: "Size"
            Dropdown {
                width: 120
                options: ["24", "32", "40", "48"]
                current: String(Config.appearance.cursorSize)
                onPicked: v => Config.set("appearance", "cursorSize", Number(v))
            }
        }
    }
    ResetGroup { sections: ["appearance"]; keys: ["cursorTheme", "cursorSize"] }
}
