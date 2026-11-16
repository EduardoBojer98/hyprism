import Quickshell
import QtQuick
import QtQuick.Layouts

// Launcher part: the right-click menu for an app (apps grid, results, home): open, the app's own actions
// (New private window, …), pin to the dock, show in Files, app info, uninstall. It opens at the pointer, or on
// the selected app with the Menu key or Shift+F10; Esc, a click outside it or picking a row closes it.
// Lives inside the launcher's own window (Launcher.qml), so the launcher keeps the keyboard. Open with Launcher.menuFor().
Item {
    id: root
    property var entry: null        // DesktopEntry
    property point at
    visible: entry !== null
    readonly property bool pinned: entry ? Config.dock.pinned.includes(entry.id) : false

    function openFor(e, item, x, y) {
        at = item ? item.mapToItem(root, x ?? item.width / 2, y ?? item.height / 2) : Qt.point(width / 2, height / 3)
        entry = e
        Qt.callLater(() => list.move(0, 0))   // the keyboard on the first row
    }
    function done() { entry = null; Launcher.field.forceActiveFocus() }
    // close the menu, then act on the app it was for
    function pick(f) { const e = entry; done(); f(e) }
    function launch(f) { pick(e => { Launcher.close(); Search.remember("app:" + e.id); f(e) }) }

    // a click (or hover) anywhere else: the menu closes and the rows under it don't react
    MouseArea { anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.AllButtons; onClicked: root.done() }

    Glass {
        strong: true
        Accessible.role: Accessible.PopupMenu
        Accessible.name: (root.entry?.name ?? "") + " menu"
        radius: Theme.radius
        width: Math.round(230 * Theme.density)
        height: list.implicitHeight + Theme.spaceS * 2
        // at the pointer, kept inside the launcher
        x: Math.max(Theme.spaceS, Math.min(root.at.x, root.width - width - Theme.spaceS))
        y: Math.max(Theme.spaceS, Math.min(root.at.y, root.height - height - Theme.spaceS))
        MouseArea { anchors.fill: parent; hoverEnabled: true }   // clicks between rows stay in the menu

        MenuList {
            id: list
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.spaceS }
            Keys.onEscapePressed: root.done()

            Text {
                Layout.fillWidth: true
                leftPadding: Theme.spaceS; bottomPadding: Theme.spaceXs
                text: root.entry?.name ?? ""; elide: Text.ElideRight
                color: Theme.subtext; font { family: Theme.font; pixelSize: Theme.fontCaption; weight: Font.DemiBold }
            }
            MenuRow { glyph: "\u{F03CC}"; label: "Open"; onClicked: root.launch(e => e.execute()) }
            Repeater {   // the app's own actions from its desktop entry
                model: root.entry?.actions ?? []
                MenuRow {
                    required property var modelData
                    label: modelData.name
                    iconSource: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                    onClicked: root.launch(() => modelData.execute())
                }
            }
            MenuDivider {}
            MenuRow {
                glyph: root.pinned ? "\u{F0931}" : "\u{F0403}"
                label: root.pinned ? "Unpin from Dock" : "Pin to Dock"
                onClicked: {
                    const pin = !root.pinned
                    root.pick(e => Config.set("dock", "pinned", Config.dock.pinned.filter(id => id !== e.id).concat(pin ? [e.id] : [])))
                }
            }
            MenuRow { glyph: "\u{F024B}"; label: "Show in Files"; onClicked: root.pick(e => { Launcher.close(); Quickshell.execDetached(["installed-apps", "show", e.id]) }) }
            MenuRow { glyph: "\u{F02FD}"; label: "App Info"; onClicked: root.pick(() => { Launcher.close(); SettingsApp.show("installed") }) }
            MenuDivider {}
            // packages: a terminal lists what goes and asks first; your own entries go to the Trash
            MenuRow {
                glyph: "\u{F0A7A}"; label: "Uninstall"; danger: true
                onClicked: root.pick(e => { Launcher.close(); Quickshell.execDetached(["sh", "-c",
                    'installed-apps remove "$1" || notify-send -a Launcher "Can\'t uninstall $2" "It did not come from a package or Flatpak. App Info shows where it lives."',
                    "sh", e.id, e.name]) })
            }
        }
    }
}
