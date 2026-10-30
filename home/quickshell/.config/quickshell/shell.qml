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
    Component.onCompleted: Launcher.open = false // create the launcher now so its IPC handler exists
    Notifications {}
}
