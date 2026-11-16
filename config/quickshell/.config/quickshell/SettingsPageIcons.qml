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
    property string status: ""

    ThemeAdder {
        id: adder
        kind: "icons"
        onDone: (names, error) => {
            page.status = error || "Added " + names.join(", ")
            if (names.length) { Config.set("appearance", "iconTheme", names[0]); cards.reload() }
        }
    }

    SettingGroup {
        title: "Icon theme"
        Text {
            Layout.fillWidth: true
            Layout.margins: 16
            Layout.bottomMargin: 0
            text: "App icons in the dock, launcher and lists (Papirus and breeze switch to their light or dark set with the theme)"
            color: Theme.subtext
            wrapMode: Text.Wrap
            font { family: Theme.font; pixelSize: Theme.fontLabel }
        }
        ThemeCards { id: cards; kind: "icons"; key: "iconTheme"; own: Theme.current.icons || "Papirus" }
        SettingRow {
            label: "Add a theme"
            hint: page.status !== "" ? page.status : "A downloaded .tar.gz, .tar.xz or .zip (e.g. from store.kde.org or gnome-look.org), or an unpacked folder"
            PillButton { text: "From file…"; onClicked: adder.pickFile() }
            PillButton { text: "From folder…"; onClicked: adder.pickFolder() }
        }
    }
    SettingGroup {
        SettingRow {
            label: "Tray icons in the bar's colour"
            hint: "Matches the bar's own icons; off keeps each app's colours"
            ConfigToggle { section: "appearance"; key: "monoTray" }
        }
    }
    ResetGroup { sections: ["appearance"]; keys: ["iconTheme"] }
}
