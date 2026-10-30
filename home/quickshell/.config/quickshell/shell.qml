//@ pragma IconTheme Papirus-Dark
//@ pragma UseQApplication
// Desktop shell: top bar + dock on every screen, one OSD and one notification stack.
// Started by hypr/modules/autostart.lua; reloads itself when a file here changes.
import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        Scope {
            required property ShellScreen modelData

            Bar { screen: modelData }
            Dock { screen: modelData }
        }
    }

    Osd {}
    ThemeSync {}
    // Create the singletons with IPC handlers now, so `qs ipc call …` works before first use
    Component.onCompleted: { Launcher.category = "All"; SettingsApp.open = false; Clipboard.filter = ""; Caffeine.minutes = 0; NightLight.now = new Date(); Panels.objectName = "panels" }
    Notifications {}
}
