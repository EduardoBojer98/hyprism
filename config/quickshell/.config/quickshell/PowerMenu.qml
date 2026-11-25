pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Power menu (utility menu > Power…, the Control Center's power button, `qs ipc call power toggle`):
// a glass card centred on the focused screen over a dimmed backdrop. Tiles in 3, 2 or 1 columns,
// whatever fits the screen; on a narrow screen they become compact rows.
//   Click or arrows + Enter, or an action's key (L S H O R P) or number (1-6) · Log out, Restart and
//   Shut down ask for a second press · Esc or a click outside closes.
// Layout: Settings > Power Menu (Config.powerMenu.layout), or "theme" for theme.json power.style: tiles (icon
// tiles) | row (one line of round buttons) | blocks (giant display-type blocks with their key, hard shadows) |
// list (a numbered mono list: 1) lock  2) sleep ...). Which actions, in what order: Config.powerMenu.actions.
// The contents are PowerMenuBody, which Settings also draws as its preview.
Singleton {
    id: root

    property bool open: false
    property int selected: 0
    property string confirming: ""     // id of the action waiting for its second press
    property string host: ""
    property string uptime: ""
    readonly property string style: Config.powerMenu.layout !== "theme" ? Config.powerMenu.layout : Theme.current.power?.style ?? "tiles"
    readonly property bool details: Config.powerMenu.details

    // the chosen ones in their order; hibernate only where it works; none chosen: all of them
    function pickActions(ids) {
        const list = ids.map(id => allActions.find(a => a.id === id)).filter(a => a && (a.id !== "hibernate" || Machine.canHibernate))
        return list.length ? list : allActions.filter(a => a.id !== "hibernate" || Machine.canHibernate)
    }
    readonly property var actions: pickActions(Config.powerMenu.actions)
    readonly property var allActions: [
        { id: "lock", key: "L",      icon: "\u{F033E}", label: "Lock",      cmd: "loginctl lock-session" },
        { id: "suspend", key: "S",   icon: "\u{F04B2}", label: "Sleep",     cmd: "systemctl suspend" },
        { id: "hibernate", key: "H", icon: "\u{F0717}", label: "Hibernate", cmd: "systemctl hibernate" },
        { id: "logout", key: "O",    icon: "\u{F0343}", label: "Log out",   cmd: "hyprshutdown", confirm: true },
        { id: "reboot", key: "R",    icon: "\u{F0709}", label: "Restart",   cmd: "systemctl reboot", confirm: true },
        { id: "poweroff", key: "P",  icon: "\u{F0425}", label: "Shut down", cmd: "systemctl poweroff", confirm: true, danger: true },
    ]

    function show() { selected = 0; confirming = ""; info.running = true; open = true }
    function hide() { open = false; confirming = "" }
    function toggle() { if (open) hide(); else show() }
    function activate(i) {
        const a = actions[i]
        selected = i
        if (a.confirm && Config.powerMenu.confirm && confirming !== a.id) { confirming = a.id; confirmReset.restart(); return }
        hide()
        // after the fade, so the lock screen or logout doesn't capture the menu
        Quickshell.execDetached(["sh", "-c", "sleep 0.25; " + a.cmd])
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.toggle() }
    }

    Process {
        id: info
        command: ["sh", "-c", "uname -n; uptime -p | sed 's/^up //'"]
        stdout: StdioCollector { onStreamFinished: { const l = text.trim().split("\n"); root.host = l[0] ?? ""; root.uptime = l[1] ?? "" } }
    }
    Timer { id: confirmReset; interval: 4000; onTriggered: root.confirming = "" }

    Overlay {
        id: card
        name: "power"
        open: root.open
        cardWidth: root.style === "blocks" ? 720 : root.style === "list" ? 480 : root.style === "row" ? Math.max(440, root.actions.length * 104 + Theme.spaceXl * 2) : 600
        cardHeight: content.implicitHeight + pad * 2
        onDismissed: root.hide()
        readonly property int pad: screenWidth - margin * 2 < 360 ? Theme.spaceL : Theme.spaceXl
        onKeyPressed: event => {
            const n = root.actions.length, cols = content.columns
            const t = event.text.toUpperCase(), byKey = root.actions.findIndex(a => a.key === t)
            if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) return
            if (event.key === Qt.Key_Escape) root.hide()
            else if (byKey >= 0) root.activate(byKey)
            else if (t >= "1" && t <= "9" && Number(t) <= n) root.activate(Number(t) - 1)
            else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) root.selected = (root.selected + 1) % n
            else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) root.selected = (root.selected - 1 + n) % n
            else if (event.key === Qt.Key_Down) root.selected = Math.min(n - 1, root.selected + cols)
            else if (event.key === Qt.Key_Up) root.selected = Math.max(0, root.selected - cols)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) root.activate(root.selected)
            else return
            if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Space && byKey < 0 && !(t >= "1" && t <= "9")) root.confirming = ""
            event.accepted = true
        }

        Flickable {   // scrolls only on very short screens
            anchors { fill: parent; margins: card.pad }
            contentHeight: content.implicitHeight
            clip: contentHeight > height
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds

            PowerMenuBody {
                id: content
                width: parent.width
                menu: root
            }
        }
    }
}
