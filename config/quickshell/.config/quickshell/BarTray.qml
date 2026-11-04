import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick

// App tray icons. Left click: the app's action, right click: its menu, middle: its second action.
Grid {
    id: tray
    property bool vertical: false
    property int iconSize: 16
    readonly property bool shown: SystemTray.items.values.some(i => i.status !== Status.Passive)
    rows: vertical ? 99 : 1
    columns: vertical ? 1 : 99
    spacing: 2
    Repeater {
        model: SystemTray.items
        BarItem {
            id: trayItem
            required property SystemTrayItem modelData
            vertical: tray.vertical
            // Passive = "nothing to show right now" (e.g. the update notifier when up to date)
            visible: modelData.status !== Status.Passive
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: button => {
                if (button === Qt.MiddleButton) modelData.secondaryActivate()
                else if (button === Qt.RightButton || modelData.onlyMenu) { if (modelData.hasMenu) trayMenu.open = !trayMenu.open }
                else modelData.activate()
            }
            onScrolled: d => modelData.scroll(d * 120, false)
            IconImage { implicitSize: tray.iconSize; source: trayItem.modelData.icon }
            TrayMenu { id: trayMenu; anchorItem: trayItem; menu: trayItem.modelData.menu }
        }
    }
}
