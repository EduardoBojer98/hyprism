pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick

// Notification server (replaces mako). New notifications pop up as banners on the focused screen, in the
// theme's corner and look unless Settings > Notifications picks others (position, style), and stay in the
// history, which the notification centre shows (the bell, Super+N). Do Not Disturb (on by hand, or on a daily
// schedule) keeps everything but critical ones out of the banners. Each urgency has its own time on screen
// and sound. `qs ipc call notifications test` sends one through this server, the way an app would. A notification leaves the history when you dismiss it or
// the app withdraws it; the oldest go past Config.notifications.historyMax.
// The history is saved to ~/.local/state/hyprism/notifications.json, so a shell restart keeps it. A saved
// one comes back as a plain record (text, icon, time): it can be read and dismissed, its app's buttons are gone.
Singleton {
    id: root

    property var history: []     // Notification objects, newest first
    property var popups: []      // the ones showing as banners now
    property var times: ({})     // id -> arrival time (ms)
    property real seenAt: 0      // when the notification centre was last open
    // arrived since then and still in the history: counted from the history, so a dismissed or withdrawn one leaves the count
    readonly property int unread: NotificationCenter.open ? 0 : history.filter(n => (times[n.id] ?? 0) > seenAt).length
    property date now: new Date()
    readonly property var c: Config.notifications
    // the banners' look and place: Settings, or the theme's (Themes.qml notify.kind / corner)
    readonly property string kind: c.style === "theme" ? Theme.current.notify.kind : c.style
    readonly property string corner: c.position === "theme" ? Theme.current.notify.corner : c.position
    // Do Not Disturb: on by hand, or inside the daily schedule (unless turned off for the rest of this window)
    readonly property bool scheduled: c.dndSchedule && inWindow(now, c.dndFrom, c.dndTo) && now.getTime() >= skipUntil
    readonly property bool dnd: c.dnd || scheduled || Focus.dnd   // a Focus mode can hold notifications too (Focus.qml)
    readonly property string dndStatus: c.dnd ? "On" : Focus.dnd ? Focus.mode.name : scheduled ? "Until " + c.dndTo : "Off"
    property real skipUntil: 0     // the schedule was turned off by hand until then (ms)
    property bool sharing: false   // a screen or window is being shared: no banners for people on the call to read

    // Hyprland sends "screencast>>1,<owner>" when a share starts and "screencast>>0,<owner>" when it stops
    // (screenshots send both at once, which just clears the banners from the shot).
    // shortcut: a shell restart during a share forgets it until the next share starts; fine unless that bites.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "screencast") return
            root.sharing = event.data.startsWith("1")
            if (root.sharing) root.popups = root.popups.filter(n => n.urgency === NotificationUrgency.Critical)
        }
    }

    // history by app, the app with the newest notification first; not grouping: each one on its own, newest first
    readonly property var groups: {
        const out = []
        if (!Config.notifications.groupByApp) return history.map(n => ({ app: n.appName || "Other", items: [n] }))
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

    // ---- sound: Config.notifications.sound (a freedesktop sound name, "" = none) at .volume
    readonly property var sounds: ({ "message-new-instant": "Chime", "message": "Message", "bell": "Bell",
                                     "complete": "Complete", "dialog-information": "Soft", "window-attention": "Attention" })
    property double lastSound: 0
    function playSound(name) {
        if (!name || Date.now() - lastSound < 800) return   // a burst of notifications plays once
        lastSound = Date.now()
        Quickshell.execDetached(["pw-play", "--volume", String(Config.notifications.volume / 100),
                                 "/usr/share/sounds/freedesktop/stereo/" + name + ".oga"])
    }
    function muted(n) { return Config.notifications.mutedApps.includes(n.appName || "Other") }

    function hidePopup(n) { popups = popups.filter(x => x !== n) }
    // Click: the app's default action if it has one (that also closes it), otherwise just close it
    function activate(n) {
        const action = n.actions.find(a => a.identifier === "default")
        if (action) action.invoke()
        if (!action || n.resident) n.dismiss()
    }
    function clearApp(app) { for (const n of history.filter(x => (x.appName || "Other") === app)) n.dismiss() }
    function clearAll() { for (const n of history.slice()) n.dismiss() }
    function minutes(hhmm) { const p = String(hhmm).split(":"); return Number(p[0]) * 60 + Number(p[1]) }
    // from-to on the clock, across midnight when `to` is earlier (22:00-07:00)
    function inWindow(d, from, to) {
        const t = d.getHours() * 60 + d.getMinutes(), a = minutes(from), b = minutes(to)
        return a === b ? false : a < b ? t >= a && t < b : t >= a || t < b
    }
    function windowEnd() {   // the next time the schedule ends
        const end = new Date(); end.setHours(0, minutes(c.dndTo), 0, 0)
        if (end.getTime() <= Date.now()) end.setDate(end.getDate() + 1)
        return end.getTime()
    }
    function toggleDnd() {
        now = new Date()
        if (dnd) { if (Focus.dnd) Focus.off(); if (scheduled) skipUntil = windowEnd(); if (c.dnd) Config.set("notifications", "dnd", false) }
        else { skipUntil = 0; Config.set("notifications", "dnd", true) }
    }
    function timeoutOf(n) {   // ms on screen; 0 = until dismissed. An app's own timeout wins, except for critical ones
        if (n?.urgency === NotificationUrgency.Critical) return c.timeoutCriticalSec * 1000
        if ((n?.expireTimeout ?? 0) > 0) return n.expireTimeout * 1000
        return (n?.urgency === NotificationUrgency.Low ? c.timeoutLowSec : c.timeoutSec) * 1000
    }
    function soundOf(n) { return n.urgency === NotificationUrgency.Critical ? c.soundCritical : n.urgency === NotificationUrgency.Low ? c.soundLow : c.sound }
    function appOf(n) { return n?.appName || "Other" }
    function groupOf(n) { return n?.urgency === NotificationUrgency.Critical ? "!" + n.id : appOf(n) }   // critical ones never fold

    // the banners on screen: the newest first, one per app when grouped (with how many more it holds)
    readonly property var shown: (c.groupByApp ? popups.filter((n, i) => popups.findIndex(x => groupOf(x) === groupOf(n)) === i) : popups).slice(0, c.maxVisible)
    function waiting(n) { return c.groupByApp ? popups.filter(x => x !== n && groupOf(x) === groupOf(n)).length : 0 }
    // a banner's time is up: grouped, its app's older banners go with it (they are in the history)
    function expire(n) {
        popups = popups.filter(x => x !== n && !(c.groupByApp && groupOf(x) === groupOf(n)))
        if (n?.transient) n.expire()
    }

    // A test notification, sent over D-Bus to this server like any app's (Settings > Notifications, IPC)
    function test(urgency) {
        const u = ({ low: 0, normal: 1, critical: 2 })[urgency] ?? 1
        const text = [
            ["Low priority test", `Low-priority notifications stay for ${c.timeoutLowSec} s` + (c.soundLow ? " and play their own sound." : " and make no sound.")],
            ["Test notification", `This is how notifications look with your settings. It stays for ${c.timeoutSec} s.`],
            ["Critical test", c.timeoutCriticalSec > 0 ? `Critical notifications stay for ${c.timeoutCriticalSec} s, even during Do Not Disturb.`
                                                      : "Critical notifications stay until you dismiss them, even during Do Not Disturb."]
        ][u]
        post(text[0], text[1], urgency)
    }
    // The desktop's own notification (a failed action, a test), sent over D-Bus to this server like any app's
    function post(summary, body, urgency, icon) {
        const u = ({ low: 0, normal: 1, critical: 2 })[urgency] ?? 1
        Quickshell.execDetached(["gdbus", "call", "--session", "--dest", "org.freedesktop.Notifications",
            "--object-path", "/org/freedesktop/Notifications", "--method", "org.freedesktop.Notifications.Notify",
            // "--": the -1 timeout at the end is a value, not an option
            "--", "Hyprism", "0", icon || "preferences-desktop-notification", summary, body, "[]", `{'urgency': <byte ${u}>}`, "-1"])
    }

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
                for (const old of root.history.slice(Config.notifications.historyMax)) old.dismiss()
            }
            // muted apps, Do Not Disturb and screen sharing (except critical) only go to the notification centre;
            // a Focus mode lets its own apps through
            const held = root.sharing || root.c.dnd || root.scheduled || (Focus.dnd && !Focus.allows(root.appOf(n)))
            if (!root.muted(n) && (!held || n.urgency === NotificationUrgency.Critical)) {
                root.popups = [n].concat(root.popups.filter(x => x !== n))
                if (!n.hints?.["suppress-sound"]) root.playSound(root.soundOf(n))
            } else if (n.transient) n.expire()
        }
    }

    // notifications kept across a shell reload come back without a new onNotification
    Component.onCompleted: {
        const kept = server.trackedNotifications.values.slice().reverse()
        for (const n of kept) n.closed.connect(() => root.forget(n))
        history = kept.filter(n => !n.transient)
        started = true
        if (savedText !== null) restore()
    }

    // ---- saved history ----
    property bool restored: false   // nothing is written before the saved file is read, so it is never emptied
    function record(n) {
        const icon = src => typeof src === "string" && !src.startsWith("image://") ? src : ""   // the server's images don't outlive it
        return { id: n.id, appName: n.appName ?? "", appIcon: icon(n.appIcon), image: icon(n.image), desktopEntry: n.desktopEntry ?? "",
                 summary: n.summary ?? "", body: n.body ?? "", urgency: n.urgency ?? 1, time: timeOf(n) }
    }
    // merged once both the live notifications (kept over a reload) and the file are in, in whichever order they come
    property bool started: false
    property var savedText: null
    function restore() {
        let saved = []
        try { saved = JSON.parse(savedText) } catch (e) {}
        if (!Array.isArray(saved)) saved = []
        const t = Object.assign({}, times), out = []
        const same = (n, r) => n.appName === r.appName && n.summary === r.summary && n.body === r.body
        saved.forEach((r, i) => {
            if (typeof r !== "object" || !r) return
            const live = history.find(n => same(n, r))
            if (live) { t[live.id] = Number(r.time) || t[live.id]; return }   // kept over a reload: keep its age
            const n = Object.assign({ actions: [], hints: ({}) }, r, { id: "saved-" + i + "-" + r.time })
            n.dismiss = () => root.forget(n)
            t[n.id] = Number(r.time) || Date.now()
            out.push(n)
        })
        times = t
        history = history.concat(out).sort((a, b) => timeOf(b) - timeOf(a)).slice(0, Config.notifications.historyMax)
        restored = true
    }
    onHistoryChanged: if (restored) saveLater.restart()
    Timer { id: saveLater; interval: 500; onTriggered: store.setText(JSON.stringify(root.history.map(n => root.record(n)), null, 1)) }
    FileView {
        id: store
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/hyprism/notifications.json"
        onLoaded: { root.savedText = text(); if (root.started) root.restore() }
        onLoadFailed: { root.savedText = "[]"; if (root.started) root.restore() }
    }

    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.now = new Date() }

    IpcHandler {
        target: "notifications"
        function toggle(): void { NotificationCenter.toggle() }
        function dnd(): void { root.toggleDnd() }
        function clear(): void { root.clearAll() }
        function status(): string { return JSON.stringify({ count: root.history.length, unread: root.unread, dnd: root.dnd }) }
        // a test notification through this server: normal, or `testAs low|normal|critical`
        function test(): void { root.test("normal") }
        function testAs(urgency: string): void { root.test(urgency) }
    }

    // Banners
    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        // the corner (or edge centre) from Settings or the theme, kept clear of the bar
        readonly property string place: root.corner
        readonly property bool atBottom: place.startsWith("bottom")
        exclusionMode: ExclusionMode.Ignore
        anchors { top: !atBottom; bottom: atBottom; right: place.endsWith("right"); left: place.endsWith("left") }   // neither: centred
        margins { top: Theme.reserveTop + 10; bottom: Theme.reserveBottom + 10; right: Theme.reserveRight + 12; left: Theme.reserveLeft + 12 }
        implicitWidth: 344
        implicitHeight: Math.max(1, list.contentHeight + (root.c.groupByApp ? 14 : 0))   // grouped: the last stack's peek
        exclusiveZone: 0
        color: "transparent"
        // held while the Control Center or the notification centre is open: they'd land on it, and the
        // notification centre lists them anyway
        visible: (root.popups.length > 0 || list.count > 0) && !ControlCenter.open && !NotificationCenter.open
        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.layer: WlrLayer.Overlay

        ListView {
            id: list
            anchors.fill: parent
            spacing: root.c.groupByApp ? 14 : 8   // grouped: room for a folded stack peeking out underneath
            interactive: false
            model: ScriptModel { values: root.shown }

            // drop in from the corner's edge with a fade (down at the top, up at the bottom), fade out in place
            // in from the corner's edge the theme's way (Theme.travel, its curve), out with a quick fade
            add: Transition { ParallelAnimation {
                NumberAnimation { property: "y"; from: (root.corner.startsWith("bottom") ? 1 : -1) * Theme.travel; duration: Theme.enter
                                  easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.enter; easing.type: Easing.OutCubic }
            } }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.exit } }
            displaced: Transition { NumberAnimation { property: "y"; duration: Theme.anim; easing.type: Easing.OutCubic } }

            delegate: NotificationCard {
                id: banner
                required property Notification modelData
                width: list.width
                notification: modelData
                banner: true
                stacked: root.waiting(modelData)

                Timer {
                    readonly property int ms: root.timeoutOf(banner.modelData)
                    running: ms > 0 && !banner.hovered
                    interval: Math.max(1, ms)
                    onTriggered: root.expire(banner.modelData)
                }
            }
        }
    }
}
