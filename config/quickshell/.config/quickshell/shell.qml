//@ pragma IconTheme Papirus-Dark
//@ pragma UseQApplication
// Desktop shell: a bar and a dock on every screen (Settings decides which), one OSD and one notification stack.
// Started by hypr/modules/autostart.lua; reloads itself when a file here changes.
import Quickshell
import QtQuick

ShellRoot {
    // the bars wait for the theme folders to be read (a few moments), so the first frame is already your theme
    LazyLoader {
        active: Themes.ready
        Variants {
            model: Quickshell.screens

            Scope {
                required property ShellScreen modelData

                Bar { screen: modelData }
                LazyLoader { active: Theme.dockShownOn(modelData); Dock { screen: modelData } }
                HotCorners { screen: modelData }
            }
        }
    }

    Osd {}
    BatteryWarning {}
    ThemeSync {}
    SettingsSync {}   // settings.json -> hypridle, input, displays, monswitch files
    // Create the singletons with IPC handlers now, so `qs ipc call …` works before first use
    Component.onCompleted: { Machine.asus; Launcher.category = "All"; SettingsApp.open = false; Clipboard.filter = ""; Caffeine.minutes = 0; NightLight.now = new Date(); ControlCenter.expanded = ""; UtilityMenu.host; PowerMenu.open; Cheatsheet.open; Welcome.open; Inputs.touchpad; Sys.recording; Notifications.unread = 0; NotificationCenter.unfolded = ({}); MissionControl.selected = -1; Calendar.month = new Date(); Wallpapers.images; WallpaperColours.own; WindowMenu.addr }
}
