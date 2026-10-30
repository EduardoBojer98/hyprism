pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick

// Notification server (replaces mako). New notifications pop up as banners in the top-right
// corner of the focused screen and stay in the history, which the notification centre shows
// (click the clock, Super+N). Do Not Disturb (Config.notifications.dnd) keeps everything but
// critical ones out of the banners. A notification leaves the history when you dismiss it or
// the app withdraws it; the oldest go past Config.notifications.historyMax.
// shortcut: the history lives in memory, so restarting the shell empties it.
Singleton {
    id: root

    property var history: []     // Notification objects, newest first
    property var popups: []      // the ones showing as banners now
    property var times: ({})     // id -> arrival time (ms)
    property int unread: 0       // arrived since the notification centre was last opened
    property date now: new Date()
    readonly property bool dnd: Config.notifications.dnd

    // history by app, the app with the newest notification first
    readonly property var groups: {
        const out = []
        for (const n of history) {
            const app = n.appName || "Other"
            let g = out.find(x => x.app === app)
            if (!g) { g = { app: app, items: [] }; out.push(g) }
            g.items.push(n)
        }
        return out
    }

    function timeOf(n) { return times[n.id] ?? Date.now() }
    function ago(n) {
        const s = Math.max(0, (now.getTime() - timeOf(n)) / 1000)
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + "m ago"
        if (s < 86400) return Math.floor(s / 3600) + "h ago"
        return Qt.formatDateTime(new Date(timeOf(n)), "d MMM HH:mm")
    }
    function iconOf(n) {
        const src = (n.image || n.appIcon || n.desktopEntry) ?? ""
        return src === "" ? "" : src.startsWith("/") || src.includes("://") ? src : Quickshell.iconPath(src, true)
    }

    function hidePopup(n) { popups = popups.filter(x => x !== n) }
    // Click: the app's default action if it has one (that also closes it), otherwise just close it
    function activate(n) {
        const action = n.actions.find(a => a.identifier === "default")
        if (action) action.invoke()
        if (!action || n.resident) n.dismiss()
    }
    function clearApp(app) { for (const n of history.filter(x => (x.appName || "Other") === app)) n.dismiss() }
    function clearAll() { for (const n of history.slice()) n.dismiss() }
    function toggleDnd() { Config.set("notifications", "dnd", !dnd) }

    function forget(n) {
        history = history.filter(x => x !== n)
        hidePopup(n)
        const t = Object.assign({}, times); delete t[n.id]; times = t
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true
        onNotification: n => {
            n.tracked = true
            const t = Object.assign({}, root.times); t[n.id] = Date.now(); root.times = t
            n.closed.connect(() => root.forget(n))
            if (!n.transient) {
                root.history = [n].concat(root.history.filter(x => x !== n))
                if (!NotificationCenter.open) root.unread++
                for (const old of root.history.slice(Config.notifications.historyMax)) old.dismiss()
            }
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n].concat(root.popups.filter(x => x !== n))
            else if (n.transient) n.expire()
        }
    }

    // notifications kept across a shell reload come back without a new onNotification
    Component.onCompleted: {
        const kept = server.trackedNotifications.values.slice().reverse()
        for (const n of kept) n.closed.connect(() => root.forget(n))
        history = kept.filter(n => !n.transient)
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = new Date() }

    IpcHandler {
        target: "notifications"
        function toggle(): void { NotificationCenter.toggle() }
        function dnd(): void { root.toggleDnd() }
        function clear(): void { root.clearAll() }
        function status(): string { return JSON.stringify({ count: root.history.length, unread: root.unread, dnd: root.dnd }) }
    }

    // Banners
    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        anchors { top: true; right: true }
        margins { top: 8; right: 10 }
        implicitWidth: 344
        implicitHeight: Math.max(1, list.contentHeight)
        exclusiveZone: 0
        color: "transparent"
        visible: root.popups.length > 0 || list.count > 0
        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        ListView {
            id: list
            anchors.fill: parent
            spacing: 8
            interactive: false
            model: ScriptModel { values: root.popups.slice(0, 5) }

            // slide in from the right edge with a fade; leave by fading and drifting right
            add: Transition { ParallelAnimation {
                NumberAnimation { property: "x"; from: 60; to: 0; duration: Theme.anim + 60; easing.type: Easing.OutQuint }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.anim }
            } }
            remove: Transition { ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.anim }
                NumberAnimation { property: "x"; to: 40; duration: Theme.anim; easing.type: Easing.InCubic }
            } }
            displaced: Transition { NumberAnimation { property: "y"; duration: Theme.anim; easing.type: Easing.OutCubic } }

            delegate: NotificationCard {
                id: banner
                required property Notification modelData
                width: list.width
                notification: modelData
                banner: true

                Timer {
                    readonly property int app: banner.modelData?.expireTimeout ?? 0
                    running: banner.modelData?.urgency !== NotificationUrgency.Critical && !banner.hovered
                    interval: app > 0 ? app * 1000 : Config.notifications.timeoutSec * 1000
                    onTriggered: {
                        root.hidePopup(banner.modelData)
                        if (banner.modelData?.transient) banner.modelData.expire()
                    }
                }
            }
        }
    }
}
